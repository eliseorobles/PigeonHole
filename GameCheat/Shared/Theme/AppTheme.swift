import UIKit

enum AppTheme {
    // MARK: - Spacing

    static let cornerRadius: CGFloat = 12
    static let smallCornerRadius: CGFloat = 8
    static let padding: CGFloat = 16
    static let smallPadding: CGFloat = 8
    static let gridSpacing: CGFloat = 4

    // MARK: - Haptics

    static func impactLight() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func impactMedium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func notificationSuccess() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
