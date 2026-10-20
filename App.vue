<script setup>
import { onLaunch, onShow, onHide } from '@dcloudio/uni-app'
import { computed, getCurrentInstance, watch } from 'vue'
import TakuAds, { TAKU_CONFIG } from '@/common/taku-sdk'
import { useAgreementStore } from '@/store/modules/agreement'
import { useAdStore } from '@/store/modules/ad'
// 【VIP 免广告范围】开屏（启动封面）广告不免：不按 isVip 跳过；
// 界面内广告（横幅/插屏/激励）由原生壳 load/show 入口代码级拦截（见 shell AdManager/AdBridge）
import { AD_CONTROL_TYPES, AD_CONTROL_STORAGE_KEY } from '@/store/modules/adControl' // 【广告开关】开屏跳过判断（缓存对象 splash=0 或旧枚举 '0' 时跳过）

const { proxy } = getCurrentInstance()

// 启动时刻与开屏展示窗口：加载成功但已超出窗口（用户可能已在操作）则放弃展示
const launchAt = Date.now()
const SPLASH_SHOW_WINDOW_MS = 10000

// 开屏广告：广告 SDK 初始化成功后调用（冷启动单次；跳过条件仅余广告开关缓存开屏关；
// 原生壳侧为纯响应式（仅响应 ad.splash.load 调用），故此处 H5 判断即完整控制点，详见 store/modules/ad.js）
const loadSplashAd = () => {
	// 【开屏不免广告】VIP 用户也展示开屏（产品约定：免广告仅覆盖 App 界面内广告）
	// 【广告开关缓存】上次登录算出的房间广告开关缓存「开屏关」 → 连开屏一起跳过
	let cachedAd = null
	try {
		cachedAd = uni.getStorageSync(AD_CONTROL_STORAGE_KEY) || ''
	} catch (e) {
		// 读取失败按无缓存处理（默认展示开屏）
	}
	// 新格式：登录后写入的开关对象 {splash,banner,rewarded,interstitial}，splash 非 1 则跳过；
	// 旧格式（升级前的枚举字符串）：仅 '0'（都不显示）跳过开屏，保持旧行为不误伤
	const splashOff =
		cachedAd && typeof cachedAd === 'object'
			? Number(cachedAd.splash) !== 1
			: String(cachedAd) === AD_CONTROL_TYPES.NONE
	if (splashOff) {
		console.log('[TakuAds] 广告开关缓存：开屏已关，跳过开屏广告')
		return
	}
	const splashId = useAdStore().getSplashAdId()
	if (!splashId) {
		console.log('[TakuAds] 未配置开屏广告位，跳过开屏')
		return
	}
	let shown = false
	TakuAds.loadSplashAd({ placementId: splashId }, {
		onAdLoaded: () => {
			if (shown || Date.now() - launchAt > SPLASH_SHOW_WINDOW_MS) {
				console.log('[TakuAds] 开屏加载成功但已超出启动窗口，放弃展示')
				return
			}
			shown = true
			TakuAds.showSplashAd({ placementId: splashId })
		},
		onAdFailed: (res) => {
			console.log('[TakuAds] 开屏广告加载失败', res)
		},
		onAdShow: () => {
			console.log('[TakuAds] 开屏广告展示')
		},
		onAdClosed: () => {
			console.log('[TakuAds] 开屏广告关闭')
		}
	})
}

// Taku 广告 SDK 初始化（隐私合规时序，重复调用幂等）：
// - Android：系统隐私弹窗同意后才进入/加载，可直接初始化；
// - iOS：需应用内同意《隐私政策》（首次弹窗/登录页勾选写入 agreement store）后才初始化
const initTakuIfAgreed = () => {
	// #ifdef APP-PLUS || H5
	const sys = uni.getSystemInfoSync()
	const agreed = sys.platform === 'ios' ? useAgreementStore().checkAgreement() : true
	if (agreed) {
		TakuAds.init(TAKU_CONFIG, (res) => {
			console.log('[TakuAds] 初始化结果', res)
			if (res && res.code === 0) loadSplashAd()
		})
	}
	// #endif
}

onLaunch(() => {
	console.log('App Launch')
	// Taku 初始化 + 开屏（未配置 appId/appKey 时 init 安全失败，全链路自动不出广告）
	initTakuIfAgreed()
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
