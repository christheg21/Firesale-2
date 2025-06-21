import Foundation
import FirebaseFirestore
import MapKit

struct Store: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var description: String
    var location: String
    var latitude: Double
    var longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case location
        case latitude
        case longitude
    }
}
