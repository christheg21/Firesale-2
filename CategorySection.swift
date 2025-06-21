import SwiftUI

struct CategorySection: View {
    let name: String
    let items: [Item]
    @Binding var isExpanded: Bool
    @Binding var cartItems: [Item]
    @Binding var reservedItems: [Item: Date]
    @Binding var favoriteItems: [Item]
    let isGridView: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(name)
                        .font(.title2)
                        .bold()
                        .foregroundColor(.black)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.black)
                }
            }
            .accessibilityLabel("\(isExpanded ? "Collapse" : "Expand") \(name) section")
            
            if isExpanded {
                if isGridView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(items.prefix(6)) { item in
                            ItemBoxView(
                                item: item,
                                cartItems: $cartItems,
                                reservedItems: $reservedItems,
                                favoriteItems: $favoriteItems,
                                bottomText: "\(String(format: "%.1f", generateRandomDistance())) miles away",
                                isNavLink: true
                            )
                            .frame(height: 200)
                        }
                    }
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 10) {
                            ForEach(items.prefix(6)) { item in
                                ItemBoxView(
                                    item: item,
                                    cartItems: $cartItems,
                                    reservedItems: $reservedItems,
                                    favoriteItems: $favoriteItems,
                                    bottomText: "\(String(format: "%.1f", generateRandomDistance())) miles away",
                                    isNavLink: true
                                )
                                .frame(width: 250)
                            }
                        }
                    }
                }
                
                NavigationLink(destination: CategoryView(categoryName: name, items: items, cartItems: $cartItems, reservedItems: $reservedItems, favoriteItems: $favoriteItems)) {
                    Text("See All")
                        .foregroundColor(.black)
                        .padding(.vertical, 5)
                }
            }
        }
        .onAppear {
            print("CategorySection \(name) rendered at \(Date())")
        }
    }
}
