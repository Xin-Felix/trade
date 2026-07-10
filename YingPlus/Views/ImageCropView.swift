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

                // 顶部/底部按钮
                VStack {
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

                    Spacer()

                    Text("移动和缩放照片")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.bottom, 40)
                }
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

        // 转换到原图坐标
        let scaleX = imageSize.width / displaySize.width
        let scaleY = imageSize.height / displaySize.height

        let cropRectInImage = CGRect(
            x: (displaySize.width / 2 - cropSize / 2 + cropOffsetX) * scaleX,
            y: (displaySize.height / 2 - cropSize / 2 + cropOffsetY) * scaleY,
            width: cropSize * scaleX,
            height: cropSize * scaleY
        )

        // 确保不超出边界
        let clampedRect = CGRect(
            x: max(0, min(cropRectInImage.origin.x, imageSize.width - cropRectInImage.width)),
            y: max(0, min(cropRectInImage.origin.y, imageSize.height - cropRectInImage.height)),
            width: min(cropRectInImage.width, imageSize.width),
            height: min(cropRectInImage.height, imageSize.height)
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
        Canvas { context, size in
            // 全屏半透明黑色
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(.black.opacity(0.6))
            )

            // 中间正方形挖空
            let cropRect = CGRect(
                x: (size.width - cropSize) / 2,
                y: (size.height - cropSize) / 2,
                width: cropSize,
                height: cropSize
            )
            context.blendMode = .clear
            context.fill(Path(roundedRect: cropRect, cornerRadius: 0), with: .color(.white))
        }
        .allowsHitTesting(false)

        // 正方形边框
        RoundedRectangle(cornerRadius: 0)
            .stroke(.white.opacity(0.8), lineWidth: 1)
            .frame(width: cropSize, height: cropSize)
            .allowsHitTesting(false)
    }
}

#Preview {
    ImageCropView(
        image: UIImage(systemName: "photo")!,
        onCropped: { _ in },
        onCancel: {}
    )
}
