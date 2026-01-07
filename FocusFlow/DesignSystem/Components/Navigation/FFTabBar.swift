import SwiftUI

// MARK: - FFTabBar
// Custom floating glass tab bar with smooth animations

struct FFTabBar: View {
    @Binding var selectedTab: AppTab
    var theme: AppTheme? = nil
    
    @ObservedObject private var appSettings = AppSettings.shared
    @Namespace private var namespace
    
    private var currentTheme: AppTheme {
        theme ?? appSettings.profileTheme
    }
    
    private let tabs: [AppTab] = [.focus, .tasks, .flow, .progress, .profile]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.self) { tab in
                FFTabItem(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    theme: currentTheme,
                    namespace: namespace
                ) {
                    withAnimation(DS.Animation.quick) {
                        selectedTab = tab
                    }
                    Haptics.impact(.light)
                }
            }
        }
        .padding(.horizontal, DS.Spacing.sm)
        .padding(.vertical, DS.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.xxl, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.xxl, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
        )
        .padding(.horizontal, DS.Spacing.lg)
        .padding(.bottom, DS.Spacing.sm)
    }
}

// MARK: - FFTabItem

struct FFTabItem: View {
    let tab: AppTab
    let isSelected: Bool
    let theme: AppTheme
    let namespace: Namespace.ID
    let action: () -> Void
    
    private var icon: String {
        switch tab {
        case .focus: return isSelected ? "timer" : "timer"
        case .tasks: return isSelected ? "checklist" : "checklist"
        case .flow: return isSelected ? "sparkles" : "sparkles"
        case .progress: return isSelected ? "chart.bar.fill" : "chart.bar"
        case .profile: return isSelected ? "person.circle.fill" : "person.circle"
        }
    }
    
    private var label: String {
        switch tab {
        case .focus: return "Focus"
        case .tasks: return "Tasks"
        case .flow: return "Flow"
        case .progress: return "Progress"
        case .profile: return "Profile"
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    // Selected background with matched geometry
                    if isSelected {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [theme.accentPrimary, theme.accentSecondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                            .matchedGeometryEffect(id: "tabBackground", in: namespace)
                            .shadow(color: theme.accentPrimary.opacity(0.4), radius: 8, y: 4)
                    }
                    
                    // Icon
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(isSelected ? .white : .white.opacity(0.5))
                        .frame(width: 44, height: 44)
                }
                
                // Label
                Text(label)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - FFTabBarModifier
// Replaces system TabView with custom tab bar

struct FFTabBarModifier: ViewModifier {
    @Binding var selectedTab: AppTab
    
    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            // Tab content
            content
            
            // Custom tab bar
            FFTabBar(selectedTab: $selectedTab)
        }
    }
}

extension View {
    /// Apply custom floating tab bar
    func ffTabBar(selectedTab: Binding<AppTab>) -> some View {
        self.modifier(FFTabBarModifier(selectedTab: selectedTab))
    }
}

// MARK: - Alternative Compact Tab Bar

struct FFCompactTabBar: View {
    @Binding var selectedTab: AppTab
    var theme: AppTheme? = nil
    
    @ObservedObject private var appSettings = AppSettings.shared
    
    private var currentTheme: AppTheme {
        theme ?? appSettings.profileTheme
    }
    
    private let tabs: [AppTab] = [.focus, .tasks, .flow, .progress, .profile]
    
    var body: some View {
        HStack(spacing: DS.Spacing.xxs) {
            ForEach(tabs, id: \.self) { tab in
                FFCompactTabItem(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    theme: currentTheme
                ) {
                    withAnimation(DS.Animation.quick) {
                        selectedTab = tab
                    }
                    Haptics.impact(.light)
                }
            }
        }
        .padding(DS.Spacing.xs)
        .background(
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.25), radius: 16, y: 8)
        )
        .padding(.horizontal, DS.Spacing.xxl)
        .padding(.bottom, DS.Spacing.sm)
    }
}

struct FFCompactTabItem: View {
    let tab: AppTab
    let isSelected: Bool
    let theme: AppTheme
    let action: () -> Void
    
    private var icon: String {
        switch tab {
        case .focus: return "timer"
        case .tasks: return "checklist"
        case .flow: return "sparkles"
        case .progress: return "chart.bar"
        case .profile: return "person.circle"
        }
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : .white.opacity(0.5))
                .frame(width: 48, height: 40)
                .background(
                    Capsule(style: .continuous)
                        .fill(
                            isSelected
                                ? LinearGradient(
                                    colors: [theme.accentPrimary, theme.accentSecondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom)
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tab Bar with Badge

struct FFBadgedTabBar: View {
    @Binding var selectedTab: AppTab
    var badges: [AppTab: Int] = [:]
    var theme: AppTheme? = nil
    
    @ObservedObject private var appSettings = AppSettings.shared
    @Namespace private var namespace
    
    private var currentTheme: AppTheme {
        theme ?? appSettings.profileTheme
    }
    
    private let tabs: [AppTab] = [.focus, .tasks, .flow, .progress, .profile]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.self) { tab in
                ZStack(alignment: .topTrailing) {
                    FFTabItem(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        theme: currentTheme,
                        namespace: namespace
                    ) {
                        withAnimation(DS.Animation.quick) {
                            selectedTab = tab
                        }
                        Haptics.impact(.light)
                    }
                    
                    // Badge
                    if let count = badges[tab], count > 0 {
                        Text(count > 99 ? "99+" : "\(count)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .clipShape(Capsule())
                            .offset(x: 8, y: 4)
                    }
                }
            }
        }
        .padding(.horizontal, DS.Spacing.sm)
        .padding(.vertical, DS.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.xxl, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.xxl, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
        )
        .padding(.horizontal, DS.Spacing.lg)
        .padding(.bottom, DS.Spacing.sm)
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedTab: AppTab = .focus
        
        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack {
                    Text("Selected: \(selectedTab.rawValue)")
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    VStack(spacing: DS.Spacing.xxl) {
                        // Full tab bar
                        FFTabBar(selectedTab: $selectedTab)
                        
                        // Compact tab bar
                        FFCompactTabBar(selectedTab: $selectedTab)
                        
                        // Badged tab bar
                        FFBadgedTabBar(
                            selectedTab: $selectedTab,
                            badges: [.tasks: 3, .flow: 1]
                        )
                    }
                }
            }
        }
    }
    
    return PreviewWrapper()
}
