import SwiftUI
import FirebaseFirestore

struct DealsView: View {
    @Binding var cartItems: [Item]
    @Binding var reservedItems: [Item: Date]
    @Binding var favoriteItems: [Item]
    @State private var items: [Item] = []
    @State private var isGridView = false
    @State private var sortOption: SortOption = .newest
    @State private var isLoading = true
    @State private var fireKitchenExpanded = true
    @State private var fireClothingExpanded = true
    @State private var fireHouseExpanded = true
    private let db = Firestore.firestore()

    private var topFiresales: [Item] {
        Array(items.sorted { $0.discountPercentage > $1.discountPercentage }.prefix(3))
    }
    private var fireKitchenItems: [Item] {
        items.filter { $0.category == "FireKitchen" }
    }
    private var fireClothingItems: [Item] {
        items.filter { $0.category == "FireClothing" }
    }
    private var fireHouseItems: [Item] {
        items.filter { $0.category == "FireHouse" }
    }
    private var sortedFavoriteItems: [Item] {
        sortItems(favoriteItems)
    }
    private var sortedFireKitchenItems: [Item] {
        sortItems(fireKitchenItems)
    }
    private var sortedFireClothingItems: [Item] {
        sortItems(fireClothingItems)
    }
    private var sortedFireHouseItems: [Item] {
        sortItems(fireHouseItems)
    }
    private var categorySections: [(name: String, items: [Item], isExpanded: Binding<Bool>)] {
        [
            ("FireKitchen", sortedFireKitchenItems, $fireKitchenExpanded),
            ("FireClothing", sortedFireClothingItems, $fireClothingExpanded),
            ("FireHouse", sortedFireHouseItems, $fireHouseExpanded)
        ].shuffled()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20, pinnedViews: [.sectionHeaders]) {
                    FeaturedBannerView(items: topFiresales, cartItems: $cartItems, reservedItems: $reservedItems, favoriteItems: $favoriteItems)
                        .frame(height: 200)
                        .padding(.horizontal)
                    
                    Section(header: FilterBarView(selectedSort: $sortOption, isGridView: $isGridView)) {
                        if isLoading {
                            ProgressView("Loading deals...")
                                .frame(maxWidth: .infinity)
                        } else if items.isEmpty {
                            Text("No deals available")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                        } else {
                            FavoritesSection(
                                items: sortedFavoriteItems,
                                cartItems: $cartItems,
                                reservedItems: $reservedItems,
                                favoriteItems: $favoriteItems,
                                isGridView: isGridView
                            )
                            .padding(.horizontal)
                            
                            TopFiresalesSection(
                                items: topFiresales,
                                cartItems: $cartItems,
                                reservedItems: $reservedItems,
                                favoriteItems: $favoriteItems,
                                isGridView: isGridView
                            )
                            .padding(.horizontal)
                            
                            ForEach(categorySections, id: \.name) { section in
                                CategorySection(
                                    name: section.name,
                                    items: section.items,
                                    isExpanded: section.isExpanded,
                                    cartItems: $cartItems,
                                    reservedItems: $reservedItems,
                                    favoriteItems: $favoriteItems,
                                    isGridView: isGridView
                                )
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Deals")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                fetchDeals()
            }
        }
    }

    private func fetchDeals() {
        db.collection("items").getDocuments { snapshot, error in
            defer { isLoading = false }
            if let error = error {
                print("Error fetching deals: \(error)")
                return
            }
            items = snapshot?.documents.compactMap { try? $0.data(as: Item.self) } ?? []
            print("Fetched \(items.count) items")
        }
    }

    private func sortItems(_ items: [Item]) -> [Item] {
        switch sortOption {
        case .priceLowToHigh:
            return items.sorted { $0.discountPrice < $1.discountPrice }
        case .priceHighToLow:
            return items.sorted { $0.discountPrice > $1.discountPrice }
        case .newest:
            return items.sorted { $0.createdAt.dateValue() > $1.createdAt.dateValue() }
        case .oldest:
            return items.sorted { $0.createdAt.dateValue() < $1.createdAt.dateValue() }
        }
    }
}
