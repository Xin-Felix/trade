import SwiftUI

struct PortfolioEditSheet: View {
    let code: String
    let name: String
    let existingItem: PortfolioItem?
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var costPriceText: String = ""
    @State private var quantityText: String = ""
    @State private var isMargin: Bool = false
    @State private var note: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var isEditing: Bool { existingItem != nil }

    init(
        code: String,
        name: String,
        existingItem: PortfolioItem? = nil,
        onSave: @escaping () -> Void
    ) {
        self.code = code
        self.name = name
        self.existingItem = existingItem
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("股票")) {
                    HStack {
                        Text(name)
                            .font(.headline)
                        Spacer()
                        Text(code)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Section(header: Text("持仓信息")) {
                    HStack {
                        Text("成本价")
                        Spacer()
                        TextField("0.00", text: $costPriceText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("持仓数量")
                        Spacer()
                        TextField("0", text: $quantityText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }

                    Toggle("融资持仓", isOn: $isMargin)
                }

                Section(header: Text("备注")) {
                    TextField("可选备注", text: $note)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(YPColor.up)
                    }
                }
            }
            .navigationTitle(isEditing ? "编辑持仓" : "添加持仓")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        Task { await save() }
                    }
                    .disabled(isLoading || !isValid)
                }
            }
            .onAppear {
                if let item = existingItem {
                    costPriceText = item.costPrice.map { String(format: "%.4f", $0) } ?? ""
                    quantityText = item.quantity.map { String(format: "%.2f", $0) } ?? ""
                    isMargin = item.isMargin
                    note = item.note ?? ""
                }
            }
        }
    }

    private var isValid: Bool {
        costPriceText.isEmpty || Double(costPriceText) != nil
            && (quantityText.isEmpty || Double(quantityText) != nil)
    }

    private func save() async {
        guard isValid else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let costPrice = Double(costPriceText)
        let quantity = Double(quantityText)
        let trimmedNote = note.isEmpty ? nil : note

        do {
            if isEditing {
                _ = try await StockService.updatePortfolio(
                    code: code,
                    costPrice: costPrice,
                    quantity: quantity,
                    isMargin: isMargin,
                    note: trimmedNote
                )
            } else {
                _ = try await StockService.addToPortfolio(
                    code: code,
                    name: name,
                    costPrice: costPrice,
                    quantity: quantity,
                    isMargin: isMargin,
                    note: trimmedNote
                )
            }
            onSave()
            dismiss()
        } catch {
            if error is CancellationError { return }
            errorMessage = "保存失败: \(error.localizedDescription)"
        }
    }
}

#Preview {
    PortfolioEditSheet(code: "000001", name: "平安银行") {}
}
