import SwiftUI

public struct GlassCard<Content: View>: View {
    public var cornerRadius: CGFloat
    public var tint: Color?
    public var glow: Double
    @ViewBuilder public var content: Content

    public init(
        cornerRadius: CGFloat = 20,
        tint: Color? = nil,
        glow: Double = 0.4,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.tint = tint
        self.glow = glow
        self.content = content()
    }

    public var body: some View {
        content
            .padding(16)
            .liquidGlass(
                cornerRadius: cornerRadius,
                depth: .ultraLiquid,
                tint: tint,
                specular: true,
                glow: glow
            )
    }
}
