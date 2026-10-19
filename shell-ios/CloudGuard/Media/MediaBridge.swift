import UIKit
import Photos
import UniformTypeIdentifiers

/// 相册 / 相机桥（image.*）——对齐 shell-android MediaManager。
///
///   image.choose / image.chooseMedia {count, sourceType[camera,album]}
///       -> {images:[{base64, mimeType, name, size}]}
///   image.saveToAlbum {filePath, base64?, mimeType?}
///
/// 前端（h5-native-bridge.js）已把 canvas/blob 产物转成 base64 再下发，故相册返回统一用 JPEG base64。
final class MediaBridge: NSObject, BridgeModule,
                        UIImagePickerControllerDelegate,
                        UINavigationControllerDelegate,
                        PHPickerViewControllerDelegate {

    private weak var viewController: ViewController?
    private let channel: JsChannel

    private var chooseCallback: String?
    private var pendingImages: [[String: Any]] = []
    private var pendingCount = 0

    init(viewController: ViewController, channel: JsChannel) {
        self.viewController = viewController
        self.channel = channel
        super.init()
    }

    func handle(_ method: String, _ params: [String: Any], _ callbackId: String) -> Bool {
        switch method {
        case "image.choose", "image.chooseMedia": choose(params, callbackId)
        case "image.saveToAlbum": saveToAlbum(params, callbackId)
        default: return false
        }
        return true
    }

    // MARK: - 选择

    private func choose(_ params: [String: Any], _ callbackId: String) {
        guard let vc = viewController else { channel.resolveErr(callbackId, "无可用界面"); return }
        let count = (params["count"] as? NSNumber)?.intValue ?? 1
        let sourceType = (params["sourceType"] as? [String]) ?? ["album", "camera"]
        let hasCamera = sourceType.contains("camera")
        let hasAlbum = sourceType.contains("album")

        chooseCallback = callbackId
        pendingImages = []
        pendingCount = max(1, count)

        if hasCamera && hasAlbum {
            sheet(vc, hasCamera: true, hasAlbum: true)
        } else if hasCamera {
            openCamera(vc)
        } else if hasAlbum {
            openAlbum(vc, multi: pendingCount > 1)
        } else {
            chooseCallback = nil
            channel.resolveErr(callbackId, "无效的 sourceType")
        }
    }

    private func sheet(_ vc: UIViewController, hasCamera: Bool, hasAlbum: Bool) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        if hasCamera {
            alert.addAction(UIAlertAction(title: "拍照", style: .default) { [weak self] _ in self?.openCamera(vc) })
        }
        if hasAlbum {
            alert.addAction(UIAlertAction(title: "从相册选择", style: .default) { [weak self] _ in self?.openAlbum(vc, multi: (self?.pendingCount ?? 1) > 1) })
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel) { [weak self] _ in
            self?.finishChooseErr("user cancelled")
        })
        alert.popoverPresentationController?.sourceView = vc.view
        vc.present(alert, animated: true)
    }

    private func openCamera(_ vc: UIViewController) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            // 无相机（模拟器等）退回相册
            openAlbum(vc, multi: pendingCount > 1); return
        }
        let p = UIImagePickerController()
        p.sourceType = .camera
        p.mediaTypes = ["public.image"]
        p.delegate = self
        vc.present(p, animated: true)
    }

    private func openAlbum(_ vc: UIViewController, multi: Bool) {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = multi ? pendingCount : 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        vc.present(picker, animated: true)
    }

    // MARK: - UIImagePickerController（拍照）

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        let image = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
        if let img = image, let item = Self.makeItem(img, name: "camera_\(Int(Date().timeIntervalSince1970 * 1000)).jpg") {
            pendingImages.append(item)
        }
        finishChoose()
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        finishChooseErr("user cancelled")
    }

    // MARK: - PHPickerViewController（相册）

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard !results.isEmpty else { finishChooseErr("user cancelled"); return }
        let group = DispatchGroup()
        var collected: [[String: Any]] = []
        let lock = NSLock()
        for r in results {
            group.enter()
            if r.itemProvider.canLoadObject(ofClass: UIImage.self) {
                r.itemProvider.loadObject(ofClass: UIImage.self) { obj, _ in
                    if let img = obj as? UIImage, let item = Self.makeItem(img, name: "img_\(Int(Date().timeIntervalSince1970 * 1000)).jpg") {
                        lock.lock(); collected.append(item); lock.unlock()
                    }
                    group.leave()
                }
            } else {
                r.itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                    if let data = data, let img = UIImage(data: data),
                       let item = Self.makeItem(img, name: "img_\(Int(Date().timeIntervalSince1970 * 1000)).jpg") {
                        lock.lock(); collected.append(item); lock.unlock()
                    }
                    group.leave()
                }
            }
        }
        group.notify(queue: .main) { [weak self] in
            self?.pendingImages.append(contentsOf: collected)
            self?.finishChoose()
        }
    }

    private func finishChoose() {
        guard let cb = chooseCallback else { return }
        chooseCallback = nil
        channel.resolveOk(cb, ["images": pendingImages])
        pendingImages = []
    }

    private func finishChooseErr(_ msg: String) {
        guard let cb = chooseCallback else { return }
        chooseCallback = nil
        channel.resolveErr(cb, msg)
    }

    // MARK: - 保存到相册

    private func saveToAlbum(_ params: [String: Any], _ callbackId: String) {
        let base64 = (params["base64"] as? String) ?? ""
        let filePath = (params["filePath"] as? String) ?? ""
        var image: UIImage?
        if !base64.isEmpty, let d = Data(base64Encoded: base64) {
            image = UIImage(data: d)
        } else if !filePath.isEmpty {
            // 兼容：data URL / 本地临时文件
            if filePath.hasPrefix("data:") {
                if let comma = filePath.firstIndex(of: ","),
                   let d = Data(base64Encoded: String(filePath[filePath.index(after: comma)...])) { image = UIImage(data: d) }
            } else {
                let path = filePath.hasPrefix("file://") ? (URL(string: filePath)?.path ?? filePath) : filePath
                if let d = FileManager.default.contents(atPath: path) { image = UIImage(data: d) }
            }
        }
        guard let img = image else { channel.resolveErr(callbackId, "图片数据无效"); return }

        let perform = {
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: img)
            }) { success, error in
                DispatchQueue.main.async {
                    if success { self.channel.resolveOk(callbackId) }
                    else { self.channel.resolveErr(callbackId, "保存失败: \(error?.localizedDescription ?? "")") }
                }
            }
        }
        if #available(iOS 14, *) {
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                DispatchQueue.main.async {
                    guard status == .addOnly || status == .readWrite else {
                        self.channel.resolveErr(callbackId, "缺少相册权限"); return
                    }
                    perform()
                }
            }
        } else {
            PHPhotoLibrary.requestAuthorization { status in
                DispatchQueue.main.async {
                    guard status == .authorized else { self.channel.resolveErr(callbackId, "缺少相册权限"); return }
                    perform()
                }
            }
        }
    }

    // MARK: - 工具

    private static func makeItem(_ image: UIImage, name: String) -> [String: Any]? {
        // 统一压缩为 JPEG base64（与 Android MediaManager 输出结构一致）
        guard let data = image.jpegData(compressionQuality: 0.9) else { return nil }
        return [
            "base64": data.base64EncodedString(),
            "mimeType": "image/jpeg",
            "name": name,
            "size": data.count
        ]
    }
}
