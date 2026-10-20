import UIKit

/// App 更新与系统能力（app.*）——对齐 shell-android UpdateManager。
///
///   app.download {url, taskId}      -> URLSession 下载，事件 app.onDownloadProgress，resolve {filePath}
///   app.installPackage {filePath}   -> iOS 无法侧载，转跳 App Store（前端 iOS 更新本应走 openStore）
///   app.openStore {url}             -> 打开 App Store（无 url 时按 bundleId 跳本应用页）
///   app.openSettings {}             -> 打开系统「设置-本应用」
///   app.quit {}                     -> 退出应用
final class UpdateBridge: NSObject, BridgeModule, URLSessionDownloadDelegate {

    private weak var viewController: ViewController?
    private let channel: JsChannel

    private var downloadCallback: [String: String] = [:]     // taskId -> callbackId
    private lazy var downloadSession: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForResource = 600
        return URLSession(configuration: cfg, delegate: self, delegateQueue: nil)
    }()

    init(viewController: ViewController, channel: JsChannel) {
        self.viewController = viewController
        self.channel = channel
        super.init()
    }

    func handle(_ method: String, _ params: [String: Any], _ callbackId: String) -> Bool {
        switch method {
        case "app.download": download(params, callbackId)
        case "app.installPackage": installPackage(params, callbackId)
        case "app.openStore": openStore(params, callbackId)
        case "app.openSettings": openSettings(callbackId)
        case "app.quit": channel.resolveOk(callbackId); DispatchQueue.main.async { exit(0) }
        default: return false
        }
        return true
    }

    // MARK: - 下载

    private func download(_ params: [String: Any], _ callbackId: String) {
        guard let urlString = params["url"] as? String, !urlString.isEmpty, let url = URL(string: urlString) else {
            channel.resolveErr(callbackId, "url 为空"); return
        }
        let taskId = (params["taskId"] as? String) ?? "dl_\(Int(Date().timeIntervalSince1970 * 1000))"
        downloadCallback[taskId] = callbackId
        let task = downloadSession.downloadTask(with: url)
        task.taskDescription = taskId
        task.resume()
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        let taskId = downloadTask.taskDescription ?? ""
        // 复制到持久临时文件
        let dest = FileManager.default.temporaryDirectory
            .appendingPathComponent("download_\(Int(Date().timeIntervalSince1970 * 1000)).tmp")
        try? FileManager.default.removeItem(at: dest)
        try? FileManager.default.moveItem(at: location, to: dest)
        if let cb = downloadCallback.removeValue(forKey: taskId) {
            channel.resolveOk(cb, ["filePath": dest.path])
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        let taskId = downloadTask.taskDescription ?? ""
        let percent = totalBytesExpectedToWrite > 0
            ? Int(totalBytesWritten * 100 / totalBytesExpectedToWrite) : 0
        channel.emit("app.onDownloadProgress", data: [
            "taskId": taskId,
            "percent": percent,
            "downloadedSize": totalBytesWritten,
            "totalSize": totalBytesExpectedToWrite
        ])
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error, let taskId = task.taskDescription else { return }
        if let cb = downloadCallback.removeValue(forKey: taskId) {
            channel.resolveErr(cb, "下载失败: \(error.localizedDescription)")
        }
    }

    // MARK: - 安装（iOS 转跳商店）

    private func installPackage(_ params: [String: Any], _ callbackId: String) {
        // iOS 不支持安装本地包，引导至 App Store
        openStore(["url": ""], callbackId)
    }

    private func openStore(_ params: [String: Any], _ callbackId: String) {
        let url = (params["url"] as? String) ?? ""
        let target: String
        if !url.isEmpty {
            target = url
        } else if let id = Bundle.main.bundleIdentifier {
            target = "itms-apps://itunes.apple.com/app/id\(id)"
        } else {
            channel.resolveErr(callbackId, "无商店地址")
            return
        }
        guard let u = URL(string: target) else { channel.resolveErr(callbackId, "商店地址无效"); return }
        UIApplication.shared.open(u) { ok in
            ok ? self.channel.resolveOk(callbackId) : self.channel.resolveErr(callbackId, "打开商店失败")
        }
    }

    private func openSettings(_ callbackId: String) {
        guard let u = URL(string: UIApplication.openSettingsURLString) else {
            channel.resolveErr(callbackId, "打开设置失败"); return
        }
        UIApplication.shared.open(u) { ok in
            ok ? self.channel.resolveOk(callbackId) : self.channel.resolveErr(callbackId, "打开设置失败")
        }
    }
}
