// 主题配置文件 - 基于UI设计稿的配色方案
// 参考：property-ui.html (深色) 和 property-ui-light.html (亮色)

// 深色主题配置
export const darkTheme = {
  // 背景色
  bgPrimary: 'linear-gradient(180deg, #0a0f1a 0%, #0d1520 100%)',
  bgSecondary: 'hsl(220, 25%, 12%)',
  bgCard: 'rgba(255, 255, 255, 0.08)',
  bgCardHover: 'rgba(255, 255, 255, 0.12)',
  bgInput: 'rgba(255, 255, 255, 0.06)',
  bgInputFocus: 'rgba(255, 255, 255, 0.1)',
  
  // 文字颜色
  textPrimary: 'hsl(220, 15%, 96%)',
  textSecondary: 'hsl(220, 15%, 65%)',
  textTertiary: '#94a3b8',
  
  // 主题色
  colorAccent: 'hsl(200, 85%, 55%)',
  colorAccentGradient: 'linear-gradient(135deg, hsl(200, 85%, 55%) 0%, hsl(210, 85%, 50%) 100%)',
  
  // 功能色
  colorSuccess: 'hsl(145, 65%, 45%)',
  colorWarning: 'hsl(35, 90%, 55%)',
  colorError: '#ff3b30',
  colorInfo: 'hsl(200, 85%, 55%)',
  
  // 边框和分割线
  borderColor: 'rgba(255, 255, 255, 0.12)',
  dividerColor: 'rgba(255, 255, 255, 0.08)',
  
  // 渐变背景
  gradientPurple: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
  gradientGreen: 'linear-gradient(135deg, #34c759 0%, #30d158 100%)',
  gradientBlue: 'linear-gradient(135deg, #0a84ff 0%, #0066cc 100%)',
  gradientOrange: 'linear-gradient(135deg, #ff9500 0%, #ff6b00 100%)',
  gradientRed: 'linear-gradient(135deg, #ff2d55 0%, #ff375f 100%)',
  gradientCyan: 'linear-gradient(135deg, #0ea5e9 0%, #0284c7 100%)',
  gradientViolet: 'linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%)',
  
  // 阴影
  shadowCard: '0 4rpx 16rpx rgba(0, 0, 0, 0.3)',
  shadowCardHover: '0 20rpx 40rpx -10px rgba(0, 0, 0, 0.4)',
  shadowButton: '0 10px 30px -10px rgba(56, 189, 248, 0.5)',
  
  // 透明度
  opacity: {
    light: '0.6',
    medium: '0.8',
    heavy: '0.9'
  }
}

// 亮色主题配置  
export const lightTheme = {
  // 背景色
  bgPrimary: 'linear-gradient(180deg, #f8fafc 0%, #f1f5f9 100%)',
  bgSecondary: 'hsl(220, 20%, 97%)',
  bgCard: '#ffffff',
  bgCardHover: '#ffffff',
  bgInput: 'hsl(220, 15%, 92%)',
  bgInputFocus: '#ffffff',
  
  // 文字颜色
  textPrimary: 'hsl(220, 25%, 20%)',
  textSecondary: 'hsl(220, 10%, 55%)',
  textTertiary: '#64748b',
  
  // 主题色
  colorAccent: 'hsl(210, 100%, 50%)',
  colorAccentGradient: 'linear-gradient(135deg, hsl(210, 100%, 50%) 0%, hsl(220, 90%, 55%) 100%)',
  
  // 功能色
  colorSuccess: 'hsl(145, 65%, 42%)',
  colorWarning: 'hsl(35, 95%, 50%)',
  colorError: '#ff3b30',
  colorInfo: 'hsl(210, 100%, 50%)',
  
  // 边框和分割线
  borderColor: 'rgba(0, 0, 0, 0.08)',
  dividerColor: 'hsl(220, 15%, 92%)',
  
  // 渐变背景
  gradientPurple: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
  gradientGreen: 'linear-gradient(135deg, #34c759 0%, #30d158 100%)',
  gradientBlue: 'linear-gradient(135deg, #0a84ff 0%, #0066cc 100%)',
  gradientOrange: 'linear-gradient(135deg, #ff9500 0%, #ff6b00 100%)',
  gradientRed: 'linear-gradient(135deg, #ff2d55 0%, #ff375f 100%)',
  gradientCyan: 'linear-gradient(135deg, #0ea5e9 0%, #0284c7 100%)',
  gradientViolet: 'linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%)',
  
  // 阴影
  shadowCard: '0 4rpx 16rpx rgba(0, 0, 0, 0.05)',
  shadowCardHover: '0 12rpx 32rpx -8px rgba(0, 0, 0, 0.12)',
  shadowButton: '0 8px 24px -8px rgba(59, 130, 246, 0.5)',
  
  // 透明度
  opacity: {
    light: '0.6',
    medium: '0.8',
    heavy: '0.9'
  }
}

// 获取当前主题配置
export const getTheme = (isDark) => {
  return isDark ? darkTheme : lightTheme
}

// 导出主题变量获取函数，便于在组件中使用
export const useThemeVars = (isDark) => {
  const theme = getTheme(isDark)
  return {
    ...theme,
    // 计算属性：根据主题返回不同的值
    getStatusColor: (online) => {
      return online ? theme.colorSuccess : theme.textTertiary
    },
    getBadgeBackground: (type) => {
      const backgrounds = {
        success: isDark ? 'rgba(52, 199, 89, 0.2)' : 'rgba(52, 199, 89, 0.12)',
        warning: isDark ? 'rgba(255, 149, 0, 0.2)' : 'rgba(255, 149, 0, 0.12)',
        error: isDark ? 'rgba(255, 59, 48, 0.2)' : 'rgba(255, 59, 48, 0.12)',
        info: isDark ? 'rgba(56, 189, 248, 0.2)' : 'rgba(59, 130, 246, 0.12)'
      }
      return backgrounds[type] || backgrounds.info
    }
  }
}
