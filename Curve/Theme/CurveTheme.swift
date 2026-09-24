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

    /// Cream-to-sage fill used for in-card progress bars.
    static let progressFill = LinearGradient(
        colors: [Color(red: 0.894, green: 0.914, blue: 0.890), Color(red: 0.576, green: 0.659, blue: 0.612)],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Glossy specular fill for small icon chips (avatar, stat icons, list icons) —
    /// the recurring "chrome glass" highlight from the reference design.
    static let glossyIconFill = LinearGradient(
        colors: [.white.opacity(0.55), .white.opacity(0.08)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Cream-to-sage conic sweep for the streak ring, matching the reference's
    /// conic-gradient(#F2F0E9 0deg, #C9D3CC 130deg, #7C8E84 270deg).
    static let ringSweep = AngularGradient(
        gradient: Gradient(stops: [
            .init(color: Color(red: 0.949, green: 0.941, blue: 0.914), location: 0),
            .init(color: Color(red: 0.788, green: 0.827, blue: 0.800), location: 0.361),
            .init(color: Color(red: 0.486, green: 0.557, blue: 0.518), location: 0.75),
        ]),
        center: .center,
        startAngle: .degrees(-90),
        endAngle: .degrees(270)
    )

    static let chromeSolid = Color(red: 0.918, green: 0.933, blue: 0.914)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.68)
    static let textTertiary = Color.white.opacity(0.5)
    static let hairline = Color.white.opacity(0.14)
}

enum CurvePalette {
    case sage
    case plum
}

private struct CurvePaletteKey: EnvironmentKey {
    static let defaultValue: CurvePalette = .sage
}

extension EnvironmentValues {
    /// Selects the glass-card look; screens on the plum background set this so their cards match.
    var curvePalette: CurvePalette {
        get { self[CurvePaletteKey.self] }
        set { self[CurvePaletteKey.self] = newValue }
    }
}

/// Full-bleed background gradient with a soft diagonal light sweep,
/// meant to sit behind the whole app.
struct CurveBackground: View {
    var palette: CurvePalette = .sage

    var body: some View {
        Group {
            switch palette {
            case .sage: sage
            case .plum: PlumBackground()
            }
        }
        .ignoresSafeArea()
    }

    private var sage: some View {
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
    }
}

/// Frosted "glass" card: translucent material, hairline border, soft top
/// highlight — the monochrome glossy surface every card in the reference
/// design sits on.
struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 24
    var padding: CGFloat = 18
    @Environment(\.curvePalette) private var palette

    func body(content: Content) -> some View {
        switch palette {
        case .sage: sage(content)
        case .plum: plum(content)
        }
    }

    private func sage(_ content: Content) -> some View {
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

    /// Glossy diagonal white wash with no dark tint, so the plum background shows
    /// through as pink-violet instead of going grey.
    private func plum(_ content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.20), location: 0),
                            .init(color: .white.opacity(0.05), location: 0.55),
                            .init(color: .white.opacity(0.10), location: 1),
                        ],
                        startPoint: UnitPoint(x: 0.3, y: 0),
                        endPoint: UnitPoint(x: 0.7, y: 1)
                    ))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.22), lineWidth: 1)
            )
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [.clear, .white.opacity(0.35), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 1)
                .padding(.horizontal, 16)
            }
            .shadow(color: .black.opacity(0.45), radius: 16, x: 0, y: 12)
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
