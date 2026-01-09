//
//  OnboardingManager.swift
//  FocusFlow
//
//  Simple onboarding state management
//

import SwiftUI
import Combine

@MainActor
final class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()
    
    private enum Keys {
        static let hasCompletedOnboarding = "ff_hasCompletedOnboarding_v2"
    }
    
    @Published var hasCompletedOnboarding: Bool
    @Published var currentPage: Int = 0
    
    let totalPages = 5
    
    private init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Keys.hasCompletedOnboarding)
    }
    
    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: Keys.hasCompletedOnboarding)
        withAnimation(.easeInOut(duration: 0.5)) {
            hasCompletedOnboarding = true
        }
    }
    
    func nextPage() {
        guard currentPage < totalPages - 1 else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentPage += 1
        }
        Haptics.impact(.light)
    }
    
    func previousPage() {
        guard currentPage > 0 else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentPage -= 1
        }
        Haptics.impact(.light)
    }
    
    func goToPage(_ page: Int) {
        guard page >= 0 && page < totalPages else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentPage = page
        }
    }
    
    func skipOnboarding() {
        Haptics.impact(.medium)
        completeOnboarding()
    }
    
    // For testing/debugging
    func resetOnboarding() {
        UserDefaults.standard.removeObject(forKey: Keys.hasCompletedOnboarding)
        hasCompletedOnboarding = false
        currentPage = 0
    }
}
