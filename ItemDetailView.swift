import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import CoreLocation

struct ItemDetailView: View {
    let item: Item
    @Binding var cartItems: [Item]
    @Binding var reservedItems: [Item: Date]
    @Binding var favoriteItems: [Item]
    @State private var showBanner: String? = nil
    private let db = Firestore.firestore()

    var body: some View {
        VStack(spacing: 16) {
            AsyncImage(url: URL(string: item.photoUrl ?? "")) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFill()
                }
            }
            .frame(height: 200)
            .clipped()
            .cornerRadius(10)

            Text(item.name)
                .font(.title2)
                .bold()
                .foregroundColor(.black)

            Text("Store: \(item.storeName)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Original: £\(String(format: "%.2f", item.originalPrice))")
                .font(.subheadline)
                .foregroundColor(.gray)
                .strikethrough()

            Text("Now: £\(String(format: "%.2f", item.discountPrice)) (\(item.discountPercentage)% OFF)")
                .font(.headline)
                .foregroundColor(.green)

            Text("Time Left: \(item.timeLeft)")
                .font(.subheadline)
                .foregroundColor(item.timeLeftColor)

            Text("Quantity Available: \(item.quantity)")
                .font(.subheadline)
                .foregroundColor(.black)

            HStack(spacing: 12) {
                Button(action: {
                    reserveItem()
                }) {
                    Text("Reserve")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(cartItems.contains(where: { $0.id == item.id }) ? Color.gray : Color.blue)
                        .cornerRadius(10)
                }
                .disabled(cartItems.contains(where: { $0.id == item.id }))
                .accessibilityLabel("Reserve \(item.name)")

                Button(action: {
                    buyNow()
                }) {
                    Text("Buy Now")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(cartItems.contains(where: { $0.id == item.id }) ? Color.gray : Color.green)
                        .cornerRadius(10)
                }
                .disabled(cartItems.contains(where: { $0.id == item.id }))
                .accessibilityLabel("Buy \(item.name)")
            }
            .padding(.horizontal)

            Button(action: {
                toggleFavorite()
            }) {
                Image(systemName: favoriteItems.contains(where: { $0.id == item.id }) ? "heart.fill" : "heart")
                    .foregroundColor(.red)
                    .frame(width: 24, height: 24)
            }
            .accessibilityLabel(favoriteItems.contains(where: { $0.id == item.id }) ? "Remove \(item.name) from favorites" : "Add \(item.name) to favorites")

            if let bannerText = showBanner {
                Text(bannerText)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.green)
                    .cornerRadius(8)
                    .transition(.opacity)
                    .accessibilityLabel(bannerText)
            }

            Spacer()
        }
        .padding()
        .navigationTitle(item.name)
        .onAppear {
            print("ItemDetailView for \(item.name) rendered at \(Date())")
        }
    }

    private func reserveItem() {
        guard !cartItems.contains(where: { $0.id == item.id }), let userId = Auth.auth().currentUser?.uid else { return }
        cartItems.append(item)
        reservedItems[item] = Date()
        showBanner = "Reservation requested for \(item.name)"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showBanner = nil }
        }
        // Save reservation to Firestore
        let reservationId = UUID().uuidString
        let expiresAt = Timestamp(date: Calendar.current.date(byAdding: .hour, value: 24, to: Date())!) // 24-hour reservation
        db.collection("reservations").document(reservationId).setData([
            "itemId": item.id ?? "",
            "userId": userId,
            "storeId": item.storeId,
            "status": "pending",
            "createdAt": Timestamp(date: Date()),
            "expiresAt": expiresAt,
            "quantity": 1
        ])
        // Update cart
        db.collection("carts").document(userId).setData([
            "items": try? Firestore.Encoder().encode(cartItems),
            "reservations": [item.id ?? "": Timestamp(date: Date())]
        ], merge: true)
    }

    private func buyNow() {
        guard !cartItems.contains(where: { $0.id == item.id }), let userId = Auth.auth().currentUser?.uid else { return }
        cartItems.append(item)
        showBanner = "Purchased \(item.name)"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showBanner = nil }
        }
        // Save purchase to Firestore
        let purchaseId = UUID().uuidString
        let pickupBy = Timestamp(date: Calendar.current.date(byAdding: .day, value: 7, to: Date())!) // 7-day pickup
        db.collection("purchases").document(purchaseId).setData([
            "itemId": item.id ?? "",
            "userId": userId,
            "storeId": item.storeId,
            "createdAt": Timestamp(date: Date()),
            "pickupBy": pickupBy,
            "quantity": 1
        ])
        // Update inventory
        db.collection("items").document(item.id ?? "").updateData([
            "quantity": FieldValue.increment(Int64(-1))
        ])
        // Update cart
        db.collection("carts").document(userId).setData([
            "items": try? Firestore.Encoder().encode(cartItems),
            "reservations": [:]
        ], merge: true)
    }

    private func toggleFavorite() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        if favoriteItems.contains(where: { $0.id == item.id }) {
            favoriteItems.removeAll { $0.id == item.id }
            showBanner = "\(item.name) removed from favorites"
        } else {
            favoriteItems.append(item)
            showBanner = "\(item.name) added to favorites"
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showBanner = nil }
        }
        db.collection("favorites").document(userId).setData([
            "items": try? Firestore.Encoder().encode(favoriteItems)
        ], merge: true)
    }
}
