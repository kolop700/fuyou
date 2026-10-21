// utils/tangeDevice.js

// 统一跨端 HTTP：原生壳内走 OkHttp/URLSession（绕 WebView 同源策略），普通浏览器/APP 端自动回退 uni.request。
// 背景：壳内直调 uni.request 访问 tange365 开放接口可能被 CORS 拦截（老整包 plus.net 无此限制），改用封装保持行为一致。
import { httpRequest } from '@/utils/nativeHttp'

// 你需要根据实际情况替换这些参数
const BASE_URL = 'https://openapi-cn01.tange365.com'
const APP_ID = 'AD_2fDa8DLLXoFgKt9wuYwJBXX8aYZ'
const PLATFORM = 'web'
const SDK_VERSION = '1024'
const LANGUAGE = 'zh-cn'
const PKGNAME = 'com.jyitoo.app'
const APP_VERSION = '1.0.0'

// 获取用户 store 中的设备 token
function getTokenFromStore() {
  try {
    console.log('开始获取设备 token...')
    
    // 尝试从全局获取用户 store
    let userStore = null
    
    // 方法1: 通过全局变量获取（uni-app 环境）
    try {
      // 在 uni-app 中，可以通过 getApp() 获取全局实例
      const app = getApp()
      if (app && app.$store && app.$store.user && app.$store.user.useUserStore) {
        userStore = app.$store.user.useUserStore()
        console.log('通过全局 app 获取到 userStore:', userStore)
      }
    } catch (e) {
      console.log('通过全局 app 获取 store 失败:', e)
    }
    
    // 方法2: 尝试通过 uni.getStorageSync 获取（如果之前保存过）
    if (!userStore) {
      try {
        const storedToken = uni.getStorageSync('device_token')
        if (storedToken) {
          console.log('从本地存储获取到设备 token:', storedToken)
          return storedToken
        }
      } catch (e) {
        console.log('从本地存储获取 token 失败:', e)
      }
    }
    
    // 如果获取到 store，尝试获取设备 token
    if (userStore) {
      console.log('userStore 存在，尝试获取设备 token')
      console.log('userStore.deviceToken:', userStore.deviceToken)
      
      // 尝试直接访问 deviceToken 属性
      if (userStore.deviceToken) {
        console.log('直接获取到 deviceToken:', userStore.deviceToken)
        return userStore.deviceToken
      }
      
      // 尝试调用 getDeviceToken 方法
      if (userStore.getDeviceToken && typeof userStore.getDeviceToken === 'function') {
        const token = userStore.getDeviceToken()
        console.log('通过方法获取到设备 token:', token)
        return token
      }
    }
    
    // 备用方案：如果无法从 store 获取，使用硬编码的 token
    console.log('使用备用设备 token')
    return 'eyJhbGciOiJFZERTQSIsImtpZCI6Im8xWnkzWE5TSGhxOCIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxOTczMTYwMyIsImlzcyI6ImFwcC9sb2dpbiIsImlhdCI6MTc1MTQyNjk4OSwiZXhwIjoxNzU0MDE4OTg5LCJhdWQiOlsiYXBwL2JhY2tlbmQiXSwidWlkIjoxOTczMTYwMywiYXBwX2lkIjoiQURfMmZEYThETExYb0ZnS3Q5d3VZd0pCWFg4YVlaIn0.mqY5xfTy3miD-7F1m-PT36bLpMAq9SvQjKEdLBiXi8yxNieEYyh5_tYrGYti843ShN-z63BL_090Z6x9KyVFCg'
  } catch (error) {
    console.error('获取用户 store 失败:', error)
    // 返回备用 token
    return 'eyJhbGciOiJFZERTQSIsImtpZCI6Im8xWnkzWE5TSGhxOCIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxOTczMTYwMyIsImlzcyI6ImFwcC9sb2dpbiIsImlhdCI6MTc1MTQyNjk4OSwiZXhwIjoxNzU0MDE4OTg5LCJhdWQiOlsiYXBwL2JhY2tlbmQiXSwidWlkIjoxOTczMTYwMywiYXBwX2lkIjoiQURfMmZEYThETExYb0ZnS3Q5d3VZd0pCWFg4YVlaIn0.mqY5xfTy3miD-7F1m-PT36bLpMAq9SvQjKEdLBiXi8yxNieEYyh5_tYrGYti843ShN-z63BL_090Z6x9KyVFCg'
  }
}

// API 路径
const API_PATHS = {
  deviceList: '/v2/device/list',
  deviceInfo: '/v2/device/info',
  deviceStatus: '/v2/device/status'
  // 可以根据需要添加更多API路径
}

// 动态生成UTC时间字符串
function getUTCDateString() {
  const now = new Date()
  const yyyy = now.getUTCFullYear()
  const MM = String(now.getUTCMonth() + 1).padStart(2, '0')
  const dd = String(now.getUTCDate()).padStart(2, '0')
  const HH = String(now.getUTCHours()).padStart(2, '0')
  const mm = String(now.getUTCMinutes()).padStart(2, '0')
  const ss = String(now.getUTCSeconds()).padStart(2, '0')
  return `${yyyy}${MM}${dd}T${HH}${mm}${ss}Z`
}

// 通用请求方法
async function request(path, data = {}, method = 'POST') {
  // 直接从 store 获取 token
  const accessToken = getTokenFromStore()
  
  if (!accessToken) {
    throw new Error('缺少访问令牌，请先登录')
  }
  
  try {
    console.log(`开始请求: ${BASE_URL}${path}`, data)
    
    // httpRequest 为回调风格（对齐 uni.request），这里 Promise 化保持原有 await 用法与出参结构 { statusCode, data }
    const res = await new Promise((resolve, reject) => {
      httpRequest({
        url: `${BASE_URL}${path}`,
        method,
        header: {
          'X-Tg-App-Id': APP_ID,
          'X-Tg-Platform': PLATFORM,
          'X-Tg-Sdk-Version': SDK_VERSION,
          'Accept-Language': LANGUAGE,
          'X-Tg-App-Pkgname': PKGNAME,
          'Authorization': accessToken,
          'X-Tg-Date': getUTCDateString(),
          'X-Tg-App-Version': APP_VERSION,
          'Content-Type': 'application/json'
        },
        data,
        success: resolve,
        fail: reject
      })
    })
    
    console.log(`请求响应: ${BASE_URL}${path}`, res)
    
    // 完整记录响应
    if (!res.data) {
      const error = new Error('请求响应为空')
      error.response = res
      throw error
    }
    
    if (res.data.code !== 200) {
      const error = new Error(res.data.msg || `API错误码: ${res.data.code}`)
      error.code = res.data.code
      error.response = res
      error.requestPath = path
      error.requestData = data
      throw error
    }
    
    return res.data.data
  } catch (e) {
    // 统一增强错误对象
    if (!e.requestPath) {
      e.requestPath = path
    }
    if (!e.requestData) {
      e.requestData = data
    }
    console.error(`请求失败: ${BASE_URL}${path}`, e)
    throw e
  }
}

// 获取设备列表
export async function fetchDeviceList({ offset = 0, limit = 20 } = {}) {
  const data = await request(API_PATHS.deviceList, { offset, limit })
  return data.items || []
}

// 获取设备详情
export async function fetchDeviceInfo(deviceId) {
  return await request(API_PATHS.deviceInfo, { device_id: deviceId })
}

// 获取设备状态
export async function fetchDeviceStatus(deviceId) {
  return await request(API_PATHS.deviceStatus, { device_id: deviceId })
} 