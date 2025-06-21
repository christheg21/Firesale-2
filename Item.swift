import SwiftUI
import CoreLocation
import FirebaseFirestore

struct Item: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    let name: String
    let originalPrice: Double
    let discountPrice: Double
    let storeName: String
    let timeLeft: String
    let location: CLLocationCoordinate2D
    let quantity: Int
    let storeId: String
    let category: String
    let photoUrl: String?
    let createdAt: Timestamp // Added for sorting by newest/oldest

    init(id: String? = nil, name: String, originalPrice: Double, discountPrice: Double, storeName: String, timeLeft: String, location: CLLocationCoordinate2D, quantity: Int, storeId: String, category: String, photoUrl: String? = nil, createdAt: Timestamp = Timestamp()) {
        self.id = id
        self.name = name
        self.originalPrice = originalPrice
        self.discountPrice = discountPrice
        self.storeName = storeName
        self.timeLeft = timeLeft
        self.location = location
        self.quantity = quantity
        self.storeId = storeId
        self.category = category
        self.photoUrl = photoUrl
        self.createdAt = createdAt
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id ?? UUID().uuidString)
    }

    static func ==(lhs: Item, rhs: Item) -> Bool {
        return lhs.id == rhs.id
    }

    var discountPercentage: Int {
        let percentage = ((originalPrice - discountPrice) / originalPrice) * 100
        return Int(percentage.rounded())
    }

    var timeLeftInDays: Double {
        let lowercased = timeLeft.lowercased()
        if lowercased.contains("day") {
            if let days = Double(timeLeft.split(separator: " ").first ?? "0") {
                return days
            }
        } else if lowercased.contains("hour") {
            if let hours = Double(timeLeft.split(separator: " ").first ?? "0") {
                return hours / 24.0
            }
        }
        return 0
    }

    var timeLeftColor: Color {
        let days = timeLeftInDays
        if days >= 5 {
            return .green
        } else if days >= 2 {
            return .yellow
        } else {
            return .red
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case originalPrice
        case discountPrice
        case storeName
        case timeLeft
        case location
        case quantity
        case storeId
        case category
        case photoUrl
        case createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        originalPrice = try container.decode(Double.self, forKey: .originalPrice)
        discountPrice = try container.decode(Double.self, forKey: .discountPrice)
        storeName = try container.decode(String.self, forKey: .storeName)
        timeLeft = try container.decode(String.self, forKey: .timeLeft)
        let geoPoint = try container.decode(GeoPoint.self, forKey: .location)
        location = CLLocationCoordinate2D(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
        quantity = try container.decode(Int.self, forKey: .quantity)
        storeId = try container.decode(String.self, forKey: .storeId)
        category = try container.decode(String.self, forKey: .category)
        photoUrl = try container.decodeIfPresent(String.self, forKey: .photoUrl)
        createdAt = try container.decode(Timestamp.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(originalPrice, forKey: .originalPrice)
        try container.encode(discountPrice, forKey: .discountPrice)
        try container.encode(storeName, forKey: .storeName)
        try container.encode(timeLeft, forKey: .timeLeft)
        let geoPoint = GeoPoint(latitude: location.latitude, longitude: location.longitude)
        try container.encode(geoPoint, forKey: .location)
        try container.encode(quantity, forKey: .quantity)
        try container.encode(storeId, forKey: .storeId)
        try container.encode(category, forKey: .category)
        try container.encodeIfPresent(photoUrl, forKey: .photoUrl)
        try container.encode(createdAt, forKey: .createdAt)
    }
}
