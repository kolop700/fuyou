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
        setupCamera()
    }

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
