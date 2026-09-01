import SwiftUI

public struct GlassProgressRing: View {
    public var progress: Double // 0.0 ... 1.0
    public var size: CGFloat
    public var strokeWidth: CGFloat
    public var accentColors: [Color]

    public init(
        progress: Double,
        size: CGFloat = 84,
        strokeWidth: CGFloat = 8,
        accentColors: [Color] = [Color.cyan, Color.blue, Color.purple]
    ) {
        self.progress = max(0.0, min(1.0, progress))
        self.size = size
        self.strokeWidth = strokeWidth
        self.accentColors = accentColors
    }

    public var body: some View {
        ZStack {
            // Background Glass Track
            Circle()
                .stroke(
                    Color.white.opacity(0.12),
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )

            // Outer Soft Glow Layer
            Circle()
                .trim(from: 0.0, to: CGFloat(progress))
                .stroke(
                    LinearGradient(
                        colors: accentColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: strokeWidth + 3, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .blur(radius: 5)
                .opacity(0.6)

            // Primary Glowing Progress Stroke
            Circle()
                .trim(from: 0.0, to: CGFloat(progress))
                .stroke(
                    LinearGradient(
                        colors: accentColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.5, dampingFraction: 0.75), value: progress)

            // Center Percentage Text
            VStack(spacing: 0) {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: size * 0.26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("готовность")
                    .font(.system(size: size * 0.11, weight: .medium))
                    .foregroundColor(.white.opacity(0.65))
            }
        }
        .frame(width: size, height: size)
    }
}
