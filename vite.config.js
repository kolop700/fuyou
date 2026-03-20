import { defineConfig } from 'vite'
import uni from '@dcloudio/vite-plugin-uni'
import AutoImport from 'unplugin-auto-import/vite'
const path = require('path');

// https://vitejs.dev/config/
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
				target: 'http://test2.yefiot.com',
				changeOrigin: true,
				secure: false,
				rewrite: (path) => path
			},
			'/locker': {
				target: 'http://test2.yefiot.com',
				changeOrigin: true,
				secure: false,
                rewrite: (path) => path.replace(/^\/locker/, '/api/locker')
			},
			'/repair': {
				target: 'http://test2.yefiot.com',
				changeOrigin: true,
				secure: false,
                rewrite: (path) => path.replace(/^\/repair/, '/api/repair')
			}
		}
	}
})
