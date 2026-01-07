<template>
  <view class="container">
    <!-- 自定义标题栏 -->
    <view v-if="!isFullScreen" class="login-view" style="padding-bottom: 0; padding-top: 40rpx; flex-direction: row; align-items: center;">
      <image 
        src="/static/icons/icon_back.png" 
        style="width: 48rpx; height: 48rpx; margin-right: 20rpx;" 
        mode="aspectFit" 
        @click="goBack"
      />
      <text style="font-size: 36rpx; font-weight: bold;">{{ title }}</text>
    </view>
    <!-- webview 区域 -->
    <web-view :src="url" style="flex: 1; width: 100%; min-height: 800rpx;" />
    <!-- 全屏按钮 -->
    <view style="width: 100%; display: flex; justify-content: center; margin: 30rpx 0;">
      <button @click="toggleFullScreen" style="width: 60%; background: #FF0036; color: #fff; font-size: 32rpx; border-radius: 12rpx;">
        {{ isFullScreen ? '退出全屏' : '全屏' }}
      </button>
    </view>
  </view>
</template>

<script setup>
import { ref } from 'vue'
import { onLoad } from '@dcloudio/uni-app'

const url = ref('')
const title = ref('网页浏览')
const isFullScreen = ref(false)

onLoad((params) => {
  if (params.url) {
    url.value = decodeURIComponent(params.url)
  }
  if (params.title) {
    title.value = params.title
  }
})

const goBack = () => {
  uni.navigateBack()
}

const toggleFullScreen = () => {
  isFullScreen.value = !isFullScreen.value
}
</script>

<style lang="scss">
.container {
  min-height: 100vh;
  background-color: #fff;
  display: flex;
  flex-direction: column;
  box-sizing: border-box;
}
.login-view {
  display: flex;
  justify-content: flex-start;
  padding: 40rpx 0 40rpx 20rpx;
  background: #fff;
  .logo {
    width: 240rpx;
    height: 240rpx;
    border-radius: 25%;
  }
}
</style> 