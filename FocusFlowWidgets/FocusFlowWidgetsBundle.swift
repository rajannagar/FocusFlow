import WidgetKit
import SwiftUI

@main
struct FocusFlowWidgetsBundle: WidgetBundle {
    var body: some Widget {
        // Only the Live Activity widget
        FocusSessionLiveActivity()
    }
}
