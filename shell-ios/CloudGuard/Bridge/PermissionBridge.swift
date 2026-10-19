import Foundation
import AVFoundation
import Photos
import CoreBluetooth
import CoreLocation

/// 权限桥（permission.request）。
///
/// 前端沿用 Android 权限名（android.permission.CAMERA 等）下发，iOS 侧据此映射到对应能力授权，
/// 结果仍以「原始权限名 -> 是否授予」的字典回传（对齐 Android 的 {perm: bool}）。
/// 无 iOS 对应的权限（如存储/电话状态）默认视为已授予，避免阻断业务。
final class PermissionBridge: NSObject, CLLocationManagerDelegate, CBCentralManagerDelegate {

    private enum Capability: Hashable {
        case camera, microphone, photo, bluetooth, location, none
    }

    // 保活：定位/蓝牙代理回调期间需持有实例
    private var locationManager: CLLocationManager?
    private var bluetoothCentral: CBCentralManager?
    private var bluetoothContinuation: ((Bool) -> Void)?
    private var locationContinuation: ((Bool) -> Void)?
    private var bluetoothTimeout: DispatchWorkItem?

    private let queue = DispatchQueue(label: "com.yefiot.cloudguard.permission")

    // MARK: - 对外

    /// 批量申请权限；批内各能力串行申请（见 handleRequest），避免系统弹窗叠加。
    func request(perms: [String], completion: @escaping ([String: Any]) -> Void) {
        guard !perms.isEmpty else { completion([:]); return }
        handleRequest(perms, completion: completion)
    }

    /// 单个能力便捷申请（供扫码/相册内部使用）；已授权时同步回调。
    func ensure(_ token: String, completion: @escaping (Bool) -> Void) {
        request(perms: [token]) { result in
            completion((result[token] as? Bool) ?? true)
        }
    }

    // MARK: - 批处理

    private func handleRequest(_ perms: [String], completion: @escaping ([String: Any]) -> Void) {
        let mapped = perms.map { (perm: $0, cap: Self.capability(for: $0)) }
        let caps = Array(Set(mapped.map { $0.cap })).filter { $0 != .none }

        var capResults: [Capability: Bool] = [:]
        func finish() {
            var out: [String: Any] = [:]
            for item in mapped {
                switch item.cap {
                case .none: out[item.perm] = true
                default: out[item.perm] = capResults[item.cap] ?? true
                }
            }
            completion(out)
        }
        guard !caps.isEmpty else { finish(); return }

        var remaining = caps
        func next() {
            guard !remaining.isEmpty else { finish(); return }
            let cap = remaining.removeFirst()
            requestCapability(cap) { ok in
                capResults[cap] = ok
                self.queue.async { next() }
            }
        }
        next()
    }

    private static func capability(for perm: String) -> Capability {
        let p = perm.lowercased()
        if p.contains("camera") { return .camera }
        if p.contains("record_audio") || p.contains("microphone") { return .microphone }
        if p.contains("bluetooth") { return .bluetooth }
        if p.contains("location") { return .location }
        if p.contains("photo") || p.contains("media_images") || p.contains("external_storage")
            || p.contains("write_external") || p.contains("read_external") { return .photo }
        return .none
    }

    // MARK: - 单能力申请（均需主线程发起 UI 相关授权）

    private func requestCapability(_ cap: Capability, _ done: @escaping (Bool) -> Void) {
        let onMain = {
            switch cap {
            case .camera:
                Self.requestAccess(.video) { done($0) }
            case .microphone:
                Self.requestAccess(.audio) { done($0) }
            case .photo:
                if #available(iOS 14, *) {
                    PHPhotoLibrary.requestAuthorization(for: .readWrite) { s in
                        done(s != .denied && s != .restricted)
                    }
                } else {
                    PHPhotoLibrary.requestAuthorization { s in done(s != .denied && s != .restricted) }
                }
            case .bluetooth:
                self.requestBluetooth(done)
            case .location:
                self.requestLocation(done)
            case .none:
                done(true)
            }
        }
        if Thread.isMainThread { onMain() } else { DispatchQueue.main.async(execute: onMain) }
    }

    private static func requestAccess(_ type: AVMediaType, _ done: @escaping (Bool) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: type)
        switch status {
        case .authorized: done(true)
        case .denied, .restricted: done(false)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: type) { granted in
                DispatchQueue.main.async { done(granted) }
            }
        @unknown default: done(false)
        }
    }

    private func requestBluetooth(_ done: @escaping (Bool) -> Void) {
        bluetoothContinuation = done
        let timeout = DispatchWorkItem { [weak self] in
            guard let self = self, let c = self.bluetoothContinuation else { return }
            self.bluetoothContinuation = nil
            c(self.bluetoothCentral?.state != .unauthorized)
        }
        bluetoothTimeout = timeout
        if bluetoothCentral == nil {
            bluetoothCentral = CBCentralManager(delegate: self, queue: nil)
        } else {
            deliverBluetoothState()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 8, execute: timeout)
    }

    private func deliverBluetoothState() {
        bluetoothTimeout?.cancel(); bluetoothTimeout = nil
        guard let state = bluetoothCentral?.state else { return }
        switch state {
        case .unauthorized:
            finishBluetooth(false)
        case .unknown:
            break // 继续等待 stateUpdate
        default:
            // poweredOn / poweredOff / unsupported：权限层面视为「非拒绝」
            finishBluetooth(state != .unauthorized)
        }
    }

    private func finishBluetooth(_ ok: Bool) {
        bluetoothTimeout?.cancel(); bluetoothTimeout = nil
        let c = bluetoothContinuation; bluetoothContinuation = nil
        c?(ok)
    }

    // CBCentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        deliverBluetoothState()
    }

    private func requestLocation(_ done: @escaping (Bool) -> Void) {
        locationContinuation = done
        if locationManager == nil {
            locationManager = CLLocationManager()
            locationManager?.delegate = self
        }
        let status = CLLocationManager.authorizationStatus()
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            finishLocation(true)
        case .denied, .restricted:
            finishLocation(false)
        case .notDetermined:
            locationManager?.requestWhenInUseAuthorization()
        @unknown default:
            finishLocation(false)
        }
    }

    private func finishLocation(_ ok: Bool) {
        let c = locationContinuation; locationContinuation = nil
        c?(ok)
    }

    // CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard locationContinuation != nil else { return }
        switch status {
        case .authorizedAlways, .authorizedWhenInUse: finishLocation(true)
        case .denied, .restricted: finishLocation(false)
        default: break
        }
    }
}
