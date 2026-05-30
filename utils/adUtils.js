import { useAdStore } from '../store/modules/ad'
import { useAdControlStore } from '../store/modules/adControl'
import { getActivePinia } from 'pinia'

class AdManager {
  constructor() {
    this.rewardedVideoAd = null
    this.interstitialAd = null
    this.adStore = null
    this.adControlStore = null
    this.urlCallback = null
    
    // 广告配置
    this.config = {
      maxDailyCount: 15,    // 每天最大展示次数
      minInterval: 10000,   // 最小间隔时间（毫秒）
      resetHour: 0,         // 每天重置时间（0-23）
      resetMinute: 0        // 重置分钟（0-59）
    }
  }

  // 设置URL回调参数
  setUrlCallback(callback) {
    this.urlCallback = callback
  }

  // 初始化store
  initStore(adStore, adControlStore) {
    console.log('初始化广告 Store:', {
      adStore: !!adStore,
      adControlStore: !!adControlStore,
      adStoreType: adStore ? typeof adStore : 'undefined',
      adControlStoreType: adControlStore ? typeof adControlStore : 'undefined'
    })

    this.adStore = adStore
    this.adControlStore = adControlStore

    // 检查 store 是否正确初始化
    if (!this.adStore || !this.adControlStore) {
      console.error('Store 初始化失败:', {
        adStore: this.adStore,
        adControlStore: this.adControlStore
      })
      return
    }

    console.log('Store 初始化成功，当前广告控制状态:', {
      广告类型: this.adControlStore.adTypeDescription,
      是否显示激励广告: this.adControlStore.showRewarded,
      是否显示插屏广告: this.adControlStore.showInterstitial
    })

    // 初始化状态
    this.initState()
  }

  // 获取今天的重置时间戳
  getTodayResetTimestamp() {
    const now = new Date()
    const resetTime = new Date(
      now.getFullYear(),
      now.getMonth(),
      now.getDate(),
      this.config.resetHour,
      this.config.resetMinute,
      0,
      0
    )
    
    // 如果当前时间小于重置时间，返回前一天的重置时间
    if (now < resetTime) {
      resetTime.setDate(resetTime.getDate() - 1)
    }
    
    return resetTime.getTime()
  }

  // 初始化状态
  initState() {
    const savedState = uni.getStorageSync('adState') || {}
    const currentResetTimestamp = this.getTodayResetTimestamp()
    
    // 检查是否需要重置（如果没有上次重置时间或上次重置时间小于当前重置时间）
    if (!savedState.lastResetTime || savedState.lastResetTime < currentResetTimestamp) {
      this.state = {
        lastResetTime: currentResetTimestamp,
        rewardedCount: 0,
        interstitialCount: 0,
        lastRewardedTime: 0,
        lastInterstitialTime: 0
      }
      console.log('广告计数已重置')
    } else {
      this.state = savedState
    }
    
    this.saveState()
  }

  // 检查是否需要重置状态
  checkAndResetState() {
    const currentResetTimestamp = this.getTodayResetTimestamp()
    if (this.state.lastResetTime < currentResetTimestamp) {
      this.state = {
        lastResetTime: currentResetTimestamp,
        rewardedCount: 0,
        interstitialCount: 0,
        lastRewardedTime: 0,
        lastInterstitialTime: 0
      }
      this.saveState()
      console.log('广告计数已重置')
      return true
    }
    return false
  }

  // 保存状态到本地存储
  saveState() {
    uni.setStorageSync('adState', this.state)
  }

  // 初始化广告实例
  init() {
    console.log('Ads module disabled to prevent HTML5+ Runtime error')
    return false
  }

  // 设置广告事件监听
  setupAdListeners() {
    if (this.rewardedVideoAd) {
      // 激励广告事件
      this.rewardedVideoAd.onLoad(() => {
        console.log('激励广告加载成功')
      })
      this.rewardedVideoAd.onError((err) => {
        console.log('激励广告加载失败', err)
        // 先检查限制，避免不必要的广告加载
        if (this.canShowAd('interstitial')) {
            this.showInterstitialAd();
        } else {
            console.log('插屏广告展示间隔不足，无法展示插屏广告')
        }
      })

      this.rewardedVideoAd.onClose((res) => {
        // 无论是否完整观看都更新计数和时间
        this.updateAdCount('rewarded')
        if (res && res.isEnded) {
          console.log("广告播放完成，发放奖励")
        } else {
          console.log("广告播放中途退出，不能获得奖励")
        }
      })
    }

    if (this.interstitialAd) {
      // 插屏广告事件
      this.interstitialAd.onLoad(() => {
        console.log('插屏广告加载成功')
      })

      this.interstitialAd.onError((err) => {
        console.log('插屏广告加载失败', err)
      })

      this.interstitialAd.onClose(() => {
        console.log('插屏广告关闭')

        this.updateAdCount('interstitial')
      })
    }
  }

  // 更新广告计数
  updateAdCount(type) {
    if (type === 'rewarded') {
      this.state.rewardedCount++
      this.state.lastRewardedTime = Date.now()
      console.log(`激励广告展示次数：${this.state.rewardedCount}/${this.config.maxDailyCount}`)
    } else if (type === 'interstitial') {
      this.state.interstitialCount++
      this.state.lastInterstitialTime = Date.now()
      console.log(`插屏广告展示次数：${this.state.interstitialCount}/${this.config.maxDailyCount}`)
    }
    
    // 记录总的统计信息
    console.log('当前广告统计信息:', {
      激励广告: `${this.state.rewardedCount}/${this.config.maxDailyCount}`,
      插屏广告: `${this.state.interstitialCount}/${this.config.maxDailyCount}`,
      下次重置时间: new Date(this.getTodayResetTimestamp() + 24 * 60 * 60 * 1000).toLocaleString()
    })
    
    this.saveState()
  }

  // 显示广告（自动选择类型）
  async showAd() {
    console.log('Ads disabled, executing callback directly')
    return false
  }

  // 显示激励广告
  async showRewardedAd() {
    if (!this.rewardedVideoAd) {
      console.error('激励广告实例未初始化')
      return false
    }

    try {
      console.log('开始展示激励广告')
      await this.rewardedVideoAd.show()
      console.log('激励广告展示成功')
      return true
    } catch (err) {
      console.log('激励广告显示失败，尝试重新加载:', err)
      try {
        await this.rewardedVideoAd.load()
        await this.rewardedVideoAd.show()
        console.log('激励广告重新加载并展示成功')
        return true
      } catch (err) {
        console.error('激励广告重新加载失败，详细错误:', err)
        return false
      }
    }
  }

  // 显示插屏广告
  async showInterstitialAd() {
    if (!this.interstitialAd) {
      console.error('插屏广告实例未初始化')
      return false
    }

    try {
      console.log('开始展示插屏广告')
      await this.interstitialAd.show()
      console.log('插屏广告展示成功')
      return true
    } catch (err) {
      console.log('插屏广告显示失败，尝试重新加载:', err)
      try {
        await this.interstitialAd.load()
        await this.interstitialAd.show()
        console.log('插屏广告重新加载并展示成功')
        return true
      } catch (err) {
        console.error('插屏广告重新加载失败，详细错误:', err)
        // uni.showToast({
        //   title: '广告加载失败',
        //   icon: 'none'
        // })
        return false
      }
    }
  }

  // 检查是否可以展示广告
  canShowAd(type) {
    const now = Date.now()
    const lastTime = type === 'rewarded' ? this.state.lastRewardedTime : this.state.lastInterstitialTime
    const timeDiff = now - lastTime
    
    if (timeDiff < this.config.minInterval) {
      // console.log(`广告展示间隔不足${this.config.minInterval / 1000}秒，还需等待${((this.config.minInterval - timeDiff) / 1000).toFixed(1)}秒`)
      // uni.showToast({
      //   title: `请等待${((this.config.minInterval - timeDiff) / 1000).toFixed(1)}秒后再试`,
      //   icon: 'none'
      // })
      return false
    }
    return true
  }

  // 检查是否达到每日限制
  checkDailyLimit(type) {
    this.checkAndResetState() // 检查是否需要重置
    const count = type === 'rewarded' ? this.state.rewardedCount : this.state.interstitialCount
    
    if (count >= this.config.maxDailyCount) {
      console.log(`广告展示受限：${type}类型已达到每日${this.config.maxDailyCount}次限制`)
      console.log('统计信息:', {
        类型: type,
        当前次数: count,
        每日上限: this.config.maxDailyCount,
        下次重置时间: new Date(this.getTodayResetTimestamp() + 24 * 60 * 60 * 1000).toLocaleString()
      })
      // uni.showToast({
      //   title: '已达到今日展示上限',
      //   icon: 'none'
      // })
      return false
    }
    return true
  }

  // 获取当前广告统计信息
  getAdStats() {
    this.checkAndResetState() // 检查是否需要重置
    return {
      rewardedCount: this.state.rewardedCount,
      interstitialCount: this.state.interstitialCount,
      maxDailyCount: this.config.maxDailyCount,
      nextResetTime: new Date(this.getTodayResetTimestamp() + 24 * 60 * 60 * 1000)
    }
  }

  // 销毁广告实例
  destroy() {
    if (this.rewardedVideoAd) {
      this.rewardedVideoAd.destroy()
      this.rewardedVideoAd = null
    }
    if (this.interstitialAd) {
      this.interstitialAd.destroy()
      this.interstitialAd = null
    }
  }
}

// 导出单例
export const adManager = new AdManager()