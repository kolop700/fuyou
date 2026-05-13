import { defineConfig } from 'vite'
import uni from '@dcloudio/vite-plugin-uni'
import AutoImport from 'unplugin-auto-import/vite'
const path = require('path');

// https://vitejs.dev/config/
// http://test2.yefiot.com  测试环境
// https://fuyou.yefiot.com  生产环境
export default defineConfig({
	plugins: [
		uni(),
		AutoImport({
			imports: ['vue', 'vue-router']
		})
	],
	server: {
		proxy: {
			'/yefiot': {
				target: 'https://fuyou.yefiot.com',
				changeOrigin: true,
				secure: false,
				rewrite: (path) => path
			},
			'/locker': {
				target: 'https://fuyou.yefiot.com',
				changeOrigin: true,
				secure: false,
                rewrite: (path) => path.replace(/^\/locker/, '/api/locker')
			},
			'/repair': {
				target: 'https://fuyou.yefiot.com',
				changeOrigin: true,
				secure: false,
                rewrite: (path) => path.replace(/^\/repair/, '/api/repair')
			}
		}
	}
})
