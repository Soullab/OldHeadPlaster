import SwiftUI

struct HomeView: View {
    @StateObject private var projectStore = ProjectStore()
    @StateObject private var captureManager = RoomCaptureManager()
    @State private var showingScanner = false
    @State private var showingResults = false
    @State private var showingNewProject = false
    @State private var newProjectName = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brandStone.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection

                        // Quick Scan Card
                        quickScanCard

                        // Current Project
                        if !projectStore.currentProject.rooms.isEmpty {
                            currentProjectCard
                        }

                        // Past Projects
                        if !projectStore.projects.isEmpty {
                            pastProjectsSection
                        }
                    }
                    .padding(20)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingScanner) {
                ScanningView(captureManager: captureManager) { room in
                    if let room = room {
                        projectStore.addRoom(room)
                    }
                    showingScanner = false
                    if projectStore.currentProject.rooms.count > 0 {
                        showingResults = true
                    }
                }
            }
            .sheet(isPresented: $showingResults) {
                ResultsView(projectStore: projectStore)
            }
            .alert("New Project", isPresented: $showingNewProject) {
                TextField("Project Name", text: $newProjectName)
                Button("Cancel", role: .cancel) {
                    newProjectName = ""
                }
                Button("Create") {
                    projectStore.createNewProject(name: newProjectName.isEmpty ? "New Project" : newProjectName)
                    newProjectName = ""
                }
            } message: {
                Text("Enter a name for your new project")
            }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Rectangle()
                    .fill(Color.brandBrass)
                    .frame(width: 40, height: 2)
                Text("OLD HEAD PLASTER")
                    .font(.brandLabel)
                    .tracking(2)
                    .foregroundColor(.brandBrass)
            }

            Text("Room Scanner")
                .font(.brandHeadingLarge)
                .foregroundColor(.brandCharcoal)

            Text("Scan rooms with LiDAR for instant plaster estimates")
                .font(.brandBody)
                .foregroundColor(.brandCharcoal.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 20)
    }

    // MARK: - Quick Scan Card
    private var quickScanCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SCAN A ROOM")
                        .font(.brandLabel)
                        .tracking(2)
                        .foregroundColor(.brandBrass)

                    Text("Use LiDAR to measure")
                        .font(.brandBodySmall)
                        .foregroundColor(.brandIvory.opacity(0.6))
                }

                Spacer()

                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 32))
                    .foregroundColor(.brandBrass)
            }

            if captureManager.isSupported {
                Button(action: { showingScanner = true }) {
                    HStack {
                        Image(systemName: "viewfinder")
                        Text("START SCAN")
                    }
                }
                .buttonStyle(BrassButtonStyle())
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text("LiDAR not available")
                            .font(.brandBodySmall)
                            .foregroundColor(.brandIvory.opacity(0.8))
                    }
                    Text("This device doesn't have a LiDAR scanner. Use iPhone 12 Pro or newer, or iPad Pro.")
                        .font(.brandCaption)
                        .foregroundColor(.brandIvory.opacity(0.5))
                }
            }
        }
        .padding(24)
        .background(Color.brandCharcoal)
    }

    // MARK: - Current Project Card
    private var currentProjectCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CURRENT PROJECT")
                        .font(.brandLabel)
                        .tracking(2)
                        .foregroundColor(.brandBrass)

                    Text(projectStore.currentProject.name)
                        .font(.brandHeadingSmall)
                        .foregroundColor(.brandCharcoal)
                }

                Spacer()

                Button(action: { showingNewProject = true }) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 24))
                        .foregroundColor(.brandBrass)
                }
            }

            // Room summary
            VStack(spacing: 8) {
                ForEach(projectStore.currentProject.rooms) { room in
                    HStack {
                        Text(room.name)
                            .font(.brandBodySmall)
                            .foregroundColor(.brandCharcoal)
                        Spacer()
                        Text("\(Int(room.totalAreaSqFt)) sq ft")
                            .font(.brandBodySmall)
                            .foregroundColor(.brandCharcoal.opacity(0.6))
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.brandStone)
                }
            }

            // Total
            HStack {
                Text("Total")
                    .font(.brandBody)
                    .foregroundColor(.brandCharcoal)
                Spacer()
                Text("\(Int(projectStore.currentProject.totalAreaSqFt)) sq ft")
                    .font(.brandHeadingSmall)
                    .foregroundColor(.brandCharcoal)
            }
            .padding(.top, 8)

            // Actions
            HStack(spacing: 12) {
                Button(action: { showingScanner = true }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("ADD ROOM")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(OutlineButtonStyle())

                Button(action: { showingResults = true }) {
                    HStack {
                        Image(systemName: "doc.text")
                        Text("VIEW ESTIMATE")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(CharcoalButtonStyle())
            }
        }
        .cardStyle()
    }

    // MARK: - Past Projects
    private var pastProjectsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("PAST PROJECTS")
                .font(.brandLabel)
                .tracking(2)
                .foregroundColor(.brandBrass)

            ForEach(projectStore.projects) { project in
                ProjectRow(project: project) {
                    projectStore.loadProject(project)
                    showingResults = true
                } onDelete: {
                    projectStore.deleteProject(project)
                }
            }
        }
    }
}

// MARK: - Project Row
struct ProjectRow: View {
    let project: Project
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.brandBody)
                        .foregroundColor(.brandCharcoal)

                    Text("\(project.rooms.count) rooms - \(Int(project.totalAreaSqFt)) sq ft")
                        .font(.brandCaption)
                        .foregroundColor(.brandCharcoal.opacity(0.5))
                }

                Spacer()

                let range = project.estimateRange
                Text("$\(range.low.formatted())-\(range.high.formatted())")
                    .font(.brandBodySmall)
                    .foregroundColor(.brandBrass)

                Image(systemName: "chevron.right")
                    .foregroundColor(.brandCharcoal.opacity(0.3))
            }
            .padding(16)
            .background(Color.white)
        }
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

#Preview {
    HomeView()
}
