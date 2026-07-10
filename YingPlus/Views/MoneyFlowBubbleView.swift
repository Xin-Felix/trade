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
    var simulatedTime: Double? = nil  // 非nil时用模拟时间渲染粒子（导出视频用）

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
                        BubbleNode(name: frame.name, netAmount: frame.netAmount, radius: frame.radius)
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
        let cols = min(count, 6)
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
            Text(label).font(.system(size: 9)).foregroundStyle(.quaternary)
        }
    }
}

// MARK: - 资金轮动粒子流

/// 粒子从流出气泡（绿）流向流入气泡（红），表现资金从被卖板块流向被买板块。
/// 每条流以「绿气泡 id」为稳定标识，即使目标红气泡切换，粒子也是平滑转向而非重置。
private struct RotationParticles: View {
    let frames: [BubbleFrame]
    var simulatedTime: Double? = nil

    private struct Stream: Identifiable {
        let id: String     // 源（绿）气泡 id，稳定
        let from: CGPoint  // 绿（流出）起点
        let to: CGPoint    // 红（流入）终点
        let intensity: Double
        let phaseSeed: Double // 由 id 派生的稳定相位偏移
    }

    private var streams: [Stream] {
        let reds = frames.filter { $0.isInflow }
        let greens = frames.filter { !$0.isInflow }
        guard !reds.isEmpty, !greens.isEmpty else { return [] }

        // 按 id 排序，保证配对稳定（不随资金大小重排）
        let redsSorted = reds.sorted { $0.id < $1.id }
        let greensSorted = greens.sorted { $0.id < $1.id }

        var result: [Stream] = []
        for (i, green) in greensSorted.enumerated() {
            let red = redsSorted[i % redsSorted.count]
            let intensity = min(abs(green.netAmount) / 30000.0, 1.0)
            result.append(Stream(
                id: green.id,
                from: green.center,
                to: red.center,
                intensity: intensity,
                phaseSeed: stableSeed(green.id)
            ))
        }
        return result
    }

    // 由 id 字符串派生 0~1 的稳定相位（同一会话内不变）
    private func stableSeed(_ id: String) -> Double {
        let sum = id.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return Double(sum % 100) / 100.0
    }

    var body: some View {
        let streamList = streams
        if let simTime = simulatedTime {
            // 导出模式：用模拟时间直接渲染（无 TimelineView）
            Canvas { ctx, _ in
                drawParticles(ctx: ctx, streams: streamList, time: simTime)
            }
            .allowsHitTesting(false)
        } else {
            // 实时模式：TimelineView 驱动
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
        .offset(y: floatY)
        .onAppear {
            withAnimation(.easeInOut(duration: Double.random(in: 2.5...3.5)).repeatForever(autoreverses: true)) {
                floatY = CGFloat.random(in: -3...3)
            }
        }
        // 颜色随资金正负渐变过渡
        .animation(.easeInOut(duration: 0.6), value: color)
    }

    private func shortAmt(_ v: Double) -> String {
        abs(v) >= 10000 ? String(format: "%.0f亿", v / 10000) : String(format: "%.0f万", v)
    }
}
