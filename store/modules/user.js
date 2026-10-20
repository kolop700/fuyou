import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import userApi from '@/api/user/user'
import deviceApi from '@/api/device/device' // 引入设备API
import { useDeviceStore } from './device'
import { useAdControlStore, AD_CONTROL_STORAGE_KEY, AD_ENUM_TO_SWITCHES, switchesToLegacyEnum } from './adControl' // 引入广告控制 store（含开关缓存键、旧枚举映射与反推）
import { useAdStore } from './ad' // 引入广告 store（横幅预加载）
import { applyVipAdControl, syncVipStatus, clearVip } from '@/utils/vipUtils' // 【VIP 免广告】状态同步与广告拦截（见 utils/vipUtils.js）

export const useUserStore = defineStore('user', () => {
  const userInfo = ref({})
  const user_id = ref('')
  const maxExpireDate = ref('') // 最大过期日期
  const adType = ref('') // 新增广告类型
  
  // 设备相关信息
  const deviceToken = ref('') // 设备访问令牌
  const deviceUserId = ref('') // 设备用户ID
  
  // 基础图片URL
  const BASE_IMG_URL = 'https://fuyou.yefiot.com/yefiot/v1/'
  
  // 头像完整URL的计算属性
  const avatarUrl = computed(() => {
    if (userInfo.value.user_face_url && userInfo.value.user_face_tag) {
      return `${BASE_IMG_URL}${userInfo.value.user_face_url}?tag=${userInfo.value.user_face_tag}`
    }
    return '' // 返回默认头像或空字符串
  })

  // 获取用户卡号A
  const userCardA = computed(() => {
    return userInfo.value.user_card_a || '00000000'
  })

  // 获取用户卡号B
  const userCardB = computed(() => {
    return userInfo.value.user_card_b || '00000000'
  })

  // 判断是否登录
  const isLogin = computed(() => {
    return !!userInfo.value.user_acct && !! userInfo.value.user_password
  })
  // 获取账号
  const userAcct = computed(() => {
    return userInfo.value.user_acct || ''
  })

  // 获取用户名
  const userName = computed(() => {
    return userInfo.value.user_name || ''
  })

  // 获取用户ID
  const userId = computed(() => {
    return userInfo.value.user_id || ''
  })

  // 获取密码
  const userPassword = computed(() => {
    return userInfo.value.user_password || ''
  })

  // 设置设备访问令牌
  function setDeviceToken(token) {
    deviceToken.value = token
    console.log('已设置设备访问令牌:', token)
  }
  
  // 获取设备访问令牌
  function getDeviceToken() {
    return deviceToken.value
  }
  
  // 设置设备用户ID
  function setDeviceUserId(id) {
    deviceUserId.value = id
    console.log('已设置设备用户ID:', id)
  }
  
  // 获取设备用户ID
  function getDeviceUserId() {
    return deviceUserId.value
  }

  // 登录方法
  async function login(loginDataOrOptions = null, options = {}) {
    try {
      let loginData = null;
      let requestOptions = options;

      // 如果第一个参数是对象，且包含 showLoading，则它是 options
      if (loginDataOrOptions && 'showLoading' in loginDataOrOptions) {
        requestOptions = loginDataOrOptions;
      } else {
        loginData = loginDataOrOptions;
      }

      // 如果没有传入登录数据且userInfo中没有账号密码，直接返回
      if (!loginData && (!userInfo.value.user_acct || !userInfo.value.user_password)) {
        return Promise.reject('无登录数据')
      }
      
      // 使用传入的登录数据或userInfo中的账号密码
      const loginParams = loginData || {
        user_acct: userInfo.value.user_acct,
        user_password: userInfo.value.user_password
      }

      const res = await userApi.UserLogin(loginParams, requestOptions)
      
      // 登录成功,保存用户信息
      const userData = res.data[0]
      loginSuccess(userData, requestOptions)
      return Promise.resolve(res)
    } catch (error) {
      return Promise.reject(error)
    }
  }

  // 检查登录状态，未登录则跳转到登录页
  function checkLogin() {
    if (!isLogin.value) {
      uni.navigateTo({
        url: '/user_package/pages/login/index'
      })
      return false
    }
    return true
  }

  // 获取用户房间列表并更新最大过期日期
  async function updateRoomList(options = {}) {
    try {
      const res = await userApi.getUserRoomList(user_id.value, options)
      if (res.data && res.data.length > 0) {
        // 找出最大的expire_date
        const maxDate = res.data.reduce((max, room) => {
          return room.expire_date > max ? room.expire_date : max
        }, res.data[0].expire_date)
        maxExpireDate.value = maxDate

        // 【广告独立开关】按房间逐项 OR：任一房间开启某类广告 → 该类广告开启
        // 只聚合有效房间（status=1）；房间级取值优先新四列（ad_splash/ad_banner/ad_rewarded/ad_interstitial），
        // 列值为 NULL/哨兵9（未配置，福优老表无这些列时接口不返回同样回退）时回退旧枚举 ad_prod_app 映射
        const sws = { splash: 0, banner: 0, rewarded: 0, interstitial: 0 }
        res.data.forEach((room) => {
          if (String(room.status) !== '1') return // 失效房间不参与广告开关计算
          const legacy = AD_ENUM_TO_SWITCHES[String(room.ad_prod_app)] || AD_ENUM_TO_SWITCHES['0']
          // 列值：0/1 直接采用；NULL/空串/哨兵9 回退旧枚举
          const pick = (col, legacyVal) => {
            const n = Number(col)
            return col === null || col === undefined || col === '' || n === 9 ? legacyVal : n === 1 ? 1 : 0
          }
          sws.splash = Math.max(sws.splash, pick(room.ad_splash, legacy.splash))
          sws.banner = Math.max(sws.banner, pick(room.ad_banner, legacy.banner))
          sws.rewarded = Math.max(sws.rewarded, pick(room.ad_rewarded, legacy.rewarded))
          sws.interstitial = Math.max(sws.interstitial, pick(room.ad_interstitial, legacy.interstitial))
        })
        console.log('广告独立开关（多房间有效房OR后）:', sws)

        // 旧字段兼容：adType 仍按开关组合反推枚举（仅供页面日志/旧展示逻辑，广告判定不再使用它）
        adType.value = switchesToLegacyEnum(sws)

        // 缓存广告开关对象（供下次冷启动 App.vue 判断开屏；开屏关时跳过开屏）
        try {
          uni.setStorageSync(AD_CONTROL_STORAGE_KEY, sws)
        } catch (e) {
          console.error('[广告] 广告开关缓存写入失败', e)
        }

        // 【VIP 免广告】VIP 用户界面广告全关（只关横幅/激励/插屏，不动开屏）；
        // 非 VIP 按房间开关正常设置并预热横幅。
        if (applyVipAdControl()) {
          console.log('[VIP] 已拦截房间广告开关设置（房间计算值仅存缓存，未生效）')
        } else {
          // 获取广告控制 store 并按房间计算值设置四项开关
          const adControlStore = useAdControlStore()
          adControlStore.setAdSwitches(sws)

          // 横幅开关开启时才预热（提前竞价，用户进入页面时可直接复用展示）
          if (adControlStore.showBanner) {
            useAdStore().preloadBanner()
          }
        }
      } else {
        // 无房间（无广告配置依据）：清除广告开关缓存，开屏按默认展示
        try {
          uni.removeStorageSync(AD_CONTROL_STORAGE_KEY)
        } catch (e) {
          console.error('[广告] 广告开关缓存清除失败', e)
        }
      }
      
      // 同时刷新设备列表
      try {
        const deviceStore = useDeviceStore()
        const deviceRes = await deviceApi.getDoorList(user_id.value, options)
        if (deviceRes.data) {
          deviceStore.setDeviceList(deviceRes.data)
          console.log('设备列表已更新')
        }
      } catch (deviceError) {
        console.error('更新设备列表失败:', deviceError)
        // 如果获取设备失败，且返回 code === '1'，说明暂无设备，应清空列表
        if (deviceError && deviceError.code === '1') {
          const deviceStore = useDeviceStore()
          deviceStore.setDeviceList([])
        }
      }
      
      console.log("更新房间列表", res)
      return Promise.resolve(res)
    } catch (error) {
      console.log("更新房间列表失败", error)
      maxExpireDate.value = userInfo.value.expire_date
      // 不再强制跳转到房屋申请页面，用户可以自主选择是否申请
      // if (error.code === '1') {
      //   uni.navigateTo({
      //     url: '/pages/house/apply'
      //   })
      // }
      return Promise.reject(error)
    }
  }

  // 登录成功
  async function loginSuccess(data, options = {}) {
    userInfo.value = data
    user_id.value = data.user_id
    console.log("广告类型", userInfo.value.ad_type_app)
    try {
      // 【换账号防御】先清零上个账号可能残留的 VIP 状态，再同步会员状态
      //（福优暂无 getVipStatus 接口，syncVipStatus 保持本地缓存，默认 normal）
      clearVip()
      await syncVipStatus(data.user_id)

      // 登录成功后默认刷新房间/设备列表；头像上传等场景可关闭，避免隐藏页面 swiper 被动重建。
      if (options.refreshRoomList !== false) {
        await updateRoomList(options)
      }

      // 默认不额外清空设备列表。updateRoomList 内部已刷新设备列表，避免 App 端 swiper 因清空再填充触发卸载异常。
      if (options.refreshDevices === true) {
        const deviceStore = useDeviceStore()
        try {
          const res = await deviceApi.getDoorList(data.user_id, options)
          if (res.data) {
            deviceStore.setDeviceList(res.data)
          }
        } catch (deviceError) {
          console.error('单独刷新设备列表失败:', deviceError)
          if (deviceError && deviceError.code === '1') {
            deviceStore.setDeviceList([])
          }
        }
      }
    } catch (error) {
      console.error('初始化数据失败:', error)
    }
  }

  // 退出登录
  function logout() {
    userInfo.value = {}
    user_id.value = ''
    deviceToken.value = '' // 清除设备令牌
    deviceUserId.value = '' // 清除设备用户ID
    // 【VIP 免广告】清除会员状态，防止残留到下一个账号
    clearVip()
    // 【广告开关缓存】清除房间广告开关缓存（防止上一账号的缓存影响下一账号冷启动开屏）
    try {
      uni.removeStorageSync(AD_CONTROL_STORAGE_KEY)
    } catch (e) {
      console.error('[广告] 广告开关缓存清除失败', e)
    }
    // 清空设备列表
    const deviceStore = useDeviceStore()
    deviceStore.clearDeviceList()
  }

  // 注销账号
  async function deleteAccount() {
    try {
      // 调用注销账号的API
      const response = await userApi.deleteAccount(user_id.value);
    } catch (error) {
      console.error('注销账号失败:', error);
      console.error('注销账号失败:', error.code);
      // 检查响应的code
      if (error.code === '1') {
        // 清除本地数据
        logout();
        return Promise.resolve('成功');
      } else {
        console.error('注销账号失败:', response);
        return Promise.reject(new Error('注销账号失败'));
      }
    }
  }

  const getUserRoomList = async () => {
    try {
      const res = await userApi.getUserRoomList(user_id.value)
      return res.data || []
    } catch (error) {
      console.error('获取房屋列表失败:', error)
      return []
    }
  }

  const bindUserRoom = async (params) => {
    return await userApi.bindUserRoom(params)
  }

  // 设置账号
  function setUserAccount(account) {
    userInfo.value.user_acct = account
  }

  // 设置密码
  function setUserPassword(password) {
    userInfo.value.user_password = password
  }

  return {
    userInfo,
    user_id,
    maxExpireDate,
    login,
    loginSuccess,
    logout,
    deleteAccount,  // 导出注销方法
    avatarUrl,
    BASE_IMG_URL,
    isLogin,
    userName,
    userAcct,
    userId,
    userPassword,  // 导出密码获取方法
    setUserPassword,  // 导出密码设置方法
    checkLogin,
    updateRoomList,
    getUserRoomList,
    bindUserRoom,
    userCardA,
    userCardB,
    setUserAccount,  // 导出设置账号方法
    setUserPassword,  // 导出设置密码方法
    adType,
    // 设备相关
    deviceToken,
    deviceUserId,
    setDeviceToken,
    getDeviceToken,
    setDeviceUserId,
    getDeviceUserId
  }
}) 

// 使用例子
// const { proxy } = getCurrentInstance()
// const userStore = proxy.$store.user.useUserStore()

// // 登录成功时
// userStore.loginSuccess(userData)

// // 获取用户信息
// const userInfo = userStore.userInfo

// // 退出登录
// userStore.logout()

// const { proxy } = getCurrentInstance()
// const userStore = proxy.$store.user.useUserStore()

// // 获取用户名
// const userName = userStore.userName

// // 获取用户ID
// const userId = userStore.userId

// // 在template中使用
// <text>{{ userStore.userName }}</text>
// <text>{{ userStore.userId }}</text>


// const { proxy } = getCurrentInstance()
// const userStore = proxy.$store.user.useUserStore()

// // 在需要登录才能访问的页面或方法中
// function someAction() {
//   // 检查是否登录，未登录会自动跳转到登录页
//   if (!userStore.checkLogin()) {
//     return // 如果未登录，终止后续操作
//   }
  
//   // 已登录，继续执行相关操作
//   // ...
// }

// // 或者在页面加载时检查
// onLoad(() => {
//   userStore.checkLogin()
// })
