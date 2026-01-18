import RoomPlan
import Combine
import simd

@MainActor
class RoomCaptureManager: NSObject, ObservableObject {
    @Published var captureState: CaptureState = .idle
    @Published var scannedRoom: ScannedRoom?
    @Published var captureProgress: Float = 0
    @Published var instructionText: String = "Point camera at a wall to begin"

    private var roomCaptureSession: RoomCaptureSession?
    private var roomCaptureView: RoomCaptureView?

    enum CaptureState: Equatable {
        case idle
        case capturing
        case processing
        case completed
        case error(String)
    }

    // Check if device supports RoomPlan (requires LiDAR)
    var isSupported: Bool {
        RoomCaptureSession.isSupported
    }

    // Start a new capture session
    func startCapture() {
        guard isSupported else {
            captureState = .error("LiDAR scanner not available on this device")
            return
        }

        let configuration = RoomCaptureSession.Configuration()
        roomCaptureSession = RoomCaptureSession()
        roomCaptureSession?.delegate = self

        captureState = .capturing
        captureProgress = 0
        instructionText = "Slowly pan around the room"
        scannedRoom = nil

        roomCaptureSession?.run(configuration: configuration)
    }

    // Stop capture and process results
    func stopCapture() {
        captureState = .processing
        instructionText = "Processing scan..."
        roomCaptureSession?.stop()
    }

    // Cancel capture without processing
    func cancelCapture() {
        roomCaptureSession?.stop()
        roomCaptureSession = nil
        captureState = .idle
        scannedRoom = nil
        captureProgress = 0
    }

    // Create and return RoomCaptureView for UIViewRepresentable
    func createCaptureView() -> RoomCaptureView {
        let view = RoomCaptureView(frame: .zero)
        view.captureSession = roomCaptureSession
        view.delegate = self
        self.roomCaptureView = view
        return view
    }
}

// MARK: - RoomCaptureSessionDelegate
extension RoomCaptureManager: RoomCaptureSessionDelegate {
    nonisolated func captureSession(_ session: RoomCaptureSession, didUpdate room: CapturedRoom) {
        Task { @MainActor in
            // Calculate progress based on walls scanned
            let wallProgress = min(1.0, Float(room.walls.count) / 4.0)
            self.captureProgress = wallProgress

            // Update instruction based on progress
            if room.walls.count < 2 {
                self.instructionText = "Scan more walls - slowly pan around"
            } else if room.walls.count < 4 {
                self.instructionText = "Good progress - continue scanning"
            } else {
                self.instructionText = "Room captured - tap Done when finished"
            }
        }
    }

    nonisolated func captureSession(_ session: RoomCaptureSession, didEndWith data: CapturedRoomData, error: Error?) {
        Task { @MainActor in
            if let error = error {
                self.captureState = .error(error.localizedDescription)
                return
            }

            // Process the final room data
            if let finalRoom = data.finalResults {
                self.scannedRoom = self.processRoom(finalRoom)
                self.captureState = .completed
            } else {
                self.captureState = .error("No room data captured")
            }
        }
    }

    nonisolated func captureSession(_ session: RoomCaptureSession, didProvide instruction: RoomCaptureSession.Instruction) {
        Task { @MainActor in
            switch instruction {
            case .moveCloseToWall:
                self.instructionText = "Move closer to the wall"
            case .moveAwayFromWall:
                self.instructionText = "Move back from the wall"
            case .slowDown:
                self.instructionText = "Slow down your movement"
            case .turnOnLight:
                self.instructionText = "Turn on more lights"
            case .normal:
                if self.captureProgress > 0.5 {
                    self.instructionText = "Looking good - continue scanning"
                } else {
                    self.instructionText = "Continue scanning the room"
                }
            case .lowTexture:
                self.instructionText = "Plain surface - try to include edges"
            @unknown default:
                self.instructionText = "Continue scanning"
            }
        }
    }
}

// MARK: - RoomCaptureViewDelegate
extension RoomCaptureManager: RoomCaptureViewDelegate {
    nonisolated func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: Error?) -> Bool {
        // Return true to show the post-processing view
        return true
    }

    nonisolated func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
        Task { @MainActor in
            if let error = error {
                self.captureState = .error(error.localizedDescription)
                return
            }

            self.scannedRoom = self.processRoom(processedResult)
            self.captureState = .completed
        }
    }
}

// MARK: - Room Processing
extension RoomCaptureManager {
    private func processRoom(_ capturedRoom: CapturedRoom) -> ScannedRoom {
        // Extract room dimensions from walls
        var minX: Float = .infinity
        var maxX: Float = -.infinity
        var minZ: Float = .infinity
        var maxZ: Float = -.infinity
        var maxHeight: Float = 0

        for wall in capturedRoom.walls {
            let dimensions = wall.dimensions
            let transform = wall.transform

            // Get wall position
            let position = simd_float3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)

            // Update bounds
            minX = min(minX, position.x - dimensions.x / 2)
            maxX = max(maxX, position.x + dimensions.x / 2)
            minZ = min(minZ, position.z - dimensions.z / 2)
            maxZ = max(maxZ, position.z + dimensions.z / 2)
            maxHeight = max(maxHeight, dimensions.y)
        }

        // Calculate room dimensions in meters
        let length = Double(maxX - minX)
        let width = Double(maxZ - minZ)
        let height = Double(maxHeight)

        // Fallback to reasonable defaults if dimensions seem off
        let finalLength = length > 0.5 && length < 30 ? length : 4.0
        let finalWidth = width > 0.5 && width < 30 ? width : 3.0
        let finalHeight = height > 1.5 && height < 6 ? height : 2.7

        return ScannedRoom(
            name: "Scanned Room",
            lengthMeters: finalLength,
            widthMeters: finalWidth,
            heightMeters: finalHeight,
            wallCount: capturedRoom.walls.count,
            doorCount: capturedRoom.doors.count,
            windowCount: capturedRoom.windows.count,
            includeWalls: true,
            includeCeiling: false
        )
    }
}
