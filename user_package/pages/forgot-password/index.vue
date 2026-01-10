<template>
  <view class="forgot-page" :style="{ background: theme.bgPrimary }">
    <!-- 环境光背景 -->
    <view class="ambient-bg"></view>
    
    <!-- 自定义导航栏 -->
    <custom-navbar title="修改密码" :show-back="true" />
    
     <!-- 内容区域 -->
    <scroll-view scroll-y class="scroll-content" :style="{ paddingTop: navbarHeight + 'px' }">
      <view class="page-content">
        <!-- 表单 -->
        <view class="form-group">
          <text class="form-label" :style="{ color: theme.textSecondary }">手机号码</text>
          <view class="input-with-icon" :style="{ background: theme.bgCard }">
            <text class="iconfont icon-mobile-alt icon" :style="{ color: theme.textSecondary }"></text>
            <input 
              v-model="form.phone" 
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
          <text class="form-label" :style="{ color: theme.textSecondary }">验证码</text>
          <view class="verify-row">
            <view class="input-with-icon verify-input" :style="{ background: theme.bgCard }">
              <input 
                v-model="form.code" 
                type="text" 
                class="input-field" 
                :style="{ color: theme.textPrimary }"
                placeholder="请输入验证码"
                placeholder-class="placeholder"
                :maxlength="6"
              />
            </view>
            <button 
              class="btn-secondary" 
              :style="secondaryBtnStyle"
              :disabled="counting" 
              @click="getCode"
            >
              {{ counting ? `${counter}s` : '获取验证码' }}
            </button>
          </view>
        </view>

        <view class="form-group">
          <text class="form-label" :style="{ color: theme.textSecondary }">新密码</text>
          <view class="input-with-icon" :style="{ background: theme.bgCard }">
            <text class="iconfont icon-fa-lock icon" :style="{ color: theme.textSecondary }"></text>
            <input 
              v-model="form.newPassword" 
              :type="showPassword ? 'text' : 'password'" 
              class="input-field" 
              :style="{ color: theme.textPrimary }"
              placeholder="请输入新密码"
              placeholder-class="placeholder"
            />
          </view>
        </view>

        <view class="form-group">
          <text class="form-label" :style="{ color: theme.textSecondary }">确认新密码</text>
          <view class="input-with-icon" :style="{ background: theme.bgCard }">
            <text class="iconfont icon-fa-lock icon" :style="{ color: theme.textSecondary }"></text>
            <input 
              v-model="form.confirmPassword" 
              :type="showConfirmPassword ? 'text' : 'password'" 
              class="input-field" 
              :style="{ color: theme.textPrimary }"
              placeholder="请再次输入新密码"
              placeholder-class="placeholder"
            />
          </view>
        </view>

        <!-- 按钮 -->
        <button class="btn-primary" :style="{ boxShadow: theme.shadowButton }" @click="handleReset">确认修改</button>

        <!-- 返回登录 -->
        <view class="register-link">
          <text class="register-text" :style="{ color: theme.textSecondary }">想起密码了？</text>
          <text class="link-text" :style="{ color: theme.colorAccent }" @click="goToLogin">返回登录</text>
        </view>
      </view>
    </scroll-view>
  </view>
</template>

<script setup>
import { ref, computed, getCurrentInstance } from 'vue'
import { onLoad } from "@dcloudio/uni-app"
import { useThemeVars } from '@/utils/themeConfig.js'

const { proxy } = getCurrentInstance()

// 数据
const form = ref({
  phone: '',
  code: '',
  newPassword: '',
  confirmPassword: ''
})

const showPassword = ref(false)
const showConfirmPassword = ref(false)
const counting = ref(false)
const counter = ref(60)
const savedVerifyCode = ref('')
const savedPhone = ref('')
const navbarHeight = ref(0)

// 获取主题 Store
const themeStore = proxy.$store.theme.useThemeStore()

// 主题变量
const theme = computed(() => useThemeVars(themeStore.isDark()))

// 次要按钮样式
const secondaryBtnStyle = computed(() => {
  const shadow = themeStore.isDark() ? 'none' : '0 4rpx 16rpx rgba(0,0,0,0.06)'
  return {
    background: theme.value.bgCard,
    color: theme.value.textPrimary,
    borderColor: theme.value.borderColor,
    boxShadow: shadow
  }
})

// 生成6位随机验证码
const generateVerifyCode = () => {
  return Math.floor(100000 + Math.random() * 900000).toString()
}

// 验证手机号
const validatePhone = () => {
  if (!form.value.phone) {
    uni.showToast({ title: '请输入手机号', icon: 'none' })
    return false
  }
  if (!/^1[3-9]\d{9}$/.test(form.value.phone)) {
    uni.showToast({ title: '手机号格式不正确', icon: 'none' })
    return false
  }
  return true
}

// 获取验证码
const getCode = async () => {
  if (counting.value) return
  if (!validatePhone()) return
  
  try {
    const verifyCode = generateVerifyCode()
    const res = await proxy.$api.user.sendSMS(form.value.phone, verifyCode)
    savedVerifyCode.value = verifyCode
    savedPhone.value = form.value.phone
    
    uni.showToast({ title: '验证码已发送', icon: 'success' })
    counting.value = true
    counter.value = 60
    const timer = setInterval(() => {
      if (counter.value > 0) {
        counter.value--
      } else {
        counting.value = false
        clearInterval(timer)
      }
    }, 1000)
  } catch (error) {
    console.error('发送验证码错误:', error)
  }
}

// 表单验证
const validateForm = () => {
  if (!form.value.code) {
    uni.showToast({ title: '请输入验证码', icon: 'none' })
    return false
  }
  
  if (!savedVerifyCode.value || !savedPhone.value) {
    uni.showToast({ title: '请先获取验证码', icon: 'none' })
    return false
  }
  if (savedPhone.value !== form.value.phone) {
    uni.showToast({ title: '手机号与获取验证码时不一致', icon: 'none' })
    return false
  }
  if (!form.value.newPassword) {
    uni.showToast({ title: '请输入密码', icon: 'none' })
    return false
  }
  if (form.value.newPassword.length < 6) {
    uni.showToast({ title: '密码不能少于6位', icon: 'none' })
    return false
  }
  if (form.value.newPassword !== form.value.confirmPassword) {
    uni.showToast({ title: '两次输入的密码不一致', icon: 'none' })
    return false
  }
  if (form.value.code !== savedVerifyCode.value) {
    uni.showToast({ title: '验证码错误', icon: 'none' })
    return false
  }
  return true
}

// 提交表单
const handleReset = async () => {
  if (validateForm()) {
    try {
      const res = await proxy.$api.user.resetPassword(form.value)
      if(res.code === "0") {
        const userStore = proxy.$store.user.useUserStore()
        try {
          userStore.setUserAccount(form.value.phone)
          userStore.setUserPassword(form.value.newPassword)
          uni.showToast({ 
            title: '重置密码成功', 
            icon: 'success',
            duration: 2000
          })
          setTimeout(() => {
            uni.reLaunch({
              url: '/pages/index/index'
            })
          }, 2000)
        } catch (error) {
          console.error('自动登录失败:', error)
        }
      }
    } catch (error) {
      console.error('重置密码失败:', error)
      uni.showToast({ 
        title: error.msg || '重置密码失败', 
        icon: 'none' 
      })
    }
  }
}

// 返回登录页
const goToLogin = () => {
  uni.navigateBack()
}

onLoad((params) => {
  // 加载主题设置
  themeStore.loadTheme()
  // 计算导航栏高度（状态栏 + 导航栏）
  const systemInfo = uni.getSystemInfoSync()
  navbarHeight.value = (systemInfo.statusBarHeight || 0) + 44
})
</script>

<style lang="scss" scoped>
@import '@/static/fonts/iconfont.css';

.forgot-page {
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

/* 导航头部 */
.nav-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 20rpx 48rpx 40rpx;
  position: relative;
  z-index: 100;
}

.nav-back {
  width: 80rpx;
  height: 80rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 24rpx;
  cursor: pointer;
  transition: all 0.3s ease;
  // 背景色和阴影由动态绑定
  
  .iconfont {
    font-size: 32rpx;
    // 颜色由动态绑定
  }
}

.nav-back:active {
  transform: scale(0.95);
}

.nav-title {
  font-size: 34rpx;
  font-weight: 600;
  // 颜色由动态绑定
}

.nav-action {
  width: 80rpx;
  height: 80rpx;
}

/* 滚动区域 */
.scroll-content {
  height: 100vh;
  // padding-top 由动态绑定
}

.page-content {
  padding: 80rpx 48rpx 80rpx;
}

/* 表单组 */
.form-group {
  margin-bottom: 32rpx;
}

.form-label {
  display: block;
  font-size: 26rpx;
  margin-bottom: 16rpx;
  // 颜色由动态绑定
}

.input-with-icon {
  position: relative;
  display: flex;
  align-items: center;
  border-radius: 28rpx;
  overflow: hidden;
  transition: all 0.3s ease;
  // 背景色由动态绑定
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
  padding: 0 32rpx;
  border-radius: 28rpx;
  font-size: 30rpx;
  border: none;
  outline: none;
  background: transparent;
  transition: all 0.3s ease;
  // 颜色由动态绑定
}

.input-with-icon .input-field {
  padding-left: 76rpx;
}

/* 验证码行 */
.verify-row {
  display: flex;
  gap: 24rpx;
  align-items: center;
}

.verify-input {
  flex: 1;
}

/* 次要按钮 */
.btn-secondary {
  height: 96rpx;
  padding: 0 32rpx;
  border-radius: 28rpx;
  font-size: 28rpx;
  font-weight: 500;
  border: 2rpx solid;
  white-space: nowrap;
  transition: all 0.3s ease;
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  line-height: 1;
  // 背景色、颜色、边框色由动态绑定
}

.btn-secondary:active:not(:disabled) {
  transform: scale(0.98);
}

.btn-secondary:disabled {
  opacity: 0.5;
}

/* 主按钮 */
.btn-primary {
  width: 100%;
  height: 96rpx;
  background: linear-gradient(135deg, #38bdf8 0%, #3b82f6 100%);
  border-radius: 28rpx;
  border: none;
  font-size: 32rpx;
  font-weight: 600;
  color: white;
  transition: all 0.3s cubic-bezier(0.2, 0.8, 0.2, 1);
  margin-bottom: 48rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  line-height: 1;
  // 阴影由动态绑定
}

.btn-primary:active {
  transform: scale(0.98);
}

/* 注册链接 */
.register-link {
  text-align: center;
  font-size: 28rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  line-height: 1;
}

.register-text {
  display: inline-flex;
  align-items: center;
  line-height: 1;
  // 颜色由动态绑定
}

.link-text {
  font-weight: 600;
  display: inline-flex;
  align-items: center;
  line-height: 1;
  // 颜色由动态绑定
}
</style>
