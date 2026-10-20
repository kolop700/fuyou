<template>
  <view class="container" :style="{ background: theme.bgPrimary }">
    <!-- 环境光背景 -->
    <view class="ambient-bg"></view>
    
    <!-- 自定义导航栏 -->
    <custom-navbar title="门禁二维码" :showBack="true" />

    <!-- 用于分享的隐藏canvas -->
    <canvas
      canvas-id="shareCanvas"
      style="width: 250px; height: 250px; position: fixed; left: -9999px;"
    ></canvas>

    <scroll-view scroll-y class="scroll-content" :style="{ paddingTop: navbarHeight + 'px' }">
      <view class="page-content">
        <!-- 二维码区域 -->
        <view class="qr-section">
          <view class="qr-card" :style="{ background: theme.bgCard, boxShadow: theme.shadowCard }">
            <up-qrcode
              ref="qrcodeRef"
              :size="250"
              :val="qrCodeValue"
              :showLoading="true"
              loadingText="二维码生成中..."
              :background="theme.bgCard"
              :foreground="theme.textPrimary"
              @result="onQRCodeGenerated"
              @longpress="save"
            ></up-qrcode>
            <view class="refresh-btn" @tap="refreshQRCode">
              <text class="iconfont icon-sync-alt" :style="{ color: theme.textSecondary }"></text>
              <text class="refresh-text" :style="{ color: theme.textSecondary }">点击刷新</text>
            </view>
          </view>
        </view>

        <view class="info-section" :style="{ background: theme.bgCard, boxShadow: theme.shadowCard }">
          <view class="info-item">
            <text class="label" :style="{ color: theme.textPrimary }">开门密码</text>
            <view class="value-container">
              <text class="value highlight" :style="{ color: theme.colorAccent }">{{doorPassword}}</text>
              <view class="copy-btn" @tap="copyPassword">
                <text class="iconfont icon-fasfa-copy" :style="{ color: theme.textSecondary }"></text>
              </view>
            </view>
          </view>
          
          <view class="divider" :style="{ background: theme.dividerColor }"></view>
          
          <view class="info-item" @click="showTimesPicker = true">
            <view class="picker-row">
              <text class="label" :style="{ color: theme.textPrimary }">有效次数</text>
              <view class="value-container">
                <text class="value" :style="{ color: theme.textSecondary }">{{ validTimesColumns[gender] }}</text>
                <text class="iconfont icon-arrow-right" :style="{ color: theme.textTertiary }"></text>
              </view>
            </view>
          </view>
          
          <view class="divider" :style="{ background: theme.dividerColor }"></view>
          
          <view class="info-item" @click="showMinutesPicker = true">
            <view class="picker-row">
              <text class="label" :style="{ color: theme.textPrimary }">有效分钟</text>
              <view class="value-container">
                <text class="value" :style="{ color: theme.textSecondary }">{{ validMinutesColumns[min] }}</text>
                <text class="iconfont icon-arrow-right" :style="{ color: theme.textTertiary }"></text>
              </view>
            </view>
          </view>
        </view>

        <!-- Pickers -->
        <up-picker
          :show="showTimesPicker"
          :columns="validTimesColumnsList"
          :defaultIndex="[gender]"
          @confirm="onTimesConfirm"
          @cancel="showTimesPicker = false"
          @close="showTimesPicker = false"
          :confirmColor="theme.colorAccent"
          :cancelColor="theme.textSecondary"
          :bgColor="theme.bgCard"
          :maskStyle="pickerMaskStyle"
        ></up-picker>

        <up-picker
          :show="showMinutesPicker"
          :columns="validMinutesColumnsList"
          :defaultIndex="[min]"
          @confirm="onMinutesConfirm"
          @cancel="showMinutesPicker = false"
          @close="showMinutesPicker = false"
          :confirmColor="theme.colorAccent"
          :cancelColor="theme.textSecondary"
          :bgColor="theme.bgCard"
          :maskStyle="pickerMaskStyle"
        ></up-picker>

        <view class="padding flex flex-direction">
          <button 
            class="cu-btn login-button" 
            :style="{ background: theme.colorAccent, color: '#fff', boxShadow: theme.shadowButton }"
            @tap="shareToFriend"
          >保存到本地相册</button>
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
import { ref, onMounted, nextTick, computed, getCurrentInstance, watch } from 'vue'
import { onLoad } from '@dcloudio/uni-app'
import DoorQRCodeUtils from '@/utils/doorQRCodeUtils'
import ShareUtils from '@/utils/shareUtils'
import { useThemeVars } from '@/utils/themeConfig.js'

const { proxy } = getCurrentInstance()
const themeStore = proxy.$store.theme.useThemeStore()

// 主题变量
const theme = computed(() => useThemeVars(themeStore.isDark()))

// Picker Theme Computed Properties
const pickerBg = computed(() => theme.value.bgCard)
const pickerText = computed(() => theme.value.textPrimary)
const pickerTitle = computed(() => theme.value.textPrimary)
const pickerMaskStyle = computed(() => {
    const bg = theme.value.bgCard
    return `background-image: linear-gradient(180deg, ${bg} 0%, rgba(0,0,0,0) 40%, rgba(0,0,0,0) 60%, ${bg} 100%)`
})

const qrcodeRef = ref(null)
const doorPassword = ref('')
const qrCodeValue = ref('')
const navbarHeight = ref(0)

const showTimesPicker = ref(false)
const showMinutesPicker = ref(false)

// 有效次数选项
const validTimesColumns = ['无限', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10']
const validMinutesColumns = Array.from({ length: 30 }, (_, i) => String(i + 1))

// Columns wrapper for u-picker
const validTimesColumnsList = computed(() => [validTimesColumns])
const validMinutesColumnsList = computed(() => [validMinutesColumns])

// 数据
const gender = ref(0)  // 有效次数索引
const min = ref(4)     // 有效分钟索引

// 生成二维码和密码
const generateQRCode = () => {
  const validTimes = validTimesColumns[gender.value] === '无限' ? 0 : parseInt(validTimesColumns[gender.value])
  const validMinutes = parseInt(validMinutesColumns[min.value])

  const result = DoorQRCodeUtils.generateDoorQRCode({
    validTimes,
    validMinutes
  })

  qrCodeValue.value = result.qrcode
  doorPassword.value = result.tempPassword
}

// 处理有效次数变化
const onTimesConfirm = (e) => {
  gender.value = e.indexs[0]
  generateQRCode()
  showTimesPicker.value = false
}

// 处理有效分钟变化
const onMinutesConfirm = (e) => {
  min.value = e.indexs[0]
  generateQRCode()
  showMinutesPicker.value = false
}

// 刷新二维码
const refreshQRCode = () => {
  qrCodeValue.value = ''
  nextTick(() => {
    generateQRCode()
  })
}

// 二维码生成成功回调
const onQRCodeGenerated = (res) => {
  console.log('二维码生成成功:', res)
}

// 复制密码
const copyPassword = async () => {
  try {
    await ShareUtils.copyToClipboard(doorPassword.value)
    uni.showToast({ title: '密码已复制', icon: 'none' })
  } catch (error) {
    console.error('复制失败:', error)
  }
}

// 保存二维码
const save = async () => {
  try {
    const res = await uni.showModal({
      title: '保存二维码',
      content: '是否保存二维码到相册？',
      confirmColor: theme.value.colorAccent
    })
    
    if (res.confirm) {
      await ShareUtils.saveImageToAlbum(qrCodeValue.value)
    }
  } catch (error) {
    console.error('保存失败:', error)
    uni.showToast({ title: '保存失败', icon: 'none' })
  }
}

// 分享给好友
const shareToFriend = async () => {
  save()
}

// 微信小程序分享配置
// #ifdef MP-WEIXIN
const onShareAppMessage = () => {
  return {
    title: '门禁二维码',
    path: '/pages/qrcode/index',
    imageUrl: qrCodeValue.value
  }
}

const onShareTimeline = () => {
  return {
    title: '门禁二维码',
    query: '',
    imageUrl: qrCodeValue.value
  }
}
// #endif

onLoad(() => {
  themeStore.loadTheme()
  const systemInfo = uni.getSystemInfoSync()
  navbarHeight.value = (systemInfo.statusBarHeight || 0) + 44
  
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

onMounted(() => {
  generateQRCode()
})

// 监听主题变化重新生成二维码以适应前景色
watch(() => theme.value.textPrimary, () => {
  refreshQRCode()
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
  padding: 30rpx;
  padding-bottom: 60rpx;
}

.qr-section {
  display: flex;
  justify-content: center;
  margin-bottom: 40rpx;
}

.qr-card {
  padding: 40rpx;
  border-radius: 24rpx;
  display: flex;
  flex-direction: column;
  align-items: center;
  transition: all 0.3s;
}

.refresh-btn {
  margin-top: 30rpx;
  display: flex;
  align-items: center;
  padding: 10rpx 20rpx;
}

.refresh-text {
  font-size: 26rpx;
  margin-left: 10rpx;
}

.icon-sync-alt {
  font-size: 32rpx;
}

.info-section {
  border-radius: 24rpx;
  padding: 0 30rpx;
  margin-bottom: 60rpx;
  transition: all 0.3s;
}

.info-item {
  height: 110rpx;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.picker-full {
  width: 100%;
}

.picker-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
  height: 110rpx;
}

.label {
  font-size: 30rpx;
  font-weight: 500;
}

.value-container {
  display: flex;
  align-items: center;
}

.value {
  font-size: 30rpx;
  margin-right: 10rpx;
}

.value.highlight {
  font-weight: bold;
  font-size: 34rpx;
  letter-spacing: 2rpx;
}

.copy-btn {
  padding: 10rpx;
  margin-left: 10rpx;
}

.icon-arrow-right {
  font-size: 24rpx;
}

.divider {
  height: 1px;
  width: 100%;
  transform: scaleY(0.5);
}

.login-button {
  width: 100%;
  height: 90rpx;
  line-height: 90rpx;
  border-radius: 45rpx;
  font-size: 32rpx;
  font-weight: 600;
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