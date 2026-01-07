import SwiftUI

// MARK: - FFLabeledTextField
/// Text input with label above - matches auth flow style

struct FFLabeledTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .never
    var height: CGFloat = 50
    var cornerRadius: CGFloat = DS.Radius.md
    
    @FocusState private var isFocused: Bool
    @State private var isSecureVisible: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: DS.Font.caption, weight: .semibold))
                .foregroundColor(.white.opacity(0.65))
            
            HStack(spacing: DS.Spacing.md) {
                Group {
                    if isSecure && !isSecureVisible {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .font(.system(size: DS.Font.body, weight: .medium))
                .foregroundColor(.white)
                .tint(.white)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled()
                .focused($isFocused)
                
                // Secure toggle
                if isSecure {
                    Button {
                        DS.Haptic.tap()
                        isSecureVisible.toggle()
                    } label: {
                        Image(systemName: isSecureVisible ? "eye.slash" : "eye")
                            .font(.system(size: DS.Font.body, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            .padding(14)
            .frame(height: height)
            .background(Color.white.opacity(DS.Glass.regular))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        isFocused
                            ? Color.white.opacity(DS.Glass.borderStrong)
                            : Color.white.opacity(DS.Glass.borderSubtle),
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }
}

// MARK: - FFTextField
/// Standardized text input field with glass styling

struct FFTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    var submitLabel: SubmitLabel = .done
    var height: CGFloat = 48
    var cornerRadius: CGFloat = DS.Radius.md
    var onSubmit: (() -> Void)? = nil
    
    @FocusState private var isFocused: Bool
    @State private var isSecureVisible: Bool = false
    
    var body: some View {
        HStack(spacing: DS.Spacing.md) {
            // Leading icon
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: DS.Font.callout, weight: .medium))
                    .foregroundColor(.white.opacity(isFocused ? 0.7 : 0.5))
                    .frame(width: 24)
                    .animation(DS.Animation.quick, value: isFocused)
            }
            
            // Text field
            Group {
                if isSecure && !isSecureVisible {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(.system(size: DS.Font.body, weight: .medium))
            .foregroundColor(.white)
            .tint(.white)
            .keyboardType(keyboardType)
            .textInputAutocapitalization(autocapitalization)
            .submitLabel(submitLabel)
            .focused($isFocused)
            .onSubmit {
                onSubmit?()
            }
            
            // Secure toggle for password fields
            if isSecure {
                Button {
                    Haptics.impact(.light)
                    isSecureVisible.toggle()
                } label: {
                    Image(systemName: isSecureVisible ? "eye.slash" : "eye")
                        .font(.system(size: DS.Font.body, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            // Clear button
            if !text.isEmpty && !isSecure {
                Button {
                    Haptics.impact(.light)
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: DS.Font.body))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
        }
        .padding(.horizontal, DS.Spacing.lg)
        .frame(height: height)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white.opacity(DS.Glass.regular))
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    isFocused
                        ? Color.white.opacity(DS.Glass.borderStrong)
                        : Color.white.opacity(DS.Glass.borderSubtle),
                    lineWidth: 1
                )
        )
        .animation(DS.Animation.quick, value: isFocused)
    }
}

// MARK: - FFTextEditor
/// Multi-line text input with glass styling

struct FFTextEditor: View {
    let placeholder: String
    @Binding var text: String
    var minHeight: CGFloat = 100
    var maxHeight: CGFloat = 200
    var cornerRadius: CGFloat = DS.Radius.md
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Placeholder
            if text.isEmpty {
                Text(placeholder)
                    .font(.system(size: DS.Font.body, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.horizontal, DS.Spacing.lg)
                    .padding(.vertical, DS.Spacing.md)
            }
            
            // Text editor
            TextEditor(text: $text)
                .font(.system(size: DS.Font.body, weight: .medium))
                .foregroundColor(.white)
                .tint(.white)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, DS.Spacing.md)
                .padding(.vertical, DS.Spacing.sm)
                .focused($isFocused)
        }
        .frame(minHeight: minHeight, maxHeight: maxHeight)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white.opacity(DS.Glass.regular))
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    isFocused
                        ? Color.white.opacity(DS.Glass.borderStrong)
                        : Color.white.opacity(DS.Glass.borderSubtle),
                    lineWidth: 1
                )
        )
        .animation(DS.Animation.quick, value: isFocused)
    }
}

// MARK: - FFSearchField
/// Search input with magnifying glass icon

struct FFSearchField: View {
    @Binding var text: String
    var placeholder: String = "Search..."
    var height: CGFloat = 44
    var cornerRadius: CGFloat = DS.Radius.full
    var onSubmit: (() -> Void)? = nil
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: DS.Font.body, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
            
            TextField(placeholder, text: $text)
                .font(.system(size: DS.Font.body, weight: .medium))
                .foregroundColor(.white)
                .tint(.white)
                .submitLabel(.search)
                .focused($isFocused)
                .onSubmit {
                    onSubmit?()
                }
            
            if !text.isEmpty {
                Button {
                    Haptics.impact(.light)
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: DS.Font.body))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
        }
        .padding(.horizontal, DS.Spacing.lg)
        .frame(height: height)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(DS.Glass.regular))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(
                    isFocused
                        ? Color.white.opacity(DS.Glass.borderMedium)
                        : Color.white.opacity(DS.Glass.borderSubtle),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - FFLabeledField
/// Text field with label above

struct FFLabeledField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    var errorMessage: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            // Label
            Text(label)
                .font(.system(size: DS.Font.footnote, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
            
            // Field
            FFTextField(
                placeholder: placeholder,
                text: $text,
                icon: icon,
                isSecure: isSecure,
                keyboardType: keyboardType,
                autocapitalization: autocapitalization
            )
            
            // Error message
            if let errorMessage {
                HStack(spacing: DS.Spacing.xxs) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: DS.Font.small))
                    Text(errorMessage)
                        .font(.system(size: DS.Font.small, weight: .medium))
                }
                .foregroundColor(.red.opacity(0.9))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        ScrollView {
            VStack(spacing: DS.Spacing.xl) {
                FFTextField(
                    placeholder: "Enter your name",
                    text: .constant(""),
                    icon: "person"
                )
                
                FFTextField(
                    placeholder: "Password",
                    text: .constant("secret123"),
                    icon: "lock",
                    isSecure: true
                )
                
                FFSearchField(text: .constant(""))
                
                FFLabeledField(
                    label: "Email Address",
                    placeholder: "you@example.com",
                    text: .constant(""),
                    icon: "envelope"
                )
                
                FFLabeledField(
                    label: "Password",
                    placeholder: "Enter password",
                    text: .constant(""),
                    icon: "lock",
                    isSecure: true,
                    errorMessage: "Password must be at least 8 characters"
                )
                
                FFTextEditor(
                    placeholder: "Write your notes here...",
                    text: .constant("")
                )
            }
            .padding(DS.Spacing.xl)
        }
    }
}
