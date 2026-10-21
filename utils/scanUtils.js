/**
 * 扫码工具类
 */

// #ifdef H5
// 原生壳桥接：H5 编译器会把 uni.scanCode 静态改写成不支持占位，window.uni 上的 shim 也覆盖不到，
// 因此壳内扫码必须直接经 NativeApp 调用原生摄像扫码。
import { isNativeShell, NativeApp } from '@/utils/h5-native-bridge'
// #endif

/**
 * 二维码格式验证正则
 */
const QR_REGEX = {
  YEFIOT: /^https?:\/\/qrapp\.yefiot\.com\/qr\/yf\?c=.+$/,
  SVR: /^https?:\/\/svr\.yefiot\.com\/xy\?c=.+$/,
  NEW_FORMAT: /^https?:\/\/xy\.yefiot\.com\/public\/dl\/\?c=.+$/,
  YT_FORMAT: /^https?:\/\/svr\.yefiot\.com\/yt\?c=.+$/,
  YULONG: /^https?:\/\/xy\.yefiot\.com\/public\/yulong\/\?c=.+$/,
  FUYOU_DOOR: /^https?:\/\/fuyou\.yefiot\.com\/?\?[^#]*\bc=[^&#]+/i,
  FUYOU_LOCKER: /^https?:\/\/fuyou\.yefiot\.com\/?\?[^#]*\blocker_mac=[^&#]+/i,
  // 裸设备码：福优门锁二维码直接是设备号本体（如 IMEI 样式的纯数字 865530079086732），
  // 与后端 door_qr_code 字段全等匹配，不走 URL 提取。
  BARE_DEVICE: /^[0-9A-Za-z]{6,32}$/
}

const safeDecodeURIComponent = (value = '') => {
  try {
    return decodeURIComponent(value)
  } catch (error) {
    return value
  }
}

const extractQueryParam = (qrString, paramName = 'c') => {
  const raw = String(qrString || '').trim()
  const queryStart = raw.indexOf('?')
  if (queryStart === -1) return ''

  const query = raw.slice(queryStart + 1).split('#')[0]
  const pairs = query.split('&')

  for (const pair of pairs) {
    if (!pair) continue

    const separatorIndex = pair.indexOf('=')
    const rawKey = separatorIndex === -1 ? pair : pair.slice(0, separatorIndex)
    const rawValue = separatorIndex === -1 ? '' : pair.slice(separatorIndex + 1)
    const key = safeDecodeURIComponent(rawKey || '')

    if (key === paramName) {
      return safeDecodeURIComponent(rawValue || '')
    }
  }

  return ''
}

const scanUtils = {
  isDoorQRCode(qrString) {
    const raw = String(qrString || '').trim()
    return QR_REGEX.YEFIOT.test(raw)
      || QR_REGEX.SVR.test(raw)
      || QR_REGEX.NEW_FORMAT.test(raw)
      || QR_REGEX.YT_FORMAT.test(raw)
      || QR_REGEX.YULONG.test(raw)
      || QR_REGEX.FUYOU_DOOR.test(raw)
  },

  isLockerQRCode(qrString) {
    const raw = String(qrString || '').trim()
    return QR_REGEX.FUYOU_LOCKER.test(raw)
  },

  /** 裸设备码（非 URL，直接作为设备号匹配 door_qr_code） */
  isBareDeviceCode(qrString) {
    const raw = String(qrString || '').trim()
    return QR_REGEX.BARE_DEVICE.test(raw) && raw.indexOf('http') !== 0
  },

  /**
   * 检查并申请权限
   * @returns {Promise<boolean>} 是否获得所有权限
   */
  async checkAndRequestPermissions() {
    // #ifdef APP-PLUS
    // iOS权限检查
    if (uni.getSystemInfoSync().platform === 'ios') {
      return new Promise((resolve) => {
        try {
          const AVCaptureDeviceClass = plus.ios.importClass("AVCaptureDevice");
          const status = AVCaptureDeviceClass.authorizationStatusForMediaType('vide');
          
          if (status === 0) {
            // 首次使用，请求权限
            plus.ios.importClass("AVCaptureDevice");
            const result = plus.ios.invoke('AVCaptureDevice', 'requestAccessForMediaType:completionHandler:', 'vide', function(granted) {
              resolve(granted);
            });
          } else if (status === 3) {
            // 已授权
            resolve(true);
          } else {
            // 未授权或已拒绝
            uni.showModal({
              title: '提示',
              content: '请在系统设置中开启相机权限',
              confirmText: '去设置',
              cancelText: '取消',
              success: function(res) {
                if (res.confirm) {
                  try {
                    const UIApplicationClass = plus.ios.importClass("UIApplication");
                    const NSURLClass = plus.ios.importClass("NSURL");
                    const settingsUrl = NSURLClass.URLWithString('app-settings:');
                    const application = UIApplicationClass.sharedApplication();
                    application.openURL(settingsUrl);
                  } catch (e) {
                    console.error('打开设置页面失败:', e);
                  }
                }
              }
            });
            resolve(false);
          }
        } catch (e) {
          console.error('iOS权限检查失败:', e);
          resolve(false);
        }
      });
    }

    // Android权限检查
    const permissionNames = {
      'android.permission.CAMERA': '相机',
      'android.permission.READ_EXTERNAL_STORAGE': '存储',
      'android.permission.BLUETOOTH': '蓝牙',
      'android.permission.ACCESS_FINE_LOCATION': '位置'
    };

    // 检查权限状态
    const checkPermission = (permission) => {
      return new Promise((resolve) => {
        plus.android.requestPermissions(
          [permission],
          function(resultObj) {
            resolve(resultObj.granted.length > 0);
          },
          function(error) {
            console.error('权限检查失败:', error);
            resolve(false);
          }
        );
      });
    };

    // 引导用户去设置页面
    const goToAppSetting = () => {
      return new Promise((resolve) => {
        uni.showModal({
          title: '权限申请',
          content: '请在设置中开启相关权限，以正常使用应用功能',
          confirmText: '去设置',
          cancelText: '取消',
          success: (res) => {
            if (res.confirm) {
              // 跳转到应用设置界面
              const Intent = plus.android.importClass('android.content.Intent');
              const Settings = plus.android.importClass('android.provider.Settings');
              const Uri = plus.android.importClass('android.net.Uri');
              const mainActivity = plus.android.runtimeMainActivity();
              const intent = new Intent();
              intent.setAction(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
              const uri = Uri.fromParts('package', mainActivity.getPackageName(), null);
              intent.setData(uri);
              mainActivity.startActivity(intent);
              resolve(true);
            } else {
              resolve(false);
            }
          }
        });
      });
    };

    // 检查所有权限
    for (let permission in permissionNames) {
      const hasPermission = await checkPermission(permission);
      if (!hasPermission) {
        // 显示权限说明
        uni.showModal({
          title: '需要' + permissionNames[permission] + '权限',
          content: '为了更好的使用体验，请授予' + permissionNames[permission] + '权限',
          success: async (res) => {
            if (res.confirm) {
              const granted = await checkPermission(permission);
              if (!granted) {
                // 如果用户拒绝了权限，引导去设置页面
                await goToAppSetting();
              }
            }
          }
        });
        return false;
      }
    }
    return true;
    // #endif

    // #ifdef H5 || MP
    return true;
    // #endif
  },

  /**
   * 扫描二维码
   * @param {Object} options 配置项
   * @param {Boolean} options.onlyFromCamera 是否只使用相机扫码，默认false
   * @param {Array} options.scanType 扫码类型，默认['qrCode']
   * @returns {Promise<string>} 返回扫码结果，失败返回空字符串
   */
  async scanQRCode(options = {}) {
    // 先检查权限
    const hasPermissions = await this.checkAndRequestPermissions();
    if (!hasPermissions) {
      uni.showToast({
        title: '缺少必要权限',
        icon: 'none'
      });
      return '';
    }

    const { 
      onlyFromCamera = false,
      scanType = ['qrCode']
    } = options

    // #ifdef H5
    if (isNativeShell) {
      try {
        const data = await NativeApp.scanQRCode({ onlyFromCamera, scanType })
        const raw = (data && data.result) || ''
        if (this.validateQRFormat(raw)) {
          return this.extractParamFromQR(raw, 'c')
        } else if (this.isLockerQRCode(raw)) {
          uni.showToast({ title: '这是快递柜二维码，请从快递柜入口进入', icon: 'none', duration: 2200 })
          return ''
        } else if (this.isBareDeviceCode(raw)) {
          // 门锁码直接是设备号本体，原样返回给 scan 页匹配 door_qr_code
          return raw
        } else {
          uni.showToast({ title: '无效的二维码格式', icon: 'none', duration: 2000 })
          return ''
        }
      } catch (error) {
        console.error('扫码失败:', error)
        const msg = (error && (error.msg || error.errMsg || error.message)) || ''
        if (msg.indexOf('cancel') === -1) {
          uni.showToast({ title: '扫描失败', icon: 'none' })
        }
        return ''
      }
    }
    // #endif

    return new Promise((resolve, reject) => {
      uni.scanCode({
        onlyFromCamera,
        scanType,
        success: (res) => {
          console.log('扫码结果:', res)
          
          // 验证二维码格式
          if (scanUtils.validateQRFormat(res.result)) {
            console.log('匹配成功:', res.result);
            // 提取参数 c 的值
            const codeParam = scanUtils.extractParamFromQR(res.result, 'c')
            console.log('提取设备号:', codeParam)
            resolve(codeParam)
          } else if (scanUtils.isLockerQRCode(res.result)) {
            uni.showToast({
              title: '这是快递柜二维码，请从快递柜入口进入',
              icon: 'none',
              duration: 2200
            })
            resolve('')
          } else if (scanUtils.isBareDeviceCode(res.result)) {
            // 门锁码直接是设备号本体，原样返回
            console.log('裸设备码:', res.result)
            resolve(String(res.result).trim())
          } else {
            console.log('匹配失败:', res.result);
            // 如果二维码格式不正确，返回空字符串
            uni.showToast({
              title: '无效的二维码格式',
              icon: 'none',
              duration: 2000
            })
            resolve('')
          }
        },
        fail: (err) => {
          console.error('扫码失败:', err)
          uni.showToast({
            title: '扫描失败',
            icon: 'none'
          })
          resolve('')
        }
      })
    })
  },

  /**
   * 扫描二维码（不校验格式）
   * @param {Object} options 配置项
   * @param {Boolean} options.onlyFromCamera 是否只使用相机扫码，默认false
   * @param {Array} options.scanType 扫码类型，默认['qrCode']
   * @returns {Promise<string>} 返回扫码原始结果，失败返回空字符串
   */
  async scanQRCodeNoValidate(options = {}) {
    // 先检查权限
    const hasPermissions = await this.checkAndRequestPermissions();
    if (!hasPermissions) {
      uni.showToast({
        title: '缺少必要权限',
        icon: 'none'
      });
      return '';
    }

    const { 
      onlyFromCamera = false,
      scanType = ['qrCode']
    } = options

    // #ifdef H5
    if (isNativeShell) {
      try {
        const data = await NativeApp.scanQRCode({ onlyFromCamera, scanType })
        return (data && data.result) || ''
      } catch (error) {
        console.error('扫码失败:', error)
        const msg = (error && (error.msg || error.errMsg || error.message)) || ''
        if (msg.indexOf('cancel') === -1) {
          uni.showToast({ title: '扫描失败', icon: 'none' })
        }
        return ''
      }
    }
    // #endif

    return new Promise((resolve, reject) => {
      uni.scanCode({
        onlyFromCamera,
        scanType,
        success: (res) => {
          console.log('扫码结果(无格式校验):', res)
          // 直接返回原始扫码结果，不进行格式校验
          resolve(res.result || '')
        },
        fail: (err) => {
          console.error('扫码失败:', err)
          uni.showToast({
            title: '扫描失败',
            icon: 'none'
          })
          resolve('')
        }
      })
    })
  },

  /**
   * 验证二维码格式
   * @param {string} qrString 二维码字符串
   * @returns {boolean} 是否为有效格式
   */
  validateQRFormat(qrString) {
    return this.isDoorQRCode(qrString)
  },

  /**
   * 从二维码URL中提取参数值
   * @param {string} qrString 二维码字符串
   * @param {string} paramName 参数名称
   * @returns {string} 参数值，未找到返回空字符串
   */
  extractParamFromQR(qrString, paramName = 'c') {
    return extractQueryParam(qrString, paramName)
  },

  /**
   * 按扫码结果在设备列表中匹配门锁。
   * 兼容三种数据形态（福优线上实际存在历史码制差异）：
   *   1) door_qr_code 直接存裸设备号 → 全等（忽略大小写/首尾空白）
   *   2) door_qr_code 存 URL（?c=设备号）→ 提取 c 参数后比对
   *   3) door_qr_code 为空/不一致，但码内容就是 door_mac（IMEI 样式 15 位）→ 按 door_mac 兜底匹配
   * @param {Array} list 设备列表
   * @param {string} code 扫码得到的设备号
   * @returns {Object|null} 匹配到的设备
   */
  findDeviceByScanCode(list = [], code = '') {
    const target = String(code || '').trim().toLowerCase()
    if (!target) return null
    const eq = (v) => String(v ?? '').trim().toLowerCase() === target

    const direct = (list || []).find(d => eq(d.door_qr_code))
    if (direct) return direct

    const fromUrl = (list || []).find(d =>
      /^https?:/i.test(String(d.door_qr_code || '')) &&
      extractQueryParam(d.door_qr_code, 'c').toLowerCase() === target
    )
    if (fromUrl) return fromUrl

    return (list || []).find(d => eq(d.door_mac)) || null
  }
}

export default scanUtils 


// 基本使用
// const result = await scanUtils.scanQRCode()

// // 自定义选项
// const result = await scanUtils.scanQRCode({
//   onlyFromCamera: false,
//   scanType: ['qrCode', 'barCode']
// })

// // 验证二维码格式
// const isValid = scanUtils.validateQRFormat(qrString)

// // 提取参数
// const code = scanUtils.extractParamFromQR(qrString)
