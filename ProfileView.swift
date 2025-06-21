import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ProfileView: View {
    @StateObject private var auth = AuthService()
    @Binding var favoriteItems: [Item]
    private let db = Firestore.firestore()
    private var userName: String {
        auth.user?.email ?? "Unknown User"
    }
    @State private var firesaleScore = 850
    @State private var followers = 120
    @State private var following = 85
    @State private var bio = "Avid deal hunter in London"
    @State private var showShareSheet = false
    private let trophies: [(name: String, milestone: String, progress: Int, target: Int)] = [
        ("Bronze Saver", "10 Deals Reserved", 5, 10),
        ("Silver Shopper", "50 Deals Reserved", 30, 50),
        ("Gold Guru", "100 Deals Reserved", 80, 100)
    ]
    private let recentActivities: [String] = [
        "Added Fresh Bread to cart",
        "Favorited T-Shirt",
        "Purchased Surplus Apples"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Top Section: Profile Photo, Username, Bio, Stats
                    VStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.white)
                            .overlay(
                                Circle()
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)

                        Text(userName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.black)

                        Text(bio)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        HStack(spacing: 24) {
                            VStack {
                                Text("\(followers)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                Text("Followers")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            VStack {
                                Text("\(following)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                Text("Following")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    .padding(.horizontal)

                    // Firesale Score
                    HStack {
                        Text("Firesale Score")
                            .font(.headline)
                            .foregroundColor(.black)
                        Spacer()
                        Text("\(firesaleScore)")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.blue)
                            .cornerRadius(16)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(10)
                    .padding(.horizontal)

                    // Favorites Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Favorites")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.black)

                        if favoriteItems.isEmpty {
                            Text("No favorite items")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(favoriteItems) { item in
                                HStack {
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

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.name)
                                            .font(.subheadline)
                                            .foregroundColor(.black)
                                        Text("Store: \(item.storeName)")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Text("£\(String(format: "%.2f", item.discountPrice))")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                    }

                                    Spacer()

                                    Button {
                                        removeFavorite(item)
                                    } label: {
                                        Image(systemName: "heart.fill")
                                            .foregroundColor(.red)
                                            .padding(8)
                                    }
                                    .accessibilityLabel("Remove \(item.name) from favorites")
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    .padding(.horizontal)

                    // Recent Activity
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent Activity")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.black)

                        if recentActivities.isEmpty {
                            Text("No recent activity")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(recentActivities.prefix(3), id: \.self) { activity in
                                HStack {
                                    Image(systemName: "clock")
                                        .foregroundColor(.gray)
                                    Text(activity)
                                        .font(.subheadline)
                                        .foregroundColor(.black)
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    .padding(.horizontal)

                    // Trophies Grid
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Firesale Trophies")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.black)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(trophies, id: \.name) { trophy in
                                VStack(spacing: 8) {
                                    Image(systemName: "trophy.fill")
                                        .foregroundColor(.yellow)
                                        .font(.title2)
                                    Text(trophy.name)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.black)
                                        .multilineTextAlignment(.center)
                                    Text(trophy.milestone)
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                    ProgressView(value: Float(trophy.progress), total: Float(trophy.target))
                                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                        .frame(height: 4)
                                    Text("\(trophy.progress)/\(trophy.target)")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Action Buttons
                    HStack(spacing: 12) {
                        NavigationLink(destination: FindFriendsView(followingCount: $following)) {
                            Text("Find Friends")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(10)
                                .shadow(color: Color.blue.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                        .accessibilityLabel("Find Friends")

                        NavigationLink(destination: SettingsView()) {
                            Text("Settings")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.gray)
                                .cornerRadius(10)
                                .shadow(color: Color.gray.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                        .accessibilityLabel("Settings")
                    }
                    .padding(.horizontal)

                    Button(action: {
                        showShareSheet = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Profile")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(10)
                        .shadow(color: Color.green.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    .padding(.horizontal)
                    .accessibilityLabel("Share Profile")
                    .sheet(isPresented: $showShareSheet) {
                        ShareSheet(activityItems: ["Check out my Firesale score: \(firesaleScore)! Join me on Firesale to hunt deals!"])
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.gray.opacity(0.02))
            .onAppear {
                auth.listenAuthState()
                print("ProfileView rendered at \(Date())")
            }
        }
    }

    private func removeFavorite(_ item: Item) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        favoriteItems.removeAll { $0.id == item.id }
        // Sync with Firestore
        db.collection("favorites").document(userId).setData([
            "items": try? Firestore.Encoder().encode(favoriteItems)
        ], merge: true) { error in
            if let error = error {
                print("Error updating favorites: \(error)")
            }
        }
    }
}

#if DEBUG
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(favoriteItems: .constant([]))
    }
}
#endif
