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
            <view class="feature-item" @click="handleNavigate('/pages/door-list/index')">
              <view class="feature-icon" style="background: linear-gradient(135deg, #3b82f6, #2563eb);">
                <text class="iconfont icon-door-open"></text>
              </view>
              <text class="feature-name" :style="{ color: theme.textPrimary }">远程开门</text>
            </view>
            <view class="feature-item" @click="handleNavigate('/pages/door/scan')">
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
  if (url === '/pages/device/index') {
    // 特殊处理跳转到房屋页面，因为它是tabbar页面（或者曾经是）
    // 如果它还是tabbar页面，应该用switchTab，但我们即将把它改为普通页面
    // 所以这里用navigateTo是安全的，前提是pages.json改了
    uni.navigateTo({
      url
    })
  } else {
    uni.navigateTo({
      url
    })
  }
}

const getLockerIdFromScanResult = (result = '') => {
  const raw = String(result || '').trim()
  if (!raw) return ''

  try {
    const url = new URL(raw)
    if (url.origin !== 'https://fuyou.yefiot.com') {
      return ''
    }

    if (url.pathname !== '/' && url.pathname !== '') {
      return ''
    }

    const id = url.searchParams.get('locker_id') || url.searchParams.get('lockerId') || url.searchParams.get('id') || url.searchParams.get('c')
    return id && /^\d+$/.test(id) ? id : ''
  } catch (error) {
    return ''
  }
}

const handleLockerScan = async () => {
  const result = await scanUtils.scanQRCodeNoValidate()
  const lockerId = getLockerIdFromScanResult(result)

  if (!lockerId) {
    uni.showToast({
      title: '无效的快递柜二维码',
      icon: 'none'
    })
    return
  }

  uni.navigateTo({
    url: `/workbench_package/pages/locker/index?locker_id=${lockerId}`
  })
}

const handleCallBind = () => {
  openWechatCallBind(userStore)
}
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
</style>
