import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useThemeStore = defineStore('theme', () => {
  // 主题模式：light/dark
  const themeMode = ref('light')
  
  // 从本地存储加载主题设置
  const loadTheme = () => {
    try {
      const savedTheme = uni.getStorageSync('app_theme_mode')
      if (savedTheme) {
        themeMode.value = savedTheme
      } else {
        // 默认使用亮色主题
        themeMode.value = 'light'
      }
    } catch (e) {
      console.error('加载主题失败:', e)
      themeMode.value = 'light'
    }
  }
  
  // 切换主题
  const toggleTheme = () => {
    themeMode.value = themeMode.value === 'light' ? 'dark' : 'light'
    saveTheme()
  }
  
  // 设置主题
  const setTheme = (mode) => {
    if (mode === 'light' || mode === 'dark') {
      themeMode.value = mode
      saveTheme()
    }
  }
  
  // 保存主题到本地存储
  const saveTheme = () => {
    try {
      uni.setStorageSync('app_theme_mode', themeMode.value)
    } catch (e) {
      console.error('保存主题失败:', e)
    }
  }
  
  // 检查是否为深色主题
  const isDark = () => {
    return themeMode.value === 'dark'
  }
  
  return {
    themeMode,
    loadTheme,
    toggleTheme,
    setTheme,
    isDark
  }
})

// 默认导出，符合store自动导入规范
export default {
  useThemeStore
}
