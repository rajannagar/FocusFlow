# 🎨 FocusFlow UI Consistency & Liquid Glass Redesign Plan

> **Created:** January 6, 2026  
> **Status:** Awaiting Review  
> **Target:** iOS 26 Liquid Glass Design Language

---

## Executive Summary

This document outlines a comprehensive plan to achieve UI consistency across FocusFlow while adopting Apple's new **Liquid Glass** design language from iOS 26. The goal is to create a cohesive, premium experience with standardized spacing, typography, components, and interactions.

---

## 📊 Current State Analysis

### What's Working Well ✅

1. **Consistent theme system** via `AppTheme` with 10 beautiful themes
2. **Shared `PremiumAppBackground`** used across all screens
3. **`FFGlassCard`** component for glass morphism
4. **Header pattern** is fairly consistent (26x26 logo, 24pt title, 36x36 icon buttons)
5. **Section headers** use 11pt bold tracking consistently

### Critical Inconsistencies Found ⚠️

| Issue | Current State | Impact |
|-------|---------------|--------|
| **Horizontal Padding** | 16, 20, 22, 24 across screens | Visual misalignment |
| **Corner Radius** | 12, 14, 16, 18, 20, 24, 26 used randomly | Inconsistent cards |
| **Background Opacity** | 0.04 - 0.08 for same components | Visual noise |
| **Icon Button Sizes** | 28, 34, 36, 40, 44 | Inconsistent touch targets |
| **Body Font Sizes** | 12, 13, 14, 15, 16 pt | Reading experience varies |
| **Spacing Values** | No system - arbitrary values | Messy layouts |

### Detailed Findings by Screen

#### FocusView
- Horizontal padding: **22** (non-standard)
- Icon buttons: 36x36 header, 40x40 intention
- VStack spacing: 20
- Top padding: 18

#### TasksView
- Horizontal padding: **20** ✅
- Corner radii: 14, 16, 18, 20 (inconsistent)
- Background opacity: 0.04, 0.05, 0.06 (varies)

#### ProgressView
- Horizontal padding: **20** ✅
- Date nav buttons: 44x44 (oversized)
- Card corner radius: 24

#### ProfileView
- Horizontal padding: **20** ✅
- Avatar ring: lineWidth 4
- Card corner radius: 24

#### SettingsView
- Horizontal padding: **20** ✅
- Row font sizes: 13, 14, 15 (varies)
- Button padding: 10, 16 (inconsistent)

#### AuthViews
- Horizontal padding: **24** (non-standard)
- Button height: 54-56 (varies)
- Corner radius: 16, 20 (inconsistent)

#### FlowChatView
- Horizontal padding: **16, 24** (both used)
- Message padding: varies
- Voice sheet corner radius: 25

---

## 🧊 Liquid Glass Design System

### What is Liquid Glass?

iOS 26 introduces a new design language featuring:
- **True glass materials** that blur and refract content
- **Depth layering** with subtle shadows and highlights
- **Fluid animations** with spring physics
- **Responsive tinting** that adapts to underlying content
- **Floating UI elements** with subtle elevation

---

## 📐 Design Tokens

### File: `FocusFlow/Core/UI/FFDesignSystem.swift`

```swift
import SwiftUI

// MARK: - FFDesignSystem
// Single source of truth for all design tokens

enum FFDesignSystem {
    
    // MARK: - Spacing Scale (4pt base unit)
    enum Spacing {
        static let xxxs: CGFloat = 2    // Micro gaps
        static let xxs: CGFloat = 4     // Icon to text
        static let xs: CGFloat = 6      // Tight grouping
        static let sm: CGFloat = 8      // Related elements
        static let md: CGFloat = 12     // Section elements
        static let lg: CGFloat = 16     // Card padding
        static let xl: CGFloat = 20     // Screen padding (STANDARD)
        static let xxl: CGFloat = 24    // Section gaps
        static let xxxl: CGFloat = 32   // Major sections
    }
    
    // MARK: - Corner Radius Scale
    enum Radius {
        static let xs: CGFloat = 8      // Small badges
        static let sm: CGFloat = 12     // Pills, chips
        static let md: CGFloat = 16     // Buttons, inputs
        static let lg: CGFloat = 20     // Cards
        static let xl: CGFloat = 24     // Large cards, sheets
        static let full: CGFloat = 999  // Capsules, circles
    }
    
    // MARK: - Typography Scale
    enum Font {
        static let micro: CGFloat = 10      // Badges, tiny labels
        static let caption: CGFloat = 11    // Section headers, hints
        static let small: CGFloat = 12      // Meta text, timestamps
        static let body: CGFloat = 15       // Body text (STANDARD)
        static let callout: CGFloat = 16    // Emphasis, buttons
        static let headline: CGFloat = 18   // Card titles
        static let title: CGFloat = 24      // Screen titles
        static let largeTitle: CGFloat = 32 // Hero text
        static let display: CGFloat = 44    // Timer displays
    }
    
    // MARK: - Icon Button Sizes
    enum IconButton {
        static let sm: CGFloat = 32     // Inline actions
        static let md: CGFloat = 36     // Header buttons (STANDARD)
        static let lg: CGFloat = 44     // Primary actions
        static let xl: CGFloat = 56     // FAB (Floating Action Button)
    }
    
    // MARK: - Glass Effects
    enum Glass {
        // Background fills
        static let ultraThin: Double = 0.03
        static let thin: Double = 0.05
        static let regular: Double = 0.08
        static let thick: Double = 0.12
        
        // Border opacities
        static let borderSubtle: Double = 0.06
        static let borderMedium: Double = 0.10
        static let borderStrong: Double = 0.15
        
        // Blur radii
        static let blurLight: CGFloat = 10
        static let blurMedium: CGFloat = 20
        static let blurHeavy: CGFloat = 40
    }
    
    // MARK: - Shadows
    enum Shadow {
        static let small = (opacity: 0.10, radius: 4.0, y: 2.0)
        static let medium = (opacity: 0.15, radius: 12.0, y: 6.0)
        static let large = (opacity: 0.20, radius: 20.0, y: 10.0)
        static let glow = (opacity: 0.25, radius: 16.0, y: 0.0)
    }
    
    // MARK: - Animation Presets
    enum Animation {
        static let quick = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.8)
        static let smooth = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.9)
        static let bounce = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.6)
        static let slow = SwiftUI.Animation.spring(response: 0.7, dampingFraction: 0.85)
    }
    
    // MARK: - Haptic Feedback
    enum Haptic {
        case light, medium, heavy, soft, rigid
        case selection
        case success, warning, error
    }
}

// MARK: - Convenience Typealiases
typealias DS = FFDesignSystem
typealias Spacing = DS.Spacing
typealias Radius = DS.Radius
```

---

## 🧱 Core Components

### 1. FFLiquidGlassCard

```swift
// File: FocusFlow/Core/UI/FFLiquidGlassCard.swift

import SwiftUI

/// Liquid Glass card component - adapts to iOS 26+
struct FFLiquidGlassCard<Content: View>: View {
    var cornerRadius: CGFloat = DS.Radius.lg
    var padding: CGFloat = DS.Spacing.lg
    var backgroundOpacity: Double = DS.Glass.thin
    var borderOpacity: Double = DS.Glass.borderMedium
    var tint: Color = .white
    var showShadow: Bool = true
    let content: () -> Content
    
    var body: some View {
        content()
            .padding(padding)
            .background {
                glassBackground
            }
            .overlay {
                glassBorder
            }
            .if(showShadow) { view in
                view.shadow(
                    color: .black.opacity(DS.Shadow.medium.opacity),
                    radius: DS.Shadow.medium.radius,
                    y: DS.Shadow.medium.y
                )
            }
    }
    
    @ViewBuilder
    private var glassBackground: some View {
        if #available(iOS 26, *) {
            // iOS 26: True liquid glass with system material
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.glassUltraThin)
                .glassBackgroundEffect(tint: tint)
        } else {
            // iOS 18-25: Fallback with material + overlay
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(backgroundOpacity))
                
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.08),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
    }
    
    private var glassBorder: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(borderOpacity * 1.5),
                        Color.white.opacity(borderOpacity * 0.5)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
}

// MARK: - View Extension for conditional modifiers
extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
```

### 2. FFIconButton

```swift
// File: FocusFlow/Core/UI/FFIconButton.swift

import SwiftUI

/// Standardized icon button used in headers and actions
struct FFIconButton: View {
    let icon: String
    var size: CGFloat = DS.IconButton.md
    var iconSize: CGFloat = 16
    var backgroundColor: Color = .white.opacity(DS.Glass.regular)
    var foregroundColor: Color = .white.opacity(0.8)
    var borderColor: Color = .white.opacity(DS.Glass.borderSubtle)
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            Haptics.impact(.light)
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundColor(foregroundColor)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(backgroundColor)
                )
                .overlay(
                    Circle()
                        .stroke(borderColor, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

/// Primary action button (gradient background)
struct FFPrimaryButton: View {
    let title: String
    var icon: String? = nil
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void
    
    @ObservedObject private var appSettings = AppSettings.shared
    
    var body: some View {
        Button(action: {
            guard !isLoading && !isDisabled else { return }
            Haptics.impact(.medium)
            action()
        }) {
            HStack(spacing: DS.Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    if let icon {
                        Image(systemName: icon)
                            .font(.system(size: DS.Font.callout, weight: .semibold))
                    }
                    Text(title)
                        .font(.system(size: DS.Font.callout, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                appSettings.profileTheme.accentPrimary,
                                appSettings.profileTheme.accentSecondary
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .opacity(isDisabled ? 0.5 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled || isLoading)
    }
}

/// Secondary button (ghost/outline style)
struct FFSecondaryButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            Haptics.impact(.light)
            action()
        }) {
            HStack(spacing: DS.Spacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: DS.Font.body, weight: .medium))
                }
                Text(title)
                    .font(.system(size: DS.Font.body, weight: .semibold))
            }
            .foregroundColor(.white.opacity(0.9))
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                    .fill(Color.white.opacity(DS.Glass.regular))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                    .stroke(Color.white.opacity(DS.Glass.borderMedium), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
```

### 3. FFTextField

```swift
// File: FocusFlow/Core/UI/FFTextField.swift

import SwiftUI

/// Standardized text input field
struct FFTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: DS.Spacing.md) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: DS.Font.callout, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 24)
            }
            
            Group {
                if isSecure {
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
            .focused($isFocused)
        }
        .padding(.horizontal, DS.Spacing.lg)
        .frame(height: 48)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                .fill(Color.white.opacity(DS.Glass.regular))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
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
```

### 4. FFSectionHeader

```swift
// File: FocusFlow/Core/UI/FFSectionHeader.swift

import SwiftUI

/// Standardized section header
struct FFSectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil
    var actionLabel: String? = nil
    var actionIcon: String? = nil
    
    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.system(size: DS.Font.caption, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1.5)
            
            Spacer()
            
            if let action, let label = actionLabel {
                Button(action: {
                    Haptics.impact(.light)
                    action()
                }) {
                    HStack(spacing: DS.Spacing.xxs) {
                        if let icon = actionIcon {
                            Image(systemName: icon)
                                .font(.system(size: DS.Font.micro, weight: .bold))
                        }
                        Text(label)
                            .font(.system(size: DS.Font.caption, weight: .semibold))
                    }
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, DS.Spacing.sm)
                    .padding(.vertical, DS.Spacing.xxs)
                    .background(Color.white.opacity(DS.Glass.ultraThin))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
```

### 5. FFScreenHeader

```swift
// File: FocusFlow/Core/UI/FFScreenHeader.swift

import SwiftUI

/// Standardized screen header with logo, title, and action buttons
struct FFScreenHeader: View {
    let title: String
    var subtitle: String? = nil
    var actions: [HeaderAction] = []
    
    struct HeaderAction: Identifiable {
        let id = UUID()
        let icon: String
        let action: () -> Void
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: DS.Spacing.md) {
            // Logo
            Image("fflogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 26, height: 26)
            
            // Title stack
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: DS.Font.title, weight: .bold))
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
        .padding(.top, DS.Spacing.lg)
    }
}
```

### 6. FFSheetModifier

```swift
// File: FocusFlow/Core/UI/FFSheetModifier.swift

import SwiftUI

/// Standardized sheet presentation
struct FFSheetModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let detents: Set<PresentationDetent>
    let showDragIndicator: Bool
    let content: () -> SheetContent
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                self.content()
                    .presentationDragIndicator(showDragIndicator ? .visible : .hidden)
                    .presentationCornerRadius(DS.Radius.xl)
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
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.modifier(
            FFSheetModifier(
                isPresented: isPresented,
                detents: detents,
                showDragIndicator: showDragIndicator,
                content: content
            )
        )
    }
}

/// Drag indicator for custom sheet implementations
struct FFDragIndicator: View {
    var body: some View {
        Capsule()
            .fill(Color.white.opacity(0.3))
            .frame(width: 36, height: 5)
            .padding(.top, DS.Spacing.sm)
    }
}
```

---

## 🏗️ Implementation Phases

### Phase 1: Foundation (Week 1)

**Create new files:**

| File | Description |
|------|-------------|
| `FFDesignSystem.swift` | All design tokens |
| `FFLiquidGlassCard.swift` | Glass card component |
| `FFIconButton.swift` | Button components |
| `FFTextField.swift` | Input field component |
| `FFSectionHeader.swift` | Section headers |
| `FFScreenHeader.swift` | Screen headers |
| `FFSheetModifier.swift` | Sheet presentation |

### Phase 2: Screen Updates (Week 2)

**Update padding inconsistencies:**

| File | Change |
|------|--------|
| `FocusView.swift` | `.padding(.horizontal, 22)` → `.padding(.horizontal, DS.Spacing.xl)` |
| `AuthLandingView.swift` | `.padding(.horizontal, 24)` → `.padding(.horizontal, DS.Spacing.xl)` |
| `FlowChatView.swift` | Various padding → `DS.Spacing.xl` |
| `EmailAuthView.swift` | `.padding(.horizontal, 24)` → `.padding(.horizontal, DS.Spacing.xl)` |

**Update corner radii:**

| Pattern | Standard |
|---------|----------|
| Small cards/chips | `DS.Radius.sm` (12) |
| Input fields/buttons | `DS.Radius.md` (16) |
| Standard cards | `DS.Radius.lg` (20) |
| Large cards/sheets | `DS.Radius.xl` (24) |

### Phase 3: Component Migration (Week 3)

**Replace inline styles with components:**

| Current | New |
|---------|-----|
| Inline header code | `FFScreenHeader` |
| Inline section headers | `FFSectionHeader` |
| Inline icon buttons | `FFIconButton` |
| Inline glass backgrounds | `FFLiquidGlassCard` |
| Inline text fields | `FFTextField` |

### Phase 4: Interactions & Polish (Week 4)

**Standardize:**

| Area | Implementation |
|------|----------------|
| Sheet presentations | Use `ffSheet()` modifier |
| Swipe actions | Red for delete, green for complete |
| Keyboard handling | Auto-dismiss, toolbar with Done |
| Haptic feedback | Consistent triggers |
| Animations | Replace `.easeInOut` with spring |

---

## 📋 Global Standards Reference

### Layout

| Element | Value | Token |
|---------|-------|-------|
| Screen horizontal padding | 20pt | `DS.Spacing.xl` |
| Screen top padding | 16pt | `DS.Spacing.lg` |
| Section spacing | 20pt | `DS.Spacing.xl` |
| Card internal padding | 16pt | `DS.Spacing.lg` |
| Element spacing (tight) | 8pt | `DS.Spacing.sm` |
| Element spacing (normal) | 12pt | `DS.Spacing.md` |

### Corner Radii

| Element | Value | Token |
|---------|-------|-------|
| Small badges/pills | 8pt | `DS.Radius.xs` |
| Chips, tags | 12pt | `DS.Radius.sm` |
| Buttons, inputs | 16pt | `DS.Radius.md` |
| Cards | 20pt | `DS.Radius.lg` |
| Sheets, large cards | 24pt | `DS.Radius.xl` |
| Capsules | 999pt | `DS.Radius.full` |

### Typography

| Element | Size | Weight | Token |
|---------|------|--------|-------|
| Screen title | 24pt | Bold | `DS.Font.title` |
| Card title | 18pt | Semibold | `DS.Font.headline` |
| Body text | 15pt | Medium | `DS.Font.body` |
| Button text | 16pt | Semibold | `DS.Font.callout` |
| Caption/meta | 13pt | Medium | `DS.Font.small` + 1 |
| Section header | 11pt | Bold | `DS.Font.caption` |
| Tiny labels | 10pt | Semibold | `DS.Font.micro` |

### Icon Buttons

| Context | Size | Token |
|---------|------|-------|
| Inline small | 32pt | `DS.IconButton.sm` |
| Header actions | 36pt | `DS.IconButton.md` |
| Primary actions | 44pt | `DS.IconButton.lg` |
| FAB | 56pt | `DS.IconButton.xl` |

### Glass Effects

| Element | Opacity | Token |
|---------|---------|-------|
| Subtle backgrounds | 0.03 | `DS.Glass.ultraThin` |
| Card backgrounds | 0.05 | `DS.Glass.thin` |
| Input backgrounds | 0.08 | `DS.Glass.regular` |
| Emphasized | 0.12 | `DS.Glass.thick` |
| Subtle borders | 0.06 | `DS.Glass.borderSubtle` |
| Normal borders | 0.10 | `DS.Glass.borderMedium` |
| Strong borders | 0.15 | `DS.Glass.borderStrong` |

---

## 🎯 Checklist

### Phase 1: Foundation ✅
- [x] Create `FFDesignSystem.swift`
- [x] Create `FFLiquidGlassCard.swift`
- [x] Create `FFIconButton.swift` (includes Primary/Secondary)
- [x] Create `FFTextField.swift`
- [x] Create `FFSectionHeader.swift`
- [x] Create `FFScreenHeader.swift`
- [x] Create `FFSheetModifier.swift`
- [x] Build and verify no errors

### Phase 2: Padding & Spacing ✅
- [x] Fix `FocusView.swift` horizontal padding (22 → 20)
- [x] Fix `AuthLandingView.swift` horizontal padding (24 → 20)
- [x] Fix `EmailAuthView.swift` horizontal padding (24 → 20)
- [x] Fix `FlowChatView.swift` padding variations
- [x] Verify all screens use `DS.Spacing.xl` for horizontal

### Phase 3: Corner Radii ✅
- [x] Audit all `cornerRadius` values
- [x] Replace with `DS.Radius.*` tokens
- [x] Ensure consistency within same component types

### Phase 4: Components ✅
- [x] Replace inline headers with `FFScreenHeader`
- [x] Replace inline section headers with `FFSectionHeader`
- [x] Replace inline icon buttons with `FFIconButton`
- [x] Migrate buttons to `FFPrimaryButton`/`FFSecondaryButton`
- [x] Migrate text inputs to `FFTextField`

### Phase 5: Interactions ✅
- [x] Standardize all sheet presentations
- [x] Verify haptic feedback consistency
- [x] Update all animations to spring
- [x] Test keyboard dismissal behavior
- [x] Verify swipe actions consistency

### Phase 6: Final Polish ✅
- [x] Code audit for remaining inconsistencies
- [x] Fixed FlowChatView cornerRadius values → DS.Radius tokens
- [x] Fixed FlowResponseCards cornerRadius values → DS.Radius tokens
- [x] Fixed FocusSoundPicker cornerRadius values → DS.Radius tokens
- [x] Fixed PaywallView cornerRadius values → DS.Radius tokens
- [x] Replaced hardcoded opacities with DS.Glass tokens
- [x] Build verification passed

---

## 📱 iOS 26 Liquid Glass Features

When iOS 26 is released, these features will auto-enable:

| Feature | Usage |
|---------|-------|
| `.glassBackgroundEffect()` | Cards, sheets, tab bar |
| `.glassProgressEffect()` | Progress rings, loading |
| Dynamic mesh gradients | Background enhancement |
| True frosted materials | All glass components |
| Depth-aware shadows | Card layering |
| Adaptive tinting | Theme-aware glass |

The `FFLiquidGlassCard` component is designed with `@available(iOS 26, *)` checks to automatically use native Liquid Glass when available.

---

## ✨ Premium Polish Features

> **These features transform a "good" app into a "premium" experience**

### 1. Micro-interactions

```swift
// File: FocusFlow/Core/UI/FFMicroInteractions.swift

import SwiftUI

// MARK: - Button Press Effect
struct FFPressEffect: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(DS.Animation.quick, value: configuration.isPressed)
    }
}

// MARK: - Glow on Tap
struct FFGlowEffect: ViewModifier {
    @State private var isGlowing = false
    let color: Color
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                    .stroke(color.opacity(isGlowing ? 0.6 : 0), lineWidth: 2)
                    .blur(radius: isGlowing ? 4 : 0)
            )
            .onTapGesture {
                withAnimation(DS.Animation.quick) {
                    isGlowing = true
                }
                withAnimation(DS.Animation.quick.delay(0.2)) {
                    isGlowing = false
                }
            }
    }
}

// MARK: - Bounce Animation
extension View {
    func ffBounce(on trigger: Bool) -> some View {
        self
            .scaleEffect(trigger ? 1.05 : 1.0)
            .animation(DS.Animation.bounce, value: trigger)
    }
    
    func ffPulse() -> some View {
        self.modifier(PulseModifier())
    }
}

struct PulseModifier: ViewModifier {
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.02 : 1.0)
            .opacity(isPulsing ? 0.95 : 1.0)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 2)
                    .repeatForever(autoreverses: true)
                ) {
                    isPulsing = true
                }
            }
    }
}
```

### 2. Skeleton Loading (Shimmer)

```swift
// File: FocusFlow/Core/UI/FFSkeletonLoader.swift

import SwiftUI

struct FFShimmer: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.2),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 400
                }
            }
    }
}

struct FFSkeletonCard: View {
    var height: CGFloat = 100
    
    var body: some View {
        RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
            .fill(Color.white.opacity(0.05))
            .frame(height: height)
            .modifier(FFShimmer())
    }
}

struct FFSkeletonRow: View {
    var body: some View {
        HStack(spacing: DS.Spacing.md) {
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 44, height: 44)
            
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 140, height: 14)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 90, height: 10)
            }
            
            Spacer()
        }
        .modifier(FFShimmer())
    }
}

extension View {
    func ffShimmer() -> some View {
        self.modifier(FFShimmer())
    }
}
```

### 3. Hero Transitions

```swift
// File: FocusFlow/Core/UI/FFTransitions.swift

import SwiftUI

// MARK: - Matched Geometry Namespace
struct FFNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID? = nil
}

extension EnvironmentValues {
    var ffNamespace: Namespace.ID? {
        get { self[FFNamespaceKey.self] }
        set { self[FFNamespaceKey.self] = newValue }
    }
}

// MARK: - Custom Transitions
extension AnyTransition {
    static var ffSlideUp: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        )
    }
    
    static var ffScale: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.9).combined(with: .opacity),
            removal: .scale(scale: 0.95).combined(with: .opacity)
        )
    }
    
    static var ffBlur: AnyTransition {
        .modifier(
            active: BlurModifier(blur: 10, opacity: 0),
            identity: BlurModifier(blur: 0, opacity: 1)
        )
    }
}

struct BlurModifier: ViewModifier {
    let blur: CGFloat
    let opacity: Double
    
    func body(content: Content) -> some View {
        content
            .blur(radius: blur)
            .opacity(opacity)
    }
}

// MARK: - Page Transition
struct FFPageTransition: ViewModifier {
    let isActive: Bool
    
    func body(content: Content) -> some View {
        content
            .offset(x: isActive ? 0 : 50)
            .opacity(isActive ? 1 : 0)
            .animation(DS.Animation.smooth, value: isActive)
    }
}
```

### 4. Scroll Effects

```swift
// File: FocusFlow/Core/UI/FFScrollEffects.swift

import SwiftUI

// MARK: - Parallax Header
struct FFParallaxHeader<Content: View>: View {
    let height: CGFloat
    let content: () -> Content
    
    var body: some View {
        GeometryReader { geo in
            let minY = geo.frame(in: .global).minY
            let isScrollingUp = minY > 0
            
            content()
                .frame(width: geo.size.width, height: height + (isScrollingUp ? minY : 0))
                .offset(y: isScrollingUp ? -minY : 0)
                .blur(radius: isScrollingUp ? minY / 50 : 0)
        }
        .frame(height: height)
    }
}

// MARK: - Blur on Scroll Header
struct FFBlurHeader: View {
    let title: String
    let scrollOffset: CGFloat
    
    private var blurAmount: CGFloat {
        min(max(0, scrollOffset / 50), 1)
    }
    
    var body: some View {
        ZStack {
            // Blur background
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(blurAmount)
            
            // Title
            Text(title)
                .font(.system(size: DS.Font.headline, weight: .semibold))
                .foregroundColor(.white)
                .opacity(blurAmount)
        }
        .frame(height: 44)
    }
}

// MARK: - Scroll Offset Reader
struct FFScrollOffsetReader: View {
    let coordinateSpace: String
    @Binding var offset: CGFloat
    
    var body: some View {
        GeometryReader { geo in
            Color.clear
                .preference(
                    key: ScrollOffsetKey.self,
                    value: -geo.frame(in: .named(coordinateSpace)).minY
                )
        }
        .frame(height: 0)
        .onPreferenceChange(ScrollOffsetKey.self) { offset = $0 }
    }
}

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
```

### 5. Celebration Effects

```swift
// File: FocusFlow/Core/UI/FFCelebrations.swift

import SwiftUI

// MARK: - Confetti Effect
struct FFConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    let colors: [Color]
    let count: Int
    
    init(colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange], count: Int = 50) {
        self.colors = colors
        self.count = count
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                        .rotationEffect(.degrees(particle.rotation))
                }
            }
            .onAppear {
                createParticles(in: geo.size)
                animateParticles(in: geo.size)
            }
        }
        .allowsHitTesting(false)
    }
    
    private func createParticles(in size: CGSize) {
        particles = (0..<count).map { _ in
            ConfettiParticle(
                color: colors.randomElement() ?? .white,
                position: CGPoint(x: size.width / 2, y: -20),
                size: CGFloat.random(in: 6...12),
                rotation: 0,
                opacity: 1
            )
        }
    }
    
    private func animateParticles(in size: CGSize) {
        for i in particles.indices {
            let delay = Double.random(in: 0...0.5)
            let duration = Double.random(in: 2...3)
            
            withAnimation(.easeOut(duration: duration).delay(delay)) {
                particles[i].position = CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: size.height + 50
                )
                particles[i].rotation = Double.random(in: 0...720)
                particles[i].opacity = 0
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let color: Color
    var position: CGPoint
    let size: CGFloat
    var rotation: Double
    var opacity: Double
}

// MARK: - Success Pulse Ring
struct FFSuccessPulse: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 1
    let color: Color
    
    var body: some View {
        Circle()
            .stroke(color, lineWidth: 3)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    scale = 2.5
                    opacity = 0
                }
            }
    }
}

// MARK: - Achievement Unlock
struct FFAchievementBadge: View {
    let icon: String
    let title: String
    let color: Color
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: DS.Spacing.md) {
            ZStack {
                // Glow rings
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(color.opacity(0.3 - Double(i) * 0.1), lineWidth: 2)
                        .scaleEffect(isAnimating ? 1.5 + CGFloat(i) * 0.3 : 1)
                        .opacity(isAnimating ? 0 : 1)
                }
                
                // Badge
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .shadow(color: color.opacity(0.5), radius: 20, y: 10)
                    .scaleEffect(isAnimating ? 1 : 0.5)
            }
            .frame(width: 150, height: 150)
            
            Text(title)
                .font(.system(size: DS.Font.headline, weight: .bold))
                .foregroundColor(.white)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
        }
        .onAppear {
            Haptics.notification(.success)
            withAnimation(DS.Animation.bounce) {
                isAnimating = true
            }
        }
    }
}
```

### 6. Empty & Error States

```swift
// File: FocusFlow/Core/UI/FFEmptyStates.swift

import SwiftUI

struct FFEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: DS.Spacing.xl) {
            // Animated icon
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.03))
                    .frame(width: 120, height: 120)
                
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 90, height: 90)
                
                Image(systemName: icon)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                    .offset(y: isAnimating ? -5 : 5)
            }
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 2)
                    .repeatForever(autoreverses: true)
                ) {
                    isAnimating = true
                }
            }
            
            VStack(spacing: DS.Spacing.sm) {
                Text(title)
                    .font(.system(size: DS.Font.headline, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(message)
                    .font(.system(size: DS.Font.body, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Spacing.xxl)
            }
            
            if let actionTitle, let action {
                FFSecondaryButton(title: actionTitle, icon: "plus", action: action)
                    .padding(.horizontal, DS.Spacing.xxxl)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct FFErrorState: View {
    let title: String
    let message: String
    var retryAction: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: DS.Spacing.xl) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48, weight: .medium))
                .foregroundColor(.orange.opacity(0.8))
            
            VStack(spacing: DS.Spacing.sm) {
                Text(title)
                    .font(.system(size: DS.Font.headline, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(message)
                    .font(.system(size: DS.Font.body, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Spacing.xxl)
            }
            
            if let retryAction {
                FFSecondaryButton(title: "Try Again", icon: "arrow.clockwise", action: retryAction)
                    .padding(.horizontal, DS.Spacing.xxxl)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

### 7. Custom Tab Bar

```swift
// File: FocusFlow/Core/UI/FFTabBar.swift

import SwiftUI

struct FFTabBar: View {
    @Binding var selectedTab: AppTab
    let theme: AppTheme
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach([AppTab.focus, .tasks, .flow, .progress, .profile], id: \.self) { tab in
                FFTabItem(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    theme: theme
                ) {
                    withAnimation(DS.Animation.quick) {
                        selectedTab = tab
                    }
                    Haptics.impact(.light)
                }
            }
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
        )
        .padding(.horizontal, DS.Spacing.xl)
        .padding(.bottom, DS.Spacing.sm)
    }
}

struct FFTabItem: View {
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
                    // Selected background
                    Circle()
                        .fill(
                            isSelected
                                ? LinearGradient(
                                    colors: [theme.accentPrimary, theme.accentSecondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom)
                        )
                        .frame(width: 44, height: 44)
                        .scaleEffect(isSelected ? 1 : 0.8)
                    
                    Image(systemName: isSelected ? "\(icon).fill" : icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isSelected ? .white : .white.opacity(0.5))
                        .scaleEffect(isSelected ? 1.1 : 1)
                }
                
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
```

### 8. Pull to Refresh

```swift
// File: FocusFlow/Core/UI/FFRefresh.swift

import SwiftUI

struct FFRefreshIndicator: View {
    let isRefreshing: Bool
    let progress: CGFloat // 0 to 1 during pull
    let theme: AppTheme
    
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 3)
            
            // Progress
            Circle()
                .trim(from: 0, to: isRefreshing ? 0.8 : progress)
                .stroke(
                    LinearGradient(
                        colors: [theme.accentPrimary, theme.accentSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(isRefreshing ? rotation : -90))
        }
        .frame(width: 28, height: 28)
        .onAppear {
            if isRefreshing {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
        }
        .onChange(of: isRefreshing) { _, newValue in
            if newValue {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            } else {
                rotation = 0
            }
        }
    }
}
```

---

## 🎯 Updated Implementation Phases

### Phase 1: Foundation (Days 1-2)
- [ ] Create design system files
- [ ] Create base components

### Phase 2: Consistency (Days 3-4)
- [ ] Fix all padding/spacing
- [ ] Standardize corner radii
- [ ] Unify typography

### Phase 3: Micro-interactions (Days 5-6)
- [ ] Add button press effects
- [ ] Add shimmer loading states
- [ ] Implement transitions

### Phase 4: Premium Polish (Days 7-8)
- [ ] Add scroll effects
- [ ] Implement celebrations
- [ ] Create empty states
- [ ] Add custom tab bar

### Phase 5: Testing & Refinement (Days 9-10)
- [ ] Test all animations at 60fps
- [ ] Verify haptics feel right
- [ ] Polish any rough edges
- [ ] Test on all device sizes

---

## 🚀 Ready to Implement

This enhanced plan provides:
1. **Complete design tokens** for consistency
2. **Reusable components** for rapid development
3. **Clear migration path** for existing screens
4. **Future-proofing** for iOS 26 Liquid Glass
5. **✨ Micro-interactions** for premium feel
6. **✨ Loading states** to eliminate blank screens
7. **✨ Smooth transitions** between screens
8. **✨ Celebration effects** to delight users
9. **✨ Custom tab bar** for unique identity
10. **✨ Scroll polish** for buttery smoothness

**Approve this plan to begin implementation.**
