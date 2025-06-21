import Foundation

enum SortOption: String, CaseIterable, Identifiable {
    case priceLowToHigh = "Price: Low to High"
    case priceHighToLow = "Price: High to Low"
    case newest = "Newest"
    case oldest = "Oldest"

    var id: String { self.rawValue }
}
