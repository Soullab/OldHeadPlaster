import SwiftUI
import RoomPlan

struct ScanningView: View {
    @ObservedObject var captureManager: RoomCaptureManager
    let onComplete: (ScannedRoom?) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // RoomPlan capture view
            RoomCaptureViewContainer(captureManager: captureManager)
                .ignoresSafeArea()

            // Overlay UI
            VStack {
                // Top bar
                topBar

                Spacer()

                // Instructions and progress
                instructionOverlay

                // Action buttons
                actionButtons
            }
        }
        .onAppear {
            captureManager.startCapture()
        }
        .onChange(of: captureManager.captureState) { _, newState in
            if case .completed = newState {
                onComplete(captureManager.scannedRoom)
            } else if case .error(let message) = newState {
                print("Capture error: \(message)")
                // Could show an alert here
            }
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            Button(action: {
                captureManager.cancelCapture()
                onComplete(nil)
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .shadow(radius: 2)
            }

            Spacer()

            // Progress indicator
            HStack(spacing: 8) {
                ProgressView(value: captureManager.captureProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .brandBrass))
                    .frame(width: 60)

                Text("\(Int(captureManager.captureProgress * 100))%")
                    .font(.brandCaption)
                    .foregroundColor(.brandBrass)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.brandCharcoal.opacity(0.8))
            .cornerRadius(8)
        }
        .padding()
    }

    // MARK: - Instruction Overlay
    private var instructionOverlay: some View {
        VStack(spacing: 12) {
            // Status indicator
            if captureManager.captureState == .processing {
                ProgressView()
                    .tint(.white)
            }

            Text(captureManager.instructionText)
                .font(.brandBody)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.brandCharcoal.opacity(0.85))
                .cornerRadius(8)
        }
        .padding(.bottom, 20)
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        Group {
            if captureManager.captureState == .capturing {
                Button(action: {
                    captureManager.stopCapture()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("FINISH SCAN")
                    }
                    .font(.brandCaption)
                    .tracking(2)
                    .foregroundColor(.brandCharcoal)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Color.brandBrass)
                }
                .disabled(captureManager.captureProgress < 0.25)
                .opacity(captureManager.captureProgress < 0.25 ? 0.5 : 1.0)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - RoomCaptureView Container
struct RoomCaptureViewContainer: UIViewRepresentable {
    @ObservedObject var captureManager: RoomCaptureManager

    func makeUIView(context: Context) -> RoomCaptureView {
        captureManager.createCaptureView()
    }

    func updateUIView(_ uiView: RoomCaptureView, context: Context) {
        // Updates handled by captureManager
    }
}

#Preview {
    ScanningView(captureManager: RoomCaptureManager()) { _ in }
}
