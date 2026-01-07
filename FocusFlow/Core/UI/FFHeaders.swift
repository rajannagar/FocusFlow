import SwiftUI

// MARK: - FFScreenHeader
/// Standardized screen header with logo, title, subtitle, and action buttons

struct FFScreenHeader: View {
    let title: String
    var subtitle: String? = nil
    var showLogo: Bool = true
    var actions: [HeaderAction] = []
    
    struct HeaderAction: Identifiable {
        let id = UUID()
        let icon: String
        var badge: Int? = nil
        let action: () -> Void
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: DS.Spacing.md) {
            // Logo
            if showLogo {
                Image("fflogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 26, height: 26)
            }
            
            // Title stack
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: DS.Font.title, weight: .bold))
                    .foregroundColor(.white)
                
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: DS.Font.footnote, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: DS.Spacing.sm) {
                ForEach(actions) { action in
                    ZStack(alignment: .topTrailing) {
                        FFIconButton(icon: action.icon, action: action.action)
                        
                        // Badge
                        if let badge = action.badge, badge > 0 {
                            Text(badge > 99 ? "99+" : "\(badge)")
                                .font(.system(size: DS.Font.tiny, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.red)
                                .clipShape(Capsule())
                                .offset(x: 6, y: -4)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, DS.Spacing.xl)
        .padding(.top, DS.Spacing.lg)
    }
}

// MARK: - FFSectionHeader
/// Standardized section header with optional action button or custom trailing content

struct FFSectionHeader<TrailingContent: View>: View {
    let title: String
    var infoAction: (() -> Void)? = nil
    var action: (() -> Void)? = nil
    var actionLabel: String? = nil
    var actionIcon: String? = nil
    var trailingContent: (() -> TrailingContent)?
    
    init(
        title: String,
        infoAction: (() -> Void)? = nil,
        action: (() -> Void)? = nil,
        actionLabel: String? = nil,
        actionIcon: String? = nil
    ) where TrailingContent == EmptyView {
        self.title = title
        self.infoAction = infoAction
        self.action = action
        self.actionLabel = actionLabel
        self.actionIcon = actionIcon
        self.trailingContent = nil
    }
    
    init(
        title: String,
        infoAction: (() -> Void)? = nil,
        @ViewBuilder trailingContent: @escaping () -> TrailingContent
    ) {
        self.title = title
        self.infoAction = infoAction
        self.action = nil
        self.actionLabel = nil
        self.actionIcon = nil
        self.trailingContent = trailingContent
    }
    
    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.system(size: DS.Font.caption, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1.5)
            
            // Optional info button right after title
            if let infoAction {
                Button(action: {
                    Haptics.impact(.light)
                    infoAction()
                }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.3))
                }
                .buttonStyle(FFPressButtonStyle())
            }
            
            Spacer()
            
            // Custom trailing content OR action button
            if let trailingContent {
                trailingContent()
            } else if let action {
                Button(action: {
                    Haptics.impact(.light)
                    action()
                }) {
                    HStack(spacing: DS.Spacing.xxs) {
                        if let icon = actionIcon {
                            Image(systemName: icon)
                                .font(.system(size: DS.Font.micro, weight: .bold))
                        }
                        if let label = actionLabel {
                            Text(label)
                                .font(.system(size: DS.Font.caption, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, DS.Spacing.sm)
                    .padding(.vertical, DS.Spacing.xxs)
                    .background(Color.white.opacity(DS.Glass.ultraThin))
                    .clipShape(Capsule())
                }
                .buttonStyle(FFPressButtonStyle())
            }
        }
    }
}

// MARK: - FFNavigationHeader
/// Header with back button for pushed screens

struct FFNavigationHeader: View {
    let title: String
    var subtitle: String? = nil
    var showBackButton: Bool = true
    var actions: [FFScreenHeader.HeaderAction] = []
    let onBack: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: DS.Spacing.md) {
            // Back button
            if showBackButton {
                FFIconButton(icon: "chevron.left", iconSize: 14) {
                    onBack()
                }
            }
            
            // Title stack
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: DS.Font.headline, weight: .bold))
                    .foregroundColor(.white)
                
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: DS.Font.small, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: DS.Spacing.sm) {
                ForEach(actions) { action in
                    FFIconButton(icon: action.icon, action: action.action)
                }
            }
        }
        .padding(.horizontal, DS.Spacing.xl)
        .padding(.vertical, DS.Spacing.md)
    }
}

// MARK: - FFSheetHeader
/// Header for bottom sheets and modals

struct FFSheetHeader: View {
    let title: String
    var subtitle: String? = nil
    var showDragIndicator: Bool = true
    var showCloseButton: Bool = true
    var onClose: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: DS.Spacing.md) {
            // Drag indicator
            if showDragIndicator {
                FFDragIndicator()
            }
            
            // Header row
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: DS.Font.title3, weight: .bold))
                        .foregroundColor(.white)
                    
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: DS.Font.footnote, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                Spacer()
                
                if showCloseButton, let onClose {
                    FFIconButton(
                        icon: "xmark",
                        size: DS.IconButton.sm,
                        iconSize: 14,
                        action: onClose
                    )
                }
            }
        }
        .padding(.horizontal, DS.Spacing.xl)
        .padding(.top, DS.Spacing.sm)
        .padding(.bottom, DS.Spacing.md)
    }
}

// MARK: - FFDragIndicator
/// Drag indicator for sheets

struct FFDragIndicator: View {
    var body: some View {
        Capsule()
            .fill(Color.white.opacity(0.3))
            .frame(width: 36, height: 5)
            .padding(.top, DS.Spacing.sm)
    }
}

// MARK: - FFDivider
/// Subtle divider line

struct FFDivider: View {
    var opacity: Double = 0.08
    var padding: CGFloat = 0
    
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(opacity))
            .frame(height: 1)
            .padding(.horizontal, padding)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack(spacing: DS.Spacing.xxl) {
            FFScreenHeader(
                title: "Focus",
                subtitle: "Stay in the zone",
                actions: [
                    .init(icon: "bell", badge: 3) {},
                    .init(icon: "gear") {}
                ]
            )
            
            FFDivider()
            
            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                FFSectionHeader(
                    title: "Today's Sessions",
                    action: {},
                    actionLabel: "See All",
                    actionIcon: "chevron.right"
                )
                
                FFLiquidGlassCard {
                    Text("Session content here")
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, DS.Spacing.xl)
            
            Spacer()
            
            // Sheet preview
            VStack(spacing: 0) {
                FFSheetHeader(
                    title: "Select Duration",
                    subtitle: "Choose your focus time"
                ) {
                    // close action
                }
                
                FFDivider(padding: DS.Spacing.xl)
                
                Text("Sheet content")
                    .foregroundColor(.white.opacity(0.6))
                    .padding(DS.Spacing.xl)
            }
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous))
            .padding(.horizontal, DS.Spacing.lg)
        }
    }
}
