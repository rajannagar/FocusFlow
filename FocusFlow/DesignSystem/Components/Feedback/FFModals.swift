import SwiftUI

// MARK: - FFSheetModifier
/// Standardized sheet presentation with glass styling

struct FFSheetModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let detents: Set<PresentationDetent>
    let showDragIndicator: Bool
    let cornerRadius: CGFloat
    let content: () -> SheetContent
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                self.content()
                    .presentationDragIndicator(showDragIndicator ? .visible : .hidden)
                    .presentationCornerRadius(cornerRadius)
                    .presentationBackground(.ultraThinMaterial)
                    .presentationDetents(detents)
            }
    }
}

extension View {
    /// Present a sheet with standardized FocusFlow styling
    func ffSheet<Content: View>(
        isPresented: Binding<Bool>,
        detents: Set<PresentationDetent> = [.medium, .large],
        showDragIndicator: Bool = true,
        cornerRadius: CGFloat = DS.Radius.xl,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.modifier(
            FFSheetModifier(
                isPresented: isPresented,
                detents: detents,
                showDragIndicator: showDragIndicator,
                cornerRadius: cornerRadius,
                content: content
            )
        )
    }
    
    /// Present a small sheet (fits content)
    func ffSmallSheet<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        ffSheet(
            isPresented: isPresented,
            detents: [.medium],
            content: content
        )
    }
    
    /// Present a full sheet
    func ffFullSheet<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        ffSheet(
            isPresented: isPresented,
            detents: [.large],
            content: content
        )
    }
}

// MARK: - FFAlertModifier
/// Standardized alert presentation

struct FFAlertConfig {
    let title: String
    var message: String? = nil
    var primaryButton: AlertButton
    var secondaryButton: AlertButton? = nil
    
    struct AlertButton {
        let title: String
        var role: ButtonRole? = nil
        let action: () -> Void
    }
}

extension View {
    /// Present a standardized alert
    func ffAlert(
        isPresented: Binding<Bool>,
        config: FFAlertConfig
    ) -> some View {
        self.alert(
            config.title,
            isPresented: isPresented
        ) {
            Button(config.primaryButton.title, role: config.primaryButton.role) {
                config.primaryButton.action()
            }
            
            if let secondary = config.secondaryButton {
                Button(secondary.title, role: secondary.role) {
                    secondary.action()
                }
            }
        } message: {
            if let message = config.message {
                Text(message)
            }
        }
    }
    
    /// Present a confirmation dialog
    func ffConfirmation(
        _ title: String,
        isPresented: Binding<Bool>,
        message: String? = nil,
        confirmTitle: String = "Confirm",
        confirmRole: ButtonRole? = .destructive,
        onConfirm: @escaping () -> Void
    ) -> some View {
        self.confirmationDialog(
            title,
            isPresented: isPresented,
            titleVisibility: .visible
        ) {
            Button(confirmTitle, role: confirmRole) {
                Haptics.impact(.medium)
                onConfirm()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let message {
                Text(message)
            }
        }
    }
}

// MARK: - FFToast
/// Toast notification view

struct FFToast: View {
    let message: String
    var icon: String? = nil
    var type: ToastType = .info
    
    enum ToastType {
        case info, success, warning, error
        
        var color: Color {
            switch self {
            case .info: return .white
            case .success: return .green
            case .warning: return .orange
            case .error: return .red
            }
        }
        
        var defaultIcon: String {
            switch self {
            case .info: return "info.circle"
            case .success: return "checkmark.circle"
            case .warning: return "exclamationmark.triangle"
            case .error: return "xmark.circle"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: DS.Spacing.md) {
            Image(systemName: icon ?? type.defaultIcon)
                .font(.system(size: DS.Font.callout, weight: .semibold))
                .foregroundColor(type.color)
            
            Text(message)
                .font(.system(size: DS.Font.body, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(2)
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, DS.Spacing.lg)
        .padding(.vertical, DS.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                .stroke(type.color.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 16, y: 8)
        .padding(.horizontal, DS.Spacing.xl)
    }
}

// MARK: - FFToastModifier
/// Toast presentation modifier

struct FFToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    var icon: String? = nil
    var type: FFToast.ToastType = .info
    var duration: TimeInterval = 3
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            VStack {
                if isPresented {
                    FFToast(message: message, icon: icon, type: type)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                                withAnimation(DS.Animation.smooth) {
                                    isPresented = false
                                }
                            }
                        }
                }
                Spacer()
            }
            .padding(.top, DS.Spacing.xl)
            .animation(DS.Animation.smooth, value: isPresented)
        }
    }
}

extension View {
    /// Show a toast notification
    func ffToast(
        isPresented: Binding<Bool>,
        message: String,
        icon: String? = nil,
        type: FFToast.ToastType = .info,
        duration: TimeInterval = 3
    ) -> some View {
        self.modifier(
            FFToastModifier(
                isPresented: isPresented,
                message: message,
                icon: icon,
                type: type,
                duration: duration
            )
        )
    }
}

// MARK: - FFPopover
/// Popover content wrapper

struct FFPopoverContent<Content: View>: View {
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        content()
            .padding(DS.Spacing.lg)
            .background(.ultraThinMaterial)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack(spacing: DS.Spacing.xxl) {
            FFToast(message: "Focus session started!", type: .success)
            
            FFToast(message: "Connection lost. Retrying...", type: .warning)
            
            FFToast(message: "Failed to save changes", type: .error)
            
            FFToast(message: "Tip: Double-tap to pause", icon: "lightbulb", type: .info)
        }
    }
}
