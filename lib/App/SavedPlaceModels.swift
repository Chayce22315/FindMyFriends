import Foundation

struct SavedPlace: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let category: String
    let note: String
    let isFavorite: Bool

    static let sample: [SavedPlace] = [
        SavedPlace(name: "Home Base", category: "Home", note: "Evening check-ins.", isFavorite: true),
        SavedPlace(name: "Work HQ", category: "Work", note: "Morning commute.", isFavorite: false),
        SavedPlace(name: "Lake Trail", category: "Outdoors", note: "Weekend walks.", isFavorite: true),
        SavedPlace(name: "North Market", category: "Grocery", note: "Pickup orders.", isFavorite: false),
        SavedPlace(name: "City Gym", category: "Fitness", note: "Sweat sessions.", isFavorite: true),
    ]
}

struct PlaceCollection: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let places: [SavedPlace]

    static let sample: [PlaceCollection] = [
        PlaceCollection(title: "Weekend", subtitle: "Quick hits", places: Array(SavedPlace.sample.prefix(3))),
        PlaceCollection(title: "Favorites", subtitle: "Always on", places: SavedPlace.sample.filter { $0.isFavorite }),
    ]
}
