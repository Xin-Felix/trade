import SwiftUI

/// 正方形图片裁切视图
struct ImageCropView: View {
    let image: UIImage
    let onCropped: (UIImage) -> Void
    let onCancel: () -> Void

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            let cropSize = min(geo.size.width - 40, geo.size.height - 200)

            ZStack {
                Color.black.ignoresSafeArea()

                // 可缩放/移动的图片
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: cropSize * scale, height: cropSize * scale)
                    .offset(offset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
                    .gesture(
                        MagnifyGesture()
                            .onChanged { value in
                                let newScale = lastScale * value.magnification
                                scale = min(max(newScale, 1.0), 4.0)
                            }
                            .onEnded { _ in
                                lastScale = scale
                            }
                    )

                // 裁切遮罩
                CropOverlay(cropSize: cropSize, totalSize: geo.size)

                // 底部按钮 + 提示
                VStack {
                    Spacer()

                    Text("移动和缩放照片")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.bottom, 20)

                    HStack {
                        Button("取消") {
                            onCancel()
                        }
                        .foregroundStyle(.white)
                        .padding()

                        Spacer()

                        Button("完成") {
                            let cropped = performCrop(cropSize: cropSize, viewSize: geo.size)
                            onCropped(cropped)
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding()
                    }
                    .padding(.bottom, 16)
                    .background(
                        Color.black.opacity(0.3)
                            .ignoresSafeArea(edges: .bottom)
                    )
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
    }

    private func performCrop(cropSize: CGFloat, viewSize: CGSize) -> UIImage {
        let imageSize = image.size
        let imageAspect = imageSize.width / imageSize.height

        // 计算图片在视图中的实际显示尺寸（scaledToFill 到 cropSize * scale 的正方形）
        let displaySize: CGSize
        if imageAspect > 1 {
            // 横图
            displaySize = CGSize(width: cropSize * scale * imageAspect, height: cropSize * scale)
        } else {
            // 竖图或正方形
            displaySize = CGSize(width: cropSize * scale, height: cropSize * scale / imageAspect)
        }

        // 裁切框在视图中心，图片的中心也在视图中心+offset
        // 裁切框相对于图片中心的偏移
        let cropOffsetX = -offset.width
        let cropOffsetY = -offset.height

        // 转换到原图坐标（points -> pixels）
        let scaleX = imageSize.width / displaySize.width
        let scaleY = imageSize.height / displaySize.height
        let pixelScale = image.scale

        let cropRectInImage = CGRect(
            x: (displaySize.width / 2 - cropSize / 2 + cropOffsetX) * scaleX * pixelScale,
            y: (displaySize.height / 2 - cropSize / 2 + cropOffsetY) * scaleY * pixelScale,
            width: cropSize * scaleX * pixelScale,
            height: cropSize * scaleY * pixelScale
        )

        // 确保不超出边界（cgImage 使用像素坐标）
        let pixelSize = CGSize(width: imageSize.width * pixelScale, height: imageSize.height * pixelScale)
        let clampedRect = CGRect(
            x: max(0, min(cropRectInImage.origin.x, pixelSize.width - cropRectInImage.width)),
            y: max(0, min(cropRectInImage.origin.y, pixelSize.height - cropRectInImage.height)),
            width: min(cropRectInImage.width, pixelSize.width),
            height: min(cropRectInImage.height, pixelSize.height)
        )

        // 裁切
        guard let cgImage = image.cgImage?.cropping(to: clampedRect) else {
            return image
        }

        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}

/// 裁切遮罩层
struct CropOverlay: View {
    let cropSize: CGFloat
    let totalSize: CGSize

    var body: some View {
        let cropRect = CGRect(
            x: (totalSize.width - cropSize) / 2,
            y: (totalSize.height - cropSize) / 2,
            width: cropSize,
            height: cropSize
        )

        ZStack {
            // 使用 even-odd 填充规则：大矩形减去中间正方形，形成遮罩
            Path { path in
                path.addRect(CGRect(origin: .zero, size: totalSize))
                path.addRect(cropRect)
            }
            .fill(.black.opacity(0.6), style: FillStyle(eoFill: true))
            .allowsHitTesting(false)

            // 正方形边框
            RoundedRectangle(cornerRadius: 0)
                .stroke(.white.opacity(0.8), lineWidth: 1)
                .frame(width: cropSize, height: cropSize)
                .allowsHitTesting(false)
        }
    }
}

#Preview {
    ImageCropView(
        image: UIImage(systemName: "photo")!,
        onCropped: { _ in },
        onCancel: {}
    )
}
