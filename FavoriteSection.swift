import SwiftUI

struct FavoritesSection: View {
    let items: [Item]
    @Binding var cartItems: [Item]
    @Binding var reservedItems: [Item: Date]
    @Binding var favoriteItems: [Item]
    let isGridView: Bool
    
    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Favorites")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.black)
                
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
                
                if items.count > 6 {
                    NavigationLink(destination: CategoryView(categoryName: "Favorites", items: items, cartItems: $cartItems, reservedItems: $reservedItems, favoriteItems: $favoriteItems)) {
                        Text("See All")
                            .foregroundColor(.black)
                            .padding(.vertical, 5)
                    }
                }
            }
            .onAppear {
                print("FavoritesSection rendered at \(Date())")
            }
        }
    }
}
