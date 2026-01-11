//
//  DataMigrationSheet.swift
//  FocusFlow
//
//  Sheet for migrating guest data to a signed-in account
//

import SwiftUI

struct DataMigrationSheet: View {
    let theme: AppTheme
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject private var auth = AuthManagerV2.shared
    @ObservedObject private var migrationManager = GuestMigrationManager.shared
    
    @State private var migrationOptions = GuestMigrationManager.MigrationOptions()
    @State private var migrationError: String?
    @State private var migrationSuccess = false
    @State private var showingAuth = false
    
    private var sessionsCount: Int { migrationManager.guestSessionsCount() }
    private var tasksCount: Int { migrationManager.guestTasksCount() }
    private var presetsCount: Int { migrationManager.guestPresetsCount() }
    private var dailyGoal: Int? { migrationManager.guestDailyGoal() }
    private var hasSettings: Bool { migrationManager.hasGuestSettings() }
    
    private var hasAnyData: Bool {
        sessionsCount > 0 || tasksCount > 0 || presetsCount > 0 || dailyGoal != nil || hasSettings
    }
    
    private var hasAnySelection: Bool {
        migrationOptions.migrateSessions ||
        migrationOptions.migrateTasks ||
        migrationOptions.migratePresets ||
        migrationOptions.migrateDailyGoal ||
        migrationOptions.migrateSettings
    }
    
    /// Check if user is already signed in (sheet shown after sign-in from ContentView)
    private var isAlreadySignedIn: Bool {
        if case .signedIn = auth.state { return true }
        return false
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Premium gradient background
                LinearGradient(
                    colors: [
                        Color.black,
                        theme.accentPrimary.opacity(0.1),
                        Color.black.opacity(0.95)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Subtle radial glow
                RadialGradient(
                    colors: [
                        theme.accentPrimary.opacity(0.15),
                        theme.accentSecondary.opacity(0.05),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 0,
                    endRadius: 400
                )
                .ignoresSafeArea()
                
                if migrationSuccess {
                    successView
                } else if migrationManager.isMigrating {
                    migratingView
                } else {
                    // Always show data selection first
                    dataSelectionView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .fullScreenCover(isPresented: $showingAuth) {
            AuthLandingView()
        }
        .onAppear {
            // If user is already signed in and has data selected, we can show the migrate button
            // Pre-select all available data by default
            if isAlreadySignedIn {
                #if DEBUG
                print("[DataMigrationSheet] User already signed in, pre-selecting all data")
                #endif
                migrationOptions.migrateSessions = sessionsCount > 0
                migrationOptions.migrateTasks = tasksCount > 0
                migrationOptions.migratePresets = presetsCount > 0
                migrationOptions.migrateDailyGoal = dailyGoal != nil
                migrationOptions.migrateSettings = hasSettings
            }
        }
        .onChange(of: auth.state) { oldState, newState in
            // When user signs in (from the auth sheet we opened), close auth and migrate
            if showingAuth, case .signedIn(let userId) = newState {
                #if DEBUG
                print("[DataMigrationSheet] User signed in: \(userId), triggering migration")
                #endif
                showingAuth = false
                
                // IMPORTANT: Before migration, ensure guest data is persisted
                // The stores will switch namespaces, so we need data in UserDefaults
                if case .guest = oldState {
                    #if DEBUG
                    print("[DataMigrationSheet] Persisting guest data before namespace switch...")
                    #endif
                    // Force persist guest data
                    ProgressStore.shared.persist()
                    TasksStore.shared.save()
                    FocusPresetStore.shared.savePresets()
                }
                
                // Small delay to ensure persistence and auth state is fully set
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    performMigration()
                }
            }
        }
    }
    
    // MARK: - Migrating View
    
    private var migratingView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.5)
                .tint(theme.accentPrimary)
            
            Text("Migrating your data...")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Text("Please wait while we transfer your guest data to your account.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, DS.Spacing.huge)
            
            Spacer()
        }
    }
    
    // MARK: - Data Selection View
    
    private var dataSelectionView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(theme.accentPrimary)
                    
                    Text("Migrate Your Data")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    if hasAnyData {
                        Text("Select the data you want to migrate to your account. Your existing account data will be preserved.")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    } else {
                        Text("You don't have any guest data to migrate. You can still create an account and start fresh.")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .padding(.top, 20)
                
                // Migration checkboxes (only show if has data)
                if hasAnyData {
                    VStack(spacing: 16) {
                        if sessionsCount > 0 {
                            migrationCheckbox(
                                title: "Focus Sessions",
                                subtitle: "\(sessionsCount) session\(sessionsCount == 1 ? "" : "s")",
                                icon: "timer",
                                isSelected: $migrationOptions.migrateSessions,
                                color: theme.accentPrimary
                            )
                        }
                        
                        if tasksCount > 0 {
                            migrationCheckbox(
                                title: "Tasks",
                                subtitle: "\(tasksCount) task\(tasksCount == 1 ? "" : "s")",
                                icon: "checklist",
                                isSelected: $migrationOptions.migrateTasks,
                                color: theme.accentSecondary
                            )
                        }
                        
                        if presetsCount > 0 {
                            migrationCheckbox(
                                title: "Focus Presets",
                                subtitle: "\(presetsCount) preset\(presetsCount == 1 ? "" : "s") (with your settings)",
                                icon: "slider.horizontal.3",
                                isSelected: $migrationOptions.migratePresets,
                                color: .orange
                            )
                        }
                        
                        if let goal = dailyGoal {
                            migrationCheckbox(
                                title: "Daily Goal",
                                subtitle: "\(goal) minutes per day",
                                icon: "target",
                                isSelected: $migrationOptions.migrateDailyGoal,
                                color: .blue
                            )
                        }
                        
                        if hasSettings {
                            migrationCheckbox(
                                title: "App Settings",
                                subtitle: "Theme, sounds & preferences",
                                icon: "gearshape.fill",
                                isSelected: $migrationOptions.migrateSettings,
                                color: .purple
                            )
                        }
                    }
                    .padding(.horizontal, DS.Spacing.xxl)
                    .padding(.top, DS.Spacing.xl)
                }
                
                // Action button - different based on auth state
                if isAlreadySignedIn {
                    // User is already signed in - show Migrate button
                    Button {
                        performMigration()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text(hasAnyData && hasAnySelection ? "Migrate Selected Data" : "Skip Migration")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(hasAnySelection ? theme.accentPrimary : Color.white.opacity(0.2))
                        .cornerRadius(DS.Radius.sm)
                    }
                    .buttonStyle(FFPressButtonStyle())
                    .padding(.horizontal, DS.Spacing.xxl)
                    .padding(.top, DS.Spacing.xl)
                } else {
                    // User needs to sign in first
                    Button {
                        showingAuth = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text(hasAnyData ? "Continue to Sign In" : "Create Account or Sign In")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(theme.accentPrimary)
                        .cornerRadius(DS.Radius.sm)
                    }
                    .buttonStyle(FFPressButtonStyle())
                    .padding(.horizontal, DS.Spacing.xxl)
                    .padding(.top, DS.Spacing.xl)
                }
                
                if let error = migrationError {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(.red.opacity(0.8))
                        .padding(.horizontal, DS.Spacing.xxl)
                        .padding(.top, DS.Spacing.sm)
                }
            }
            .padding(.bottom, DS.Spacing.huge)
        }
    }
    
    // MARK: - Success View
    
    private var successView: some View {
        VStack(spacing: DS.Spacing.xxl) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)
            
            Text("Migration Complete!")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text("Your data has been successfully migrated to your account.")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, DS.Spacing.huge)
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(theme.accentPrimary)
                    .cornerRadius(DS.Radius.sm)
            }
            .buttonStyle(FFPressButtonStyle())
            .padding(.horizontal, DS.Spacing.xxl)
            .padding(.bottom, DS.Spacing.huge)
        }
    }
    
    // MARK: - Helper Views
    
    private func dataRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 24)
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.8))
            Spacer()
        }
        .padding(.horizontal, DS.Spacing.xl)
        .padding(.vertical, DS.Spacing.md)
        .background(Color.white.opacity(DS.Glass.thin))
        .cornerRadius(DS.Radius.sm)
    }
    
    private func migrationCheckbox(
        title: String,
        subtitle: String,
        icon: String,
        isSelected: Binding<Bool>,
        color: Color
    ) -> some View {
        Button {
            Haptics.impact(.light)
            isSelected.wrappedValue.toggle()
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected.wrappedValue ? color : Color.clear)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(isSelected.wrappedValue ? color : Color.white.opacity(0.3), lineWidth: 2)
                        )
                    
                    if isSelected.wrappedValue {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 28)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
            }
            .padding(DS.Spacing.lg)
            .background(Color.white.opacity(DS.Glass.thin))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous)
                    .stroke(isSelected.wrappedValue ? color.opacity(0.5) : Color.clear, lineWidth: 1)
            )
            .cornerRadius(DS.Radius.sm)
        }
        .buttonStyle(FFPressButtonStyle())
    }
    
    // MARK: - Migration
    
    private func performMigration() {
        guard case .signedIn(let userId) = auth.state else {
            #if DEBUG
            print("[DataMigrationSheet] performMigration called but user not signed in")
            #endif
            migrationError = "You must be signed in to migrate data"
            return
        }
        
        #if DEBUG
        print("[DataMigrationSheet] performMigration - userId: \(userId)")
        print("[DataMigrationSheet] hasAnyData: \(hasAnyData), hasAnySelection: \(hasAnySelection)")
        print("[DataMigrationSheet] Options: sessions=\(migrationOptions.migrateSessions), tasks=\(migrationOptions.migrateTasks), presets=\(migrationOptions.migratePresets), goal=\(migrationOptions.migrateDailyGoal)")
        #endif
        
        // If no data available at all, just show success and dismiss
        if !hasAnyData {
            #if DEBUG
            print("[DataMigrationSheet] No data to migrate, showing success")
            #endif
            migrationSuccess = true
            return
        }
        
        // If has data but nothing selected, skip migration (user chose to skip)
        if !hasAnySelection {
            #if DEBUG
            print("[DataMigrationSheet] User skipped migration (nothing selected)")
            #endif
            dismiss()
            return
        }
        
        migrationError = nil
        
        Task {
            do {
                #if DEBUG
                print("[DataMigrationSheet] Starting migration...")
                #endif
                try await migrationManager.migrateSelectedData(to: userId, options: migrationOptions)
                await MainActor.run {
                    #if DEBUG
                    print("[DataMigrationSheet] Migration completed successfully")
                    #endif
                    migrationSuccess = true
                }
            } catch {
                await MainActor.run {
                    #if DEBUG
                    print("[DataMigrationSheet] Migration error: \(error)")
                    #endif
                    migrationError = error.localizedDescription
                }
            }
        }
    }
}
