import SwiftUI
import Combine

// MARK: - Flow Navigation Coordinator

/// Coordinates navigation requests from Flow AI to the app's navigation system
/// This bridges the FlowActionHandler to ContentView's navigation state

@MainActor
final class FlowNavigationCoordinator: ObservableObject {
    static let shared = FlowNavigationCoordinator()
    
    // MARK: - Navigation State
    
    /// The tab to navigate to (bound to ContentView's selectedTab)
    @Published var pendingTab: AppTab?
    
    /// Sheet to present
    @Published var sheetToPresent: FlowSheet?
    
    /// Whether to show paywall
    @Published var showPaywall: Bool = false
    var paywallContext: PaywallContext = .general
    
    // MARK: - Sheet Types
    
    enum FlowSheet: Identifiable {
        case presetManager
        case settings
        case notificationCenter
        
        var id: String {
            switch self {
            case .presetManager: return "presetManager"
            case .settings: return "settings"
            case .notificationCenter: return "notificationCenter"
            }
        }
    }
    
    // MARK: - Subscriptions
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupBindings()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Listen to FlowActionHandler navigation requests
        FlowActionHandler.shared.$navigationRequest
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] request in
                self?.handleNavigationRequest(request)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Handle Navigation
    
    private func handleNavigationRequest(_ request: FlowActionHandler.NavigationRequest) {
        switch request.destination {
        case .tab(let tabDestination):
            navigateToTab(tabDestination)
            
        case .presetManager:
            sheetToPresent = .presetManager
            
        case .settings:
            sheetToPresent = .settings
            
        case .notificationCenter:
            sheetToPresent = .notificationCenter
            
        case .paywall(let trigger):
            paywallContext = mapTriggerToContext(trigger)
            showPaywall = true
            
        case .back:
            // Dismiss any presented sheet
            sheetToPresent = nil
            showPaywall = false
        }
    }
    
    private func mapTriggerToContext(_ trigger: PaywallTrigger) -> PaywallContext {
        switch trigger {
        case .ai: return .ai
        case .preset: return .preset
        case .theme: return .theme
        case .stats: return .general
        case .general: return .general
        }
    }
    
    private func navigateToTab(_ destination: AppTabDestination) {
        switch destination {
        case .focus:
            pendingTab = .focus
        case .tasks:
            pendingTab = .tasks
        case .progress:
            pendingTab = .progress
        case .profile:
            pendingTab = .profile
        case .flow:
            pendingTab = .flow
        }
        
        // Clear after a brief delay to allow the navigation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.pendingTab = nil
        }
    }
    
    // MARK: - Manual Navigation
    
    /// Navigate to a specific tab programmatically
    func navigateTo(tab: AppTab) {
        pendingTab = tab
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.pendingTab = nil
        }
    }
    
    /// Present a sheet
    func present(sheet: FlowSheet) {
        sheetToPresent = sheet
    }
    
    /// Show paywall with context
    func showPaywall(context: PaywallContext) {
        paywallContext = context
        showPaywall = true
    }
    
    /// Dismiss any presented content
    func dismiss() {
        sheetToPresent = nil
        showPaywall = false
    }
}

// MARK: - Focus Control Coordinator

/// Coordinates focus control requests from Flow AI to the FocusView/Timer
@MainActor
final class FlowFocusCoordinator: ObservableObject {
    static let shared = FlowFocusCoordinator()
    
    // MARK: - Focus State Callbacks
    
    /// Called when AI wants to start a focus session
    var onStartFocus: ((Int, UUID?, String?) -> Void)?
    
    /// Called when AI wants to pause focus
    var onPauseFocus: (() -> Void)?
    
    /// Called when AI wants to resume focus
    var onResumeFocus: (() -> Void)?
    
    /// Called when AI wants to end focus
    var onEndFocus: (() -> Void)?
    
    /// Called when AI wants to extend focus
    var onExtendFocus: ((Int) -> Void)?
    
    /// Called when AI sets an intention
    var onSetIntention: ((String) -> Void)?
    
    // MARK: - Subscriptions
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupBindings()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        FlowActionHandler.shared.$focusControlRequest
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] request in
                self?.handleFocusRequest(request)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Handle Focus Control
    
    private func handleFocusRequest(_ request: FlowActionHandler.FocusControlRequest) {
        switch request.action {
        case .start(let minutes, let presetID, let sessionName):
            onStartFocus?(minutes, presetID, sessionName)
            
        case .pause:
            onPauseFocus?()
            
        case .resume:
            onResumeFocus?()
            
        case .end:
            onEndFocus?()
            
        case .extend(let minutes):
            onExtendFocus?(minutes)
            
        case .setIntention(let text):
            onSetIntention?(text)
        }
    }
}

// MARK: - View Extension for Navigation Binding

/// View modifier to bind Flow navigation to a view
struct FlowNavigationBinder: ViewModifier {
    @ObservedObject var coordinator = FlowNavigationCoordinator.shared
    @Binding var selectedTab: AppTab
    
    func body(content: Content) -> some View {
        content
            .onChange(of: coordinator.pendingTab) { newTab in
                if let tab = newTab {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }
            }
    }
}

extension View {
    /// Bind Flow AI navigation to this view's tab selection
    func flowNavigationBound(selectedTab: Binding<AppTab>) -> some View {
        modifier(FlowNavigationBinder(selectedTab: selectedTab))
    }
}

// MARK: - ContentView Integration Helper

/// A wrapper view that handles Flow navigation sheets and paywall
struct FlowNavigationOverlay<Content: View>: View {
    let content: Content
    @ObservedObject var coordinator = FlowNavigationCoordinator.shared
    @EnvironmentObject var appSettings: AppSettings
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .sheet(item: $coordinator.sheetToPresent) { sheet in
                sheetContent(for: sheet)
            }
            .sheet(isPresented: $coordinator.showPaywall) {
                PaywallView(context: coordinator.paywallContext)
                    .environmentObject(appSettings)
            }
    }
    
    @ViewBuilder
    private func sheetContent(for sheet: FlowNavigationCoordinator.FlowSheet) -> some View {
        switch sheet {
        case .presetManager:
            // Navigate to focus view where presets can be managed
            NavigationStack {
                FocusView()
                    .navigationTitle("Focus")
            }
            .environmentObject(appSettings)
            
        case .settings:
            NavigationStack {
                SettingsView()
            }
            .environmentObject(appSettings)
            
        case .notificationCenter:
            NavigationStack {
                NotificationCenterView()
                    .navigationTitle("Notifications")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .environmentObject(appSettings)
        }
    }
}
