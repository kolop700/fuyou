<template>
  <view class="login-page" :style="{ background: theme.bgPrimary }">
    <!-- 环境光背景 -->
    <view class="ambient-bg"></view>
    
    <!-- 状态栏占位 -->
    <view class="status-bar-space" :style="{ height: statusBarHeight + 'px' }"></view>
    
    <!-- 内容区域 -->
    <view class="page-content">
      <!-- Logo区域 -->
      <view class="logo-section">
        <view class="logo-box" :style="{ background: theme.logoGradient, boxShadow: theme.shadowLogo }">
          <text class="iconfont icon-fa-building"></text>
        </view>
        <text class="title" :style="{ color: theme.textPrimary }">欢迎回来</text>
        <text class="subtitle" :style="{ color: theme.textSecondary }">登录您的优福社区账户</text>
      </view>
      
      <!-- 表单 -->
      <view class="form-group">
        <view class="input-with-icon" :style="{ background: theme.bgCard }">
          <text class="iconfont icon-mobile-alt icon" :style="{ color: theme.textSecondary }"></text>
          <input 
            v-model="form.user_account" 
            type="text" 
            class="input-field" 
            :style="{ color: theme.textPrimary }"
            placeholder="请输入手机号"
            placeholder-class="placeholder"
            :maxlength="11"
          />
        </view>
      </view>
      
      <view class="form-group">
        <view class="input-with-icon" :style="{ background: theme.bgCard }">
          <text class="iconfont icon-fa-lock icon" :style="{ color: theme.textSecondary }"></text>
          <input 
            v-model="form.password" 
            :type="showPassword ? 'text' : 'password'" 
            class="input-field" 
            :style="{ color: theme.textPrimary }"
            placeholder="请输入密码"
            placeholder-class="placeholder"
          />
        </view>
      </view>
      
      <!-- 记住密码和忘记密码 -->
      <view class="options-row">
        <label class="remember-label" @click="toggleRemember">
          <checkbox :checked="remember" :color="theme.colorAccent" />
          <text class="remember-text" :style="{ color: theme.textSecondary }">记住密码</text>
        </label>
        <text class="link-text" :style="{ color: theme.colorAccent }" @click="goToForgotPassword">忘记密码?</text>
      </view>
      
      <!-- 登录按钮 -->
      <button class="btn-primary" @click="handleLogin">登 录</button>
      
      <!-- 暂时隐藏社交登录 -->
      <!-- <view class="divider">
        <view class="divider-line" :style="{ background: theme.dividerColor }"></view>
        <text class="divider-text" :style="{ color: theme.textSecondary }">其他方式登录</text>
        <view class="divider-line" :style="{ background: theme.dividerColor }"></view>
      </view>
      
      <view class="social-login">
        <view class="social-btn wechat" :style="{ background: theme.bgCard, borderColor: theme.borderColor }">
          <text class="iconfont icon-a-fabfa-weixin"></text>
        </view>
        <view class="social-btn alipay" :style="{ background: theme.bgCard, borderColor: theme.borderColor }">
          <text class="iconfont icon-f-alipay"></text>
        </view>
        <view class="social-btn apple" :style="{ background: theme.bgCard, borderColor: theme.borderColor }">
          <text class="iconfont icon-f-apple" :style="{ color: theme.textPrimary }"></text>
        </view>
      </view> -->
      
      <!-- 注册提示 -->
      <view class="register-tip" style="margin-top: 64rpx;">
        <text class="tip-text" :style="{ color: theme.textSecondary }">还没有账号? </text>
        <text class="link-text" :style="{ color: theme.colorAccent }" @click="goToRegister">立即注册</text>
      </view>
    </view>
  </view>
</template>

<script setup>
import { ref, computed, getCurrentInstance } from 'vue'
import { onLoad } from "@dcloudio/uni-app"
import { useThemeVars } from '@/utils/themeConfig.js'

const { proxy } = getCurrentInstance()

// 数据
const form = ref({
  user_account: '',
  password: ''
})
const showPassword = ref(false)
const remember = ref(false)
const statusBarHeight = ref(0)

// 获取主题 Store
const themeStore = proxy.$store.theme.useThemeStore()

// 主题变量
const theme = computed(() => useThemeVars(themeStore.isDark()))

// 切换记住密码
const toggleRemember = () => {
  remember.value = !remember.value
}

// 登录处理
const handleLogin = async () => {
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
    
    const res = await proxy.$api.user.UserLogin(loginData)
    
    if (res.code === "0") {
      const userData = res.data[0]
      await proxy.$store.user.useUserStore().loginSuccess(userData)
      
      uni.showToast({
        title: '登录成功',
        icon: 'success',
        duration: 1500
      })
      
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

// 跳转注册
const goToRegister = () => {
  uni.navigateTo({
    url: '../register/index'
  })
}

// 跳转忘记密码
const goToForgotPassword = () => {
  uni.navigateTo({
    url: '../forgot-password/index'
  })
}

onLoad((params) => {
  // 加载主题设置
  themeStore.loadTheme()
  // 获取状态栏高度
  const systemInfo = uni.getSystemInfoSync()
  statusBarHeight.value = systemInfo.statusBarHeight || 0
})
</script>

<style lang="scss" scoped>
@import '@/static/fonts/iconfont.css';

.login-page {
  width: 100%;
  min-height: 100vh;
  position: relative;
  overflow: hidden;
  // 背景色由动态绑定
}

/* 环境光背景 */
.ambient-bg {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  pointer-events: none;
  background: 
    radial-gradient(circle at 20% 20%, hsla(200, 80%, 50%, 0.15), transparent 40%),
    radial-gradient(circle at 80% 80%, hsla(280, 60%, 40%, 0.1), transparent 40%);
}

/* 状态栏占位 */
.status-bar-space {
  width: 100%;
}

/* 页面内容 */
.page-content {
  padding: 120rpx 48rpx 48rpx;
  position: relative;
  z-index: 10;
}

/* Logo区域 */
.logo-section {
  text-align: center;
  margin-bottom: 80rpx;
}

.logo-box {
  width: 160rpx;
  height: 160rpx;
  margin: 0 auto 40rpx;
  border-radius: 48rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  // 背景渐变和阴影由动态绑定
  
  .iconfont {
    font-size: 72rpx;
    color: white;
  }
}

.title {
  display: block;
  font-size: 48rpx;
  font-weight: 700;
  margin-bottom: 16rpx;
  // 颜色由动态绑定
}

.subtitle {
  display: block;
  font-size: 28rpx;
  // 颜色由动态绑定
}

/* 表单组 */
.form-group {
  margin-bottom: 32rpx;
}

.input-with-icon {
  position: relative;
  display: flex;
  align-items: center;
  border-radius: 28rpx;
  overflow: hidden;
  // 背景色由动态绑定
  transition: all 0.3s ease;
}

.icon {
  position: absolute;
  left: 32rpx;
  font-size: 32rpx;
  z-index: 2;
  // 颜色由动态绑定
}

.input-field {
  width: 100%;
  height: 96rpx;
  padding: 0 32rpx 0 76rpx;
  border-radius: 28rpx;
  font-size: 30rpx;
  border: none;
  outline: none;
  background: transparent;
  transition: all 0.3s ease;
  // 颜色由动态绑定
}

/* 选项行 */
.options-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 64rpx;
}

.remember-label {
  display: flex;
  align-items: center;
  gap: 16rpx;
  font-size: 26rpx;
  color: var(--color-text-secondary);
}

.remember-text {
  // 颜色由动态绑定
}

.link-text {
  font-size: 26rpx;
  font-weight: 600;
  // 颜色由动态绑定
}

/* 登录按钮 */
.btn-primary {
  width: 100%;
  height: 96rpx;
  background: linear-gradient(135deg, #38bdf8 0%, #3b82f6 100%);
  border-radius: 28rpx;
  border: none;
  font-size: 32rpx;
  font-weight: 600;
  color: white;
  margin-bottom: 48rpx;
  box-shadow: 0 20rpx 60rpx -20rpx rgba(56, 189, 248, 0.5);
  transition: all 0.3s cubic-bezier(0.2, 0.8, 0.2, 1);
}

.btn-primary:active {
  transform: scale(0.98);
}

/* 分割线 */
.divider {
  display: flex;
  align-items: center;
  gap: 32rpx;
  margin-bottom: 48rpx;
}

.divider-line {
  flex: 1;
  height: 2rpx;
  // 背景色由动态绑定
}

.divider-text {
  font-size: 26rpx;
  // 颜色由动态绑定
}

/* 社交登录 */
.social-login {
  display: flex;
  justify-content: center;
  gap: 40rpx;
  margin-bottom: 64rpx;
}

.social-btn {
  width: 112rpx;
  height: 112rpx;
  border-radius: 32rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.3s ease;
  border: 2rpx solid;
  // 背景色和边框色由动态绑定
  
  .iconfont {
    font-size: 48rpx;
  }
}

.social-btn:active {
  transform: translateY(-4rpx);
}

.social-btn.wechat .iconfont {
  color: #07C160;
}

.social-btn.alipay .iconfont {
  color: #1677FF;
}

// Apple 图标颜色由动态绑定

/* 注册提示 */
.register-tip {
  text-align: center;
  font-size: 28rpx;
}

.tip-text {
  // 颜色由动态绑定
}
</style>
