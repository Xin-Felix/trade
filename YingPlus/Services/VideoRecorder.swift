import AVFoundation
import Photos
import SwiftUI
import UIKit

/// 流式视频录制：逐帧渲染+写入，不缓存全部图片，避免内存溢出
enum VideoRecorder {

    enum RecordError: Error {
        case setupFailed
        case writerFailed(String)
        case photoLibraryDenied
    }

    /// 流式录制：逐帧回调渲染并立即写入
    @MainActor
    static func streamRecord(
        totalFrames: Int,
        fps: Int,
        renderSize: CGSize,
        progress: @escaping (Double) -> Void,
        renderFrame: (Int) -> some View
    ) async throws -> URL {
        guard totalFrames > 0 else { throw RecordError.setupFailed }

        let scale = UIScreen.main.scale
        let pixelW = Int(renderSize.width * scale)
        let pixelH = Int(renderSize.height * scale)

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("flow_\(Int(Date().timeIntervalSince1970)).mp4")
        try? FileManager.default.removeItem(at: outputURL)

        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)

        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.hevc,
            AVVideoWidthKey: pixelW,
            AVVideoHeightKey: pixelH,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 15_000_000,
                AVVideoExpectedSourceFrameRateKey: fps,
            ] as [String: Any],
        ]
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = false

        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey as String: pixelW,
                kCVPixelBufferHeightKey as String: pixelH,
            ]
        )

        writer.add(input)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)

        let imageRenderer = ImageRenderer(content: EmptyView())
        imageRenderer.scale = scale

        for i in 0..<totalFrames {
            while !input.isReadyForMoreMediaData {
                try await Task.sleep(nanoseconds: 5_000_000)
            }

            // 渲染当前帧
            let view = renderFrame(i)
            let renderer = ImageRenderer(content: view.frame(width: renderSize.width, height: renderSize.height))
            renderer.scale = scale
            guard let uiImage = renderer.uiImage,
                  let buffer = pixelBuffer(from: uiImage) else { continue }

            let time = CMTime(value: CMTimeValue(i), timescale: CMTimeScale(fps))
            adaptor.append(buffer, withPresentationTime: time)

            if i % 5 == 0 {
                progress(Double(i + 1) / Double(totalFrames))
            }

            // 让出主线程一瞬间，避免 watchdog kill
            if i % 30 == 0 {
                try await Task.sleep(nanoseconds: 1_000_000)
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

    // MARK: - 内部

    private static func pixelBuffer(from image: UIImage) -> CVPixelBuffer? {
        guard let cgImage = image.cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height

        var buffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault, width, height,
            kCVPixelFormatType_32BGRA,
            [kCVPixelBufferCGImageCompatibilityKey: true,
             kCVPixelBufferCGBitmapContextCompatibilityKey: true] as CFDictionary,
            &buffer
        )
        guard status == kCVReturnSuccess, let pb = buffer else { return nil }

        CVPixelBufferLockBaseAddress(pb, [])
        defer { CVPixelBufferUnlockBaseAddress(pb, []) }

        guard let data = CVPixelBufferGetBaseAddress(pb),
              let ctx = CGContext(
                data: data,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: CVPixelBufferGetBytesPerRow(pb),
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
              ) else { return nil }

        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return pb
    }
}
