import Foundation

enum ReactionType: String, CaseIterable, Codable {
    case heart = "heart.fill"
    case fire = "flame.fill"
    case wow = "sparkles"
    case clap = "hands.clap.fill"

    var label: String {
        switch self {
        case .heart: return "Love"
        case .fire: return "Fire"
        case .wow: return "Wow"
        case .clap: return "Clap"
        }
    }
}

struct Reaction: Identifiable, Hashable, Codable {
    var id: UUID
    let type: ReactionType
    var count: Int
    var isSelected: Bool

    init(id: UUID = UUID(), type: ReactionType, count: Int, isSelected: Bool) {
        self.id = id
        self.type = type
        self.count = count
        self.isSelected = isSelected
    }
}

struct CheckIn: Identifiable, Hashable, Codable {
    var id: UUID
    let name: String
    let place: String
    let time: Date
    let status: String
    var reactions: [Reaction]

    init(id: UUID = UUID(), name: String, place: String, time: Date, status: String, reactions: [Reaction]) {
        self.id = id
        self.name = name
        self.place = place
        self.time = time
        self.status = status
        self.reactions = reactions
    }

    static let sample: [CheckIn] = [
        CheckIn(name: "You", place: "Lakeside Brew", time: .now.addingTimeInterval(-900), status: "Coffee break.", reactions: ReactionType.allCases.map { Reaction(type: $0, count: Int.random(in: 1...12), isSelected: $0 == .heart) }),
        CheckIn(name: "Morgan", place: "Vista Ridge", time: .now.addingTimeInterval(-3600), status: "Golden hour views.", reactions: ReactionType.allCases.map { Reaction(type: $0, count: Int.random(in: 0...8), isSelected: false) }),
        CheckIn(name: "Cam", place: "North Market", time: .now.addingTimeInterval(-7200), status: "Grabbed groceries.", reactions: ReactionType.allCases.map { Reaction(type: $0, count: Int.random(in: 0...6), isSelected: $0 == .clap) }),
    ]
}
