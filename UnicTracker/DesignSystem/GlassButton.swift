import SwiftUI

public struct GlassButtonStyle: ButtonStyle {
    public var tint: Color?
    public var cornerRadius: CGFloat
    public var isProminent: Bool

    public init(tint: Color? = nil, cornerRadius: CGFloat = 16, isProminent: Bool = false) {
        self.tint = tint
        self.cornerRadius = cornerRadius
        self.isProminent = isProminent
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
            .liquidGlass(
                cornerRadius: cornerRadius,
                depth: .ultraLiquid,
                tint: isProminent ? (tint ?? Color.blue) : tint,
                specular: true,
                glow: isProminent ? 0.8 : 0.3
            )
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    HapticManager.shared.buttonPress()
                }
            }
    }
}

public struct GlassFAB: View {
    public var icon: String
    public var label: String?
    public var tint: Color
    public var action: () -> Void

    public init(
        icon: String = "plus",
        label: String? = nil,
        tint: Color = Color.cyan,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.label = label
        self.tint = tint
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                if let text = label {
                    Text(text)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, label != nil ? 20 : 16)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    Capsule().fill(.ultraThinMaterial)
                    Capsule().fill(tint.opacity(0.35))
                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(0.8), tint.opacity(0.6), Color.white.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                }
            )
            .shadow(color: tint.opacity(0.5), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
