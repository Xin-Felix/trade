import SwiftUI

/// 用 UIKit UIScrollView 实现的指数跑马灯，支持无缝自动横向滚动
struct IndexMarqueeView: UIViewRepresentable {
    let indices: [IndexItem]
    let speed: CGFloat = 35 // 每秒滚动的点数

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.isUserInteractionEnabled = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.backgroundColor = .clear
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        let container = UIStackView()
        container.axis = .horizontal
        container.spacing = 0
        container.alignment = .center
        container.distribution = .fill
        container.translatesAutoresizingMaskIntoConstraints = false

        // 复制两份，实现无缝循环；两份保持完全一致的 item + 分隔符序列
        for _ in 0..<2 {
            for index in indices {
                let itemLabel = makeItemLabel(index: index)
                container.addArrangedSubview(itemLabel)

                let separator = makeSeparator()
                container.addArrangedSubview(separator)
            }
        }

        scrollView.addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: scrollView.topAnchor),
            container.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            container.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            container.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])

        // 让 StackView 根据内容自然高度在滚动视图内垂直居中，避免字体视觉中心偏移
        for subview in container.arrangedSubviews {
            subview.setContentHuggingPriority(.required, for: .vertical)
            subview.setContentCompressionResistancePriority(.required, for: .vertical)
        }

        context.coordinator.scrollView = scrollView
        context.coordinator.container = container
        context.coordinator.observeAppLifecycle()

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        // 数据变化时重置并重新启动动画
        context.coordinator.stopAnimation()
        context.coordinator.resetContent()
        context.coordinator.startAnimation(indices: indices)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(speed: speed)
    }

    // MARK: - Coordinator

    class Coordinator {
        weak var scrollView: UIScrollView?
        weak var container: UIStackView?

        let speed: CGFloat
        var displayLink: CADisplayLink?
        var offset: CGFloat = 0
        var singleLoopWidth: CGFloat = 0
        var lastTimestamp: CFTimeInterval?
        private var indices: [IndexItem] = []

        init(speed: CGFloat) {
            self.speed = speed
        }

        deinit {
            stopAnimation()
            NotificationCenter.default.removeObserver(self)
        }

        func observeAppLifecycle() {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(appDidEnterBackground),
                name: UIApplication.didEnterBackgroundNotification,
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(appWillEnterForeground),
                name: UIApplication.willEnterForegroundNotification,
                object: nil
            )
        }

        @objc private func appDidEnterBackground() {
            stopAnimation()
        }

        @objc private func appWillEnterForeground() {
            startAnimation(indices: indices)
        }

        func resetContent() {
            scrollView?.contentOffset = .zero
            offset = 0
            lastTimestamp = nil
        }

        func startAnimation(indices: [IndexItem]) {
            self.indices = indices
            guard !indices.isEmpty else { return }
            DispatchQueue.main.async { [weak self] in
                self?.scrollView?.layoutIfNeeded()
                guard let container = self?.container else { return }
                let totalWidth = container.frame.width
                self?.singleLoopWidth = totalWidth / 2
                guard (self?.singleLoopWidth ?? 0) > 0 else { return }
                self?.startDisplayLink()
            }
        }

        func stopAnimation() {
            displayLink?.invalidate()
            displayLink = nil
            lastTimestamp = nil
        }

        private func startDisplayLink() {
            displayLink?.invalidate()
            let link = CADisplayLink(target: self, selector: #selector(tick))
            link.add(to: .main, forMode: .common)
            displayLink = link
        }

        @objc private func tick() {
            guard let displayLink = displayLink, singleLoopWidth > 0 else { return }

            let now = displayLink.targetTimestamp
            let dt: CFTimeInterval
            if let last = lastTimestamp {
                dt = now - last
            } else {
                dt = displayLink.duration
            }
            lastTimestamp = now

            guard dt > 0, dt < 1 else { return }

            offset += speed * CGFloat(dt)
            if offset >= singleLoopWidth {
                offset = 0
            }
            scrollView?.contentOffset = CGPoint(x: offset, y: 0)
        }
    }

    // MARK: - Helpers

    private func makeItemLabel(index: IndexItem) -> UILabel {
        let label = UILabel()
        label.attributedText = attributedString(for: index)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .horizontal)
        return label
    }

    private func makeSeparator() -> UILabel {
        let label = UILabel()
        label.text = "  |  "
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    private func attributedString(for index: IndexItem) -> NSAttributedString {
        let changeAmount = index.value * index.change / 100.0
        let isUp = index.change >= 0
        let arrow = isUp ? "▲" : "▼"
        let changeColor: UIColor = isUp ? YPColor.uiUp : YPColor.uiDown

        let nameAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.label
        ]
        let valueAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: UIColor.label
        ]
        let changeAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: changeColor
        ]

        let result = NSMutableAttributedString()
        result.append(NSAttributedString(string: index.name + " ", attributes: nameAttrs))
        result.append(NSAttributedString(string: String(format: "%.2f", index.value), attributes: valueAttrs))
        result.append(NSAttributedString(string: " \(arrow) ", attributes: changeAttrs))
        result.append(NSAttributedString(string: String(format: "%+.2f", abs(changeAmount)), attributes: changeAttrs))
        result.append(NSAttributedString(string: String(format: " %+.2f%%", index.change), attributes: changeAttrs))
        return result
    }
}
