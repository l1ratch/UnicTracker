import SwiftUI

// MARK: - Liquid Glass View Modifier (iOS 26/27 Refractive Design)
public struct LiquidGlassModifier: ViewModifier {
    public var cornerRadius: CGFloat
    public var depth: GlassMaterialDepth
    public var tintColor: Color?
    public var hasSpecularHighlight: Bool
    public var glowIntensity: Double

    public init(
        cornerRadius: CGFloat = 20,
        depth: GlassMaterialDepth = .ultraLiquid,
        tintColor: Color? = nil,
        hasSpecularHighlight: Bool = true,
        glowIntensity: Double = 0.5
    ) {
        self.cornerRadius = cornerRadius
        self.depth = depth
        self.tintColor = tintColor
        self.hasSpecularHighlight = hasSpecularHighlight
        self.glowIntensity = glowIntensity
    }

    public func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Base Ultra-Thin Blur Layer
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)

                    // Liquid Glass Sub-Surface Tint
                    if let tint = tintColor {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        tint.opacity(depth.surfaceOpacity * 1.5),
                                        tint.opacity(depth.surfaceOpacity * 0.4),
                                        Color.white.opacity(0.02)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    } else {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(depth.surfaceOpacity),
                                        Color.white.opacity(depth.surfaceOpacity * 0.3),
                                        Color.black.opacity(0.15)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    // Top Specular Refraction Arc (Liquid Glass Characteristic)
                    if hasSpecularHighlight {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    stops: [
                                        .init(color: Color.white.opacity(depth.borderOpacity + 0.3), location: 0.0),
                                        .init(color: (tintColor ?? Color.white).opacity(0.4), location: 0.25),
                                        .init(color: Color.white.opacity(0.05), location: 0.6),
                                        .init(color: Color.white.opacity(depth.borderOpacity * 0.5), location: 1.0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.2
                            )
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(
                color: (tintColor ?? Color.black).opacity(0.18 * glowIntensity),
                radius: 14,
                x: 0,
                y: 8
            )
    }
}

// MARK: - View Extension for Liquid Glass
public extension View {
    func liquidGlass(
        cornerRadius: CGFloat = 20,
        depth: GlassMaterialDepth = .ultraLiquid,
        tint: Color? = nil,
        specular: Bool = true,
        glow: Double = 0.5
    ) -> some View {
        self.modifier(
            LiquidGlassModifier(
                cornerRadius: cornerRadius,
                depth: depth,
                tintColor: tint,
                hasSpecularHighlight: specular,
                glowIntensity: glow
            )
        )
    }

    func liquidGlassPod(cornerRadius: CGFloat = 28) -> some View {
        self.modifier(
            LiquidGlassModifier(
                cornerRadius: cornerRadius,
                depth: .ultraLiquid,
                tintColor: nil,
                hasSpecularHighlight: true,
                glowIntensity: 0.6
            )
        )
    }
}
