//
//  DesignSystem.swift
//  Subly
//
//  Design System centralizzato per garantire coerenza visiva in tutta l'app
//

import SwiftUI

// MARK: - Design Tokens

/// Token di spaziatura standardizzati
enum Spacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

/// Token per corner radius standardizzati
enum CornerRadius {
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    /// Per pill/capsule
    static let full: CGFloat = 999
}

/// Dimensioni standardizzate per icone in cerchi
enum IconContainerSize {
    static let sm: CGFloat = 36
    static let md: CGFloat = 44
    static let lg: CGFloat = 52
    static let xl: CGFloat = 80
}

/// Opacita standardizzate per sfondi icone
enum IconBackgroundOpacity {
    static let subtle: Double = 0.10
    static let medium: Double = 0.15
    static let strong: Double = 0.20
}

/// Altezze standard per pulsanti
enum ButtonHeight {
    static let sm: CGFloat = 44
    static let md: CGFloat = 52
    static let lg: CGFloat = 56
}

/// Shadow presets
enum ShadowStyle {
    case none
    case subtle
    case medium
    case elevated

    var color: Color {
        switch self {
        case .none: return .clear
        case .subtle, .medium, .elevated: return .black
        }
    }

    var opacity: Double {
        switch self {
        case .none: return 0
        case .subtle: return 0.04
        case .medium: return 0.08
        case .elevated: return 0.12
        }
    }

    var radius: CGFloat {
        switch self {
        case .none: return 0
        case .subtle: return 4
        case .medium: return 8
        case .elevated: return 16
        }
    }

    var y: CGFloat {
        switch self {
        case .none: return 0
        case .subtle: return 2
        case .medium: return 4
        case .elevated: return 8
        }
    }
}

// MARK: - Typography Styles

/// Stili tipografici predefiniti per garantire coerenza
struct Typography {
    // Titoli
    static let largeTitle = Font.largeTitle.weight(.bold)
    static let title1 = Font.title.weight(.bold)
    static let title2 = Font.title2.weight(.bold)
    static let title3 = Font.title3.weight(.semibold)

    // Body
    static let headline = Font.headline
    static let body = Font.body
    static let callout = Font.callout

    // Supporto
    static let subheadline = Font.subheadline
    static let footnote = Font.footnote
    static let caption = Font.caption
    static let caption2 = Font.caption2

    // Numeri (rounded)
    static func numericLarge(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func numericMedium(_ size: CGFloat = 22) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func numericSmall(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
}

// MARK: - Card Styles

/// Stili predefiniti per le card
struct CardStyle: ViewModifier {
    let cornerRadius: CGFloat
    let shadow: ShadowStyle
    let hasBorder: Bool
    let borderColor: Color

    init(
        cornerRadius: CGFloat = CornerRadius.lg,
        shadow: ShadowStyle = .subtle,
        hasBorder: Bool = false,
        borderColor: Color = .clear
    ) {
        self.cornerRadius = cornerRadius
        self.shadow = shadow
        self.hasBorder = hasBorder
        self.borderColor = borderColor
    }

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(
                        color: shadow.color.opacity(shadow.opacity),
                        radius: shadow.radius,
                        x: 0,
                        y: shadow.y
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(hasBorder ? borderColor : .clear, lineWidth: 1)
            )
    }
}

extension View {
    func cardStyle(
        cornerRadius: CGFloat = CornerRadius.lg,
        shadow: ShadowStyle = .subtle,
        hasBorder: Bool = false,
        borderColor: Color = .clear
    ) -> some View {
        self.modifier(CardStyle(
            cornerRadius: cornerRadius,
            shadow: shadow,
            hasBorder: hasBorder,
            borderColor: borderColor
        ))
    }
}

// MARK: - Icon Container

/// Componente riutilizzabile per icone in cerchi
struct IconContainer: View {
    let systemName: String
    let size: CGFloat
    let color: Color
    let backgroundOpacity: Double
    var iconScale: CGFloat = 0.45

    init(
        systemName: String,
        size: CGFloat = IconContainerSize.md,
        color: Color,
        backgroundOpacity: Double = IconBackgroundOpacity.medium
    ) {
        self.systemName = systemName
        self.size = size
        self.color = color
        self.backgroundOpacity = backgroundOpacity
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(backgroundOpacity))
                .frame(width: size, height: size)

            Image(systemName: systemName)
                .font(.system(size: size * iconScale, weight: .semibold))
                .foregroundColor(color)
        }
    }
}

/// Icona con gradiente per casi speciali (Pro, features)
struct GradientIconContainer: View {
    let systemName: String
    let size: CGFloat
    let gradientColors: [Color]
    var iconScale: CGFloat = 0.45
    var hasShadow: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .if(hasShadow) { view in
                    view.shadow(
                        color: gradientColors.first?.opacity(0.4) ?? .clear,
                        radius: 10,
                        x: 0,
                        y: 4
                    )
                }

            Image(systemName: systemName)
                .font(.system(size: size * iconScale, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Enhanced Button Styles

/// Pulsante primario migliorato con stati disabled e loading
struct EnhancedPrimaryButtonStyle: ButtonStyle {
    let isLoading: Bool
    let height: CGFloat

    init(isLoading: Bool = false, height: CGFloat = ButtonHeight.lg) {
        self.isLoading = isLoading
        self.height = height
    }

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                configuration.label
            }
        }
        .font(.headline)
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(
                    LinearGradient(
                        colors: [.appPrimary, .appSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .opacity(configuration.isPressed ? 0.9 : 1.0)
        .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Pulsante secondario outline
struct EnhancedSecondaryButtonStyle: ButtonStyle {
    let height: CGFloat

    init(height: CGFloat = ButtonHeight.lg) {
        self.height = height
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.appPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(Color.appPrimary, lineWidth: 2)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Badge Styles

/// Badge per etichette (NEW, PRO, Consigliato, etc)
struct BadgeView: View {
    enum Style {
        case filled(Color)
        case gradient([Color])
        case outline(Color)
    }

    let text: String
    let style: Style
    var fontSize: CGFloat = 10

    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: .bold))
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundView)
    }

    private var foregroundColor: Color {
        switch style {
        case .filled, .gradient:
            return .white
        case .outline(let color):
            return color
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .filled(let color):
            Capsule().fill(color)
        case .gradient(let colors):
            Capsule().fill(
                LinearGradient(
                    colors: colors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        case .outline(let color):
            Capsule()
                .stroke(color, lineWidth: 1)
                .background(Capsule().fill(color.opacity(0.1)))
        }
    }
}

// MARK: - Page Indicator

/// Indicatori di pagina migliorati
struct PageIndicator: View {
    let totalPages: Int
    let currentPage: Int
    var activeColor: Color = .appPrimary
    var inactiveColor: Color = Color(.systemGray4)
    var size: CGFloat = 8
    var spacing: CGFloat = 8

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? activeColor : inactiveColor)
                    .frame(width: index == currentPage ? size * 1.2 : size, height: size)
                    .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
    }
}

// MARK: - Divider with Label

struct LabeledDivider: View {
    let label: String
    var color: Color = .secondary

    var body: some View {
        HStack {
            line
            Text(label)
                .font(.caption)
                .foregroundColor(color)
            line
        }
    }

    private var line: some View {
        Rectangle()
            .fill(Color(.separator))
            .frame(height: 1)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: Spacing.lg) {
            // Icon containers
            HStack(spacing: Spacing.md) {
                IconContainer(systemName: "bell.fill", color: .orange)
                IconContainer(systemName: "star.fill", size: IconContainerSize.lg, color: .yellow)
                GradientIconContainer(
                    systemName: "crown.fill",
                    size: IconContainerSize.xl,
                    gradientColors: [.yellow, .orange],
                    hasShadow: true
                )
            }

            // Badges
            HStack(spacing: Spacing.sm) {
                BadgeView(text: "NEW", style: .gradient([.blue, .purple]))
                BadgeView(text: "PRO", style: .filled(.orange))
                BadgeView(text: "Consigliato", style: .outline(.green))
            }

            // Card
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Card Example")
                    .font(Typography.headline)
                Text("This is a card with the standard design system applied.")
                    .font(Typography.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(Spacing.md)
            .cardStyle(shadow: .medium)

            // Buttons
            Button("Primary Button") {}
                .buttonStyle(EnhancedPrimaryButtonStyle())

            Button("Secondary Button") {}
                .buttonStyle(EnhancedSecondaryButtonStyle())

            // Page indicators
            PageIndicator(totalPages: 5, currentPage: 2)

            // Divider
            LabeledDivider(label: "oppure")
        }
        .padding(Spacing.lg)
    }
    .background(Color(.systemGroupedBackground))
}
