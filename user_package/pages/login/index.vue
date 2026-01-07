<template>
  <view class="login-container">
    <view class="login-content">
      <!-- Logo Section -->
      <view class="logo-section">
        <view class="logo">
          <image class="logo-image" src="/static/logo.png" mode="aspectFit"></image>
        </view>
        <text class="app-title">玉龙智眸</text>
        <text class="app-subtitle">智能门禁 · 安全便捷</text>
      </view>

      <!-- Login Form -->
      <view class="form-card">
        <text class="form-title">欢迎回来</text>
        <text class="form-subtitle">登录您的账户继续使用</text>

        <view class="input-group">
          <text class="input-label">手机号</text>
          <u-input
            v-model="form.user_account"
            type="text"
            placeholder="请输入手机号"
            :maxlength="11"
            :border="false"
            :customStyle="inputStyle"
            shape="round"
          >
            <template #suffix>
              <text class="iconfont icon-mobile-alt" style="color: #94a3b8; font-size: 36rpx;"></text>
            </template>
          </u-input>
        </view>

        <view class="input-group">
          <text class="input-label">密码</text>
          <u-input
            v-model="form.password"
            :type="showPassword ? 'text' : 'password'"
            placeholder="请输入密码"
            :border="false"
            :customStyle="inputStyle"
            shape="round"
          >
            <template #suffix>
              <view @click="togglePasswordVisibility" style="padding: 0 10rpx;">
                <text 
                  class="iconfont" 
                  :class="showPassword ? 'icon-a-fasfa-eye' : 'icon-fa-eye-close'"
                  style="color: #94a3b8; font-size: 36rpx;"
                ></text>
              </view>
            </template>
          </u-input>
        </view>

        <!-- 忘记密码 -->
        <view class="forgot-password-wrapper">
          <text class="link-text" @click="goToForgotPassword">忘记密码?</text>
        </view>

        <!-- 协议同意 -->
        <view class="agreement">
          <checkbox-group @change="onCheckboxChange">
            <checkbox 
              value="agree"
              :checked="checked" 
              color="#667eea"
              style="transform:scale(0.75); margin-right: 8rpx;"
            />
          </checkbox-group>
          <text class="agreement-text">我已阅读并同意</text>
          <text class="link-text-inline" @click="openUserAgreement">《用户协议》</text>
          <text class="agreement-text-inline">和</text>
          <text class="link-text-inline" @click="openPrivacyPolicy">《隐私政策》</text>
        </view>

        <!-- 登录按钮 -->
        <view class="btn-wrapper">
          <u-button
            text="登录"
            type="primary"
            size="normal"
            :plain="false"
            shape="round"
            :customStyle="buttonStyle"
            @click="handleLogin"
          ></u-button>
        </view>

        <!-- 注册链接 -->
        <view class="register-link">
          <text class="register-text">还没有账户？</text>
          <text class="link-text" @click="goToRegister">立即注册</text>
        </view>
      </view>
    </view>

    <!-- 提示信息弹窗 -->
    <uni-popup ref="message" type="message">
      <uni-popup-message :type="msgType" :message="messageText" :duration="2000"></uni-popup-message>
    </uni-popup>
  </view>
</template>

<script setup>
import { ref, getCurrentInstance } from 'vue'
import { onLoad } from "@dcloudio/uni-app"

const { proxy } = getCurrentInstance()
const form = ref({
  user_account: '',
  password: ''
})
const showPassword = ref(false)
const checked = ref(false) // 默认不同意
const msgType = ref('')
const messageText = ref('')
const message = ref(null)

// 输入框样式
const inputStyle = {
  border: '4rpx solid #e2e8f0',
  borderRadius: '20rpx',
  padding: '24rpx 28rpx',
  backgroundColor: '#fff',
  fontSize: '28rpx'
}

// 按钮样式
const buttonStyle = {
  width: '100%',
  background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)'
}

// 协议勾选改变
const onCheckboxChange = (e) => {
  checked.value = e.detail.value.includes('agree')
}

// 切换密码显示/隐藏
const togglePasswordVisibility = () => {
  showPassword.value = !showPassword.value
}

// 打开用户协议
const openUserAgreement = () => {
  uni.navigateTo({ url: '/user_package/pages/agreement/user' })
}

// 打开隐私政策
const openPrivacyPolicy = () => {
  uni.navigateTo({ url: '/user_package/pages/agreement/privacy' })
}


const handleLogin = async () => {
  // 检查协议同意
  if (!checked.value) {
    uni.showToast({
      title: '请先同意用户协议和隐私政策',
      icon: 'none',
      duration: 2000
    })
    return
  }

  // 手机号验证
  if (!form.value.user_account) {
    uni.showToast({
      title: '请输入手机号',
      icon: 'none',
      duration: 2000
    })
    return
  }

  if (!/^1[3-9]\d{9}$/.test(form.value.user_account)) {
    uni.showToast({
      title: '请输入正确的手机号',
      icon: 'none',
      duration: 2000
    })
    return
  }

  if (!form.value.password) {
    uni.showToast({
      title: '请输入密码',
      icon: 'none',
      duration: 2000
    })
    return
  }

  if (form.value.password.length < 6) {
    uni.showToast({
      title: '密码长度至少6位',
      icon: 'none',
      duration: 2000
    })
    return
  }

  try {
    const loginData = {
      app_phone_mac: "0",
      app_login_type: "2",
      user_acct: form.value.user_account,
      user_password: form.value.password
    }
    console.log(loginData)
    const res = await proxy.$api.user.UserLogin(loginData)
    console.log(res)
    if (res.code === "0") {
      // 先保存用户信息到pinia store（这样才能确保登录状态更新）
      const userData = res.data[0]
      await proxy.$store.user.useUserStore().loginSuccess(userData)
      
      // 显示成功提示
      uni.showToast({
        title: '登录成功',
        icon: 'success',
        duration: 1500
      })
      
      // 延迟跳转到首页，使用 reLaunch 清除页面栈，避免重复跳转
      setTimeout(() => {
        uni.reLaunch({
          url: '/pages/index/index'
        })
      }, 1500)
    } else {
      uni.showToast({
        title: res.msg || '登录失败',
        icon: 'none'
      })
    }
  } catch (error) {
    uni.showToast({
      title: '登录失败，请检查账号密码是否正确',
      icon: 'none'
    })
    console.error('登录错误:', error)
  }
}

const goToRegister = () => {
  uni.navigateTo({
    url: '../register/index'
  })
}

const goToForgotPassword = () => {
  uni.navigateTo({
    url: '../forgot-password/index'
  })
}

onLoad((params) => {
  console.log(params)
})
</script>

<style lang="scss" scoped>
@import '@/static/fonts/iconfont.css';

.login-container {
  height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 0 60rpx 20rpx;
  box-sizing: border-box;
  overflow: hidden;
}

.login-content {
  width: 100%;
  max-width: 750rpx;
}

.logo-section {
  text-align: center;
  margin-bottom: 20rpx;
}

.logo {
  width: 160rpx;
  height: 160rpx;
  border-radius: 48rpx;
  background: white;
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 auto 16rpx;
  box-shadow: 0 20rpx 60rpx rgba(0, 0, 0, 0.2);
  overflow: hidden;
}

.logo-image {
  width: 100%;
  height: 100%;
}

.app-title {
  display: block;
  font-size: 44rpx;
  font-weight: 700;
  color: white;
  margin-bottom: 8rpx;
}

.app-subtitle {
  display: block;
  font-size: 24rpx;
  color: rgba(255, 255, 255, 0.8);
}

.form-card {
  background: white;
  border-radius: 40rpx;
  padding: 36rpx 32rpx;
  width: 100%;
  box-shadow: 0 40rpx 80rpx rgba(0, 0, 0, 0.15);
  box-sizing: border-box;
}

.form-title {
  display: block;
  font-size: 40rpx;
  font-weight: 700;
  color: #1e293b;
  margin-bottom: 8rpx;
}

.form-subtitle {
  display: block;
  font-size: 24rpx;
  color: #64748b;
  margin-bottom: 24rpx;
}

.input-group {
  margin-bottom: 24rpx;
}

.input-label {
  display: block;
  font-size: 24rpx;
  font-weight: 600;
  color: #64748b;
  margin-bottom: 12rpx;
}


.forgot-password-wrapper {
  text-align: right;
  margin-bottom: 20rpx;
}

.agreement {
  display: flex;
  align-items: center;
  flex-wrap: nowrap;
  margin-bottom: 24rpx;
  font-size: 22rpx;
  line-height: 1.4;
  white-space: nowrap;
}

.agreement-text {
  color: #64748b;
  font-size: 22rpx;
  white-space: nowrap;
}

.agreement-text-inline {
  color: #64748b;
  font-size: 22rpx;
  white-space: nowrap;
  margin: 0 4rpx;
}

.link-text-inline {
  color: #667eea;
  font-weight: 600;
  font-size: 22rpx;
  white-space: nowrap;
  margin: 0 2rpx;
}

.link-text {
  color: #667eea;
  font-weight: 600;
  font-size: 26rpx;
}

.btn-wrapper {
  margin-bottom: 20rpx;
}


.register-link {
  text-align: center;
  font-size: 24rpx;
  color: #64748b;
  margin-top: 0;
}

.register-text {
  color: #64748b;
}
</style>