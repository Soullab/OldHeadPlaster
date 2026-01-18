import SwiftUI

struct ResultsView: View {
    @ObservedObject var projectStore: ProjectStore
    @Environment(\.dismiss) private var dismiss

    @State private var showingShareSheet = false
    @State private var showingQRCode = false
    @State private var shareItems: [Any] = []

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brandStone.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Header with total area
                        headerSection

                        // Tier selection
                        tierSelectionSection

                        // Estimate display
                        estimateSection

                        // Room breakdown
                        roomBreakdownSection

                        // Actions
                        actionsSection
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        projectStore.saveCurrentProject()
                        dismiss()
                    }
                    .foregroundColor(.brandBrass)
                }

                ToolbarItem(placement: .principal) {
                    Text(projectStore.currentProject.name)
                        .font(.brandBody)
                        .foregroundColor(.brandCharcoal)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: shareItems)
            }
            .sheet(isPresented: $showingQRCode) {
                QRCodeView(project: projectStore.currentProject)
            }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 16) {
            Text("TOTAL SURFACE AREA")
                .font(.brandLabel)
                .tracking(2)
                .foregroundColor(.brandCharcoal.opacity(0.5))

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(Int(projectStore.currentProject.totalAreaSqFt))")
                    .font(.system(size: 56, weight: .light, design: .serif))
                    .foregroundColor(.brandCharcoal)

                Text("sq ft")
                    .font(.brandBody)
                    .foregroundColor(.brandCharcoal.opacity(0.5))
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(Color.white)
    }

    // MARK: - Tier Selection
    private var tierSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SELECT FINISH TIER")
                .font(.brandLabel)
                .tracking(2)
                .foregroundColor(.brandCharcoal.opacity(0.5))

            ForEach(PricingTier.allCases) { tier in
                TierSelectionRow(
                    tier: tier,
                    isSelected: projectStore.currentProject.selectedTier == tier
                ) {
                    projectStore.currentProject.selectedTier = tier
                }
            }
        }
        .padding(24)
        .background(Color.white)
    }

    // MARK: - Estimate
    private var estimateSection: some View {
        VStack(spacing: 16) {
            Text("ESTIMATED RANGE")
                .font(.brandLabel)
                .tracking(2)
                .foregroundColor(.brandIvory.opacity(0.5))

            let range = projectStore.currentProject.estimateRange
            Text("$\(range.low.formatted()) - $\(range.high.formatted())")
                .font(.system(size: 36, weight: .light, design: .serif))
                .foregroundColor(.brandBrass)

            Text("Based on \(projectStore.currentProject.selectedTier.displayName) tier")
                .font(.brandBodySmall)
                .foregroundColor(.brandIvory.opacity(0.5))

            Text("Final pricing requires on-site consultation")
                .font(.brandCaption)
                .foregroundColor(.brandIvory.opacity(0.4))
                .padding(.top, 8)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(Color.brandCharcoal)
    }

    // MARK: - Room Breakdown
    private var roomBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("ROOMS SCANNED")
                    .font(.brandLabel)
                    .tracking(2)
                    .foregroundColor(.brandCharcoal.opacity(0.5))

                Spacer()

                Text("\(projectStore.currentProject.rooms.count) rooms")
                    .font(.brandCaption)
                    .foregroundColor(.brandCharcoal.opacity(0.4))
            }

            ForEach(projectStore.currentProject.rooms) { room in
                RoomSummaryCard(room: room) {
                    projectStore.removeRoom(room)
                }
            }
        }
        .padding(24)
        .background(Color.white)
    }

    // MARK: - Actions
    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Share button
            Button(action: shareEstimate) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("SHARE ESTIMATE")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(BrassButtonStyle())

            // QR Code button
            Button(action: { showingQRCode = true }) {
                HStack {
                    Image(systemName: "qrcode")
                    Text("SHOW QR CODE")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(OutlineButtonStyle())

            // Request quote link
            if let url = URL(string: "https://oldheadplaster.com/contact") {
                Link(destination: url) {
                    HStack {
                        Image(systemName: "envelope")
                        Text("REQUEST FORMAL QUOTE")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(CharcoalButtonStyle())
            }
        }
        .padding(24)
        .background(Color.brandStone)
    }

    // MARK: - Share
    private func shareEstimate() {
        let exportService = ExportService.shared
        let text = exportService.generateShareText(for: projectStore.currentProject)
        let pdfData = exportService.generatePDFReport(for: projectStore.currentProject)

        // Create temporary file for PDF
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("OldHeadPlaster_Estimate.pdf")
        try? pdfData.write(to: tempURL)

        shareItems = [text, tempURL]
        showingShareSheet = true
    }
}

// MARK: - Tier Selection Row
struct TierSelectionRow: View {
    let tier: PricingTier
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tier.displayName)
                        .font(.brandBody)
                        .foregroundColor(.brandCharcoal)

                    Text(tier.description)
                        .font(.brandCaption)
                        .foregroundColor(.brandCharcoal.opacity(0.5))
                }

                Spacer()

                Text(tier.priceRange)
                    .font(.brandBodySmall)
                    .foregroundColor(isSelected ? .brandBrass : .brandCharcoal.opacity(0.6))

                Text("/sq ft")
                    .font(.brandCaption)
                    .foregroundColor(.brandCharcoal.opacity(0.4))

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .brandBrass : .brandCharcoal.opacity(0.3))
                    .font(.title3)
            }
            .padding(16)
            .background(isSelected ? Color.brandBrass.opacity(0.08) : Color.brandStone.opacity(0.5))
            .overlay(
                Rectangle()
                    .stroke(isSelected ? Color.brandBrass : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Room Summary Card
struct RoomSummaryCard: View {
    let room: ScannedRoom
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(room.name)
                    .font(.brandBody)
                    .foregroundColor(.brandCharcoal)

                Spacer()

                Text("\(Int(room.totalAreaSqFt)) sq ft")
                    .font(.brandHeadingSmall)
                    .foregroundColor(.brandCharcoal)
            }

            HStack(spacing: 16) {
                dimensionItem("L", value: room.lengthFeet)
                dimensionItem("W", value: room.widthFeet)
                dimensionItem("H", value: room.heightFeet)

                Spacer()

                HStack(spacing: 8) {
                    if room.includeWalls {
                        Label("Walls", systemImage: "rectangle.portrait")
                            .font(.brandCaption)
                            .foregroundColor(.brandCharcoal.opacity(0.5))
                    }
                    if room.includeCeiling {
                        Label("Ceiling", systemImage: "square")
                            .font(.brandCaption)
                            .foregroundColor(.brandCharcoal.opacity(0.5))
                    }
                }
            }

            if room.doorCount > 0 || room.windowCount > 0 {
                HStack(spacing: 16) {
                    if room.doorCount > 0 {
                        Label("\(room.doorCount) door\(room.doorCount > 1 ? "s" : "")", systemImage: "door.left.hand.closed")
                            .font(.brandCaption)
                            .foregroundColor(.brandCharcoal.opacity(0.4))
                    }
                    if room.windowCount > 0 {
                        Label("\(room.windowCount) window\(room.windowCount > 1 ? "s" : "")", systemImage: "window.vertical.closed")
                            .font(.brandCaption)
                            .foregroundColor(.brandCharcoal.opacity(0.4))
                    }
                }
            }
        }
        .padding(16)
        .background(Color.brandStone.opacity(0.5))
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Remove Room", systemImage: "trash")
            }
        }
    }

    private func dimensionItem(_ label: String, value: Double) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.brandCaption)
                .foregroundColor(.brandCharcoal.opacity(0.4))
            Text(String(format: "%.1f'", value))
                .font(.brandBodySmall)
                .foregroundColor(.brandCharcoal.opacity(0.7))
        }
    }
}

// MARK: - QR Code View
struct QRCodeView: View {
    let project: Project
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Scan to open in web calculator")
                    .font(.brandBody)
                    .foregroundColor(.brandCharcoal.opacity(0.7))

                if let qrImage = ExportService.shared.generateQRCode(for: project, size: 250) {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .frame(width: 250, height: 250)
                        .padding(20)
                        .background(Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 10)
                } else {
                    Text("Unable to generate QR code")
                        .foregroundColor(.red)
                }

                if let url = ExportService.shared.generateWebEstimateURL(for: project) {
                    Text(url.absoluteString)
                        .font(.brandCaption)
                        .foregroundColor(.brandCharcoal.opacity(0.4))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding()
            .navigationTitle("QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.brandBrass)
                }
            }
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    let store = ProjectStore()
    store.currentProject = Project(
        name: "Sample Project",
        rooms: [
            ScannedRoom(name: "Living Room", lengthMeters: 5, widthMeters: 4, heightMeters: 2.7, wallCount: 4, doorCount: 2, windowCount: 3),
            ScannedRoom(name: "Bedroom", lengthMeters: 4, widthMeters: 3.5, heightMeters: 2.7, wallCount: 4, doorCount: 1, windowCount: 1)
        ]
    )
    return ResultsView(projectStore: store)
}
