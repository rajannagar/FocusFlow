import Foundation
import SwiftUI

struct FocusNotification: Identifiable, Codable, Hashable {
    enum Kind: String, Codable {
        case sessionCompleted
        case taskCompleted
        case streak
        case levelUp
        case badgeUnlocked
        case goalUpdated
        case dailyRecap
        case general
    }

    let id: UUID
    let kind: Kind
    let title: String
    let body: String
    let date: Date
    var isRead: Bool

    init(
        id: UUID = UUID(),
        kind: Kind,
        title: String,
        body: String,
        date: Date = Date(),
        isRead: Bool = false
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.body = body
        self.date = date
        self.isRead = isRead
    }

    // MARK: - Presentation helpers

    var iconName: String {
        switch kind {
        case .sessionCompleted: return "sparkles"
        case .taskCompleted:    return "checkmark.circle.fill"
        case .streak:           return "flame.fill"
        case .levelUp:          return "arrow.up.circle.fill"
        case .badgeUnlocked:    return "rosette"
        case .goalUpdated:      return "target"
        case .dailyRecap:       return "book.pages.fill"
        case .general:          return "bell.fill"
        }
    }

    var relativeDateString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
