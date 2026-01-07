import SwiftUI

// MARK: - FFToggle
/// Standardized toggle switch with glass styling

struct FFToggle: View {
    @Binding var isOn: Bool
    var theme: AppTheme? = nil
    
    @ObservedObject private var appSettings = AppSettings.shared
    
    private var currentTheme: AppTheme {
        theme ?? appSettings.profileTheme
    }
    
    var body: some View {
        Toggle("", isOn: $isOn)
            .labelsHidden()
            .tint(currentTheme.accentPrimary)
            .onChange(of: isOn) { _, _ in
                Haptics.impact(.light)
            }
    }
}

// MARK: - FFSettingsRow
/// Standard settings row with icon, label, and trailing content

struct FFSettingsRow<Trailing: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    var subtitle: String? = nil
    @ViewBuilder let trailing: () -> Trailing
    var action: (() -> Void)? = nil
    
    init(
        icon: String,
        iconColor: Color = .white.opacity(0.8),
        title: String,
        subtitle: String? = nil,
        @ViewBuilder trailing: @escaping () -> Trailing,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            if let action {
                Haptics.impact(.light)
                action()
            }
        }) {
            HStack(spacing: DS.Spacing.md) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: DS.Font.body, weight: .medium))
                    .foregroundColor(iconColor)
                    .frame(width: 28, height: 28)
                    .background(iconColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.xs, style: .continuous))
                
                // Labels
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: DS.Font.body, weight: .medium))
                        .foregroundColor(.white)
                    
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: DS.Font.small, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                Spacer()
                
                // Trailing content
                trailing()
            }
            .padding(.vertical, DS.Spacing.md)
            .padding(.horizontal, DS.Spacing.lg)
            .background(Color.white.opacity(DS.Glass.thin))
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}

// MARK: - Convenience initializers

extension FFSettingsRow where Trailing == FFToggle {
    /// Settings row with toggle
    init(
        icon: String,
        iconColor: Color = .white.opacity(0.8),
        title: String,
        subtitle: String? = nil,
        isOn: Binding<Bool>
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.trailing = { FFToggle(isOn: isOn) }
        self.action = nil
    }
}

extension FFSettingsRow where Trailing == FFChevron {
    /// Settings row with chevron
    init(
        icon: String,
        iconColor: Color = .white.opacity(0.8),
        title: String,
        subtitle: String? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.trailing = { FFChevron() }
        self.action = action
    }
}

extension FFSettingsRow where Trailing == FFValueLabel {
    /// Settings row with value label
    init(
        icon: String,
        iconColor: Color = .white.opacity(0.8),
        title: String,
        subtitle: String? = nil,
        value: String,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.trailing = { FFValueLabel(value: value) }
        self.action = action
    }
}

// MARK: - Supporting Views

struct FFChevron: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: DS.Font.small, weight: .semibold))
            .foregroundColor(.white.opacity(0.4))
    }
}

struct FFValueLabel: View {
    let value: String
    
    var body: some View {
        HStack(spacing: DS.Spacing.xxs) {
            Text(value)
                .font(.system(size: DS.Font.body, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
            
            FFChevron()
        }
    }
}

// MARK: - FFSettingsSection
/// Group of settings rows with section header

struct FFSettingsSection<Content: View>: View {
    let title: String?
    @ViewBuilder let content: () -> Content
    
    init(title: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            if let title {
                FFSectionHeader(title: title)
            }
            
            VStack(spacing: DS.Spacing.sm) {
                content()
            }
        }
    }
}

// MARK: - FFListRow
/// Simple list row without icon

struct FFListRow<Trailing: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder let trailing: () -> Trailing
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button(action: {
            if let action {
                Haptics.impact(.light)
                action()
            }
        }) {
            HStack(spacing: DS.Spacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: DS.Font.body, weight: .medium))
                        .foregroundColor(.white)
                    
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: DS.Font.small, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                Spacer()
                
                trailing()
            }
            .padding(.vertical, DS.Spacing.md)
            .padding(.horizontal, DS.Spacing.lg)
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        ScrollView {
            VStack(spacing: DS.Spacing.xxl) {
                FFSettingsSection(title: "General") {
                    FFSettingsRow(
                        icon: "bell",
                        iconColor: .orange,
                        title: "Notifications",
                        isOn: .constant(true)
                    )
                    
                    FFSettingsRow(
                        icon: "speaker.wave.2",
                        iconColor: .blue,
                        title: "Sound Effects",
                        subtitle: "Play sounds during focus",
                        isOn: .constant(false)
                    )
                }
                
                FFSettingsSection(title: "Preferences") {
                    FFSettingsRow(
                        icon: "paintpalette",
                        iconColor: .purple,
                        title: "Theme",
                        value: "Forest"
                    ) {
                        // action
                    }
                    
                    FFSettingsRow(
                        icon: "clock",
                        iconColor: .green,
                        title: "Default Duration",
                        value: "25 min"
                    )
                }
                
                FFSettingsSection(title: "Account") {
                    FFSettingsRow(
                        icon: "person.circle",
                        iconColor: .cyan,
                        title: "Profile"
                    ) {
                        // navigate to profile
                    }
                }
            }
            .padding(.horizontal, DS.Spacing.xl)
            .padding(.vertical, DS.Spacing.lg)
        }
    }
}
