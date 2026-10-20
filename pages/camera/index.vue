<template>
  <view class="page-container">
    <!-- 顶部标题 -->
    <view class="user-header">
      <text>摄像头列表</text>
      <view class="header-icons">
        <view class="scan-icon" @click="handleScanCode">
          <image src="/static/icons/icon_opendoor_code.png" mode="aspectFit"></image>
        </view>
        <view class="refresh-icon" :class="{ 'rotating': isRotating }" @click="getCameraList">
          <image src="/static/icons/icon_refresh.png" mode="aspectFit"></image>
        </view>
      </view>
    </view>

    <!-- 内容区域 -->
    <view class="content-wrapper">
      <!-- 扫码结果区域 -->
      <view v-if="scanResult" class="scan-result-box">
        <view class="scan-result-title">扫码结果</view>
        <view class="scan-result-content">{{ scanResult }}</view>
      </view>
      
      <button class="custom-btn" @click="getCameraList">获取摄像头列表</button>
      
      <!-- 错误信息区域 -->
      <view v-if="errorInfo" class="error-box">
        <view class="error-title">错误信息:</view>
        <view class="error-message">{{ errorInfo.message }}</view>
        <view v-if="errorInfo.code" class="error-detail">错误码: {{ errorInfo.code }}</view>
        <view v-if="errorInfo.path" class="error-detail">请求路径: {{ errorInfo.path }}</view>
      </view>
      
      <view v-if="cameraList.length === 0 && !errorInfo" class="empty-tip">
        暂无摄像头，请点击上方按钮获取
      </view>
      <view v-if="cameraList.length > 0">
        <view class="camera-list">
          <view class="camera-item" v-for="item in cameraList" :key="item.device_id">
            <view class="camera-info">
              <text class="camera-name">{{ item.device_name || '未命名设备' }}</text>
              <text class="camera-id">ID: {{ item.device_id }}</text>
              <text class="camera-type">类型: {{ item.category_name || item.product_name }}</text>
            </view>
          </view>
        </view>
      </view>
    </view>
  
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
import { ref, onMounted, getCurrentInstance } from 'vue'
import { fetchDeviceList } from '@/utils/tangeDevice.js'
import scanUtils from '@/utils/scanUtils'

const cameraList = ref([])
const isRotating = ref(false)
const errorInfo = ref(null)
const scanResult = ref('')

// 获取当前实例和用户状态
const { proxy } = getCurrentInstance()
const userStore = proxy?.$store?.user?.useUserStore?.()

// 组件挂载时初始化
onMounted(() => {
  console.log('摄像头页面已加载')
  
  // 直接设置设备 token
  if (userStore) {
    // 设置设备访问令牌
    userStore.setDeviceToken('eyJhbGciOiJFZERTQSIsImtpZCI6Im8xWnkzWE5TSGhxOCIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxOTczMTYwMyIsImlzcyI6ImFwcC9sb2dpbiIsImlhdCI6MTc1MTQyNjk4OSwiZXhwIjoxNzU0MDE4OTg5LCJhdWQiOlsiYXBwL2JhY2tlbmQiXSwidWlkIjoxOTczMTYwMywiYXBwX2lkIjoiQURfMmZEYThETExYb0ZnS3Q5d3VZd0pCWFg4YVlaIn0.mqY5xfTy3miD-7F1m-PT36bLpMAq9SvQjKEdLBiXi8yxNieEYyh5_tYrGYti843ShN-z63BL_090Z6x9KyVFCg')
    // 设置设备用户ID
    userStore.setDeviceUserId('19731603')
    console.log('已设置设备 token 和用户ID')
  }
})

// 处理扫码功能
const handleScanCode = async () => {
  try {
    // 使用不校验格式的扫码方法
    const result = await scanUtils.scanQRCodeNoValidate()
    console.log('摄像头页面扫码结果:', result)
    
    if (result) {
      // 将扫码结果保存而不是跳转
      scanResult.value = result
      uni.showToast({
        title: '扫码成功',
        icon: 'success'
      })
    } else {
      uni.showToast({
        title: '扫码结果为空',
        icon: 'none'
      })
    }
  } catch (error) {
    console.error('扫码错误:', error)
    uni.showToast({
      title: '扫码发生错误',
      icon: 'none'
    })
  }
}

const getCameraList = async () => {
  if (isRotating.value) return
  isRotating.value = true
  errorInfo.value = null // 清除之前的错误
  
  try {
    // 使用工具类获取设备列表，token 会自动从 user store 获取
    cameraList.value = await fetchDeviceList({ offset: 0, limit: 20 })
    console.log('设备列表', cameraList.value)
    if (cameraList.value.length === 0) {
      uni.showToast({
        title: '暂无摄像头设备',
        icon: 'none'
      })
    }
  } catch (e) {
    // 详细记录错误信息
    console.error('获取设备列表错误:', e)
    
    // 保存错误信息
    errorInfo.value = {
      message: e.message || '获取设备列表失败',
      code: e.code,
      path: e.requestPath
    }
    
    // 显示错误提示
    uni.showToast({
      title: '获取失败，查看详情',
      icon: 'none'
    })
  } finally {
    setTimeout(() => {
      isRotating.value = false
    }, 1000)
  }
}

// ===== Taku 底部横幅广告位 ID（空/全关时不展示；随广告开关自动响应更新） =====
import { computed as __takuComputed, getCurrentInstance as __takuGci } from 'vue'
const __takuInst = __takuGci()
const __takuAdStore = __takuInst.proxy.$store.ad.useAdStore()
const bannerAdId = __takuComputed(() => __takuAdStore.getBannerAdId())
</script>

<style lang="scss">
.page-container {
  height: 100vh;
  display: flex;
  flex-direction: column;
  padding: 10rpx;
  box-sizing: border-box;
  overflow: hidden;
}

.user-header {
  height: 6vh;
  min-height: 70rpx;
  flex: none;
  display: flex;
  align-items: center;
  padding-left: 20rpx;
  position: relative;
  justify-content: space-between;

  text {
    font-size: calc(12px + 0.5vh);
    font-weight: bold;
  }
  
  .header-icons {
    display: flex;
    align-items: center;
  }

  .scan-icon {
    width: 80rpx;
    height: 80rpx;
    display: flex;
    align-items: center;
    justify-content: center;
    margin-right: 10rpx;
    
    image {
      width: 60%;
      height: 60%;
    }
  }

  .refresh-icon {
    width: 80rpx;
    height: 80rpx;
    display: flex;
    align-items: center;
    justify-content: center;
    image {
      width: 100%;
      height: 100%;
    }
    &.rotating {
      animation: rotate 1s linear;
    }
  }
}

@keyframes rotate {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}

.content-wrapper {
  flex: 1;
  display: flex;
  flex-direction: column;
  justify-content: flex-start;
  align-items: center;
  padding-top: 40rpx;
}

.custom-btn {
  width: 80%;
  height: 80rpx;
  background: #FF0036;
  color: #fff;
  border-radius: 40rpx;
  font-size: 32rpx;
  margin-bottom: 40rpx;
}

.empty-tip {
  color: #999;
  margin-top: 40rpx;
  text-align: center;
  font-size: 28rpx;
}

.error-box {
  width: 90%;
  padding: 20rpx;
  margin-bottom: 30rpx;
  background-color: #fff0f0;
  border: 1px solid #ffcccc;
  border-radius: 10rpx;
  
  .error-title {
    font-size: 28rpx;
    font-weight: bold;
    color: #ff3333;
    margin-bottom: 10rpx;
  }
  
  .error-message {
    font-size: 26rpx;
    color: #333;
    margin-bottom: 10rpx;
    word-break: break-all;
  }
  
  .error-detail {
    font-size: 24rpx;
    color: #666;
    margin-top: 6rpx;
    word-break: break-all;
  }
}

.camera-list {
  width: 100%;
  padding: 0 20rpx;
  box-sizing: border-box;

  .camera-item {
    padding: 20rpx;
    border-bottom: 1rpx solid #eee;
    margin-bottom: 20rpx;
    border-radius: 10rpx;
    background-color: #f9f9f9;
    box-shadow: 0 2rpx 10rpx rgba(0,0,0,0.05);
    
    .camera-info {
      display: flex;
      flex-direction: column;
      
      .camera-name {
        font-size: 32rpx;
        font-weight: bold;
        margin-bottom: 10rpx;
        color: #333;
      }
      
      .camera-id {
        font-size: 24rpx;
        color: #666;
        margin-bottom: 10rpx;
      }
      
      .camera-type {
        font-size: 24rpx;
        color: #999;
      }
    }
  }
}

.scan-result-box {
  width: 90%;
  padding: 20rpx;
  margin-bottom: 30rpx;
  background-color: #f0f9ff;
  border: 1px solid #a0d7ff;
  border-radius: 10rpx;
  
  .scan-result-title {
    font-size: 28rpx;
    font-weight: bold;
    color: #0066cc;
    margin-bottom: 10rpx;
  }
  
  .scan-result-content {
    font-size: 26rpx;
    color: #333;
    word-break: break-all;
    padding: 10rpx;
    background: #ffffff;
    border-radius: 6rpx;
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
