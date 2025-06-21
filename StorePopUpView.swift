import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct StorePopupView: View {
    let store: Store
    @Environment(\.dismiss) private var dismiss
    @Binding var cartItems: [Item]
    @Binding var reservedItems: [Item: Date]
    @Binding var favoriteItems: [Item]
    @State private var showBanner: String? = nil
    @State private var storeItems: [Item] = []
    private let db = Firestore.firestore()

    var body: some View {
        VStack(spacing: 16) {
            Text(store.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.black)

            Text("\(String(format: "%.1f", generateRandomDistance())) miles away")
                .font(.subheadline)
                .foregroundColor(.gray)

            Text("Available Deals")
                .font(.headline)
                .foregroundColor(.black)

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(storeItems.prefix(3)) { item in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.name)
                                    .font(.subheadline)
                                    .foregroundColor(.black)
                                Text("£\(String(format: "%.2f", item.discountPrice))")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                Text("Time Left: \(item.timeLeft)")
                                    .font(.caption)
                                    .foregroundColor(item.timeLeftColor)
                            }
                            Spacer()
                            VStack(spacing: 8) {
                                Button(action: {
                                    addToCart(item: item)
                                }) {
                                    Image(systemName: cartItems.contains(where: { $0.id == item.id }) ? "cart.fill" : "cart")
                                        .foregroundColor(.blue)
                                        .frame(width: 24, height: 24)
                                }
                                .disabled(cartItems.contains(where: { $0.id == item.id }))
                                .accessibilityLabel("Add \(item.name) to cart")

                                Button(action: {
                                    toggleFavorite(item: item)
                                }) {
                                    Image(systemName: favoriteItems.contains(where: { $0.id == item.id }) ? "heart.fill" : "heart")
                                        .foregroundColor(.red)
                                        .frame(width: 24, height: 24)
                                }
                                .accessibilityLabel(favoriteItems.contains(where: { $0.id == item.id }) ? "Remove \(item.name) from favorites" : "Add \(item.name) to favorites")
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .frame(maxHeight: 120)

            Button("Close") {
                dismiss()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .accessibilityLabel("Close store popup")

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
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 4)
        .onAppear {
            fetchItems()
            cleanUpExpiredReservations()
        }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            cleanUpExpiredReservations()
        }
    }

    private func fetchItems() {
        db.collection("items")
            .whereField("storeId", isEqualTo: store.id ?? "")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching items for store \(store.id ?? ""): \(error)")
                    return
                }
                storeItems = snapshot?.documents.compactMap { try? $0.data(as: Item.self) } ?? []
                print("Fetched \(storeItems.count) items for store \(store.name)")
            }
    }

    private func addToCart(item: Item) {
        guard !cartItems.contains(where: { $0.id == item.id }), let userId = Auth.auth().currentUser?.uid else { return }
        cartItems.append(item)
        reservedItems[item] = Date()
        showBanner = "\(item.name) added to cart"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showBanner = nil }
        }
        // Save to Firestore
        let reservationId = UUID().uuidString
        let expiresAt = Timestamp(date: Calendar.current.date(byAdding: .hour, value: 24, to: Date())!)
        db.collection("reservations").document(reservationId).setData([
            "itemId": item.id ?? "",
            "userId": userId,
            "storeId": item.storeId,
            "status": "pending",
            "createdAt": Timestamp(date: Date()),
            "expiresAt": expiresAt,
            "quantity": 1
        ])
        db.collection("carts").document(userId).setData([
            "items": try? Firestore.Encoder().encode(cartItems),
            "reservations": [item.id ?? "": Timestamp(date: Date())]
        ], merge: true)
    }

    private func toggleFavorite(item: Item) {
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
        // Save to Firestore
        db.collection("favorites").document(userId).setData([
            "items": try? Firestore.Encoder().encode(favoriteItems)
        ], merge: true)
    }

    private func cleanUpExpiredReservations() {
        let calendar = Calendar.current
        reservedItems = reservedItems.filter { item, reservationDate in
            guard let expirationDate = calendar.date(byAdding: .hour, value: 24, to: reservationDate) else {
                return false
            }
            return Date() < expirationDate
        }
        cartItems.removeAll { item in
            !reservedItems.keys.contains(where: { $0.id == item.id })
        }
        // Sync with Firestore
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let reservations = reservedItems.reduce(into: [String: Timestamp]()) { dict, entry in
            if let id = entry.key.id {
                dict[id] = Timestamp(date: entry.value)
            }
        }
        db.collection("carts").document(userId).setData([
            "items": try? Firestore.Encoder().encode(cartItems),
            "reservations": reservations
        ], merge: true)
    }
}
