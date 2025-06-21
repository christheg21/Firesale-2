import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct PaymentView: View {
    let items: [Item]
    private let db = Firestore.firestore()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if items.isEmpty {
                    emptyView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(items) { item in
                                itemRow(item)
                            }
                        }
                        .padding(.vertical, 12)
                    }

                    Divider()

                    footerView
                }
            }
            .navigationTitle("Checkout")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.white)
            .onAppear {
                print("PaymentView rendered at \(Date())")
            }
        }
    }

    private var emptyView: some View {
        VStack {
            Image(systemName: "creditcard")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.gray)
            Text("No Items to Checkout")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.gray)
            Text("Add items to your cart to proceed with payment.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func itemRow(_ item: Item) -> some View {
        HStack(spacing: 12) {
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
            .frame(width: 60, height: 60)
            .clipped()
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                Text("Store: \(item.storeName)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            Text("£\(String(format: "%.2f", item.discountPrice))")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.green)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }

    private var footerView: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Total")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                Spacer()
                Text("£\(String(format: "%.2f", items.reduce(0.0) { $0 + $1.discountPrice })))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
            }
            .padding(.horizontal)

            VStack(spacing: 12) {
                Button(action: {
                    completePurchase()
                    print("Pay with Apple Pay at \(Date())")
                }) {
                    HStack {
                        Image(systemName: "applelogo")
                        Text("Pay with Apple Pay")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.black)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.2), radius: 4)
                }
                .accessibilityLabel("Pay with Apple Pay")

                Button(action: {
                    completePurchase()
                    print("Pay with Credit Card at \(Date())")
                }) {
                    HStack {
                        Image(systemName: "creditcard")
                        Text("Pay with Credit Card")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .shadow(color: Color.blue.opacity(0.2), radius: 4)
                }
                .accessibilityLabel("Pay with Credit Card")

                Button(action: {
                    completePurchase()
                    print("Pay with Firesale Wallet at \(Date())")
                }) {
                    HStack {
                        Image(systemName: "wallet.pass")
                        Text("Pay with Firesale Wallet")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.black)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange)
                    .cornerRadius(10)
                    .shadow(color: Color.orange.opacity(0.2), radius: 4)
                }
                .accessibilityLabel("Pay with Firesale Wallet")
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 16)
        .background(Color.gray.opacity(0.05))
    }

    private func completePurchase() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        // Update inventory
        for item in items {
            db.collection("items").document(item.id ?? "").updateData([
                "quantity": FieldValue.increment(Int64(-1))
            ])
        }
        // Clear cart
        db.collection("carts").document(userId).setData([
            "items": [],
            "reservations": [:]
        ])
        // Remove reservations
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
}
