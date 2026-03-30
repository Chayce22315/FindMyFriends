import CoreLocation
import Foundation

enum FriendSource: String, Codable, CaseIterable {
    case contacts
    case familyInvite
    case manual

    var label: String {
        switch self {
        case .contacts: return "Contacts"
        case .familyInvite: return "Family invite"
        case .manual: return "Added"
        }
    }
}

struct Friend: Identifiable, Hashable, Codable {
    var id: UUID
    var name: String
    var subtitle: String
    var latitude: Double?
    var longitude: Double?
    var source: FriendSource
    var isFamilyMember: Bool

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(
        id: UUID = UUID(),
        name: String,
        subtitle: String = "",
        latitude: Double? = nil,
        longitude: Double? = nil,
        source: FriendSource,
        isFamilyMember: Bool = false
    ) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.latitude = latitude
        self.longitude = longitude
        self.source = source
        self.isFamilyMember = isFamilyMember
    }
}
