import SwiftUI

public struct PriorityBadge: View {
    public var priority: TaskPriority
    public var compact: Bool

    public init(priority: TaskPriority, compact: Bool = false) {
        self.priority = priority
        self.compact = compact
    }

    public var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(priority.color)
                .frame(width: compact ? 6 : 7, height: compact ? 6 : 7)
                .shadow(color: priority.color.opacity(0.8), radius: 3)

            if !compact {
                Text(priority.rawValue)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(priority.color)
            }
        }
        .padding(.horizontal, compact ? 6 : 8)
        .padding(.vertical, compact ? 3 : 4)
        .background(
            Capsule()
                .fill(priority.color.opacity(0.14))
                .overlay(
                    Capsule()
                        .strokeBorder(priority.color.opacity(0.35), lineWidth: 0.8)
                )
        )
    }
}
