import Foundation
import UIKit
import CoreImage.CIFilterBuiltins

class ExportService {
    static let shared = ExportService()
    private init() {}

    // Base URL for the web calculator
    private let baseURL = "https://oldheadplaster.com/estimate"

    // Generate URL that opens web calculator with pre-filled room data
    func generateWebEstimateURL(for project: Project) -> URL? {
        var components = URLComponents(string: baseURL)

        // Encode room data as JSON then base64
        let roomData = project.rooms.map { $0.toURLParams() }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: roomData),
              let base64String = jsonData.base64EncodedString()
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }

        components?.queryItems = [
            URLQueryItem(name: "tier", value: project.selectedTier.rawValue),
            URLQueryItem(name: "rooms", value: base64String)
        ]

        return components?.url
    }

    // Generate shareable text summary
    func generateShareText(for project: Project) -> String {
        let range = project.estimateRange

        var text = """
        Old Head Plaster - Room Estimate

        Project: \(project.name)
        Total Area: \(Int(project.totalAreaSqFt)) sq ft
        Finish Tier: \(project.selectedTier.displayName)
        Estimated Range: $\(range.low.formatted()) - $\(range.high.formatted())

        Rooms:
        """

        for room in project.rooms {
            text += "\n- \(room.name): \(Int(room.totalAreaSqFt)) sq ft"
            text += " (\(String(format: "%.1f", room.lengthFeet))' x \(String(format: "%.1f", room.widthFeet))')"
        }

        text += "\n\nRequest a formal quote: oldheadplaster.com/contact"

        return text
    }

    // Generate QR code image for web URL
    func generateQRCode(for project: Project, size: CGFloat = 200) -> UIImage? {
        guard let url = generateWebEstimateURL(for: project) else { return nil }

        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(url.absoluteString.utf8)
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else { return nil }

        // Scale up the QR code
        let scale = size / outputImage.extent.size.width
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        let scaledImage = outputImage.transformed(by: transform)

        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    // Generate PDF report
    func generatePDFReport(for project: Project) -> Data {
        let pageWidth: CGFloat = 612  // 8.5" at 72 dpi
        let pageHeight: CGFloat = 792 // 11" at 72 dpi
        let margin: CGFloat = 50

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        return renderer.pdfData { context in
            context.beginPage()

            var yOffset: CGFloat = margin

            // Header
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "Georgia", size: 28) ?? UIFont.systemFont(ofSize: 28),
                .foregroundColor: UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
            ]

            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .medium),
                .foregroundColor: UIColor(red: 0.66, green: 0.58, blue: 0.36, alpha: 1.0)
            ]

            "OLD HEAD PLASTER".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: subtitleAttributes)
            yOffset += 25

            "Room Scan Estimate".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: titleAttributes)
            yOffset += 50

            // Project info
            let labelAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .medium),
                .foregroundColor: UIColor.gray
            ]

            let valueAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.darkGray
            ]

            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long

            let infoItems: [(String, String)] = [
                ("PROJECT", project.name),
                ("DATE", dateFormatter.string(from: project.createdAt)),
                ("TOTAL AREA", "\(Int(project.totalAreaSqFt)) sq ft"),
                ("FINISH TIER", project.selectedTier.displayName)
            ]

            for (label, value) in infoItems {
                label.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: labelAttributes)
                yOffset += 16
                value.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: valueAttributes)
                yOffset += 30
            }

            // Estimate range (highlighted)
            yOffset += 10
            let range = project.estimateRange
            let rangeRect = CGRect(x: margin, y: yOffset, width: pageWidth - margin * 2, height: 60)

            UIColor(red: 0.66, green: 0.58, blue: 0.36, alpha: 0.1).setFill()
            UIBezierPath(rect: rangeRect).fill()

            let rangeAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "Georgia", size: 24) ?? UIFont.systemFont(ofSize: 24),
                .foregroundColor: UIColor(red: 0.66, green: 0.58, blue: 0.36, alpha: 1.0)
            ]

            "ESTIMATED RANGE".draw(at: CGPoint(x: margin + 15, y: yOffset + 10), withAttributes: labelAttributes)
            "$\(range.low.formatted()) - $\(range.high.formatted())".draw(
                at: CGPoint(x: margin + 15, y: yOffset + 28),
                withAttributes: rangeAttributes
            )
            yOffset += 80

            // Room breakdown
            "ROOMS SCANNED".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: labelAttributes)
            yOffset += 25

            for room in project.rooms {
                let roomText = "\(room.name): \(Int(room.totalAreaSqFt)) sq ft"
                let dimText = "(\(String(format: "%.1f", room.lengthFeet))' x \(String(format: "%.1f", room.widthFeet))' x \(String(format: "%.1f", room.heightFeet))')"

                roomText.draw(at: CGPoint(x: margin + 10, y: yOffset), withAttributes: valueAttributes)
                dimText.draw(
                    at: CGPoint(x: margin + 200, y: yOffset),
                    withAttributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.gray]
                )
                yOffset += 25
            }

            // Footer
            let footerY = pageHeight - margin - 40

            UIColor.lightGray.setStroke()
            let line = UIBezierPath()
            line.move(to: CGPoint(x: margin, y: footerY))
            line.addLine(to: CGPoint(x: pageWidth - margin, y: footerY))
            line.lineWidth = 0.5
            line.stroke()

            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.italicSystemFont(ofSize: 10),
                .foregroundColor: UIColor.gray
            ]

            "This is a planning estimate only. Contact us for a formal quote.".draw(
                at: CGPoint(x: margin, y: footerY + 10),
                withAttributes: footerAttributes
            )

            let contactAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.gray
            ]

            "oldheadplaster.com | 860-574-7004 | daragh@oldheadplaster.com".draw(
                at: CGPoint(x: margin, y: footerY + 25),
                withAttributes: contactAttributes
            )
        }
    }
}

// Number formatting extension
extension Int {
    func formatted() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
