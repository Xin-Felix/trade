import SwiftUI
import PhotosUI

/// 包装 UIImage 使其可作为 fullScreenCover(item:) 的参数
struct CropImageWrapper: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var profile: UserProfile?
    @State private var editName: String = ""
    @State private var avatarURL: String?
    @State private var isLoading = false
    @State private var isSaving = false
    @State private var isUploadingAvatar = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    // 图片选择
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var imageToCrop: CropImageWrapper?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                avatarSection
                infoSection
                saveButton
            }
            .padding()
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle("编辑资料")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadProfile()
        }
        .fullScreenCover(item: $imageToCrop) { wrapper in
            ImageCropView(
                image: wrapper.image,
                onCropped: { croppedImage in
                    imageToCrop = nil
                    selectedImage = croppedImage
                    Task { await uploadAvatar(image: croppedImage) }
                },
                onCancel: {
                    imageToCrop = nil
                    selectedPhoto = nil
                }
            )
        }
        .overlay {
            if isLoading {
                ProgressView("加载中...")
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - 头像

    private var avatarSection: some View {
        VStack(spacing: 12) {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    avatarImage
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)

                    // 编辑图标
                    Image(systemName: "camera.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .background(Circle().fill(YPColor.accent).frame(width: 30, height: 30))
                        .offset(x: -2, y: -2)
                }
            }
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    await handlePhotoSelection(newValue)
                }
            }

            if isUploadingAvatar {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("上传中...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(YPColor.down)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Text("点击更换头像")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Text("支持 jpg/png/gif/webp 格式")
                .font(.caption2)
                .foregroundStyle(.quaternary)
        }
        .padding(.top, 12)
    }

    @ViewBuilder
    private var avatarImage: some View {
        if let selectedImage {
            Image(uiImage: selectedImage)
                .resizable()
                .scaledToFill()
        } else if let avatarURL, let url = URL(string: avatarURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure(let error):
                    defaultAvatar
                        .onAppear {
                            print("[ProfileEdit] 头像加载失败: \(avatarURL), error: \(error.localizedDescription)")
                        }
                case .empty:
                    ProgressView()
                        .frame(width: 100, height: 100)
                @unknown default:
                    defaultAvatar
                }
            }
            .id(url)
        } else {
            defaultAvatar
        }
    }

    private var defaultAvatar: some View {
        Image("AppLogo")
            .resizable()
            .scaledToFill()
    }

    // MARK: - 信息编辑

    private var infoSection: some View {
        VStack(spacing: 0) {
            // 昵称
            VStack(alignment: .leading, spacing: 8) {
                Text("昵称")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                TextField("输入你的昵称", text: $editName)
                    .font(.body)
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Divider()
                .padding(.vertical, 16)

            // 邮箱（只读）
            VStack(alignment: .leading, spacing: 8) {
                Text("邮箱")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                HStack {
                    Text(profile?.email ?? "--")
                        .font(.body)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Divider()
                .padding(.vertical, 16)

            // 注册时间（只读）
            VStack(alignment: .leading, spacing: 8) {
                Text("注册时间")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                HStack {
                    Text(formatDate(profile?.createdAt))
                        .font(.body)
                        .foregroundStyle(.primary)
                    Spacer()
                }
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // 提示信息
            if let error = errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle")
                    Text(error)
                }
                .font(.caption)
                .foregroundStyle(YPColor.down)
                .padding(.top, 16)
            }

            if let success = successMessage {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle")
                    Text(success)
                }
                .font(.caption)
                .foregroundStyle(YPColor.success)
                .padding(.top, 16)
            }
        }
    }

    // MARK: - 保存按钮

    private var saveButton: some View {
        Button {
            Task { await saveProfile() }
        } label: {
            HStack {
                if isSaving {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.8)
                }
                Text("保存修改")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(hasChanges ? YPColor.accent : Color.gray.opacity(0.4))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!hasChanges || isSaving)
        .padding(.top, 8)
    }

    private var hasChanges: Bool {
        let nameChanged = editName != (profile?.name ?? "")
        return nameChanged
    }

    // MARK: - 数据操作

    private func loadProfile() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let p = try await UserService.fetchProfile()
            profile = p
            editName = p.name ?? ""
            avatarURL = p.avatar
        } catch {
            errorMessage = "加载失败: \(error.localizedDescription)"
        }
    }

    private func handlePhotoSelection(_ item: PhotosPickerItem?) async {
        guard let item else { return }

        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                errorMessage = "无法读取图片数据"
                print("[ProfileEdit] loadTransferable 返回 nil")
                return
            }
            // 用 ImageIO 直接下采样，比 UIImage(data:) 再 UIGraphicsImageRenderer 快很多
            guard let image = downsampleImageFromData(data, maxDimension: 1024) else {
                errorMessage = "图片格式不支持"
                print("[ProfileEdit] 下采样失败，data 大小: \(data.count)")
                return
            }
            print("[ProfileEdit] 加载图片成功: \(image.size)")
            presentCropView(image: image)
        } catch {
            errorMessage = "读取图片失败: \(error.localizedDescription)"
            print("[ProfileEdit] 加载图片失败: \(error)")
        }
    }

    private func presentCropView(image: UIImage) {
        errorMessage = nil
        successMessage = nil
        imageToCrop = CropImageWrapper(image: image)
    }

    /// 使用 ImageIO 直接生成缩略图，避免解码整张大图
    private func downsampleImageFromData(_ data: Data, maxDimension: CGFloat) -> UIImage? {
        guard let imageSource = CGImageSourceCreateWithData(
            data as CFData,
            [kCGImageSourceShouldCache: false] as CFDictionary
        ) else {
            return nil
        }

        let options: [NSString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: maxDimension,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: false
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
            return nil
        }

        return UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
    }

    private func uploadAvatar(image: UIImage) async {
        isUploadingAvatar = true
        defer { isUploadingAvatar = false }

        // 清理裁剪和照片选择状态，避免重复选择同一张图时不触发 onChange
        imageToCrop = nil
        selectedPhoto = nil

        do {
            let result = try await UserService.uploadAvatar(image: image, maxSizeKB: 500)
            // 立即使用上传返回的公共 URL 显示头像，避免等待 /auth/me 刷新
            avatarURL = result.url
            // 上传成功后把 object_key 同步到用户资料
            let updated = try await UserService.updateProfile(avatar: result.objectKey)
            profile = updated
            avatarURL = updated.avatar ?? result.url
            successMessage = "头像上传成功"
            errorMessage = nil
            // 通知外部刷新
            NotificationCenter.default.post(name: .userProfileUpdated, object: nil)
        } catch let error as APIError {
            switch error {
            case .httpError(_, let message):
                errorMessage = message ?? "上传失败"
            default:
                errorMessage = "上传失败: \(error.localizedDescription)"
            }
            // 清除预览，回退
            selectedImage = nil
        } catch {
            errorMessage = "上传失败: \(error.localizedDescription)"
            selectedImage = nil
        }
    }

    private func saveProfile() async {
        guard hasChanges else { return }

        isSaving = true
        defer { isSaving = false }
        errorMessage = nil
        successMessage = nil

        do {
            let updated = try await UserService.updateProfile(name: editName.isEmpty ? nil : editName)
            profile = updated
            editName = updated.name ?? ""
            successMessage = "修改成功"
            // 通知外部刷新
            NotificationCenter.default.post(name: .userProfileUpdated, object: nil)
        } catch {
            errorMessage = "保存失败: \(error.localizedDescription)"
        }
    }

    // MARK: - Helpers

    private func formatDate(_ dateString: String?) -> String {
        guard let dateString else { return "--" }
        // ISO 8601: "2026-07-08T10:30:00"
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            let display = DateFormatter()
            display.dateFormat = "yyyy年M月d日"
            return display.string(from: date)
        }
        // fallback: 尝试不带小数秒
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: dateString) {
            let display = DateFormatter()
            display.dateFormat = "yyyy年M月d日"
            return display.string(from: date)
        }
        return dateString.prefix(10).replacingOccurrences(of: "-", with: ".")
    }
}

#Preview {
    NavigationStack {
        ProfileEditView()
    }
}
