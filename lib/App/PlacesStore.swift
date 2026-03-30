import Combine
import Foundation

final class PlacesStore: ObservableObject {
    @Published var savedPlaces: [SavedPlace] = SavedPlace.sample
    @Published var collections: [PlaceCollection] = PlaceCollection.sample
}
