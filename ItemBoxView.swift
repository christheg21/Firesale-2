import SwiftUI

struct ItemBoxView: View {
    let item: Item
    @Binding var cartItems: [Item]
    @Binding var reservedItems: [Item: Date]
    @Binding var favoriteItems: [Item]
    let bottomText: String
    let isNavLink: Bool

    var body: some View {
        if isNavLink {
            NavigationLink(
                destination: ItemDetailView(
                    item: item,
                    cartItems: $cartItems,
                    reservedItems: $reservedItems,
                    favoriteItems: $favoriteItems
                )
            ) {
                itemBoxContent
            }
        } else {
            itemBoxContent
        }
    }

    private var itemBoxContent: some View {
        HStack(alignment: .top, spacing: 10) {
            // Left: Photo
            Image(systemName: "photo")
                .resizable()
                .scaledToFill()
                .frame(width: 110, height: 110)
                .clipped()
                .cornerRadius(10)

            // Right: Details
            VStack(alignment: .leading, spacing: 5) {
                Text(item.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("£\(String(format: "%.2f", item.discountPrice))") // Fix: Use discountPrice
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Text(bottomText)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 5)

            Spacer()
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray, lineWidth: 1)
        )
        .cornerRadius(10)
        .padding(.vertical, 5)
    }
}
