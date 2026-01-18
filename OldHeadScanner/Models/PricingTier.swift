import Foundation

enum PricingTier: String, Codable, CaseIterable, Identifiable {
    case foundation
    case signature
    case bespoke

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .foundation: return "Foundation"
        case .signature: return "Signature"
        case .bespoke: return "Bespoke"
        }
    }

    var minPerSqFt: Int {
        switch self {
        case .foundation: return 35
        case .signature: return 55
        case .bespoke: return 85
        }
    }

    var maxPerSqFt: Int {
        switch self {
        case .foundation: return 55
        case .signature: return 85
        case .bespoke: return 150
        }
    }

    var priceRange: String {
        switch self {
        case .foundation: return "$35-55"
        case .signature: return "$55-85"
        case .bespoke: return "$85-150+"
        }
    }

    var description: String {
        switch self {
        case .foundation: return "Single rooms, good substrate"
        case .signature: return "Multi-room, polished finishes"
        case .bespoke: return "Large-scale, specialty finishes"
        }
    }
}
