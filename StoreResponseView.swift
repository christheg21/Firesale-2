import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct StoreResponseView: View {
    @State private var reservations: [(reservation: Reservation, item: Item?)] = []
    private let db = Firestore.firestore()

    var body: some View {
        NavigationStack {
            Group {
                if reservations.isEmpty {
                    VStack {
                        Spacer()
                        Image(systemName: "envelope")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                        Text("No Pending Reservations")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                        Text("You'll see reservation requests here when buyers reserve items.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding()
                        Spacer()
                    }
                } else {
                    List(reservations, id: \.reservation.id) { reservation, item in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item?.name ?? "Item ID: \(reservation.itemId)")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                Text("User ID: \(reservation.userId)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                if let item = item {
                                    Text("Price: £\(String(format: "%.2f", item.discountPrice))")
                                        .font(.subheadline)
                                        .foregroundColor(.green)
                                }
                                Text("Status: \(reservation.status.capitalized)")
                                    .font(.subheadline)
                                    .foregroundColor(reservation.status == "accepted" ? .green : reservation.status == "declined" ? .red : .orange)
                                Text("Expires: \(dateFormatter.string(from: reservation.expiresAt.dateValue()))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            if reservation.status == "pending" {
                                HStack(spacing: 8) {
                                    Button(action: {
                                        updateReservationStatus(reservation, status: "accepted")
                                    }) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                    .accessibilityLabel("Accept reservation for item \(item?.name ?? reservation.itemId)")

                                    Button(action: {
                                        updateReservationStatus(reservation, status: "declined")
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                    .accessibilityLabel("Decline reservation for item \(item?.name ?? reservation.itemId)")
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Reservations")
            .onAppear {
                fetchReservations()
            }
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }

    private func fetchReservations() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(userId).getDocument { snapshot, error in
            guard let data = snapshot?.data(), let storeId = data["storeId"] as? String else {
                print("Error fetching user data: \(error?.localizedDescription ?? "No storeId")")
                return
            }
            db.collection("reservations")
                .whereField("storeId", isEqualTo: storeId)
                .whereField("status", isEqualTo: "pending")
                .getDocuments { snapshot, error in
                    if let error = error {
                        print("Error fetching reservations: \(error)")
                        return
                    }
                    let reservations = snapshot?.documents.compactMap { try? $0.data(as: Reservation.self) } ?? []
                    var reservationItems: [(Reservation, Item?)] = []
                    let group = DispatchGroup()
                    for reservation in reservations {
                        group.enter()
                        db.collection("items").document(reservation.itemId).getDocument { doc, error in
                            defer { group.leave() }
                            if let error = error {
                                print("Error fetching item \(reservation.itemId): \(error)")
                                reservationItems.append((reservation, nil))
                                return
                            }
                            let item = try? doc?.data(as: Item.self)
                            reservationItems.append((reservation, item))
                        }
                    }
                    group.notify(queue: .main) {
                        self.reservations = reservationItems.sorted { (res1: (Reservation, Item?), res2: (Reservation, Item?)) in
                            res1.0.createdAt.dateValue() > res2.0.createdAt.dateValue()
                        }
                        print("Fetched \(self.reservations.count) pending reservations")
                    }
                }
        }
    }

    private func updateReservationStatus(_ reservation: Reservation, status: String) {
        db.collection("reservations").document(reservation.id ?? "").updateData([
            "status": status
        ]) { error in
            if let error = error {
                print("Error updating reservation: \(error)")
                return
            }
            // Refresh the list to reflect changes
            fetchReservations()
        }
    }
}

#Preview {
    StoreResponseView()
}
