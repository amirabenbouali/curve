import SwiftUI

/// Shared visual language for Curve: a dark sage-to-charcoal gradient with
/// frosted "glass" cards, mirroring the Today-dashboard design reference.
enum CurveTheme {
    static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.663, green: 0.741, blue: 0.698),
            Color(red: 0.576, green: 0.659, blue: 0.612),
            Color(red: 0.369, green: 0.431, blue: 0.404),
            Color(red: 0.169, green: 0.200, blue: 0.184),
            Color(red: 0.078, green: 0.129, blue: 0.114),
            Color(red: 0.047, green: 0.086, blue: 0.075),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Off-white "chrome" used for primary pill buttons and progress fills.
    static let chrome = LinearGradient(
        colors: [Color(white: 0.97), Color(red: 0.863, green: 0.886, blue: 0.855)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let chromeSolid = Color(red: 0.918, green: 0.933, blue: 0.914)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.68)
    static let textTertiary = Color.white.opacity(0.5)
    static let hairline = Color.white.opacity(0.14)
}

/// Full-bleed background gradient with a soft diagonal light sweep,
/// meant to sit behind the whole app.
struct CurveBackground: View {
    var body: some View {
        ZStack {
            CurveTheme.backgroundGradient
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.30),
                    .init(color: .white.opacity(0.16), location: 0.46),
                    .init(color: .white.opacity(0.04), location: 0.54),
                    .init(color: .clear, location: 0.68),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blendMode(.overlay)
        }
        .ignoresSafeArea()
    }
}

/// Frosted "glass" card: translucent material, hairline border, soft top
/// highlight — the monochrome glossy surface every card in the reference
/// design sits on.
struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 24
    var padding: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.white.opacity(0.10))
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .opacity(0.55)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.35), lineWidth: 1)
            )
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(.white.opacity(0.55))
                    .frame(height: 1)
                    .padding(.horizontal, cornerRadius * 0.7)
                    .padding(.top, 1)
            }
            .shadow(color: .black.opacity(0.25), radius: 18, x: 0, y: 10)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 24, padding: CGFloat = 18) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius, padding: padding))
    }

    /// Strips the system grouped background from List/Form so CurveBackground shows through,
    /// and tints row separators for the dark palette.
    func curveScrollBackground() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(Color.clear)
    }
}

extension Font {
    /// Editorial italic accent, standing in for the reference's "Newsreader" serif.
    static func curveEyebrow(_ size: CGFloat = 15) -> Font {
        .system(size: size, weight: .regular, design: .serif).italic()
    }
}

/// Off-white pill button matching the reference's "Start workout" CTA.
struct CurveChromeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(Color(red: 0.078, green: 0.129, blue: 0.114))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(CurveTheme.chrome)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(.white.opacity(0.9), lineWidth: 1)
                    .blendMode(.overlay)
            )
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 6)
            .opacity(configuration.isPressed ? 0.75 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

extension ButtonStyle where Self == CurveChromeButtonStyle {
    static var curveChrome: CurveChromeButtonStyle { CurveChromeButtonStyle() }
}
