import SwiftUI

struct TopFiresalesSection: View {
    let items: [Item]
    @Binding var cartItems: [Item]
    @Binding var reservedItems: [Item: Date]
    @Binding var favoriteItems: [Item]
    let isGridView: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Top Firesales")
                .font(.title2)
                .bold()
                .foregroundColor(.black)
            
            if isGridView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(items) { item in
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
                        ForEach(items) { item in
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
        }
        .onAppear {
            print("TopFiresalesSection rendered at \(Date())")
        }
    }
}
