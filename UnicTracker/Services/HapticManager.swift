import UIKit

// MARK: - Liquid Haptic Feedback Engine
public final class HapticManager {
    public static let shared = HapticManager()

    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let softGenerator = UIImpactFeedbackGenerator(style: .soft)
    private let rigidGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()

    private init() {
        prepare()
    }

    public func prepare() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        softGenerator.prepare()
        rigidGenerator.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }

    public func touchGlass() {
        softGenerator.impactOccurred(intensity: 0.7)
    }

    public func toggleTask() {
        rigidGenerator.impactOccurred(intensity: 0.85)
    }

    public func cardExpand() {
        lightGenerator.impactOccurred(intensity: 0.6)
    }

    public func buttonPress() {
        mediumGenerator.impactOccurred()
    }

    public func notifySuccess() {
        notificationGenerator.notificationOccurred(.success)
    }

    public func notifyWarning() {
        notificationGenerator.notificationOccurred(.warning)
    }

    public func notifyError() {
        notificationGenerator.notificationOccurred(.error)
    }

    public func selectionChanged() {
        selectionGenerator.selectionChanged()
    }
}
