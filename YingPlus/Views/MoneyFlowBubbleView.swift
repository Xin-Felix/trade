import SwiftUI

// MARK: - 数据模型

struct FlowBubble: Identifiable, Equatable {
    let id: String
    let name: String
    let netAmount: Double
    let pctChange: Double

    static func == (lhs: FlowBubble, rhs: FlowBubble) -> Bool {
        lhs.id == rhs.id && lhs.netAmount == rhs.netAmount
    }
}

// 气泡布局信息（供粒子层使用）
private struct BubbleFrame {
    let id: String
    let name: String
    var center: CGPoint
    let radius: CGFloat
    let netAmount: Double
    var isInflow: Bool { netAmount >= 0 }
}

// MARK: - 资金气泡流视图

struct MoneyFlowBubbleView: View {
    let bubbles: [FlowBubble]
    let title: String
    var referenceScale: Double = 1
    var moveDuration: Double = 0.5
    var simulatedTime: Double? = nil
    var disableFloat: Bool { simulatedTime != nil }  // 导出时禁用浮动

    private let maxRadius: CGFloat = 34
    private let minRadius: CGFloat = 14
    private let viewHeight: CGFloat = 400

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.caption).fontWeight(.medium).foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: 10) {
                    dot(YPColor.up, "流入")
                    dot(YPColor.down, "流出")
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 8)

            GeometryReader { geo in
                let size = geo.size
                let midY = size.height / 2
                let maxAbs = max(referenceScale, 1)

                // 预计算 + 碰撞分离（贴合但不重叠）
                let frames = resolvedFrames(in: size, maxAbs: maxAbs, midY: midY)

                ZStack {
                    // 背景渐变
                    LinearGradient(
                        colors: [YPColor.up.opacity(0.04), .clear, YPColor.down.opacity(0.04)],
                        startPoint: .top, endPoint: .bottom
                    )

                    // 中线
                    Path { p in
                        p.move(to: CGPoint(x: 24, y: midY))
                        p.addLine(to: CGPoint(x: size.width - 24, y: midY))
                    }
                    .stroke(Color.gray.opacity(0.1), style: StrokeStyle(lineWidth: 0.5, dash: [5, 4]))

                    // 资金流粒子
                    RotationParticles(frames: frames, simulatedTime: simulatedTime)

                    // 气泡
                    ForEach(frames, id: \.id) { frame in
                        BubbleNode(name: frame.name, netAmount: frame.netAmount, radius: frame.radius, disableFloat: disableFloat)
                            .position(frame.center)
                            .animation(.linear(duration: moveDuration), value: frame.center)
                            .animation(.linear(duration: moveDuration), value: frame.radius)
                    }
                }
            }
            .frame(height: viewHeight)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // 计算所有气泡位置并做碰撞分离
    private func resolvedFrames(in size: CGSize, maxAbs: Double, midY: CGFloat) -> [BubbleFrame] {
        var result: [BubbleFrame] = bubbles.map { bubble in
            BubbleFrame(
                id: bubble.id,
                name: bubble.name,
                center: CGPoint(
                    x: slotPosition(for: bubble, in: size),
                    y: yPosition(netAmount: bubble.netAmount, maxAbs: maxAbs, midY: midY)
                ),
                radius: radius(for: abs(bubble.netAmount), maxAbs: maxAbs),
                netAmount: bubble.netAmount
            )
        }

        // 碰撞分离：贴合但不重叠
        let padding: CGFloat = 2
        for _ in 0..<10 {
            for i in 0..<result.count {
                for j in (i + 1)..<result.count {
                    let a = result[i], b = result[j]
                    let dx = b.center.x - a.center.x
                    let dy = b.center.y - a.center.y
                    let dist = max(sqrt(dx * dx + dy * dy), 0.01)
                    let minDist = a.radius + b.radius + padding
                    if dist < minDist {
                        let overlap = (minDist - dist) / 2
                        let nx = dx / dist
                        let ny = dy / dist
                        result[i].center.x -= nx * overlap
                        result[i].center.y -= ny * overlap
                        result[j].center.x += nx * overlap
                        result[j].center.y += ny * overlap
                    }
                }
            }
        }

        // 边界约束
        for i in 0..<result.count {
            let r = result[i].radius
            result[i].center.x = min(max(result[i].center.x, r + 6), size.width - r - 6)
            result[i].center.y = min(max(result[i].center.y, r + 6), size.height - r - 6)
        }

        return result
    }

    // X: 固定列位，不左右跳
    private func slotPosition(for bubble: FlowBubble, in size: CGSize) -> CGFloat {
        let count = bubbles.count
        guard count > 0, let idx = bubbles.firstIndex(where: { $0.id == bubble.id }) else {
            return size.width / 2
        }
        let cols = min(count, 7)
        let col = idx % cols
        let padding: CGFloat = 44
        let usable = size.width - padding * 2
        let spacing = usable / CGFloat(cols)
        return padding + spacing * (CGFloat(col) + 0.5)
    }

    // Y: 净流入越大越往上，净流出越大越往下
    private func yPosition(netAmount: Double, maxAbs: Double, midY: CGFloat) -> CGFloat {
        let normalized = netAmount / max(maxAbs, 1)
        let margin: CGFloat = 40
        let range = midY - margin
        return midY - CGFloat(normalized) * range
    }

    private func radius(for amount: Double, maxAbs: Double) -> CGFloat {
        let ratio = amount / max(maxAbs, 1)
        return minRadius + (maxRadius - minRadius) * CGFloat(ratio)
    }

    private func dot(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 3) {
            Circle().fill(color.opacity(0.7)).frame(width: 7, height: 7)
            Text(label).font(.system(size: 9)).foregroundStyle(.secondary)
        }
    }
}

// MARK: - 资金轮动粒子流

/// 粒子从流出气泡（绿）流向流入气泡（红）。
/// 每条流绑定到源气泡 id，目标是最近的红气泡中心。
/// 当目标切换时，粒子路径平滑弯曲过渡而不是瞬移。
private struct RotationParticles: View {
    let frames: [BubbleFrame]
    var simulatedTime: Double? = nil

    private struct Stream {
        let id: String
        let from: CGPoint
        let to: CGPoint
        let intensity: Double
        let phaseSeed: Double
    }

    private var streams: [Stream] {
        let greens = frames.filter { !$0.isInflow && abs($0.netAmount) > 0.01 }
        let reds = frames.filter { $0.isInflow && abs($0.netAmount) > 0.01 }
        guard !greens.isEmpty, !reds.isEmpty else { return [] }

        var result: [Stream] = []
        var assignedReds: Set<String> = []

        // 第一轮：确保每个红气泡至少被一条绿指向
        for red in reds {
            // 找离这个红最近的绿
            let nearest = greens.min(by: {
                distance($0.center, red.center) < distance($1.center, red.center)
            })!
            result.append(Stream(
                id: "\(nearest.id)->\(red.id)",
                from: nearest.center,
                to: red.center,
                intensity: min(abs(nearest.netAmount) / 30000.0, 1.0),
                phaseSeed: stableSeed(nearest.id + red.id)
            ))
            assignedReds.insert(red.id)
        }

        // 第二轮：剩余的绿气泡也发射流（指向最近的红）
        for green in greens {
            // 如果这个绿已经在第一轮中作为源用过了，检查它是否还有余力
            let target = reds.min(by: {
                distance($0.center, green.center) < distance($1.center, green.center)
            })!
            let streamId = "\(green.id)->\(target.id)"
            // 避免完全重复
            if !result.contains(where: { $0.id == streamId }) {
                result.append(Stream(
                    id: streamId,
                    from: green.center,
                    to: target.center,
                    intensity: min(abs(green.netAmount) / 30000.0, 1.0),
                    phaseSeed: stableSeed(green.id)
                ))
            }
        }

        return result
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        sqrt((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y))
    }

    private func stableSeed(_ id: String) -> Double {
        Double(id.unicodeScalars.reduce(0) { $0 + Int($1.value) } % 100) / 100.0
    }

    var body: some View {
        let streamList = streams
        if let simTime = simulatedTime {
            Canvas { ctx, _ in
                drawParticles(ctx: ctx, streams: streamList, time: simTime)
            }
            .allowsHitTesting(false)
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 60)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                Canvas { ctx, _ in
                    drawParticles(ctx: ctx, streams: streamList, time: t)
                }
            }
            .allowsHitTesting(false)
        }
    }

    private func drawParticles(ctx: GraphicsContext, streams: [Stream], time t: Double) {
        for stream in streams {
            let particleCount = 6
            let speed = 0.16
            for p in 0..<particleCount {
                let evenOffset = Double(p) / Double(particleCount)
                let phase = (t * speed + evenOffset + stream.phaseSeed).truncatingRemainder(dividingBy: 1.0)

                let x = stream.from.x + (stream.to.x - stream.from.x) * CGFloat(phase)
                let y = stream.from.y + (stream.to.y - stream.from.y) * CGFloat(phase)

                let color = lerpColor(YPColor.down, YPColor.up, CGFloat(phase))

                let envelope = sin(phase * .pi)
                let alpha = Double(envelope) * (0.4 + stream.intensity * 0.3)
                let r = 2.0 + CGFloat(stream.intensity) * 1.5

                let dx = stream.to.x - stream.from.x
                let dy = stream.to.y - stream.from.y
                let len = max(sqrt(dx * dx + dy * dy), 0.01)
                let tailLen: CGFloat = 10
                let tailX = x - dx / len * tailLen
                let tailY = y - dy / len * tailLen

                var tail = Path()
                tail.move(to: CGPoint(x: tailX, y: tailY))
                tail.addLine(to: CGPoint(x: x, y: y))
                ctx.stroke(tail, with: .color(color.opacity(alpha * 0.5)),
                           style: StrokeStyle(lineWidth: r, lineCap: .round))

                let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
                ctx.fill(Circle().path(in: rect), with: .color(color.opacity(alpha)))
            }
        }
    }

    private func lerpColor(_ a: Color, _ b: Color, _ t: CGFloat) -> Color {
        let ua = UIColor(a), ub = UIColor(b)
        var ar: CGFloat = 0, ag: CGFloat = 0, ab: CGFloat = 0, aa: CGFloat = 0
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        ua.getRed(&ar, green: &ag, blue: &ab, alpha: &aa)
        ub.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        return Color(
            red: Double(ar + (br - ar) * t),
            green: Double(ag + (bg - ag) * t),
            blue: Double(ab + (bb - ab) * t)
        )
    }
}

// MARK: - 气泡节点

struct BubbleNode: View {
    let name: String
    let netAmount: Double
    let radius: CGFloat
    var disableFloat: Bool = false

    @State private var floatY: CGFloat = 0
    private var color: Color { netAmount >= 0 ? YPColor.up : YPColor.down }
    private var diameter: CGFloat { radius * 2 }

    var body: some View {
        ZStack {
            // 光晕
            Circle()
                .fill(RadialGradient(
                    colors: [color.opacity(0.18), color.opacity(0)],
                    center: .center, startRadius: radius * 0.5, endRadius: radius * 1.3
                ))
                .frame(width: diameter * 1.5, height: diameter * 1.5)

            // 主体
            Circle()
                .fill(RadialGradient(
                    colors: [color.opacity(0.9), color.opacity(0.5)],
                    center: UnitPoint(x: 0.35, y: 0.3),
                    startRadius: 0, endRadius: radius
                ))
                .frame(width: diameter, height: diameter)
                .overlay(
                    Circle()
                        .fill(RadialGradient(
                            colors: [.white.opacity(0.5), .clear],
                            center: UnitPoint(x: 0.3, y: 0.25),
                            startRadius: 0, endRadius: radius * 0.3
                        ))
                        .frame(width: radius * 0.65, height: radius * 0.65)
                        .offset(x: -radius * 0.18, y: -radius * 0.18)
                )
                .shadow(color: color.opacity(0.25), radius: 4, y: 2)

            // 文字
            VStack(spacing: 0) {
                Text(name)
                    .font(.system(size: max(radius * 0.38, 9), weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                if radius > 20 {
                    Text(shortAmt(netAmount))
                        .font(.system(size: max(radius * 0.28, 7)))
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            .frame(width: diameter * 0.85)
        }
        .offset(y: disableFloat ? 0 : floatY)
        .onAppear {
            guard !disableFloat else { return }
            withAnimation(.easeInOut(duration: Double.random(in: 2.5...3.5)).repeatForever(autoreverses: true)) {
                floatY = CGFloat.random(in: -3...3)
            }
        }
        .animation(.easeInOut(duration: 0.6), value: color)
    }

    private func shortAmt(_ v: Double) -> String {
        abs(v) >= 10000 ? String(format: "%.0f亿", v / 10000) : String(format: "%.0f万", v)
    }
}
