import Foundation
import CoreBluetooth

/// 蓝牙桥（ble.*）——对齐 shell-android BleManager 的方法/事件/载荷。
///
/// 方法：ble.open / startDiscovery / stopDiscovery / connect / getServices /
///       getCharacteristics / write / closeConnection / closeAdapter
/// 事件：ble.onAdapterStateChange {available, discovering}
///       ble.onDeviceFound {devices:[{deviceId,seq,name,localName,RSSI,advertisData,advertisServiceUUIDs}]}
///
/// iOS 与 Android 的差异处理：
///  - deviceId：iOS 用 peripheral.identifier.uuidString（会话内自洽，前端仅回传我们发现时给的 id）；
///  - MTU：iOS 自动协商，无 requestMtu；连接成功后直接进入服务发现；
///  - 服务/特征发现是异步两步（discoverServices → didDiscoverServices；discoverCharacteristics → didDiscover…），
///    对未缓存者触发发现并挂起回调，配 5s 超时兜底（对齐 Android 的 Promise 不悬空策略）。
final class BleBridge: NSObject, BridgeModule, CBCentralManagerDelegate, CBPeripheralDelegate {

    private let channel: JsChannel
    private var central: CBCentralManager?
    private var discovering = false

    private var scanSeq = 0
    private var discovered: [String: CBPeripheral] = [:]     // deviceId -> peripheral
    private var connected: [String: CBPeripheral] = [:]

    private var pendingOpen: [(String)] = []
    private var pendingConnect: [String: String] = [:]
    private var connectTimeouts: [String: DispatchWorkItem] = [:]
    private var pendingServices: [String: String] = [:]
    private var serviceTimeouts: [String: DispatchWorkItem] = [:]
    private var pendingChars: [String: String] = [:]         // key: deviceId|serviceId
    private var charTimeouts: [String: DispatchWorkItem] = [:]
    private var pendingWrite: [String: String] = [:]
    private var writeTimeouts: [String: DispatchWorkItem] = [:]

    init(channel: JsChannel) {
        self.channel = channel
        super.init()
    }

    // MARK: - 分发

    func handle(_ method: String, _ params: [String: Any], _ callbackId: String) -> Bool {
        switch method {
        case "ble.open": open(callbackId)
        case "ble.startDiscovery": startDiscovery(callbackId)
        case "ble.stopDiscovery": stopDiscovery(callbackId)
        case "ble.connect": connect(params, callbackId)
        case "ble.getServices": getServices(params, callbackId)
        case "ble.getCharacteristics": getCharacteristics(params, callbackId)
        case "ble.write": write(params, callbackId)
        case "ble.closeConnection": closeConnection(params, callbackId)
        case "ble.closeAdapter": closeAdapter(); channel.resolveOk(callbackId)
        default: return false
        }
        return true
    }

    // MARK: - 适配器

    private func open(_ callbackId: String) {
        if let c = central {
            switch c.state {
            case .poweredOn: channel.resolveOk(callbackId, ["state": "on"])
            case .unauthorized: channel.resolveErr(callbackId, "缺少蓝牙权限")
            case .unsupported: channel.resolveErr(callbackId, "当前设备不支持蓝牙")
            default: pendingOpen.append(callbackId)  // poweredOff/unknown：等待状态更新
            }
        } else {
            pendingOpen.append(callbackId)
            central = CBCentralManager(delegate: self, queue: nil)  // 触发系统授权弹窗
        }
    }

    func closeAdapter() {
        stopScanInternal()
        connected.values.forEach { central?.cancelPeripheralConnection($0) }
        connected.removeAll()
        discovered.removeAll()
    }

    private func emitAdapterState() {
        let available = (central?.state == .poweredOn)
        channel.emit("ble.onAdapterStateChange", data: ["available": available, "discovering": discovering])
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            flushPendingOpen()
        } else {
            failPendingOpen()
        }
        emitAdapterState()
    }

    private func flushPendingOpen() {
        guard !pendingOpen.isEmpty else { return }
        let ids = pendingOpen; pendingOpen.removeAll()
        ids.forEach { channel.resolveOk($0, ["state": "on"]) }
    }

    private func failPendingOpen() {
        guard !pendingOpen.isEmpty else { return }
        let ids = pendingOpen; pendingOpen.removeAll()
        let msg = (central?.state == .unauthorized) ? "缺少蓝牙权限" : "蓝牙未开启"
        ids.forEach { channel.resolveErr($0, msg) }
    }

    // MARK: - 扫描

    private func startDiscovery(_ callbackId: String) {
        guard let c = central, c.state == .poweredOn else {
            channel.resolveErr(callbackId, "蓝牙未开启"); return
        }
        stopScanInternal()
        c.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        discovering = true
        emitAdapterState()
        channel.resolveOk(callbackId)
    }

    private func stopDiscovery(_ callbackId: String) {
        stopScanInternal()
        emitAdapterState()
        channel.resolveOk(callbackId)
    }

    private func stopScanInternal() {
        if discovering, let c = central { c.stopScan() }
        discovering = false
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        scanSeq += 1
        let deviceId = peripheral.identifier.uuidString
        discovered[deviceId] = peripheral

        let advName = (advertisementData[CBAdvertisementDataLocalNameKey] as? String) ?? ""
        let name = peripheral.name ?? ""
        let finalName = !advName.isEmpty ? advName : name

        var serviceUUIDs: [String] = []
        if let uuids = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
            serviceUUIDs = uuids.map { $0.uuidString.lowercased() }
        }
        let mfgData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data

        let obj: [String: Any] = [
            "deviceId": deviceId,
            "seq": scanSeq,
            "name": finalName,
            "localName": advName.isEmpty ? finalName : advName,
            "RSSI": RSSI.intValue,
            "advertisData": mfgData.map { $0.base64EncodedString() } ?? "",
            "advertisServiceUUIDs": serviceUUIDs
        ]
        channel.emit("ble.onDeviceFound", data: ["devices": [obj]])
    }

    // MARK: - 连接

    private func connect(_ params: [String: Any], _ callbackId: String) {
        guard let deviceId = params["deviceId"] as? String, !deviceId.isEmpty else {
            channel.resolveErr(callbackId, "deviceId 为空"); return
        }
        guard let c = central, c.state == .poweredOn else {
            channel.resolveErr(callbackId, "蓝牙不可用"); return
        }
        guard let peripheral = resolvedPeripheral(deviceId) else {
            channel.resolveErr(callbackId, "无效的 deviceId: \(deviceId)"); return
        }
        let timeoutMs = (params["timeout"] as? NSNumber)?.int64Value ?? 15000

        // 取代旧连接回调
        pendingConnect.removeValue(forKey: deviceId).flatMap { channel.resolveErr($0, "已被新的连接请求取代") }
        cancelConnectTimeout(deviceId)

        c.connect(peripheral, options: nil)
        pendingConnect[deviceId] = callbackId
        let work = DispatchWorkItem { [weak self] in
            guard let self = self, self.pendingConnect[deviceId] != nil else { return }
            self.pendingConnect.removeValue(forKey: deviceId)
            self.channel.resolveErr(callbackId, "连接超时")
            if let p = self.connected[deviceId] ?? self.discovered[deviceId] { self.central?.cancelPeripheralConnection(p) }
        }
        connectTimeouts[deviceId] = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(timeoutMs) / 1000.0, execute: work)
    }

    private func resolvedPeripheral(_ deviceId: String) -> CBPeripheral? {
        if let p = discovered[deviceId] ?? connected[deviceId] { return p }
        if let uuid = UUID(uuidString: deviceId) {
            return central?.retrievePeripherals(withIdentifiers: [uuid]).first
        }
        return nil
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        let deviceId = peripheral.identifier.uuidString
        connected[deviceId] = peripheral
        peripheral.delegate = self
        cancelConnectTimeout(deviceId)
        pendingConnect.removeValue(forKey: deviceId).flatMap { channel.resolveOk($0) }
    }

    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral, error: Error?) {
        let deviceId = peripheral.identifier.uuidString
        cancelConnectTimeout(deviceId)
        pendingConnect.removeValue(forKey: deviceId).flatMap { channel.resolveErr($0, "连接失败: \(error?.localizedDescription ?? "")") }
    }

    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        let deviceId = peripheral.identifier.uuidString
        connected.removeValue(forKey: deviceId)
        servicesCacheRemove(deviceId)
        cancelConnectTimeout(deviceId)
        pendingConnect.removeValue(forKey: deviceId).flatMap { channel.resolveErr($0, "连接已断开") }
        failPendingServices(deviceId, "连接已断开")
        failPendingWrite(deviceId, "连接已断开")
    }

    // MARK: - 服务

    private func getServices(_ params: [String: Any], _ callbackId: String) {
        let deviceId = (params["deviceId"] as? String) ?? ""
        guard let peripheral = connected[deviceId] else {
            channel.resolveErr(callbackId, "设备未连接"); return
        }
        if let services = peripheral.services, !services.isEmpty {
            channel.resolveOk(callbackId, ["services": buildServices(services)])
            return
        }
        pendingServices[deviceId] = callbackId
        let key = deviceId
        serviceTimeouts[key]?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self = self, self.pendingServices[deviceId] != nil else { return }
            self.pendingServices.removeValue(forKey: deviceId)
            self.channel.resolveErr(callbackId, "服务发现超时")
            _ = key
        }
        serviceTimeouts[key] = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: work)
        peripheral.discoverServices(nil)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        let deviceId = peripheral.identifier.uuidString
        serviceTimeouts[deviceId]?.cancel(); serviceTimeouts.removeValue(forKey: deviceId)
        guard let cb = pendingServices.removeValue(forKey: deviceId) else { return }
        if let error = error {
            channel.resolveErr(cb, "服务发现失败: \(error.localizedDescription)")
        } else {
            channel.resolveOk(cb, ["services": buildServices(peripheral.services ?? [])])
        }
    }

    private func buildServices(_ services: [CBService]) -> [[String: Any]] {
        services.map { ["uuid": $0.uuid.uuidString.lowercased(), "isPrimary": $0.isPrimary] }
    }

    // MARK: - 特征值

    private func getCharacteristics(_ params: [String: Any], _ callbackId: String) {
        let deviceId = (params["deviceId"] as? String) ?? ""
        let serviceId = ((params["serviceId"] as? String) ?? "").lowercased()
        guard let peripheral = connected[deviceId],
              let service = findService(peripheral: peripheral, serviceId: serviceId) else {
            channel.resolveErr(callbackId, "未找到服务: \(serviceId)"); return
        }
        if let chars = service.characteristics, !chars.isEmpty {
            channel.resolveOk(callbackId, ["characteristics": buildCharacteristics(chars)])
            return
        }
        let key = "\(deviceId)|\(serviceId)"
        pendingChars[key] = callbackId
        charTimeouts[key]?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self = self, self.pendingChars[key] != nil else { return }
            self.pendingChars.removeValue(forKey: key)
            self.channel.resolveErr(callbackId, "特征发现超时")
        }
        charTimeouts[key] = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: work)
        peripheral.discoverCharacteristics(nil, for: service)
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        let deviceId = peripheral.identifier.uuidString
        let key = "\(deviceId)|\(service.uuid.uuidString.lowercased())"
        charTimeouts[key]?.cancel(); charTimeouts.removeValue(forKey: key)
        guard let cb = pendingChars.removeValue(forKey: key) else { return }
        if let error = error {
            channel.resolveErr(cb, "特征发现失败: \(error.localizedDescription)")
        } else {
            channel.resolveOk(cb, ["characteristics": buildCharacteristics(service.characteristics ?? [])])
        }
    }

    private func buildCharacteristics(_ chars: [CBCharacteristic]) -> [[String: Any]] {
        chars.map { c in
            let p = c.properties
            return [
                "uuid": c.uuid.uuidString.lowercased(),
                "properties": [
                    "read": p.contains(.read),
                    "write": p.contains(.write),
                    "notify": p.contains(.notify),
                    "indicate": p.contains(.indicate),
                    "writeNoResponse": p.contains(.writeWithoutResponse)
                ]
            ]
        }
    }

    // MARK: - 写入

    private func write(_ params: [String: Any], _ callbackId: String) {
        let deviceId = (params["deviceId"] as? String) ?? ""
        let serviceId = ((params["serviceId"] as? String) ?? "").lowercased()
        let charId = ((params["characteristicId"] as? String) ?? "").lowercased()
        let valueB64 = (params["value"] as? String) ?? ""
        guard let peripheral = connected[deviceId] else {
            channel.resolveErr(callbackId, "设备未连接"); return
        }
        guard let service = findService(peripheral: peripheral, serviceId: serviceId),
              let ch = (service.characteristics ?? []).first(where: { $0.uuid.uuidString.lowercased() == charId }) else {
            channel.resolveErr(callbackId, "未找到特征值: \(charId)"); return
        }
        guard let data = Data(base64Encoded: valueB64) else {
            channel.resolveErr(callbackId, "value 解码失败"); return
        }
        let type: CBCharacteristicWriteType = ch.properties.contains(.writeWithoutResponse) ? .withoutResponse : .withResponse

        // .withoutResponse 不会触发 didWriteValueFor，直接成功（对齐 Android 无响应写语义）
        if type == .withoutResponse {
            peripheral.writeValue(data, for: ch, type: .withoutResponse)
            channel.resolveOk(callbackId)
            return
        }
        pendingWrite[deviceId] = callbackId
        writeTimeouts[deviceId]?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self = self, self.pendingWrite[deviceId] != nil else { return }
            self.pendingWrite.removeValue(forKey: deviceId)
            self.channel.resolveErr(callbackId, "写入响应超时")
        }
        writeTimeouts[deviceId] = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: work)
        peripheral.writeValue(data, for: ch, type: .withResponse)
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        let deviceId = peripheral.identifier.uuidString
        writeTimeouts[deviceId]?.cancel(); writeTimeouts.removeValue(forKey: deviceId)
        guard let cb = pendingWrite.removeValue(forKey: deviceId) else { return }
        if let error = error { channel.resolveErr(cb, "写入失败: \(error.localizedDescription)") }
        else { channel.resolveOk(cb) }
    }

    // MARK: - 关闭

    private func closeConnection(_ params: [String: Any], _ callbackId: String) {
        let deviceId = (params["deviceId"] as? String) ?? ""
        if let peripheral = connected[deviceId] {
            central?.cancelPeripheralConnection(peripheral)
        }
        connected.removeValue(forKey: deviceId)
        servicesCacheRemove(deviceId)
        failPendingServices(deviceId, "连接已关闭")
        failPendingWrite(deviceId, "连接已关闭")
        channel.resolveOk(callbackId)
    }

    // MARK: - 工具

    private func findService(peripheral: CBPeripheral, serviceId: String) -> CBService? {
        peripheral.services?.first(where: { Self.matchUuid($0.uuid.uuidString, serviceId) })
    }

    /// UUID 宽松匹配：容忍「完整/短形式」「大小写」差异
    private static func matchUuid(_ a: String, _ bLower: String) -> Bool {
        let x = a.lowercased(), y = bLower
        if x == y { return true }
        // 短形式：180A <-> 0000180a-0000-1000-8000-00805f9b34fb
        if x.count == 4, y.hasPrefix("0000"), y.hasSuffix("0000-1000-8000-00805f9b34fb") { return x == String(y.dropFirst(4).prefix(4)) }
        if y.count == 4, x.hasPrefix("0000"), x.hasSuffix("0000-1000-8000-00805f9b34fb") { return y == String(x.dropFirst(4).prefix(4)) }
        return false
    }

    private func servicesCacheRemove(_ deviceId: String) {
        // iOS 的 services/characteristics 挂在 peripheral 上，随断开自动失效；此处清挂起回调
        let prefix = "\(deviceId)|"
        for k in pendingChars.keys where k.hasPrefix(prefix) {
            charTimeouts[k]?.cancel(); charTimeouts.removeValue(forKey: k)
            pendingChars.removeValue(forKey: k)
        }
    }

    private func cancelConnectTimeout(_ deviceId: String) {
        connectTimeouts[deviceId]?.cancel(); connectTimeouts.removeValue(forKey: deviceId)
    }

    private func failPendingServices(_ deviceId: String, _ reason: String) {
        serviceTimeouts[deviceId]?.cancel(); serviceTimeouts.removeValue(forKey: deviceId)
        pendingServices.removeValue(forKey: deviceId).flatMap { channel.resolveErr($0, reason) }
    }

    private func failPendingWrite(_ deviceId: String, _ reason: String) {
        writeTimeouts[deviceId]?.cancel(); writeTimeouts.removeValue(forKey: deviceId)
        pendingWrite.removeValue(forKey: deviceId).flatMap { channel.resolveErr($0, reason) }
    }
}
