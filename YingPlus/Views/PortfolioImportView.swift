import SwiftUI
import PhotosUI
import Vision

struct PortfolioImportView: View {
    let onImportComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var ocrText: String = ""
    @State private var isRecognizing = false
    @State private var isImporting = false
    @State private var importResult: ImportResult?
    @State private var errorMessage: String?

    private struct ImportResult {
        let imported: [[String: Any]]
        let total: Int
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    instructionSection
                    imagePickerSection
                    if let image = selectedImage {
                        imagePreview(image)
                    }
                    if isRecognizing {
                        recognizingIndicator
                    }
                    if !ocrText.isEmpty {
                        ocrResultSection
                    }
                    if let result = importResult {
                        resultSection(result)
                    }
                    if let error = errorMessage {
                        errorSection(error)
                    }
                }
                .padding()
            }
            .navigationTitle("导入持仓")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
            .onChange(of: selectedPhoto) { _, newValue in
                Task { await loadImage(from: newValue) }
            }
        }
    }

    // MARK: - Sections

    private var instructionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("使用说明", systemImage: "info.circle")
                .font(.subheadline)
                .fontWeight(.semibold)

            Text("从券商 App 截图你的持仓页面，上传后自动识别并导入。导入后将替换当前持仓数据。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var imagePickerSection: some View {
        PhotosPicker(selection: $selectedPhoto, matching: .images) {
            HStack {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.title2)
                Text(selectedImage == nil ? "选择持仓截图" : "重新选择")
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private func imagePreview(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(maxHeight: 300)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            )
    }

    private var recognizingIndicator: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.8)
            Text("正在识别文字...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private var ocrResultSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("识别结果")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(ocrText.count) 字")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(ocrText)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(Color(.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Button {
                Task { await importPortfolio() }
            } label: {
                HStack {
                    if isImporting {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    }
                    Text(isImporting ? "正在解析导入..." : "确认导入持仓")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isImporting ? Color.gray : Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(isImporting)
        }
    }

    private func resultSection(_ result: ImportResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("导入成功", systemImage: "checkmark.circle.fill")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.green)

            Text("成功导入 \(result.total) 只股票到持仓")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("完成") {
                onImportComplete()
                dismiss()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.accentColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .fontWeight(.semibold)
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func errorSection(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("出错了", systemImage: "exclamationmark.triangle.fill")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.red)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Logic

    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }

        selectedImage = image
        ocrText = ""
        importResult = nil
        errorMessage = nil

        await recognizeText(from: image)
    }

    private func recognizeText(from image: UIImage) async {
        guard let cgImage = image.cgImage else { return }
        isRecognizing = true
        defer { isRecognizing = false }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["zh-Hans", "en"]
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([request])
            let observations = request.results ?? []
            let lines = observations.compactMap { $0.topCandidates(1).first?.string }
            ocrText = lines.joined(separator: "\n")
        } catch {
            errorMessage = "文字识别失败: \(error.localizedDescription)"
        }
    }

    private func importPortfolio() async {
        guard !ocrText.isEmpty else { return }
        isImporting = true
        errorMessage = nil
        importResult = nil
        defer { isImporting = false }

        do {
            let result = try await StockService.importPortfolioFromText(ocrText)
            importResult = ImportResult(
                imported: result.imported,
                total: result.total
            )
        } catch {
            errorMessage = "导入失败: \(error.localizedDescription)"
        }
    }
}
