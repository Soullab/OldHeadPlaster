# Old Head Scanner - iOS Room Scanning App

LiDAR-powered room scanner for Old Head Plaster. Scan client rooms to get instant square footage estimates for decorative plaster projects.

## Requirements

- **Device**: iPhone 12 Pro, 13 Pro, 14 Pro, 15 Pro, or iPad Pro (LiDAR required)
- **iOS**: 16.0+
- **Xcode**: 15.0+

## Setup Instructions

### 1. Create Xcode Project

1. Open Xcode
2. File → New → Project
3. Select **iOS → App**
4. Configure:
   - Product Name: `OldHeadScanner`
   - Team: Your Apple Developer Team
   - Organization Identifier: `com.oldheadplaster`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: None (or SwiftData if you prefer)

### 2. Add Source Files

Copy all files from this directory into the Xcode project:

```
OldHeadScanner/
├── App/
│   └── OldHeadScannerApp.swift
├── Models/
│   ├── PricingTier.swift
│   ├── Room.swift
│   └── Project.swift
├── Services/
│   ├── ExportService.swift
│   └── RoomCapture/
│       └── RoomCaptureManager.swift
├── Views/
│   ├── Components/
│   │   └── BrandTheme.swift
│   ├── Home/
│   │   └── HomeView.swift
│   ├── Scanning/
│   │   └── ScanningView.swift
│   └── Results/
│       └── ResultsView.swift
└── Info.plist
```

### 3. Configure Capabilities

In Xcode, select your target and go to **Signing & Capabilities**:

1. Add capability: **Camera** (required for RoomPlan)
2. Ensure Info.plist has `NSCameraUsageDescription`

### 4. Update Info.plist

Replace the auto-generated Info.plist with the provided one, or merge these keys:

```xml
<key>NSCameraUsageDescription</key>
<string>Old Head Scanner uses the camera and LiDAR sensor to scan rooms and measure wall surfaces for plaster estimates.</string>
```

### 5. Add App Icon

Use the logo assets from `/public/images/`:
- `headland-seal.svg` - Main logo
- `headland-mark.svg` - Icon mark

Convert to required sizes for Assets.xcassets/AppIcon.

### 6. Build & Run

1. Connect a LiDAR-equipped device
2. Select the device as build target
3. Build and run (⌘R)

## Features

- **Room Scanning**: Use RoomPlan API to scan rooms with LiDAR
- **Auto-Measurement**: Extracts wall dimensions, door/window counts
- **Instant Estimates**: Real-time pricing based on three tiers
- **Project Management**: Save and manage multiple scanning projects
- **Export Options**:
  - Share text summary
  - Generate PDF report
  - QR code to web calculator
  - Direct link to contact page

## Pricing Tiers

| Tier | Price/sq ft | Use Case |
|------|-------------|----------|
| Foundation | $35-55 | Single rooms, good substrate |
| Signature | $55-85 | Multi-room, polished finishes |
| Bespoke | $85-150+ | Large-scale, specialty finishes |

## Web Integration

The app generates URLs that open the web calculator with pre-filled room data:

```
https://oldheadplaster.com/estimate?tier=signature&rooms=[base64-encoded-data]
```

This allows seamless handoff from mobile scan to detailed web estimate.

## Brand Colors

```swift
Color.brandCharcoal   // #1C1C1E
Color.brandBrass      // #A8935C
Color.brandIvory      // #FAFAF8
Color.brandStone      // #ECEAE7
```

## Support

- Website: oldheadplaster.com
- Email: daragh@oldheadplaster.com
- Phone: 860-574-7004
