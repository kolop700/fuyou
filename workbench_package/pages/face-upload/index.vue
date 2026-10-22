<template>
	<view>
		<qf-image-cropper :width="300" :height="300" :fileType="'jpg'" :show-angle="false" :rotatable="false" :quality="0.8" @crop="handleCrop"></qf-image-cropper>
	
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
import { ref, onMounted } from 'vue'
import QfImageCropper from '@/uni_modules/qf-image-cropper/components/qf-image-cropper/qf-image-cropper.vue'
import userApi from '@/api/user/user.js'
import { useUserStore } from '@/store/modules/user'
import scanUtils from '@/utils/scanUtils.js'

const userStore = useUserStore()

const getUploadErrorMessage = (error, fallback = '上传失败，请重试') => {
	if (!error) return fallback
	if (typeof error === 'string') return error
	return error.info || error.msg || error.message || error.errMsg || fallback
}

// 页面加载时检查权限
onMounted(async () => {
	const permissionNames = {
		'android.permission.CAMERA': '相机',
		'android.permission.READ_EXTERNAL_STORAGE': '存储'
	}
	
	const hasPermissions = await scanUtils.checkAndRequestPermissions(permissionNames)
	if (!hasPermissions) {
		uni.showToast({
			title: '请授予相机和相册权限以使用此功能',
			icon: 'none',
			duration: 2000
		})
	}
})

const handleCrop = async (e) => {
	try {
		const tempFilePath = e?.tempFilePath || ''
		const userAcct = userStore.userAcct

		console.log('[face-upload] crop event:', e)
		console.log('[face-upload] tempFilePath:', tempFilePath)
		console.log('[face-upload] userAcct:', userAcct)

		if (!tempFilePath) {
			uni.showToast({
				title: '裁剪图片路径为空，请重新选择',
				icon: 'none'
			})
			return
		}

		if (!userAcct) {
			uni.showToast({
				title: '账号信息为空，请重新登录',
				icon: 'none'
			})
			return
		}

		// 显示上传中
		uni.showLoading({
			title: '上传中...',
			mask: true
		})

		// 调用上传接口
		const result = await userApi.uploadUserFacePic(
			tempFilePath,
			userAcct
		)

		console.log('[face-upload] upload result:', result)

		if (result.code === "0") {
			// 重新登录刷新用户信息
			await userStore.login(null, { showLoading: false, refreshRoomList: false })
			
			uni.showToast({
				title: '图片上传成功!',
				icon: 'none',
				duration: 2000
			})
			
			// 返回上一页
			setTimeout(() => {
				uni.navigateBack()
			}, 1500)
		} else {
			uni.showToast({
				title: getUploadErrorMessage(result),
				icon: 'none'
			})
		}
	} catch (error) {
		console.error('上传失败:', error)
		uni.showToast({
			title: getUploadErrorMessage(error),
			icon: 'none'
		})
	} finally {
		uni.hideLoading()
	}
}

// ===== Taku 底部横幅广告位 ID（空/全关时不展示；随广告开关自动响应更新） =====
import { computed as __takuComputed, getCurrentInstance as __takuGci } from 'vue'
const __takuInst = __takuGci()
const __takuAdStore = __takuInst.proxy.$store.ad.useAdStore()
const bannerAdId = __takuComputed(() => __takuAdStore.getBannerAdId())
</script>

<style>


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
}

/* Tab 页：横幅悬浮在自定义 tabbar（高100rpx+安全区）上方 */
.ad-section.ad-tab {
  bottom: calc(100rpx + env(safe-area-inset-bottom));
  box-shadow: 0 -4rpx 16rpx rgba(31, 48, 152, 0.12);
}
</style>
