import Foundation
import UIKit

/// 机型标识（如 iPhone14,2）——对齐 Android Build.MODEL 的“机型字符串”语义。
enum DeviceInfo {
    static func machineIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        let identifier = mirror.children.reduce(into: "") { result, element in
            guard let value = element.value as? Int8, value != 0 else { return }
            result.append(String(UnicodeScalar(UInt8(value))))
        }
        return identifier.isEmpty ? UIDevice.current.model : identifier
    }
}
