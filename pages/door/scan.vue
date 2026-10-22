<template>
  <view class="container">
    <!-- 设备号显示 -->
    <view class="device-number">{{deviceNumber}}</view>
    <text class="tip-text">{{searchStatus}}</text>
    <!-- 开门按钮区域 -->
    <view class="door-control">
      <view class="door-button" @click="openDoor">
        <text>一键开门</text>
      </view>
	  <view class="door-ble-button" @click="openBleDoor" v-if="isDeviceFound">
	    <text>蓝牙开门</text>
	  </view>
    </view>

    <!-- 访客密码区域 -->
    <view class="visitor-section">
      <text class="section-title">访客密钥</text>
      <input 
        type="number" 
        v-model="visitorPassword"
        placeholder="请输入访客密码"
        class="custom-input"
      />
      <view class="button-container">
            <button 
              class="cu-btn login-button bg-red"
              :class="{'secondary': !isFormValid}"
              @click="openDoorWithPassword"
              type="submit"
            >提交申请</button>
          </view>
    </view>
	<!-- 底部横幅广告（Taku）：常驻页面底部（fixed，不随滚动移动） -->
	<view class="ad-section" v-if="bannerAdId">
	  <view class="ad-divider"></view>
	  <view class="ad-view">
	    <taku-banner :placement-id="bannerAdId"></taku-banner>
	  </view>
	</view>
  </view>
</template>

<script setup>
import { ref, getCurrentInstance, computed, inject, onMounted } from 'vue'
import { storeToRefs } from 'pinia'
const { proxy } = getCurrentInstance()
import { onLoad } from '@dcloudio/uni-app'
const adStore = proxy.$store.ad.useAdStore()
const adControlStore = proxy.$store.adControl.useAdControlStore()
import doorAccessUtils from '@/utils/doorAccessUtils'
import scanUtils from '@/utils/scanUtils'
import visitorPasswordUtils from '@/utils/visitorPasswordUtils'
import { adManager } from '@/utils/adUtils'
// 横幅广告位 ID（Taku placementId，空/全关时不展示；随开关自动响应更新）
const bannerAdId = computed(() => adStore.getBannerAdId())
// 注入蓝牙实例
const doorBleUtils = inject('doorBleUtils')

const deviceStore = proxy.$store.device.useDeviceStore()
const deviceApi = proxy.$api.device
const { deviceList } = storeToRefs(deviceStore)
const deviceNumber = ref('')
const visitorPassword = ref('')
const matchedDevice = ref(null)
// 本次扫码是否为 fuyou /c?auto= 免授权码（是才允许查库免授权直开）
const isAutoCode = ref(false)

// 添加 userStore
const userStore = proxy.$store.user.useUserStore()

// 添加设备搜索状态
const searchStatus = ref('正在搜索设备...')
const isDeviceFound = ref(false)

// 判断表单是否有效的计算属性
const isFormValid = computed(() => {
  return visitorPassword.value.length >= 6 && /^\d+$/.test(visitorPassword.value)
})

const setDeviceNumber = (number) => {
  deviceNumber.value = number
  matchedDevice.value = null
  isDeviceFound.value = false
  searchStatus.value = '正在搜索设备...'
  console.log('设备号:', deviceNumber.value)

  // 容错匹配：door_qr_code 裸号 / URL 提参 / door_mac 兜底（历史码制差异）
  const device = scanUtils.findDeviceByScanCode(deviceList.value, deviceNumber.value)
  if (device) {
    matchedDevice.value = device
  } else if (!isAutoCode.value) {
    // 免授权码不在授权列表属正常（点开门时查库直开），不弹误导提示
    uni.showToast({
      title: '未找到匹配的设备',
      icon: 'none'
    })
  }
}

// 页面加载时获取设备号和查找设备
onLoad((options) => {
  // 先读免授权码标记（scanQRCode 扫码时置位，读取后重置）
  isAutoCode.value = scanUtils.isAutoScanResult(true)
  console.log('是否免授权码(/c?auto=):', isAutoCode.value)
  if (options.device_number) {
    setDeviceNumber(options.device_number)
  }
  console.log('设备列表:', deviceList.value)
  console.log('匹配的设备:', matchedDevice.value)

  // 初始化广告管理器（预加载激励/插屏广告）
  adManager.initStore(adStore, adControlStore)
  adManager.init()
})

// 搜索设备
const searchDevice = async () => {
  if (!deviceNumber.value) {
    uni.showToast({
      title: '设备号不能为空',
      icon: 'none'
    })
    return
  }

  try {
    // 初始化蓝牙
    if (!doorBleUtils) {
      throw new Error('蓝牙模块未初始化')
    }
    await doorBleUtils.bleUtils.initBluetooth()
    
    // 开始搜索设备
    searchStatus.value = '点击下面按钮开门，正在搜索设备...'
    isDeviceFound.value = false
    
    await doorBleUtils.bleUtils.startBluetoothDevicesDiscovery()
    
    // 监听设备
    const targetDeviceName = 'BMXWL' + deviceNumber.value
    
    // 设置超时
    const timeout = setTimeout(() => {
      if (!isDeviceFound.value) {
        searchStatus.value = '未找到设备，请确保设备在范围内'
        doorBleUtils.bleUtils.stopBluetoothDevicesDiscovery()
      }
    }, 10000)
    
    uni.onBluetoothDeviceFound(res => {
      res.devices.forEach(device => {
        if (device.name === targetDeviceName || device.localName === targetDeviceName) {
          clearTimeout(timeout)
          isDeviceFound.value = true
          searchStatus.value = '点击下面按钮开门，蓝牙设备已找到'
          // 保存找到的设备信息
          if (!matchedDevice.value) {
            const foundDevice = scanUtils.findDeviceByScanCode(deviceList.value, deviceNumber.value)
            if (foundDevice) {
              matchedDevice.value = foundDevice
              // 找到设备后停止搜索
              doorBleUtils.bleUtils.stopBluetoothDevicesDiscovery()
            }
          }
        }
      })
    })
  } catch (error) {
    console.error('搜索设备失败:', error)
    searchStatus.value = '点击下面按钮开门'
    isDeviceFound.value = false
  }
}

// 页面加载时开始搜索
onMounted(() => {
  if (deviceNumber.value) {
    searchDevice()
  }
})

// 直接开门
const openDoor = async () => {
  if (!deviceNumber.value) {
    uni.showToast({
      title: '设备号不能为空',
      icon: 'none'
    })
    return
  }

  try {
    // 查找匹配的设备（容错匹配，与 setDeviceNumber 同源）
    if (!matchedDevice.value) {
      const device = scanUtils.findDeviceByScanCode(deviceList.value, deviceNumber.value)
      if (device) {
        matchedDevice.value = device
      }
    }

    // 免授权开门：仅当扫的是 fuyou /c?auto= 码时，按设备码查库直开（门需 allow_qr_open=1）
    if (!matchedDevice.value && isAutoCode.value) {
      try {
        const res = await deviceApi.getDoorByScanCode(deviceNumber.value, { showLoading: false })
        const rows = res && Array.isArray(res.data) ? res.data : []
        if (rows.length > 0 && rows[0].door_mac) {
          matchedDevice.value = rows[0]
          console.log('免授权开门(auto码)：已查库匹配到设备', matchedDevice.value)
        }
      } catch (queryError) {
        console.error('查门设备失败:', queryError)
      }
    }

    if (!matchedDevice.value) {
      uni.showToast({
        title: isAutoCode.value ? '未找到该门设备或门未开启扫码开门' : '设备未授权',
        icon: 'none'
      })
      return
    }

    // 优先尝试网络开门
    try {
      console.log('尝试网络开门')
      uni.showLoading({
        title: '正在开门...',
        mask: true
      })
      await doorAccessUtils.openDoor(matchedDevice.value)
      uni.hideLoading()
      uni.showToast({
        title: '开门成功',
        icon: 'success'
      })
      // 开门成功后展示广告
      try {
        // 先尝试展示激励广告
        const adResult = await adManager.showAd()
        if (!adResult) {
          console.log('广告展示受限：可能达到每日限制或间隔时间不足')
        }
      } catch (error) {
        console.error('广告展示失败:', error)
      }
    } catch (networkError) {
      uni.hideLoading()
      console.error('网络开门失败:', networkError)
      console.log('尝试蓝牙开门')
      // 网络开门失败后尝试蓝牙开门
      if (!doorBleUtils) {
        throw new Error('蓝牙模块未初始化')
      }
      await doorBleUtils.openDoorWithBle(matchedDevice.value, userStore.userId)
      // 蓝牙开门成功后显示成功提示
      uni.showToast({
        title: '开门成功',
        icon: 'success'
      })
      // 蓝牙开门成功后展示广告
      try {
        // 先尝试展示激励广告
        const adResult = await adManager.showAd()
        if (!adResult) {
          console.log('广告展示受限：可能达到每日限制或间隔时间不足')
        }
      } catch (error) {
        console.error('广告展示失败:', error)
      }
    }
  } catch (error) {
    uni.hideLoading()
    console.error('开门失败:', error)
    uni.showToast({
      title: '开门失败，请重试',
      icon: 'none',
      duration: 2000
    })
  }
}

// 修改蓝牙开门函数
const openBleDoor = async () => {
  if (!isDeviceFound.value) {
    uni.showToast({
      title: '请等待设备搜索完成',
      icon: 'none'
    })
    return
  }
  
  if (!deviceNumber.value) {
    uni.showToast({
      title: '设备号不能为空',
      icon: 'none'
    })
    return
  }

  try {
    uni.showLoading({
      title: '正在开门...',
      mask: true
    })

    if (!doorBleUtils) {
      throw new Error('蓝牙模块未初始化')
    }
    await doorBleUtils.openDoorWithBle(matchedDevice.value, userStore.userId)
    
    uni.hideLoading()
    uni.showToast({
      title: '开门成功',
      icon: 'success'
    })
    // 开门成功后展示广告
    try {
      // 先尝试展示激励广告
      const adResult = await adManager.showAd()
      if (!adResult) {
        console.log('广告展示受限：可能达到每日限制或间隔时间不足')
      }
    } catch (error) {
      console.error('广告展示失败:', error)
    }
  } catch (error) {
    uni.hideLoading()
    console.error('蓝牙开门失败:', error)
    uni.showToast({
      title: '开门失败，请重试',
      icon: 'none',
      duration: 2000
    })
  }
}

// 访客密码接口用的 qrcode：后端按 door_qr_code 字段查门（老小程序实测成功格式），
// 而扫到的码内容可能是 door_mac 裸号，故优先用匹配到设备在库里的 door_qr_code，兜底用扫码原值
const getQrCodeForApi = () => {
  const stored = String(matchedDevice.value?.door_qr_code || '').trim()
  return stored || deviceNumber.value
}

// 验证访客密码
const verifyVisitorPassword = async () => {
  if (!deviceNumber.value) {
    uni.showToast({
      title: '设备号不能为空',
      icon: 'none'
    })
    return false
  }

  if (!visitorPassword.value) {
    uni.showToast({
      title: '请输入访客密码',
      icon: 'none'
    })
    return false
  }

  // 获取新的序列号
  const sn = deviceStore.getSerialNo()
  
  // 处理密码值：如果是0或'0'，转换为-1；其余保持字符串传参（与老小程序成功调用格式一致）
  const password = visitorPassword.value === '0' || visitorPassword.value === 0 ? -1 : String(visitorPassword.value)
  
  // 调用访客密码验证接口
  return await visitorPasswordUtils.verifyPassword({
    password: password,
    deviceNumber: getQrCodeForApi(),
    sn: sn
  })
}

// 使用访客密码开门
const openDoorWithPassword = async () => {
  const verifyResult = await verifyVisitorPassword()
  if (!verifyResult.success) return
  
  try {
    uni.showLoading({
      title: '正在开门...',
      mask: true
    })
    // 验证成功后，调用开门接口（qrcode 与校验时保持同一口径；
    // openid 传校验命中的密码主人 user_WeChat_id，后端据此查权限下发开门指令）
    const openResult = await visitorPasswordUtils.openDoor({
      deviceNumber: getQrCodeForApi(),
      sn: verifyResult.sn,
      openid: (verifyResult.doorInfo && verifyResult.doorInfo.user_WeChat_id) || '0'
    })
    
    uni.hideLoading()
    // openDoor 内部已按设备回执弹成功/失败提示，失败时不再叠加通用文案
    if (!openResult) return
    
    // 开门成功后展示广告
    try {
      // 先尝试展示激励广告
      const adResult = await adManager.showAd()
      if (!adResult) {
        console.log('广告展示受限：可能达到每日限制或间隔时间不足')
      }
    } catch (error) {
      console.error('广告展示失败:', error)
    }
  } catch (error) {
    uni.hideLoading()
    console.error('访客密码开门失败:', error)
    uni.showToast({
      title: '开门失败，请重试',
      icon: 'none',
      duration: 2000
    })
  }
}
</script>

<style lang="scss" scoped>
.container {
  min-height: 100vh;
  background-color: #FFFFFF;
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 40rpx 40rpx 0;
  box-sizing: border-box;
}

.device-number {
  font-size: 32rpx;
  color: #333333;
  margin-bottom: 10rpx;
}

.door-control {
  display: flex;
  flex-direction: column;
  align-items: center;
  margin-bottom: 30rpx;
}

.door-button {
  width: 250rpx !important;
  height: 250rpx !important;
  background-image: url('/static/icons/icon_open_door.png'); 
  background-size: cover; 
  background-position: center; 
  border: none; 
  border-radius: 50%; 
  color: white; 
  font-size: 36rpx; 
  line-height: 250rpx; 
  text-align: center; 
  cursor: pointer; 
  transition: all 0.2s ease;
  transform: scale(1);
  
  &:active {
    transform: scale(0.85);
  }
  
  text {
    color: #FFFFFF;
    font-size: 36rpx;
    font-weight: bold;
  }
}

.door-ble-button {
  margin-top: 20rpx;
  width: 250rpx !important;
  height: 250rpx !important;
  background-image: url('/static/icons/icon_o_door.png'); 
  background-size: cover; 
  background-position: center; 
  border: none; 
  border-radius: 50%; 
  color: white; 
  font-size: 36rpx; 
  line-height: 250rpx; 
  text-align: center; 
  cursor: pointer; 
  transition: all 0.2s ease;
  transform: scale(1);
  
  &:active {
    transform: scale(0.85);
  }
  
  text {
    color: #FFFFFF;
    font-size: 36rpx;
    font-weight: bold;
  }
}

.tip-text {
  font-size: 28rpx;
  color: #999999;
  margin-bottom: 20rpx;
}

.visitor-section {
  width: 100%;
  border-radius: 20rpx;
  box-sizing: border-box;
  margin-bottom: auto;
}

.section-title {
  font-size: 32rpx;
  color: #333333;
  margin-bottom: 30rpx;
  display: block;
}

.custom-input {
  border: 1px solid #ddd;
  border-radius: 8rpx;
  margin-bottom: 20rpx;
  background: #F9F9F9;
  height: 100rpx;
  display: flex;
  align-items: center;
  padding: 0 30rpx;
  font-size: 30rpx;
  line-height: 30rpx;
  box-sizing: border-box;
  width: 100%;
}

.button-container {
  display: flex;
  width: 100%;
  justify-content: center;
  margin-top: 10rpx;
}

.login-button {
  width: 100%;
  height: 88rpx;
  line-height: 88rpx;
  font-size: 32rpx;
  text-align: center;
  font-weight: bold;
  border-radius: 8rpx;
}

.login-button.secondary {
  background-color: #FCA5A7;
}
/* ===== 底部横幅广告（Taku）：常驻页面底部 ===== */
.ad-section {
  position: fixed;
  left: 24rpx;
  right: 24rpx;
  bottom: 0;
  z-index: 20;
  background: #ffffff;
  border-radius: 24rpx 24rpx 0 0;
  box-shadow: 0 -6rpx 20rpx rgba(74, 108, 247, 0.08);
  box-sizing: border-box;

  .ad-divider {
    height: 2rpx;
    background: #EEEEEE;
  }

  .ad-view {
    display: flex;
    justify-content: center;
    align-items: center;
  }
}
</style>
