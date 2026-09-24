import SwiftUI
import UIKit

/// Plum/raspberry variant of the app background used by the Today tab:
/// four soft radial glows over a near-black base, a faint diagonal sheen,
/// and a film-grain overlay.
struct PlumBackground: View {
    private static let designSize = CGSize(width: 362, height: 816)

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    stops: [
                        .init(color: Color(hex: 0x12040C), location: 0),
                        .init(color: Color(hex: 0x080306), location: 0.6),
                        .init(color: Color(hex: 0x030102), location: 1),
                    ],
                    startPoint: UnitPoint(x: 0.33, y: 0),
                    endPoint: UnitPoint(x: 0.67, y: 1)
                )

                // Bottom-most first: the reference lists the pink top-right glow as the top layer.
                glow(0x931043, x: 0.92, y: 0.88, rx: 700, ry: 900, in: geo.size)
                glow(0x4F1466, x: 0.58, y: 0.68, rx: 850, ry: 1050, in: geo.size)
                glow(0x8A0F43, x: 0.10, y: 0.32, rx: 750, ry: 950, in: geo.size)
                glow(0xB8567F, x: 0.78, y: 0.08, rx: 650, ry: 850, in: geo.size)

                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.32),
                        .init(color: .white.opacity(0.07), location: 0.47),
                        .init(color: .white.opacity(0.02), location: 0.55),
                        .init(color: .clear, location: 0.68),
                    ],
                    startPoint: UnitPoint(x: 0, y: 0.3),
                    endPoint: UnitPoint(x: 1, y: 0.7)
                )

                Image(uiImage: FilmGrain.image)
                    .resizable(resizingMode: .tile)
                    .blendMode(.overlay)
                    .opacity(0.2)
                    .allowsHitTesting(false)
            }
            .compositingGroup()
        }
    }

    /// An elliptical glow that fades to transparent at 45% of its radii, matching
    /// the reference's `radial-gradient(ellipse rx ry at x y, color 0%, transparent 45%)`.
    private func glow(_ hex: UInt32, x: CGFloat, y: CGFloat, rx: CGFloat, ry: CGFloat, in size: CGSize) -> some View {
        let color = Color(hex: hex)
        let scaleX = rx * 0.45 * size.width / Self.designSize.width / 100
        let scaleY = ry * 0.45 * size.height / Self.designSize.height / 100
        return Rectangle()
            .fill(RadialGradient(colors: [color, color.opacity(0)], center: .center, startRadius: 0, endRadius: 100))
            .frame(width: 200, height: 200)
            .scaleEffect(x: scaleX, y: scaleY)
            .position(x: size.width * x, y: size.height * y)
    }
}

private enum FilmGrain {
    static let image: UIImage = {
        let side = 180
        let bytes = (0..<side * side).map { _ in UInt8.random(in: 0...255) }
        guard
            let provider = CGDataProvider(data: Data(bytes) as CFData),
            let cgImage = CGImage(
                width: side, height: side,
                bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: side,
                space: CGColorSpaceCreateDeviceGray(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
                provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent
            )
        else { return UIImage() }
        return UIImage(cgImage: cgImage, scale: 3, orientation: .up)
    }()
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
