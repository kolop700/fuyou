<template>
  <view class="container" :style="{ background: theme.bgPrimary }">
    <!-- 环境光背景 -->
    <view class="ambient-bg"></view>
    
    <!-- 自定义导航栏 -->
    <custom-navbar title="临时访客密码" :showBack="true" />
    
    <scroll-view scroll-y class="scroll-content" :style="{ paddingTop: navbarHeight + 'px' }">
      <view class="page-content">
        <view class="title" :style="{ color: theme.textPrimary }">设备</view>
        <!-- 设备列表 -->
        <view class="device-list">
          <view v-for="(item, index) in deviceList" :key="index" class="device-item">
            <button 
              :class="['cu-btn login-button']" 
              :style="item.selected ? { background: theme.colorAccent, color: '#fff' } : { background: theme.bgInput, color: theme.textSecondary, borderColor: theme.borderColor }"
              @tap="toggleSelection(item.id)"
            >{{ item.name }}</button>
          </view>
        </view>
        
        <view class="divider-botton"></view>
        <view class="divider_40rpx"></view>
        
        <view class="info-section">
          
          <view class="form-group">
            <text class="form-label" :style="{ color: theme.textSecondary }">开始时间</text>
            <view class="input-with-icon" :style="{ background: theme.bgCard }" @click="showStartPicker = true">
              <text class="iconfont icon-clock icon" :style="{ color: theme.textSecondary }"></text>
              <view class="picker-field" :style="{ color: theme.textPrimary }">
                {{ formatDateTime(startDateTime) }}
              </view>
              <text class="iconfont icon-arrow-down picker-arrow" :style="{ color: theme.textSecondary }"></text>
            </view>
            <up-datetime-picker
              ref="startPickerRef"
              :show="showStartPicker"
              v-model="startDateTime"
              mode="datetime"
              :formatter="formatter"
              :min-date="currentTime"
              @confirm="onStartTimeConfirm"
              @cancel="showStartPicker = false"
              @close="showStartPicker = false"
              :show-seconds="true"
              :confirmColor="theme.colorAccent"
              :cancelColor="theme.textSecondary"
              :maskStyle="pickerMaskStyle"
            ></up-datetime-picker>
          </view>

          <view class="form-group">
            <text class="form-label" :style="{ color: theme.textSecondary }">结束时间</text>
            <view class="input-with-icon" :style="{ background: theme.bgCard }" @click="showEndPicker = true">
              <text class="iconfont icon-clock icon" :style="{ color: theme.textSecondary }"></text>
              <view class="picker-field" :style="{ color: theme.textPrimary }">
                {{ formatDateTime(endDateTime) }}
              </view>
              <text class="iconfont icon-arrow-down picker-arrow" :style="{ color: theme.textSecondary }"></text>
            </view>
            <up-datetime-picker
              ref="endPickerRef"
              :show="showEndPicker"
              v-model="endDateTime"
              mode="datetime"
              :formatter="formatter"
              :min-date="startDateTime"
              :max-date="maxEndTime"
              @confirm="onEndTimeConfirm"
              @cancel="showEndPicker = false"
              @close="showEndPicker = false"
              :show-seconds="true"
              :confirmColor="theme.colorAccent"
              :cancelColor="theme.textSecondary"
              :maskStyle="pickerMaskStyle"
            ></up-datetime-picker>
          </view>

          <view class="form-group">
            <text class="form-label" :style="{ color: theme.textSecondary }">有效次数</text>
            <view class="input-with-icon" :style="{ background: theme.bgCard }" @click="showValidTimesPicker = true">
              <text class="iconfont icon-calendar-check icon" :style="{ color: theme.textSecondary }"></text>
              <view class="picker-field" :style="{ color: theme.textPrimary }">
                {{ validTimes }} 次 {{ validTimes == 0 ? '(无限次)' : '' }}
              </view>
              <text class="iconfont icon-arrow-down picker-arrow" :style="{ color: theme.textSecondary }"></text>
            </view>
            <up-picker
              :show="showValidTimesPicker"
              :columns="validTimesColumns"
              :defaultIndex="[validTimes]"
              keyName="text"
              @confirm="onValidTimesConfirm"
              @cancel="showValidTimesPicker = false"
              @close="showValidTimesPicker = false"
              :confirmColor="theme.colorAccent"
              :cancelColor="theme.textSecondary"
              :maskStyle="pickerMaskStyle"
            ></up-picker>
          </view>

          <view class="form-group">
            <text class="form-label" :style="{ color: theme.textSecondary }">开门密码</text>
            <view class="input-with-icon" :style="{ background: theme.bgCard }">
              <text class="iconfont icon-lock icon" :style="{ color: theme.textSecondary }"></text>
              <view class="picker-field" :style="{ color: theme.textPrimary }">
                {{ doorPassword }}
              </view>
              <view class="copy-btn" @tap="copyPassword" :style="{ color: theme.colorAccent }">复制</view>
            </view>
          </view>

        </view>
        <view class="flex flex-direction button-view">
          <button 
            class="cu-btn login-button" 
            :style="{ background: 'transparent', color: theme.colorAccent, border: '1px solid ' + theme.colorAccent }"
            @tap="refresh"
          >刷新</button>
          <button 
            class="cu-btn login-button" 
            :style="{ background: theme.colorAccent, color: '#fff' }"
            @tap="shareKeys"
          >保存并分享钥匙</button>
        </view>
      </view>
    </scroll-view>
  
    <!-- 底部横幅广告（Taku）：常驻页面底部，placementId 为空/开关全关时自动隐藏 -->
    <view class="ad-section" v-if="bannerAdId">
      <view class="ad-divider"></view>
      <view class="ad-view">
        <taku-banner :placement-id="bannerAdId"></taku-banner>
      </view>
    </view>
    </view>
</template>

<script setup>
import { ref, getCurrentInstance, computed, onMounted } from 'vue'
import { onReady, onLoad } from '@dcloudio/uni-app'
import { useThemeVars } from '@/utils/themeConfig.js'
import { formatDoorLocation, formatDoorName } from '@/utils/deviceDisplayUtils.js'

const { proxy } = getCurrentInstance()
const userStore = proxy.$store.user.useUserStore()
const themeStore = proxy.$store.theme.useThemeStore()
const deviceApi = proxy.$api.device

// 主题变量
const theme = computed(() => useThemeVars(themeStore.isDark()))

// Picker Theme Computed Properties
const pickerBg = computed(() => theme.value.bgCard)
const pickerText = computed(() => theme.value.textPrimary)
const pickerTitle = computed(() => theme.value.textPrimary)
const pickerBorder = computed(() => theme.value.borderColor)
const pickerMaskStyle = computed(() => {
    const bg = theme.value.bgCard
    // App-Plus picker mask gradient
    return `background-image: linear-gradient(180deg, ${bg} 0%, rgba(0,0,0,0) 40%, rgba(0,0,0,0) 60%, ${bg} 100%)`
})

const navbarHeight = ref(0)

// 数据定义
const now = new Date()
const end = new Date(now.getTime() + 24 * 60 * 60 * 1000)

const deviceList = ref([])
const startDateTime = ref(now.getTime())
const endDateTime = ref(end.getTime())
const showStartPicker = ref(false)
const showEndPicker = ref(false)
const showValidTimesPicker = ref(false)
const validTimes = ref(0)
const doorPassword = ref(generateRandomPassword())
const startPickerRef = ref(null)
const endPickerRef = ref(null)

// Valid Times Columns for Picker
const validTimesColumns = computed(() => {
  const columns = Array.from({ length: 31 }, (_, i) => ({
    text: i === 0 ? '无限次' : `${i}次`,
    value: i
  }))
  return [columns]
})

// 计算属性
const currentTime = computed(() => Date.now())
const maxEndTime = computed(() => startDateTime.value + (3 * 24 * 60 * 60 * 1000))

// 方法定义
const getDoorDisplayName = (item = {}) => {
  return formatDoorName(item)
}

const getDeviceList = async () => {
  try {
    const response = await deviceApi.getRemoteOpenDoorList(userStore.userId)
    if (response.data && Array.isArray(response.data)) {
      deviceList.value = response.data.map(item => ({
        id: item.door_id,
        name: getDoorDisplayName(item),
        location: formatDoorLocation(item),
        selected: false
      }))
    }
  } catch (error) {
    console.error('获取设备列表失败:', error)
    uni.showToast({
      title: '获取设备列表失败',
      icon: 'none'
    })
  }
}

const toggleSelection = (id) => {
  const index = deviceList.value.findIndex(item => item.id === id)
  if (index !== -1) {
    deviceList.value[index].selected = !deviceList.value[index].selected
    deviceList.value = [...deviceList.value]
  }
}

const getSelectedDevices = () => {
  return deviceList.value.filter(item => item.selected)
}

const onValidTimesConfirm = (e) => {
  validTimes.value = e.value[0].value
  showValidTimesPicker.value = false
}

const copyPassword = () => {
  uni.setClipboardData({
    data: doorPassword.value,
    success: () => {
      uni.showToast({ title: '已复制到剪贴板', icon: 'none' })
    }
  })
}

const formatDateTime = (timestamp) => {
  if (!timestamp) return ''
  const date = new Date(timestamp)
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  const hours = String(date.getHours()).padStart(2, '0')
  const minutes = String(date.getMinutes()).padStart(2, '0')
  const seconds = String(date.getSeconds()).padStart(2, '0')
  return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`
}

const formatter = (type, value) => {
  if (type === 'year') return `${value}年`
  if (type === 'month') return `${value}月`
  if (type === 'day') return `${value}日`
  if (type === 'hour') return `${value}时`
  if (type === 'minute') return `${value}分`
  if (type === 'second') return `${value}秒`
  return value
}

function generateRandomPassword() {
  return String(Math.floor(100000 + Math.random() * 900000))
}

const refresh = () => {
  doorPassword.value = generateRandomPassword()
}

const onStartTimeConfirm = (e) => {
  startDateTime.value = e.value
  showStartPicker.value = false
  
  if (endDateTime.value < startDateTime.value) {
    endDateTime.value = startDateTime.value + (24 * 60 * 60 * 1000)
  }
  if (endDateTime.value > maxEndTime.value) {
    endDateTime.value = maxEndTime.value
  }
}

const onEndTimeConfirm = (e) => {
  endDateTime.value = e.value
  showEndPicker.value = false
}

const shareKeys = async () => {
  if (endDateTime.value > maxEndTime.value) {
    uni.showToast({
      title: '结束时间不能超过开始时间后3天',
      icon: 'none'
    })
    return
  }
  
  const selectedDevices = getSelectedDevices()
  if (selectedDevices.length === 0) {
    uni.showToast({
      title: '请选择至少一个设备',
      icon: 'none'
    })
    return
  }

  try {
    // 处理设备ID列表
    const doorPhoneId = selectedDevices.map(device => device.id).join(',') + ','
    
    // 处理时间格式
    const startTime = formatDateTime(startDateTime.value)
    const endTime = formatDateTime(endDateTime.value)
    
    // 处理次数转换：0 或 '0' 转为 -1，其他数字保持不变
    const times = validTimes.value === 0 || validTimes.value === '0' ? -1 : parseInt(validTimes.value)
    
    const params = {
      doorPhoneId,
      userId: userStore.userId,
      startTime,
      endTime,
      times,
      tempkey: parseInt(doorPassword.value)
    }
    const response = await deviceApi.saveTempKey(params)
    if (response.code === '0') {
      // 构建提示消息
      const deviceLocations = selectedDevices.map(device => device.location || device.name).join('、')
      const message = `临时访客密码\n适用位置：${deviceLocations}\n尊敬的访客朋友您好! 请您在规定的时间内,使用app扫描设备上的二维码并输入临时访问密钥,开启相应的通行权限。时间为${startTime}至${endTime}, 您的临时开门密码为:${doorPassword.value}`
      // 显示模态框
      uni.showModal({
        title: '临时访客密码',
        content: message,
        showCancel: true,
        cancelText: '关闭',
        confirmText: '复制内容',
        success: function (res) {
          if (res.confirm) {
            uni.setClipboardData({
              data: message,
              success: function () {
                uni.showToast({
                  title: '复制成功',
                  icon: 'success'
                })
              }
            })
          }
        }
      })
      refresh() // 刷新密码
    } else {
      throw new Error('保存失败')
    }
  } catch (error) {
    console.error('保存访客密码失败:', error)
    uni.showToast({
      title: '设置失败，请重试',
      icon: 'none'
    })
  }
}

// 生命周期钩子
onMounted(() => {
  getDeviceList()
})

onLoad(() => {
  // 加载主题设置
  themeStore.loadTheme()
  
  // 计算导航栏高度
  const systemInfo = uni.getSystemInfoSync()
  const statusBarHeight = systemInfo.statusBarHeight || 0
  // #ifdef MP-WEIXIN
  const menuButtonInfo = uni.getMenuButtonBoundingClientRect()
  navbarHeight.value = statusBarHeight + menuButtonInfo.height + (menuButtonInfo.top - statusBarHeight) * 2
  // #endif
  // #ifdef APP-PLUS || H5
  navbarHeight.value = statusBarHeight + 44
  // #endif
  
  // #ifdef H5
  // Update CSS variables for H5 pickers
  const updatePickerStyles = () => {
    if (typeof document !== 'undefined') {
      const bg = theme.value.bgCard
      const text = theme.value.textPrimary
      const border = theme.value.borderColor
      document.body.style.setProperty('--picker-bg-card', bg)
      document.body.style.setProperty('--picker-text-color', text)
      document.body.style.setProperty('--picker-border-color', border)
    }
  }
  
  updatePickerStyles()
  watch(theme, updatePickerStyles, { deep: true })
  // #endif
})

onReady(() => {
  startPickerRef.value?.setFormatter?.(formatter)
  endPickerRef.value?.setFormatter?.(formatter)
})

// ===== Taku 底部横幅广告位 ID（空/全关时不展示；随广告开关自动响应更新） =====
import { computed as __takuComputed, getCurrentInstance as __takuGci } from 'vue'
const __takuInst = __takuGci()
const __takuAdStore = __takuInst.proxy.$store.ad.useAdStore()
const bannerAdId = __takuComputed(() => __takuAdStore.getBannerAdId())
</script>

<style scoped>
@import '@/static/fonts/iconfont.css';

.container {
  width: 100%;
  min-height: 100vh;
  position: relative;
  overflow: hidden;
}

.ambient-bg {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  pointer-events: none;
  z-index: 0;
  background: 
    radial-gradient(circle at 20% 20%, hsla(200, 80%, 50%, 0.15), transparent 40%),
    radial-gradient(circle at 80% 80%, hsla(280, 60%, 40%, 0.1), transparent 40%);
}

.scroll-content {
  height: 100vh;
  box-sizing: border-box;
  position: relative;
  z-index: 1;
}

.page-content {
  padding-bottom: 60rpx;
}

.title {
  padding-left: 24rpx;
  padding-top: 30rpx;
  font-family: PingFang SC, PingFang SC;
  font-weight: 800;
  font-size: 34rpx;
  line-height: 34rpx;
  text-align: left;
  margin-bottom: 20rpx;
}

.device-list {
  padding: 0 32rpx;
  max-height: 400rpx;
  overflow-y: auto;
}

.device-item {
  margin-bottom: 20rpx;
}

.login-button {
  padding: 0 30rpx;
  height: 84rpx;
  width: 100%;
  font-family: PingFang SC, PingFang SC;
  font-weight: 500;
  font-size: 28rpx;
  line-height: 84rpx;
  border-radius: 12rpx;
}

.divider-botton {
  width: 100%;
  height: 40rpx;
}

.info-section {
  padding: 0 32rpx;
}

.form-group {
  margin-bottom: 30rpx;
}

.form-label {
  display: block;
  font-size: 28rpx;
  font-weight: 500;
  margin-bottom: 16rpx;
  padding-left: 10rpx;
}

.input-with-icon {
  display: flex;
  align-items: center;
  border-radius: 12rpx;
  height: 100rpx;
  padding: 0 30rpx;
  position: relative;
  transition: all 0.3s;
}

.icon {
  font-size: 36rpx;
  margin-right: 20rpx;
}

.picker-field {
  flex: 1;
  font-size: 30rpx;
}

.picker-arrow {
  font-size: 28rpx;
  margin-left: 10rpx;
}

.copy-btn {
  font-size: 28rpx;
  font-weight: 500;
  padding: 10rpx 20rpx;
}

.button-view {
  margin-top: 60rpx;
  padding: 0 32rpx;
  display: flex;
  flex-direction: column;
  gap: 30rpx;
}

.divider_40rpx {
  height: 40rpx;
}

/* Picker Dark Mode Support */
:deep(.u-popup__content) {
  background-color: v-bind(pickerBg) !important;
}
:deep(.u-picker) {
  background-color: v-bind(pickerBg) !important;
}
:deep(.u-picker__view) {
  background-color: v-bind(pickerBg) !important;
}
:deep(.u-picker__view__column__item) {
  color: v-bind(pickerText) !important;
}
:deep(.u-toolbar) {
  background-color: v-bind(pickerBg) !important;
}
:deep(.u-toolbar__title) {
  color: v-bind(pickerTitle) !important;
}

/* #ifdef H5 */
:global(.u-popup .u-toolbar) {
  background-color: var(--picker-bg-card) !important;
}
:global(.u-popup .u-toolbar__title) {
  color: var(--picker-text-color) !important;
}
:global(.u-popup .u-toolbar__wrapper__cancel) {
  color: var(--picker-border-color) !important;
}
:global(.u-picker__view) {
  background-color: var(--picker-bg-card) !important;
}
:global(.u-picker-column-item) {
  color: var(--picker-text-color) !important;
}
/* #endif */
</style>

<!-- Non-scoped styles for H5 Picker overrides -->
<style>
/* #ifdef H5 */
.uni-picker-view-mask {
  background-image: linear-gradient(180deg, var(--picker-bg-card) 0%, rgba(0,0,0,0) 40%, rgba(0,0,0,0) 60%, var(--picker-bg-card) 100%) !important;
}

.uni-picker-view-indicator::before,
.uni-picker-view-indicator::after {
  border-color: var(--picker-border-color) !important;
}

.u-picker__view__column__item {
  color: var(--picker-text-color) !important;
}
/* #endif */

/* ===== Taku 底部横幅广告 ===== */
.ad-section {
  position: fixed;
  left: 0;
  right: 0;
  bottom: 0;
  z-index: 20;
  width: 100%;
  box-sizing: border-box;
  background: #ffffff;
  box-shadow: 0 -6rpx 20rpx rgba(31, 48, 152, 0.08);
}

.ad-section .ad-divider {
  height: 2rpx;
  background: #eeeeee;
}

.ad-section .ad-view {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 120rpx;
  padding: 8rpx 0;
}

/* Tab 页：横幅悬浮在自定义 tabbar（高100rpx+安全区）上方 */
.ad-section.ad-tab {
  bottom: calc(100rpx + env(safe-area-inset-bottom));
  box-shadow: 0 -4rpx 16rpx rgba(31, 48, 152, 0.12);
}
</style>
