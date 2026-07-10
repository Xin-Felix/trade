import AVFoundation
import Photos
import SwiftUI
import UIKit

/// 将一系列 UIImage 帧合成为视频并保存到相册
enum VideoRecorder {

    enum RecordError: Error {
        case noFrames
        case writerFailed(String)
        case photoLibraryDenied
    }

    /// 从一组预渲染图片生成视频文件
    @MainActor
    static func createVideo(
        frames: [UIImage],
        fps: Int = 60,
        progress: @escaping (Double) -> Void
    ) async throws -> URL {
        guard let first = frames.first, !frames.isEmpty else {
            throw RecordError.noFrames
        }

        // 使用实际像素尺寸（不是逻辑尺寸）
        guard let cgFirst = first.cgImage else { throw RecordError.noFrames }
        let pixelWidth = cgFirst.width
        let pixelHeight = cgFirst.height

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("flow_\(Int(Date().timeIntervalSince1970)).mp4")
        try? FileManager.default.removeItem(at: outputURL)

        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)

        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.hevc,  // HEVC 更高效更清晰
            AVVideoWidthKey: pixelWidth,
            AVVideoHeightKey: pixelHeight,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 20_000_000,       // 20 Mbps
                AVVideoExpectedSourceFrameRateKey: fps,
                AVVideoMaxKeyFrameIntervalKey: fps * 2,     // 关键帧间隔 2 秒
            ] as [String: Any],
        ]
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = false

        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey as String: pixelWidth,
                kCVPixelBufferHeightKey as String: pixelHeight,
            ]
        )

        writer.add(input)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)

        for (i, image) in frames.enumerated() {
            while !input.isReadyForMoreMediaData {
                try await Task.sleep(nanoseconds: 5_000_000)
            }

            guard let buffer = pixelBuffer(from: image) else { continue }
            let time = CMTime(value: CMTimeValue(i), timescale: CMTimeScale(fps))
            adaptor.append(buffer, withPresentationTime: time)

            if i % 10 == 0 {
                progress(Double(i + 1) / Double(frames.count))
            }
        }

        input.markAsFinished()
        await writer.finishWriting()

        if writer.status == .failed {
            throw RecordError.writerFailed(writer.error?.localizedDescription ?? "未知错误")
        }

        return outputURL
    }

    /// 请求相册权限并保存
    static func saveToPhotos(url: URL) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw RecordError.photoLibraryDenied
        }

        try await PHPhotoLibrary.shared().performChanges {
            PHAssetCreationRequest.forAsset().addResource(with: .video, fileURL: url, options: nil)
        }
    }

    /// 渲染 SwiftUI 视图为 UIImage（@3x 像素密度）
    @MainActor
    static func renderFrame<V: View>(_ view: V, size: CGSize) -> UIImage? {
        let renderer = ImageRenderer(content: view.frame(width: size.width, height: size.height))
        renderer.scale = UIScreen.main.scale // 跟设备一致（iPhone 一般 @3x）
        return renderer.uiImage
    }

    // MARK: - 内部

    /// 从 UIImage 创建 CVPixelBuffer，使用 cgImage 的实际像素尺寸
    private static func pixelBuffer(from image: UIImage) -> CVPixelBuffer? {
        guard let cgImage = image.cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height

        var buffer: CVPixelBuffer?
        let attrs: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
        ]
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault, width, height,
            kCVPixelFormatType_32BGRA, attrs as CFDictionary, &buffer
        )
        guard status == kCVReturnSuccess, let pixelBuffer = buffer else { return nil }

        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

        guard let data = CVPixelBufferGetBaseAddress(pixelBuffer) else { return nil }
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: data,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else { return nil }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return pixelBuffer
    }
}
