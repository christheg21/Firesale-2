import SwiftUI
import FirebaseFirestore

struct SearchView: View {
    @State private var searchText = ""
    @Binding var cartItems: [Item]
    @Binding var reservedItems: [Item: Date]
    @Binding var favoriteItems: [Item]
    @State private var selectedCategory: String? = nil
    @State private var selectedPriceRange: PriceRange? = nil
    @State private var selectedDistance: DistanceFilter? = nil
    @State private var selectedTimeLeft: TimeLeftFilter? = nil
    @State private var sortOption: SearchSortOption = .default
    @State private var recentSearches: [String] = []
    @State private var showRecentSearches = true
    @State private var showStoreInfo: Store? = nil
    @State private var items: [Item] = []
    private let db = Firestore.firestore()
    
    private let suggestedSearches = ["Fresh Bread", "T-Shirts", "Candles", "Pastries"]
    private let categories = ["All", "FireKitchen", "FireClothing", "FireHouse"]

    private var filteredItems: [Item] {
        var filtered = items
        
        // Apply search text filter
        if !searchText.isEmpty {
            filtered = filtered.filter { $0.name.lowercased().contains(searchText.lowercased()) || $0.storeName.lowercased().contains(searchText.lowercased()) }
        }
        
        // Apply category filter
        if let category = selectedCategory, category != "All" {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Apply price range filter
        if let priceRange = selectedPriceRange {
            switch priceRange {
            case .under5: filtered = filtered.filter { $0.discountPrice < 5 }
            case .from5to20: filtered = filtered.filter { $0.discountPrice >= 5 && $0.discountPrice <= 20 }
            case .over20: filtered = filtered.filter { $0.discountPrice > 20 }
            }
        }
        
        // Apply distance filter (simulated)
        if let distance = selectedDistance {
            switch distance {
            case .under1: filtered = filtered.filter { _ in Bool.random() }
            case .from1to5: filtered = filtered.filter { _ in Bool.random() }
            case .over5: filtered = filtered.filter { _ in Bool.random() }
            }
        }
        
        // Apply time left filter
        if let timeLeft = selectedTimeLeft {
            switch timeLeft {
            case .under1day: filtered = filtered.filter { $0.timeLeftInDays < 1 }
            case .from1to3days: filtered = filtered.filter { $0.timeLeftInDays >= 1 && $0.timeLeftInDays <= 3 }
            case .over3days: filtered = filtered.filter { $0.timeLeftInDays > 3 }
            }
        }
        
        // Apply sorting
        switch sortOption {
        case .default:
            return filtered
        case .priceLowToHigh:
            return filtered.sorted { $0.discountPrice < $1.discountPrice }
        case .priceHighToLow:
            return filtered.sorted { $0.discountPrice > $1.discountPrice }
        case .distance:
            return filtered.sorted { _,_ in Bool.random() }
        case .timeLeft:
            return filtered.sorted { timeLeftToMinutes($0.timeLeft) < timeLeftToMinutes($1.timeLeft) }
        case .discount:
            return filtered.sorted { $0.discountPercentage > $1.discountPercentage }
        }
    }
    
    enum SearchSortOption: String, CaseIterable, Identifiable {
        case `default` = "Default"
        case priceLowToHigh = "Price: Low to High"
        case priceHighToLow = "Price: High to Low"
        case distance = "Distance"
        case timeLeft = "Time Left"
        case discount = "Discount"
        
        var id: String { rawValue }
    }
    
    enum PriceRange: String, CaseIterable, Identifiable {
        case under5 = "Under £5"
        case from5to20 = "£5 - £20"
        case over20 = "Over £20"
        
        var id: String { rawValue }
    }
    
    enum DistanceFilter: String, CaseIterable, Identifiable {
        case under1 = "< 1 mile"
        case from1to5 = "1 - 5 miles"
        case over5 = "> 5 miles"
        
        var id: String { rawValue }
    }
    
    enum TimeLeftFilter: String, CaseIterable, Identifiable {
        case under1day = "< 1 day"
        case from1to3days = "1 - 3 days"
        case over3days = "> 3 days"
        
        var id: String { rawValue }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Search Bar
            TextField("Search Deals...", text: $searchText, onCommit: {
                if !searchText.isEmpty && !recentSearches.contains(searchText) {
                    recentSearches.insert(searchText, at: 0)
                    if recentSearches.count > 5 {
                        recentSearches.removeLast()
                    }
                }
            })
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.horizontal)
            .frame(height: 40)
            .foregroundColor(.black)
            .accessibilityLabel("Search deals")
            .accessibilityHint("Enter item or store name to find deals")
            
            // Filter Bar
            HStack(spacing: 8) {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { category in
                        Text(category).tag(category as String?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: 100)
                
                Picker("Price", selection: $selectedPriceRange) {
                    Text("All Prices").tag(nil as PriceRange?)
                    ForEach(PriceRange.allCases) { price in
                        Text(price.rawValue).tag(price as PriceRange?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: 100)
                
                Picker("Sort", selection: $sortOption) {
                    ForEach(SearchSortOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: 100)
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            // Advanced Filters
            HStack(spacing: 8) {
                Picker("Distance", selection: $selectedDistance) {
                    Text("All Distances").tag(nil as DistanceFilter?)
                    ForEach(DistanceFilter.allCases) { distance in
                        Text(distance.rawValue).tag(distance as DistanceFilter?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: 120)
                
                Picker("Time Left", selection: $selectedTimeLeft) {
                    Text("All Times").tag(nil as TimeLeftFilter?)
                    ForEach(TimeLeftFilter.allCases) { time in
                        Text(time.rawValue).tag(time as TimeLeftFilter?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: 120)
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
            
            // Recent Searches
            if !recentSearches.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Recent Searches")
                            .font(.subheadline)
                            .bold()
                            .foregroundColor(.black)
                        Spacer()
                        Button("Clear") {
                            recentSearches.removeAll()
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                        .accessibilityLabel("Clear recent searches")
                    }
                    if showRecentSearches {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(recentSearches, id: \.self) { term in
                                    Button(action: {
                                        searchText = term
                                    }) {
                                        Text(term)
                                            .font(.caption)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(Color.gray.opacity(0.2))
                                            .cornerRadius(10)
                                    }
                                    .accessibilityLabel("Search for \(term)")
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    Button(action: {
                        withAnimation {
                            showRecentSearches.toggle()
                        }
                    }) {
                        Text(showRecentSearches ? "Hide" : "Show")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .accessibilityLabel(showRecentSearches ? "Hide recent searches" : "Show recent searches")
                }
                .padding(.horizontal)
            }
            
            // Suggested Searches
            if searchText.isEmpty && filteredItems.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Suggested Searches")
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.black)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(suggestedSearches, id: \.self) { term in
                                Button(action: {
                                    searchText = term
                                    if !recentSearches.contains(term) {
                                        recentSearches.insert(term, at: 0)
                                        if recentSearches.count > 5 {
                                            recentSearches.removeLast()
                                        }
                                    }
                                }) {
                                    Text(term)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(10)
                                }
                                .accessibilityLabel("Search for \(term)")
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(.horizontal)
            }
            
            // Category Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories, id: \.self) { category in
                        Button(action: {
                            selectedCategory = category == "All" ? nil : category
                        }) {
                            Text(category)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(selectedCategory == category || (category == "All" && selectedCategory == nil) ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(selectedCategory == category || (category == "All" && selectedCategory == nil) ? .white : .black)
                                .cornerRadius(10)
                        }
                        .accessibilityLabel("Filter by \(category)")
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
            }
            
            // Search Results Placeholder (since ItemDetailView and Store are not provided)
            List(filteredItems) { item in
                Text(item.name) // Simplified for compilation; replace with your full item view
            }
        }
        .navigationTitle("Search")
        .onAppear {
            fetchItems()
        }
    }
    
    private func fetchItems() {
        db.collection("items").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching items: \(error)")
                return
            }
            items = snapshot?.documents.compactMap { try? $0.data(as: Item.self) } ?? []
        }
    }
    
    func timeLeftToMinutes(_ timeLeft: String) -> Int {
        let components = timeLeft.split(separator: " ")
        if components.count == 2, let value = Int(components[0]) {
            let unit = components[1].lowercased()
            switch unit {
            case "day", "days":
                return value * 24 * 60
            case "hour", "hours":
                return value * 60
            case "minute", "minutes":
                return value
            default:
                return 0
            }
        }
        return 0
    }
}
