import SwiftUI

// =========================================================
// MARK: - FFGlassCard (Shared premium glass container)
// =========================================================

/// Shared premium glass container used across FocusFlow screens.
///
/// Keeping this centralized prevents each feature from drifting into slightly
/// different glass gradients / strokes. This also makes future tweaks trivial.
struct FFGlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 26
    var padding: CGFloat = 16
    var showsStroke: Bool = true
    let content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.20),
                                Color.white.opacity(0.08)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.white.opacity(showsStroke ? 0.14 : 0.0), lineWidth: showsStroke ? 1 : 0)
                    )
            )
    }
}

// =========================================================
// MARK: - Small reusable UI bits for Progress
// =========================================================

struct FFStatPill: View {
    let icon: String
    let text: String
    var tint: Color = .white.opacity(0.8)

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(text)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundColor(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.12))
        .clipShape(Capsule(style: .continuous))
    }
}

struct FFMetricTile: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    var icon: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.75))
                }
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.75))
            }

            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white.opacity(DS.Glass.regular))
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                .stroke(Color.white.opacity(DS.Glass.borderMedium), lineWidth: 1)
        )
    }
}
