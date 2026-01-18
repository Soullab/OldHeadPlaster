import Foundation

struct Project: Identifiable, Codable {
    let id: UUID
    var name: String
    var createdAt: Date
    var rooms: [ScannedRoom]
    var selectedTier: PricingTier
    var notes: String

    // Total surface area across all rooms
    var totalAreaSqFt: Double {
        rooms.reduce(0) { $0 + $1.totalAreaSqFt }
    }

    // Estimate range based on selected tier
    var estimateRange: (low: Int, high: Int) {
        let sqft = totalAreaSqFt
        // Apply scale discount for larger projects
        let scaleDiscount = sqft > 2000 ? 0.95 : sqft > 1000 ? 0.97 : 1.0

        return (
            Int(sqft * Double(selectedTier.minPerSqFt) * scaleDiscount),
            Int(sqft * Double(selectedTier.maxPerSqFt) * scaleDiscount)
        )
    }

    // Initialize with defaults
    init(
        id: UUID = UUID(),
        name: String = "New Project",
        createdAt: Date = Date(),
        rooms: [ScannedRoom] = [],
        selectedTier: PricingTier = .signature,
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.rooms = rooms
        self.selectedTier = selectedTier
        self.notes = notes
    }
}

// Observable wrapper for SwiftUI
@MainActor
class ProjectStore: ObservableObject {
    @Published var projects: [Project] = []
    @Published var currentProject: Project

    private let saveKey = "savedProjects"

    init() {
        self.currentProject = Project()
        loadProjects()
    }

    func createNewProject(name: String = "New Project") {
        currentProject = Project(name: name)
    }

    func addRoom(_ room: ScannedRoom) {
        currentProject.rooms.append(room)
    }

    func removeRoom(_ room: ScannedRoom) {
        currentProject.rooms.removeAll { $0.id == room.id }
    }

    func saveCurrentProject() {
        if let index = projects.firstIndex(where: { $0.id == currentProject.id }) {
            projects[index] = currentProject
        } else {
            projects.append(currentProject)
        }
        persistProjects()
    }

    func deleteProject(_ project: Project) {
        projects.removeAll { $0.id == project.id }
        persistProjects()
    }

    func loadProject(_ project: Project) {
        currentProject = project
    }

    private func loadProjects() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Project].self, from: data) {
            projects = decoded
        }
    }

    private func persistProjects() {
        if let encoded = try? JSONEncoder().encode(projects) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
}
