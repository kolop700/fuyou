import UIKit
import AVFoundation

/// 扫码结果
enum ScanResult {
    case success(String)
    case cancelled
}

/// 扫码封装（scan.qrcode）——对齐 Android ZXing ScanActivity：仅二维码，返回 {result, scanType:"qrCode"}。
final class ScanBridge {

    func present(from presenter: UIViewController, completion: @escaping (ScanResult) -> Void) {
        // 【主线程兜底】建导航控制器/present 属 UIKit 操作，子线程调用会崩（AutoLayout 异常）。
        // 主修复在 PermissionBridge（权限结果统一切回主线程），此处再设一道防护，
        // 任何调用方误在子线程进来都自动回主线程执行。
        guard Thread.isMainThread else {
            DispatchQueue.main.async { self.present(from: presenter, completion: completion) }
            return
        }
        let scanVC = ScanViewController()
        scanVC.completion = completion
        let nav = UINavigationController(rootViewController: scanVC)
        nav.modalPresentationStyle = .fullScreen
        presenter.present(nav, animated: true)
    }
}

/// AVFoundation 二维码扫描页
final class ScanViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    var completion: ((ScanResult) -> Void)?

    private var session: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var didFind = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        title = "扫描二维码"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel, target: self, action: #selector(cancel)
        )
        // 模拟器无真实相机（模拟视频自带测试码会秒触发误识别，或设备直接不可用），
        // 改用手动输入二维码内容走通完整扫码链路；真机不受影响。
        #if !targetEnvironment(simulator)
        setupCamera()
        #endif
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        #if targetEnvironment(simulator)
        guard !didFind else { return }
        showSimulatorScanInput()
        #endif
    }

    #if targetEnvironment(simulator)
    /// 模拟器专用：手动输入二维码内容（如 https://.../c?device_number=YNxxxx），
    /// 输入后按与真机相同的结果回传（resolveOk/resolveErr），验证 H5 校验与跳转链路。
    private func showSimulatorScanInput() {
        let alert = UIAlertController(
            title: "模拟器扫码",
            message: "模拟器无真实相机，请手动输入二维码内容以验证扫码链路（真机不受影响）",
            preferredStyle: .alert
        )
        alert.addTextField { tf in
            tf.placeholder = "粘贴二维码内容，如 https://.../c?device_number=YNxxxx"
            tf.autocapitalizationType = "none"
        }
        alert.addAction(UIAlertAction(title: "模拟扫码成功", style: .default) { [weak self] _ in
            let text = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if text.isEmpty { self?.finish(.cancelled) } else { self?.finish(.success(text)) }
        })
        alert.addAction(UIAlertAction(title: "取消扫码", style: .cancel) { [weak self] _ in
            self?.finish(.cancelled)
        })
        present(alert, animated: true)
    }
    #endif

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    private func setupCamera() {
        guard let device = AVCaptureDevice.default(for: .video) else { finish(.cancelled); return }
        guard let input = try? AVCaptureDeviceInput(device: device),
              session == nil else { return }
        let s = AVCaptureSession()
        s.beginConfiguration()
        if s.canAddInput(input) { s.addInput(input) }
        let output = AVCaptureMetadataOutput()
        if s.canAddOutput(output) {
            s.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            if output.availableMetadataObjectTypes.contains(.qr) {
                output.metadataObjectTypes = [.qr]
            }
        }
        s.commitConfiguration()
        session = s

        let layer = AVCaptureVideoPreviewLayer(session: s)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.addSublayer(layer)
        previewLayer = layer

        DispatchQueue.global(qos: .userInitiated).async { s.startRunning() }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard !didFind else { return }
        guard let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject else { return }
        guard let value = obj.stringValue, !value.isEmpty else { return }
        didFind = true
        session?.stopRunning()
        finish(.success(value))
    }

    @objc private func cancel() { finish(.cancelled) }

    private func finish(_ result: ScanResult) {
        let cb = completion
        completion = nil
        dismiss(animated: true) { cb?(result) }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if !didFind { session?.stopRunning() }
    }
}
