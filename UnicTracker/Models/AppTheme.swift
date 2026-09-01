import SwiftUI

// MARK: - Liquid Glass Theme Definition
public enum LiquidThemePreset: String, CaseIterable, Identifiable, Codable {
    case cyberGlass = "Cyber Glass"
    case obsidianOLED = "Obsidian OLED"
    case auroraGlow = "Aurora Glass"
    case nebulaPurple = "Nebula Purple"
    case emeraldRefraction = "Emerald Glass"
    case royalSapphire = "Royal Sapphire"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .cyberGlass: return "Cyber Glass (Неон)"
        case .obsidianOLED: return "Obsidian (OLED Черный)"
        case .auroraGlow: return "Aurora (Северное Сияние)"
        case .nebulaPurple: return "Nebula (Неоновый Фиолетовый)"
        case .emeraldRefraction: return "Emerald (Изумрудный)"
        case .royalSapphire: return "Sapphire (Королевский Сапфир)"
        }
    }

    public var primaryAccent: Color {
        switch self {
        case .cyberGlass: return Color(red: 0.0, green: 0.9, blue: 0.95)
        case .obsidianOLED: return Color(red: 0.85, green: 0.85, blue: 0.9)
        case .auroraGlow: return Color(red: 0.15, green: 0.95, blue: 0.65)
        case .nebulaPurple: return Color(red: 0.75, green: 0.35, blue: 1.0)
        case .emeraldRefraction: return Color(red: 0.2, green: 0.85, blue: 0.5)
        case .royalSapphire: return Color(red: 0.25, green: 0.55, blue: 1.0)
        }
    }

    public var secondaryAccent: Color {
        switch self {
        case .cyberGlass: return Color(red: 0.55, green: 0.2, blue: 1.0)
        case .obsidianOLED: return Color(red: 0.3, green: 0.3, blue: 0.35)
        case .auroraGlow: return Color(red: 0.0, green: 0.65, blue: 0.95)
        case .nebulaPurple: return Color(red: 1.0, green: 0.2, blue: 0.65)
        case .emeraldRefraction: return Color(red: 0.0, green: 0.6, blue: 0.8)
        case .royalSapphire: return Color(red: 0.6, green: 0.2, blue: 0.95)
        }
    }

    public var backgroundColors: [Color] {
        switch self {
        case .cyberGlass:
            return [Color(red: 0.05, green: 0.05, blue: 0.12), Color(red: 0.02, green: 0.02, blue: 0.06)]
        case .obsidianOLED:
            return [Color.black, Color(red: 0.03, green: 0.03, blue: 0.04)]
        case .auroraGlow:
            return [Color(red: 0.02, green: 0.08, blue: 0.08), Color(red: 0.01, green: 0.03, blue: 0.05)]
        case .nebulaPurple:
            return [Color(red: 0.08, green: 0.03, blue: 0.12), Color(red: 0.02, green: 0.01, blue: 0.05)]
        case .emeraldRefraction:
            return [Color(red: 0.02, green: 0.07, blue: 0.05), Color(red: 0.01, green: 0.02, blue: 0.03)]
        case .royalSapphire:
            return [Color(red: 0.03, green: 0.05, blue: 0.14), Color(red: 0.01, green: 0.02, blue: 0.05)]
        }
    }
}

// MARK: - Glass Blur Intensity
public enum GlassMaterialDepth: String, CaseIterable, Identifiable, Codable {
    case ultraLiquid = "Ultra Liquid (26/27 Refractive)"
    case frostedDeep = "Frosted Deep (Матовое)"
    case crystalClear = "Crystal Clear (Прозрачное)"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .ultraLiquid: return "Liquid Glass (Глянцевый рефрактив)"
        case .frostedDeep: return "Frosted Glass (Глубокое матовое)"
        case .crystalClear: return "Crystal (Минималистичное чистое)"
        }
    }

    public var surfaceOpacity: Double {
        switch self {
        case .ultraLiquid: return 0.14
        case .frostedDeep: return 0.22
        case .crystalClear: return 0.08
        }
    }

    public var borderOpacity: Double {
        switch self {
        case .ultraLiquid: return 0.35
        case .frostedDeep: return 0.25
        case .crystalClear: return 0.18
        }
    }
}

// MARK: - App Preferences Model
public struct AppThemeSettings: Codable, Equatable {
    public var preset: LiquidThemePreset = .cyberGlass
    public var glassDepth: GlassMaterialDepth = .ultraLiquid
    public var enableHaptics: Bool = true
    public var enableAmbientGlow: Bool = true
    public var compactCardView: Bool = false

    public init() {}
}
