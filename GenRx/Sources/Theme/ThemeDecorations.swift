import SwiftUI

// MARK: - Synthwave grid lines

struct SynthwaveGridBackground: View {
    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let spacing: CGFloat = 60
                var y: CGFloat = spacing
                while y < size.height {
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    context.stroke(path, with: .color(Color(hex: "#BF5FFF").opacity(0.08)), lineWidth: 1)
                    y += spacing
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - VHS scanlines

struct VHSScanlines: View {
    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                var y: CGFloat = 0
                while y < size.height {
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    context.stroke(path, with: .color(Color.black.opacity(0.15)), lineWidth: 1)
                    y += 3
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - Memphis geometric shapes

private struct ShapeDef {
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let rotation: Double
    let kind: Int  // 0=dot, 1=triangle, 2=zigzag
    let colorIndex: Int
}

// Fixed positions — never use random() at render time
private let memphisShapes: [ShapeDef] = [
    ShapeDef(x: 0.05, y: 0.08, size: 20, rotation: 15, kind: 1, colorIndex: 0),
    ShapeDef(x: 0.88, y: 0.05, size: 14, rotation: 0, kind: 0, colorIndex: 1),
    ShapeDef(x: 0.92, y: 0.22, size: 30, rotation: -20, kind: 2, colorIndex: 2),
    ShapeDef(x: 0.03, y: 0.35, size: 18, rotation: 45, kind: 0, colorIndex: 0),
    ShapeDef(x: 0.95, y: 0.45, size: 22, rotation: 10, kind: 1, colorIndex: 1),
    ShapeDef(x: 0.08, y: 0.60, size: 16, rotation: -30, kind: 2, colorIndex: 2),
    ShapeDef(x: 0.85, y: 0.68, size: 20, rotation: 60, kind: 0, colorIndex: 0),
    ShapeDef(x: 0.12, y: 0.80, size: 24, rotation: 0, kind: 1, colorIndex: 1),
    ShapeDef(x: 0.90, y: 0.88, size: 18, rotation: 25, kind: 2, colorIndex: 2),
]

private let memphisColors: [Color] = [
    Color(hex: "#E63946").opacity(0.12),
    Color(hex: "#2196F3").opacity(0.10),
    Color(hex: "#FF9800").opacity(0.12),
]

struct MemphisShapes: View {
    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                for shape in memphisShapes {
                    let x = shape.x * size.width
                    let y = shape.y * size.height
                    let s = shape.size
                    let color = memphisColors[shape.colorIndex % memphisColors.count]

                    context.translateBy(x: x, y: y)
                    context.rotate(by: .degrees(shape.rotation))

                    switch shape.kind {
                    case 0:
                        // Dot
                        let rect = CGRect(x: -s / 2, y: -s / 2, width: s, height: s)
                        context.fill(Path(ellipseIn: rect), with: .color(color))
                    case 1:
                        // Triangle
                        var path = Path()
                        path.move(to: CGPoint(x: 0, y: -s / 2))
                        path.addLine(to: CGPoint(x: s / 2, y: s / 2))
                        path.addLine(to: CGPoint(x: -s / 2, y: s / 2))
                        path.closeSubpath()
                        context.fill(path, with: .color(color))
                    default:
                        // Zigzag (3 teeth)
                        var path = Path()
                        let teeth: CGFloat = 3
                        let toothW = s / teeth
                        path.move(to: CGPoint(x: -s / 2, y: 0))
                        for i in 0..<Int(teeth) {
                            let baseX = -s / 2 + CGFloat(i) * toothW
                            path.addLine(to: CGPoint(x: baseX + toothW / 2, y: -s / 3))
                            path.addLine(to: CGPoint(x: baseX + toothW, y: 0))
                        }
                        context.stroke(path, with: .color(color), lineWidth: 2)
                    }

                    // Reset transform for next shape
                    context.rotate(by: .degrees(-shape.rotation))
                    context.translateBy(x: -x, y: -y)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - VHS glitch text modifier

struct GlitchText: ViewModifier {
    @Environment(\.appTheme) private var theme
    @State private var offset: CGFloat = 0

    private let timer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()

    func body(content: Content) -> some View {
        if theme == .vhs {
            content
                .offset(x: offset)
                .onReceive(timer) { _ in
                    withAnimation(.easeInOut(duration: 0.08).repeatCount(2, autoreverses: true)) {
                        offset = 3
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                        offset = 0
                    }
                }
        } else {
            content
        }
    }
}

extension View {
    func glitchText() -> some View {
        modifier(GlitchText())
    }
}
