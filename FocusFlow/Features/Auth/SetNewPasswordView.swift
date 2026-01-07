import SwiftUI
import Supabase
import Auth

struct SetNewPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var appSettings = AppSettings.shared

    let onFinished: () -> Void

    @State private var password: String = ""
    @State private var confirm: String = ""
    @State private var isLoading: Bool = false
    @State private var error: String?
    @State private var showSuccess: Bool = false

    var body: some View {
        let theme = appSettings.selectedTheme

        ZStack {
            PremiumAppBackground(theme: theme, showParticles: true, particleCount: 14)
                .ignoresSafeArea()

            if showSuccess {
                successView(theme: theme)
            } else {
                formView(theme: theme)
            }
        }
    }
    
    // MARK: - Form View
    
    private func formView(theme: AppTheme) -> some View {
        VStack(spacing: 16) {
            
            // Header with cancel option
            HStack {
                Spacer()
                
                Button {
                    Haptics.impact(.light)
                    cancelAndSignOut()
                } label: {
                    Text("Cancel")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(FFPressButtonStyle())
            }
            .padding(.top, DS.Spacing.lg)
            .padding(.horizontal, DS.Spacing.xl + 2)

            VStack(alignment: .leading, spacing: 10) {
                Text("Set a new password")
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                Text("Choose a strong password to secure your FocusFlow account.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.72))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DS.Spacing.xl + 2)
            .padding(.top, DS.Spacing.xxs)

            VStack(spacing: 14) {
                FFLabeledTextField(
                    label: "NEW PASSWORD",
                    placeholder: "",
                    text: $password,
                    isSecure: true
                )
                FFLabeledTextField(
                    label: "CONFIRM PASSWORD",
                    placeholder: "",
                    text: $confirm,
                    isSecure: true
                )
            }
            .padding(.horizontal, DS.Spacing.xl + 2)
            .padding(.top, DS.Spacing.xxs)

            if let error {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.red.opacity(0.9))
                    Text(error)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.red.opacity(0.9))
                }
                .padding(.horizontal, DS.Spacing.xl + 2)
            }

            FFPrimaryButton(
                title: "Update Password",
                isLoading: isLoading,
                isDisabled: isDisabled,
                theme: theme
            ) {
                submit()
            }
            .padding(.horizontal, DS.Spacing.xl + 2)
            .padding(.top, DS.Spacing.sm)

            Spacer(minLength: 0)
        }
    }
    
    // MARK: - Success View
    
    private func successView(theme: AppTheme) -> some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Success checkmark
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.green.opacity(0.3), Color.green.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.green, Color.green.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 88)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Success text
            VStack(spacing: 12) {
                Text("Password Updated!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Your password has been changed successfully. You can now sign in with your new password.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            
            // Continue button
            VStack(spacing: 16) {
                FFPrimaryButton(
                    title: "Sign In",
                    height: 56,
                    theme: theme
                ) {
                    // Sign out so user can sign in with new password
                    Task {
                        await AuthManagerV2.shared.signOut()
                        onFinished()
                        dismiss()
                        // Post notification to open email login sheet
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            NotificationCenter.default.post(
                                name: Notification.Name("FocusFlow.openEmailLogin"),
                                object: nil
                            )
                        }
                    }
                }
                
                // Not now option - just goes to auth landing
                FFTextButton(title: "Not now", color: .white.opacity(0.6)) {
                    Task {
                        await AuthManagerV2.shared.signOut()
                        onFinished()
                        dismiss()
                    }
                }
            }
            .padding(.horizontal, DS.Spacing.xxl)
            .padding(.bottom, DS.Spacing.huge)
        }
        .onAppear {
            Haptics.notification(.success)
        }
    }

    private var isDisabled: Bool {
        isLoading ||
        password.trimmingCharacters(in: .whitespacesAndNewlines).count < 6 ||
        confirm.trimmingCharacters(in: .whitespacesAndNewlines).count < 6 ||
        password.trimmingCharacters(in: .whitespacesAndNewlines) != confirm.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func submit() {
        error = nil

        let trimmed = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedConfirm = confirm.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmed.count >= 6 else {
            error = "Password must be at least 6 characters."
            return
        }

        guard trimmed == trimmedConfirm else {
            error = "Passwords don't match."
            return
        }

        isLoading = true

        Task {
            do {
                // Requires that the recovery deep link has already established a session.
                _ = try await SupabaseManager.shared.auth.update(
                    user: UserAttributes(password: trimmed)
                )

                await MainActor.run {
                    isLoading = false
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showSuccess = true
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    self.error = error.localizedDescription.isEmpty
                        ? "Couldn't update password. Please try again."
                        : error.localizedDescription
                }
            }
        }
    }
    
    /// Cancel the password reset flow - signs out and returns to login
    private func cancelAndSignOut() {
        Task {
            await AuthManagerV2.shared.signOut()
            await MainActor.run {
                onFinished()
                dismiss()
            }
        }
    }
}
