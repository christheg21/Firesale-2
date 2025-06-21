import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct CartView: View {
    @Binding var cartItems: [Item]
    @Binding var reservedItems: [Item: Date]
    @State private var showBanner: String? = nil
    @State private var reservations: [Reservation] = []
    @State private var purchases: [Purchase] = []
    private let db = Firestore.firestore()

    var body: some View {
        NavigationStack {
            contentView
                .navigationTitle("Cart")
                .onAppear {
                    fetchReservationsAndPurchases()
                    print("CartView rendered with \(cartItems.count) items at \(Date())")
                }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if cartItems.isEmpty {
            emptyCartView
        } else {
            nonEmptyCartView
        }
    }

    private var emptyCartView: some View {
        VStack {
            Spacer()
            Image(systemName: "cart")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.gray)
            Text("Your Cart is Empty")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.gray)
            Text("Add items to your cart from Deals or Map!")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding()
            Spacer()
        }
    }

    private var nonEmptyCartView: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(cartItems) { item in
                        cartRow(item)
                    }
                }
                .padding(.vertical, 12)
            }

            Divider()

            footerView

            if let banner = showBanner {
                Text(banner)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.blue)
                    .cornerRadius(8)
                    .transition(.opacity)
                    .padding(.bottom, 8)
            }
        }
    }

    private func cartRow(_ item: Item) -> some View {
        HStack(alignment: .top, spacing: 12) {
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
            .frame(width: 80, height: 80)
            .clipped()
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.headline)
                    .lineLimit(1)
                Text("Store: \(item.storeName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                HStack {
                    Text(String(format: "£%.2f", item.discountPrice))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                    Spacer()
                    Text("Time Left: \(item.timeLeft)")
                        .font(.caption)
                        .foregroundColor(item.timeLeftColor)
                }
                if let reservation = reservations.first(where: { $0.itemId == item.id }) {
                    Text("Reservation Status: \(reservation.status.capitalized)")
                        .font(.caption)
                        .foregroundColor(reservation.status == "accepted" ? .green : reservation.status == "declined" ? .red : .orange)
                } else if purchases.contains(where: { $0.itemId == item.id }) {
                    Text("Purchased: Pickup by \(pickupByText(item))")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }

            Spacer()

            Button {
                remove(item: item)
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .padding(8)
                    .background(Color.red.opacity(0.1))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Remove \(item.name) from cart")
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }

    private var footerView: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Total")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Text(String(format: "£%.2f", cartItems.reduce(0.0) { $0 + $1.discountPrice }))
                    .font(.title3)
                    .fontWeight(.bold)
            }
            .padding(.horizontal)

            HStack(spacing: 12) {
                Button {
                    clearCart()
                } label: {
                    Text("Clear Cart")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(10)
                }
                .accessibilityLabel("Clear cart")
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color.gray.opacity(0.05))
    }

    private func pickupByText(_ item: Item) -> String {
        if let purchase = purchases.first(where: { $0.itemId == item.id }) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            return dateFormatter.string(from: purchase.pickupBy.dateValue())
        }
        return ""
    }

    private func remove(item: Item) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        if let index = cartItems.firstIndex(where: { $0.id == item.id }) {
            let removed = cartItems.remove(at: index)
            reservedItems.removeValue(forKey: item)
            showBanner = "\(removed.name) removed"
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { showBanner = nil }
            }
            // Update Firestore
            db.collection("carts").document(userId).setData([
                "items": try? Firestore.Encoder().encode(cartItems),
                "reservations": reservedItems.reduce(into: [String: Timestamp]()) { dict, entry in
                    if let id = entry.key.id {
                        dict[id] = Timestamp(date: entry.value)
                    }
                }
            ], merge: true)
            // Remove reservation
            db.collection("reservations")
                .whereField("itemId", isEqualTo: item.id ?? "")
                .whereField("userId", isEqualTo: userId)
                .getDocuments { snapshot, error in
                    if let error = error {
                        print("Error removing reservation: \(error)")
                        return
                    }
                    snapshot?.documents.forEach { $0.reference.delete() }
                }
        }
    }

    private func clearCart() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let count = cartItems.count
        cartItems.removeAll()
        reservedItems.removeAll()
        showBanner = "\(count) item(s) cleared"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showBanner = nil }
        }
        // Update Firestore
        db.collection("carts").document(userId).setData([
            "items": [],
            "reservations": [:]
        ])
        // Clear reservations (but not purchases)
        db.collection("reservations")
            .whereField("userId", isEqualTo: userId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error clearing reservations: \(error)")
                    return
                }
                snapshot?.documents.forEach { $0.reference.delete() }
            }
    }

    private func fetchReservationsAndPurchases() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        // Fetch reservations
        db.collection("reservations")
            .whereField("userId", isEqualTo: userId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching reservations: \(error)")
                    return
                }
                reservations = snapshot?.documents.compactMap { try? $0.data(as: Reservation.self) } ?? []
                print("Fetched \(reservations.count) reservations")
            }
        // Fetch purchases
        db.collection("purchases")
            .whereField("userId", isEqualTo: userId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching purchases: \(error)")
                    return
                }
                purchases = snapshot?.documents.compactMap { try? $0.data(as: Purchase.self) } ?? []
                print("Fetched \(purchases.count) purchases")
            }
    }
}
