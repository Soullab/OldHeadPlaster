import Foundation

struct ScannedRoom: Identifiable, Codable {
    let id: UUID
    var name: String
    var lengthMeters: Double
    var widthMeters: Double
    var heightMeters: Double
    var wallCount: Int
    var doorCount: Int
    var windowCount: Int
    var includeWalls: Bool
    var includeCeiling: Bool

    // Conversion constants
    private static let sqMetersToSqFeet: Double = 10.764
    private static let metersToFeet: Double = 3.281

    // Dimensions in feet
    var lengthFeet: Double { lengthMeters * Self.metersToFeet }
    var widthFeet: Double { widthMeters * Self.metersToFeet }
    var heightFeet: Double { heightMeters * Self.metersToFeet }

    // Calculated wall area in square feet
    var wallAreaSqFt: Double {
        guard includeWalls else { return 0 }

        let perimeterMeters = 2 * (lengthMeters + widthMeters)
        let grossWallAreaMeters = perimeterMeters * heightMeters

        // Subtract estimated openings (doors ~21 sqft, windows ~15 sqft)
        let doorAreaMeters = Double(doorCount) * 1.95
        let windowAreaMeters = Double(windowCount) * 1.4
        let netWallAreaMeters = max(0, grossWallAreaMeters - doorAreaMeters - windowAreaMeters)

        return netWallAreaMeters * Self.sqMetersToSqFeet
    }

    // Calculated ceiling area in square feet
    var ceilingAreaSqFt: Double {
        guard includeCeiling else { return 0 }
        return lengthMeters * widthMeters * Self.sqMetersToSqFeet
    }

    // Total surface area
    var totalAreaSqFt: Double {
        wallAreaSqFt + ceilingAreaSqFt
    }

    // Initialize with default values
    init(
        id: UUID = UUID(),
        name: String = "Scanned Room",
        lengthMeters: Double = 4.0,
        widthMeters: Double = 3.0,
        heightMeters: Double = 2.7,
        wallCount: Int = 4,
        doorCount: Int = 1,
        windowCount: Int = 1,
        includeWalls: Bool = true,
        includeCeiling: Bool = false
    ) {
        self.id = id
        self.name = name
        self.lengthMeters = lengthMeters
        self.widthMeters = widthMeters
        self.heightMeters = heightMeters
        self.wallCount = wallCount
        self.doorCount = doorCount
        self.windowCount = windowCount
        self.includeWalls = includeWalls
        self.includeCeiling = includeCeiling
    }

    // For URL export (dimensions in feet)
    func toURLParams() -> [String: String] {
        return [
            "name": name,
            "length": String(format: "%.1f", lengthFeet),
            "width": String(format: "%.1f", widthFeet),
            "height": String(format: "%.1f", heightFeet),
            "walls": includeWalls ? "1" : "0",
            "ceiling": includeCeiling ? "1" : "0"
        ]
    }
}
