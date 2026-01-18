import SwiftUI

// MARK: - Brand Colors
extension Color {
    static let brandCharcoal = Color(hex: "1C1C1E")
    static let brandCharcoalLight = Color(hex: "2D2D30")
    static let brandCharcoalBorder = Color(hex: "3a3a3d")
    static let brandBrass = Color(hex: "A8935C")
    static let brandBrassLight = Color(hex: "C4B07A")
    static let brandIvory = Color(hex: "FAFAF8")
    static let brandStone = Color(hex: "ECEAE7")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Brand Typography
extension Font {
    static let brandHeadingLarge = Font.custom("Georgia", size: 32)
    static let brandHeading = Font.custom("Georgia", size: 24)
    static let brandHeadingSmall = Font.custom("Georgia", size: 20)
    static let brandBody = Font.system(size: 16)
    static let brandBodySmall = Font.system(size: 14)
    static let brandCaption = Font.system(size: 12, weight: .medium)
    static let brandLabel = Font.system(size: 11, weight: .medium)
}

// MARK: - Brand Button Styles
struct BrassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.brandCaption)
            .tracking(2)
            .foregroundColor(.brandCharcoal)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(configuration.isPressed ? Color.brandBrassLight : Color.brandBrass)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct CharcoalButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.brandCaption)
            .tracking(2)
            .foregroundColor(.brandIvory)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(configuration.isPressed ? Color.brandCharcoalLight : Color.brandCharcoal)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct OutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.brandCaption)
            .tracking(2)
            .foregroundColor(.brandCharcoal)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(Color.clear)
            .overlay(
                Rectangle()
                    .stroke(Color.brandCharcoal.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - View Extensions
extension View {
    func sectionLabel() -> some View {
        self
            .font(.brandLabel)
            .tracking(2)
            .textCase(.uppercase)
            .foregroundColor(.brandBrass)
    }

    func cardStyle() -> some View {
        self
            .padding(24)
            .background(Color.white)
            .shadow(color: .black.opacity(0.06), radius: 20, x: 0, y: 4)
    }

    func darkCardStyle() -> some View {
        self
            .padding(24)
            .background(Color.brandCharcoal)
    }
}

// MARK: - Reusable Components
struct SectionHeader: View {
    let title: String
    let label: String?

    init(_ title: String, label: String? = nil) {
        self.title = title
        self.label = label
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let label = label {
                Text(label)
                    .sectionLabel()
            }
            Text(title)
                .font(.brandHeading)
                .foregroundColor(.brandCharcoal)
        }
    }
}

struct DarkSectionHeader: View {
    let title: String
    let label: String?

    init(_ title: String, label: String? = nil) {
        self.title = title
        self.label = label
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let label = label {
                HStack(spacing: 12) {
                    Rectangle()
                        .fill(Color.brandBrass.opacity(0.6))
                        .frame(width: 32, height: 1)
                    Text(label)
                        .sectionLabel()
                }
            }
            Text(title)
                .font(.brandHeading)
                .foregroundColor(.brandIvory)
        }
    }
}
