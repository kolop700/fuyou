<template>
  <view class="workbench-container" :style="{ background: theme.bgPrimary }">
    <view class="ambient-bg"></view>
    <!-- 自定义导航栏 -->
    <custom-navbar title="服务中心" />
    
    <scroll-view 
      class="workbench-content" 
      scroll-y
      :style="{ paddingTop: navbarHeight + 'px', paddingBottom: '120rpx' }"
    >
      <view class="content-wrapper">
        <!-- 门禁服务 -->
        <view class="section">
          <text class="section-title" :style="{ color: theme.textSecondary }">门禁服务</text>
          <view class="feature-grid">
            <view class="feature-item" @click="handleNavigate('/workbench_package/pages/door-list/index')">
              <view class="feature-icon" style="background: linear-gradient(135deg, #3b82f6, #2563eb);">
                <text class="iconfont icon-door-open"></text>
              </view>
              <text class="feature-name" :style="{ color: theme.textPrimary }">远程开门</text>
            </view>
            <view class="feature-item" @click="handleScanCode">
              <view class="feature-icon" style="background: linear-gradient(135deg, #f59e0b, #d97706);">
                <text class="iconfont icon-saoyisao"></text>
              </view>
              <text class="feature-name" :style="{ color: theme.textPrimary }">扫码开门</text>
            </view>
            <view class="feature-item" @click="handleNavigate('/workbench_package/pages/visitor-password/index')">
              <view class="feature-icon" style="background: linear-gradient(135deg, #8b5cf6, #7c3aed);">
                <text class="iconfont icon-fa-key"></text>
              </view>
              <text class="feature-name" :style="{ color: theme.textPrimary }">临时密码</text>
            </view>
            <view class="feature-item" @click="handleNavigate('/workbench_package/pages/qrcode/index')">
              <view class="feature-icon" style="background: linear-gradient(135deg, #ec4899, #db2777);">
                <text class="iconfont icon-th-large"></text>
              </view>
              <text class="feature-name" :style="{ color: theme.textPrimary }">二维码管理</text>
            </view>
          </view>
        </view>
        
        <!-- 生活服务 -->
        <view class="section">
          <text class="section-title" :style="{ color: theme.textSecondary }">生活服务</text>
          <view class="feature-grid">
            <view class="feature-item" @click="handleNavigate('/workbench_package/pages/visitor-password/index')">
              <view class="feature-icon" style="background: linear-gradient(135deg, #10b981, #059669);">
                <text class="iconfont icon-user-friends"></text>
              </view>
              <text class="feature-name" :style="{ color: theme.textPrimary }">访客管理</text>
            </view>
            <view class="feature-item" @click="handleNavigate('/workbench_package/pages/repair/index')">
              <view class="feature-icon" style="background: linear-gradient(135deg, #14b8a6, #0d9488);">
                <text class="iconfont icon-tools"></text>
              </view>
              <text class="feature-name" :style="{ color: theme.textPrimary }">报修服务</text>
            </view>
            <view class="feature-item" @click="handleCallBind">
              <view class="feature-icon" style="background: linear-gradient(135deg, #06b6d4, #0891b2);">
                <text class="iconfont icon-phone"></text>
              </view>
              <text class="feature-name" :style="{ color: theme.textPrimary }">呼叫绑定</text>
            </view>
            <!-- 链接到旧的"我的房屋"页面 -->
            <view class="feature-item" @click="handleNavigate('/pages/device/index')">
              <view class="feature-icon" style="background: linear-gradient(135deg, #6366f1, #4f46e5);">
                <text class="iconfont icon-fa-id-card"></text>
              </view>
              <text class="feature-name" :style="{ color: theme.textPrimary }">房屋认证</text>
            </view>
          </view>
        </view>
        
        <!-- 快递服务 -->
        <view class="section">
          <text class="section-title" :style="{ color: theme.textSecondary }">快递服务</text>
          <view class="feature-grid">
            <view class="feature-item" @click="handleLockerScan">
              <view class="feature-icon" style="background: linear-gradient(135deg, #ef4444, #dc2626);">
                <text class="iconfont icon-box"></text>
              </view>
              <text class="feature-name" :style="{ color: theme.textPrimary }">快递柜</text>
            </view>
            <view class="feature-item" @click="handleNavigate('/workbench_package/pages/courier-application/index')">
              <view class="feature-icon" style="background: linear-gradient(135deg, #22c55e, #16a34a);">
                <text class="iconfont icon-shipping-fast"></text>
              </view>
              <text class="feature-name" :style="{ color: theme.textPrimary }">快递员申请</text>
            </view>
            <view class="feature-item" @click="handleNavigate('/workbench_package/pages/courier-history/index')">
              <view class="feature-icon" style="background: linear-gradient(135deg, #34d399, #059669);">
                <text class="iconfont icon-fa-id-card"></text>
              </view>
              <text class="feature-name" :style="{ color: theme.textPrimary }">快递员申请记录</text>
            </view>
            <view class="feature-item" @click="handleNavigate('/workbench_package/pages/locker/storage-records')">
              <view class="feature-icon" style="background: linear-gradient(135deg, #6366f1, #4f46e5);">
                <text class="iconfont icon-clipboard-list"></text>
              </view>
              <text class="feature-name" :style="{ color: theme.textPrimary }">存取记录</text>
            </view>
            <view class="feature-item" @click="handleNavigate('/workbench_package/pages/locker/settlement-bills')">
              <view class="feature-icon" style="background: linear-gradient(135deg, #f59e0b, #d97706);">
                <text class="iconfont icon-file-invoice-dollar"></text>
              </view>
              <text class="feature-name" :style="{ color: theme.textPrimary }">快递结算单</text>
            </view>
          </view>
        </view>

        <!-- 物业服务
        <view class="section">
          <text class="section-title" :style="{ color: theme.textSecondary }">物业服务</text>
          <view class="feature-grid">
            <view class="feature-item">
              <view class="feature-icon" style="background: linear-gradient(135deg, #f97316, #ea580c);">
                <text class="iconfont icon-bullhorn"></text>
              </view>
              <text class="feature-name" :style="{ color: theme.textPrimary }">社区公告</text>
            </view>
            <view class="feature-item">
              <view class="feature-icon" style="background: linear-gradient(135deg, #0ea5e9, #0284c7);">
                <text class="iconfont icon-phone"></text>
              </view>
              <text class="feature-name" :style="{ color: theme.textPrimary }">物业电话</text>
            </view>
            <view class="feature-item">
              <view class="feature-icon" style="background: linear-gradient(135deg, #a855f7, #9333ea);">
                <text class="iconfont icon-fa-comments"></text>
              </view>
              <text class="feature-name" :style="{ color: theme.textPrimary }">投诉建议</text>
            </view>
          </view>
        </view>
        -->
      </view>
    </scroll-view>
    
    <!-- 自定义底部标签栏 -->
    <custom-tabbar />
  
    <!-- 底部横幅广告（Taku）：常驻页面底部，placementId 为空/开关全关时自动隐藏 -->
    <view class="ad-section ad-tab" v-if="bannerAdId">
      <view class="ad-divider"></view>
      <view class="ad-view">
        <taku-banner :placement-id="bannerAdId"></taku-banner>
      </view>
    </view>
    </view>
</template>

<script setup>
import { computed, ref } from 'vue'
import { onShow, onLoad } from '@dcloudio/uni-app'
import { useThemeStore } from '@/store/modules/theme'
import { useUserStore } from '@/store/modules/user'
import { useThemeVars } from '@/utils/themeConfig'
import { openWechatCallBind } from '@/utils/wechatMiniProgramUtils'
import scanUtils from '@/utils/scanUtils'

const themeStore = useThemeStore()
const userStore = useUserStore()
const theme = computed(() => useThemeVars(themeStore.isDark()))
const navbarHeight = ref(0)

onLoad(() => {
  // 获取系统信息，计算导航栏高度
  const systemInfo = uni.getSystemInfoSync()
  // 状态栏高度 + 导航栏内容高度(44px)
  navbarHeight.value = systemInfo.statusBarHeight + 44
})

onShow(() => {
  uni.hideTabBar({
    animation: false
  })
})

const handleNavigate = (url) => {
  // 统一 navigateTo；失败不再静默（此前 door-list 分包路径写错导致点击无反应无从发现）
  uni.navigateTo({
    url,
    fail: (err) => {
      console.error('[workbench] 页面跳转失败:', url, err)
      uni.showToast({ title: '页面打开失败，请重试', icon: 'none' })
    }
  })
}

const handleScanCode = async () => {
  if (!userStore.checkLogin()) return

  const result = await scanUtils.scanQRCode()
  if (!result) {
    uni.showToast({
      title: '扫码失败，请重试',
      icon: 'none',
      duration: 2000
    })
    return
  }

  uni.navigateTo({
    url: `/pages/door/scan?device_number=${result}`
  })
}

const getLockerIdFromScanResult = (result = '') => {
  const raw = String(result || '').trim()
  if (!raw) return ''

  const match = raw.match(/^https:\/\/fuyou\.yefiot\.com\/?\?(.+)$/i)
  if (!match) return ''

  const params = match[1].split('&').reduce((acc, item) => {
    const [key, value = ''] = item.split('=')
    if (key) {
      acc[decodeURIComponent(key)] = decodeURIComponent(value)
    }
    return acc
  }, {})

  return String(params.locker_mac || '').trim()
}

const handleLockerScan = async () => {
  const result = await scanUtils.scanQRCodeNoValidate()
  const lockerId = getLockerIdFromScanResult(result)

  if (!lockerId) {
    if (scanUtils.isDoorQRCode(result)) {
      uni.showToast({
        title: '这是扫码开门二维码，请从扫码开门入口进入',
        icon: 'none'
      })
      return
    }

    uni.showToast({
      title: '无效的快递柜二维码',
      icon: 'none'
    })
    return
  }

  uni.navigateTo({
    url: `/workbench_package/pages/locker/index?mac=${encodeURIComponent(lockerId)}`
  })
}

const handleCallBind = () => {
  openWechatCallBind(userStore)
}

// ===== Taku 底部横幅广告位 ID（空/全关时不展示；随广告开关自动响应更新） =====
import { computed as __takuComputed, getCurrentInstance as __takuGci } from 'vue'
const __takuInst = __takuGci()
const __takuAdStore = __takuInst.proxy.$store.ad.useAdStore()
const bannerAdId = __takuComputed(() => __takuAdStore.getBannerAdId())
</script>

<style scoped>
.workbench-container {
  min-height: 100vh;
  position: relative;
}

.workbench-content {
  height: 100vh;
  box-sizing: border-box;
}

.content-wrapper {
  padding: 20rpx 32rpx;
}

.section {
  margin-bottom: 48rpx;
}

.section-title {
  font-size: 28rpx;
  font-weight: 600;
  margin-bottom: 32rpx;
  display: block;
}

.feature-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 32rpx;
}

.feature-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16rpx;
}

.feature-item:active {
  opacity: 0.8;
  transform: scale(0.98);
}

.feature-icon {
  width: 112rpx;
  height: 112rpx;
  border-radius: 32rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 4rpx 12rpx rgba(0, 0, 0, 0.1);
}

.feature-icon .iconfont {
  font-size: 48rpx;
  color: #fff;
}

.feature-name {
  font-size: 24rpx;
  text-align: center;

.ambient-bg {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: 
    radial-gradient(circle at 20% 20%, hsla(210, 100%, 70%, 0.08), transparent 40%),
    radial-gradient(circle at 80% 80%, hsla(280, 80%, 70%, 0.05), transparent 40%);
  pointer-events: none;
}
}

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
