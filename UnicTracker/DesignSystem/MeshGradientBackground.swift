import SwiftUI

public struct MeshGradientBackground: View {
    @ObservedObject var store: DataStore
    @State private var animateGlow: Bool = false

    public init(store: DataStore) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            // Base dark background
            LinearGradient(
                colors: store.theme.preset.backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if store.theme.enableAmbientGlow {
                // Ambient Luminous Liquid Orbs
                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height

                    // Orb 1: Primary Accent
                    Circle()
                        .fill(store.theme.preset.primaryAccent.opacity(0.22))
                        .frame(width: w * 0.9, height: w * 0.9)
                        .blur(radius: 70)
                        .offset(
                            x: animateGlow ? -w * 0.2 : w * 0.1,
                            y: animateGlow ? -h * 0.15 : -h * 0.05
                        )

                    // Orb 2: Secondary Accent
                    Circle()
                        .fill(store.theme.preset.secondaryAccent.opacity(0.18))
                        .frame(width: w * 0.85, height: w * 0.85)
                        .blur(radius: 80)
                        .offset(
                            x: animateGlow ? w * 0.3 : -w * 0.1,
                            y: animateGlow ? h * 0.4 : h * 0.2
                        )

                    // Orb 3: Subtle Sub-Surface Refraction
                    Circle()
                        .fill(Color.cyan.opacity(0.12))
                        .frame(width: w * 0.6, height: w * 0.6)
                        .blur(radius: 60)
                        .offset(
                            x: animateGlow ? 0 : w * 0.2,
                            y: animateGlow ? h * 0.7 : h * 0.6
                        )
                }
                .ignoresSafeArea()
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8.0).repeatForever(autoreverses: true)) {
                animateGlow.toggle()
            }
        }
    }
}
