import SwiftUI

// MARK: - Appearance Theme Mode (Системная / Светлая / Темная)
public enum AppThemeMode: String, CaseIterable, Identifiable, Codable {
    case system = "Системная"
    case light = "Светлая"
    case dark = "Темная"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .system: return "circle.righthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.stars.fill"
        }
    }

    public var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

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
        case .obsidianOLED: return "Obsidian (Черный)"
        case .auroraGlow: return "Aurora (Северное Сияние)"
        case .nebulaPurple: return "Nebula (Фиолетовый)"
        case .emeraldRefraction: return "Emerald (Изумрудный)"
        case .royalSapphire: return "Sapphire (Сапфир)"
        }
    }

    public var primaryAccent: Color {
        switch self {
        case .cyberGlass: return Color(red: 0.0, green: 0.78, blue: 0.95)
        case .obsidianOLED: return Color(red: 0.55, green: 0.55, blue: 0.65)
        case .auroraGlow: return Color(red: 0.1, green: 0.85, blue: 0.6)
        case .nebulaPurple: return Color(red: 0.7, green: 0.35, blue: 0.95)
        case .emeraldRefraction: return Color(red: 0.15, green: 0.8, blue: 0.45)
        case .royalSapphire: return Color(red: 0.2, green: 0.5, blue: 0.95)
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

    public func backgroundColors(isDark: Bool) -> [Color] {
        if !isDark {
            // Light adaptive liquid pearl palette
            switch self {
            case .cyberGlass:
                return [Color(red: 0.93, green: 0.96, blue: 0.99), Color(red: 0.88, green: 0.92, blue: 0.97)]
            case .obsidianOLED:
                return [Color(red: 0.95, green: 0.95, blue: 0.96), Color(red: 0.90, green: 0.90, blue: 0.92)]
            case .auroraGlow:
                return [Color(red: 0.92, green: 0.97, blue: 0.95), Color(red: 0.87, green: 0.94, blue: 0.92)]
            case .nebulaPurple:
                return [Color(red: 0.95, green: 0.93, blue: 0.98), Color(red: 0.91, green: 0.88, blue: 0.96)]
            case .emeraldRefraction:
                return [Color(red: 0.92, green: 0.97, blue: 0.93), Color(red: 0.88, green: 0.94, blue: 0.89)]
            case .royalSapphire:
                return [Color(red: 0.93, green: 0.95, blue: 0.99), Color(red: 0.88, green: 0.91, blue: 0.97)]
            }
        } else {
            // Dark obsidian liquid palette
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

    public var backgroundColors: [Color] {
        backgroundColors(isDark: true)
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
    public var themeMode: AppThemeMode = .system
    public var preset: LiquidThemePreset = .cyberGlass
    public var glassDepth: GlassMaterialDepth = .ultraLiquid
    public var enableHaptics: Bool = true
    public var enableAmbientGlow: Bool = true
    public var compactCardView: Bool = false

    public init() {}

    enum CodingKeys: String, CodingKey {
        case themeMode, preset, glassDepth, enableHaptics, enableAmbientGlow, compactCardView
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.themeMode = try container.decodeIfPresent(AppThemeMode.self, forKey: .themeMode) ?? .system
        self.preset = try container.decodeIfPresent(LiquidThemePreset.self, forKey: .preset) ?? .cyberGlass
        self.glassDepth = try container.decodeIfPresent(GlassMaterialDepth.self, forKey: .glassDepth) ?? .ultraLiquid
        self.enableHaptics = try container.decodeIfPresent(Bool.self, forKey: .enableHaptics) ?? true
        self.enableAmbientGlow = try container.decodeIfPresent(Bool.self, forKey: .enableAmbientGlow) ?? true
        self.compactCardView = try container.decodeIfPresent(Bool.self, forKey: .compactCardView) ?? false
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(themeMode, forKey: .themeMode)
        try container.encode(preset, forKey: .preset)
        try container.encode(glassDepth, forKey: .glassDepth)
        try container.encode(enableHaptics, forKey: .enableHaptics)
        try container.encode(enableAmbientGlow, forKey: .enableAmbientGlow)
        try container.encode(compactCardView, forKey: .compactCardView)
    }
}
