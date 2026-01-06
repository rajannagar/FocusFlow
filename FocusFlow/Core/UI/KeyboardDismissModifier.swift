import SwiftUI
import UIKit

/// Modifier to dismiss keyboard when tapping outside text fields
/// Uses simultaneousGesture to work alongside other tap gestures
struct KeyboardDismissModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                // This will be triggered when tapping on empty space
                hideKeyboard()
            }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

extension View {
    /// Dismisses keyboard when tapping on any non-interactive area
    /// Interactive elements (text fields, buttons, etc.) will still work normally
    func dismissKeyboardOnTap() -> some View {
        self.modifier(KeyboardDismissModifier())
    }
}

