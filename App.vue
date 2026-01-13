<script setup>
import { onLaunch, onShow, onHide } from '@dcloudio/uni-app'
import { computed, getCurrentInstance, watch } from 'vue'

const { proxy } = getCurrentInstance()

onLaunch(() => {
	console.log('App Launch')
	// const userStore = proxy.$store.user.useUserStore()
	
	// // 将登录请求放在后台执行，不阻塞界面加载
	// setTimeout(async () => {
	// 	try {
	// 		await userStore.login({ showLoading: false })
	// 		console.log('自动登录成功')
	// 	} catch (error) {
	// 		console.log('自动登录失败', error)
	// 	}
	// }, 0)
})

onShow(() => {
	console.log('App Show')
})

onHide(() => {
	console.log('App Hide')
})

// 获取主题 Store
const themeStore = proxy.$store.theme.useThemeStore()

// 导入主题配置
import { useThemeVars } from '@/utils/themeConfig.js'

// 主题变量
const theme = computed(() => useThemeVars(themeStore.isDark()))

// uview 组件主题样式 - 动态计算
const actionSheetBg = computed(() => theme.value.bgCard)
const actionSheetTitleColor = computed(() => theme.value.textPrimary)
const actionSheetItemColor = computed(() => theme.value.textPrimary)
const actionSheetCancelColor = computed(() => theme.value.textSecondary)
const actionSheetHoverBg = computed(() => theme.value.bgCardHover)
const actionSheetCloseBg = computed(() => theme.value.bgInput)
const actionSheetLineColor = computed(() => theme.value.borderColor)
const actionSheetGapBg = computed(() => theme.value.bgInput)
</script>

<style lang="scss">
	/* 注意要写在第一行，注意不能引入至uni.scss，同时给style标签加入lang="scss"属性 */
	@import "@/uni_modules/uview-plus/index.scss";
	@import '@/static/fonts/iconfont.css';
	@import 'static/css/common.css';
</style>
