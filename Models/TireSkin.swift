import Foundation

nonisolated enum TireSkin: String, CaseIterable, Codable, Identifiable, Sendable {
    case car = "Car"
    case truck = "Truck"
    case motor = "Motorcycle"
    case bicycle = "Bicycle"
    case racing = "Racing"
    case tractor = "Tractor"

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .car: "Car"
        case .truck: "Truck"
        case .motor: "Motorcycle"
        case .bicycle: "Bicycle"
        case .racing: "Racing"
        case .tractor: "Tractor"
        }
    }

    var detail: LocalizedStringResource {
        switch self {
        case .car: "Balanced. Fills at a normal pace."
        case .truck: "Big and stubborn. Takes more air."
        case .motor: "Small and quick. Fills fast."
        case .bicycle: "Tiny and twitchy. Fills in a flash."
        case .racing: "Slick and sensitive. Pops easily."
        case .tractor: "Gigantic. Takes forever to fill."
        }
    }

    var pumpMultiplier: Double {
        switch self {
        case .car: 1.0
        case .truck: 0.6
        case .motor: 1.4
        case .bicycle: 1.8
        case .racing: 1.2
        case .tractor: 0.4
        }
    }
}
