import { useUserStore } from '@/store/modules/user';

// 根据环境设置baseURL
const BASE_URL = process.env.NODE_ENV === 'development' && process.env.UNI_PLATFORM === 'h5' 
  ? '' // 开发环境下H5使用代理
  : 'http://test2.yefiot.com'; // 其他环境使用完整URL，App 端使用 HTTPS 避免明文请求被拦截 http://test2.yefiot.com   https://fuyou.yefiot.com
// 错误代码-消息映射表
const errorMessages = {
    401: '用户验证失败，请先登录',
    404: '未找到资源',
    422: '请求参数错误',
    423: '缺少必填参数',
    408: '请求超时',
    500: '系统错误',
    452: '没有操作权限',
    453: '数据关联(外键)错误，无法删除/修改',
    454: '记录已存在(唯一键重复)',
    455: '记录不存在',
    456: '更新数据库错误',
    457: '密码错误',
    458: '旧密码错误',
    459: '当前状态不允许操作',
    460: '验证码错误或已失效',
    461: '后台相关配置错误',
    464: '设备返回错误'
};

const getErrorMessage = (payload, fallback = '请求失败，请稍后重试') => {
    if (!payload) return fallback;

    if (typeof payload === 'string') {
        return payload;
    }

    return payload.detail || payload.message || payload.msg || fallback;
};

const normalizeRequestUrl = (url = '') => {
    if (!url) return url;

    // H5 开发环境走 vite 代理，保留原始路径
    if (process.env.NODE_ENV === 'development' && process.env.UNI_PLATFORM === 'h5') {
        return url;
    }

    if (url.startsWith('/locker/')) {
        return url.replace(/^\/locker\//, '/api/locker/');
    }

    if (url.startsWith('/repair/')) {
        return url.replace(/^\/repair\//, '/api/repair/');
    }

    return url;
};

const buildDebugUrl = (url, params) => {
    if (!params || typeof params !== 'object') return url;

    const query = Object.entries(params)
        .filter(([, value]) => value !== undefined && value !== null && value !== '')
        .map(([key, value]) => `${encodeURIComponent(key)}=${encodeURIComponent(value)}`)
        .join('&');

    if (!query) return url;
    return `${url}${url.includes('?') ? '&' : '?'}${query}`;
};

const request = ({
    url, // 请求url
    method, // 请求方式：get/post/put/delete
    params, // get请求提交参数
    data, // post/put请求提交参数
    headers, // 请求头
    showLoading = true, // 新增参数，默认为true保持原有行为
}) => {
    return new Promise((resolve, reject) => {
        // 仅在 showLoading 为 true 时显示加载框
        if (showLoading) {
            uni.showLoading({
                title: '加载中',
                mask: true
            });
        }

        if (!headers) {
            const token = uni.getStorageSync('token');
            const userStore = useUserStore();
            const userId = userStore.userInfo?.user_id || 0;

            headers = {
                'Content-Type': 'application/json;charset=utf-8',
                Authorization: token,
                TENANT_ID: 1,
                UserId: userId
            };
        }
        const requestUrl = BASE_URL + normalizeRequestUrl(url);
        const requestData = method === 'get' ? params : data;
        const debugUrl = method === 'get' ? buildDebugUrl(requestUrl, params) : requestUrl;

        if (url?.startsWith('/locker/')) {
            console.log('[request] locker url:', debugUrl);
            console.log('[request] locker method:', method);
            console.log('[request] locker params:', params);
            console.log('[request] locker data:', data);
            console.log('[request] locker headers:', headers);
        }

        uni.request({
            url: requestUrl,
            data: requestData,
            method: method,
            header: headers,
            // 收到开发者服务器成功返回的回调函数
            success: (res) => {
                if (url?.startsWith('/locker/')) {
                    console.log('[request] locker response url:', debugUrl);
                    console.log('[request] locker response status:', res.statusCode);
                    console.log('[request] locker response data:', res.data);
                }

                const globalErrorCodes = [401, 404, 408, 500];

                // 优先处理HTTP状态码错误
                if (res.statusCode && res.statusCode !== 200) {
                    const errorMsg = getErrorMessage(
                        res.data,
                        errorMessages[res.statusCode] || '请求失败，请稍后重试'
                    );

                    // 只对全局错误码进行统一提示
                    if (globalErrorCodes.includes(res.statusCode)) {
                        uni.showToast({
                            icon: 'none',
                            duration: 3000,
                            title: errorMsg,
                        });
                    }

                    // 对401错误做特殊处理，自动跳转到登录页
                    if (res.statusCode === 401) {
                        setTimeout(() => {
                            uni.reLaunch({
                                url: '/user_package/pages/login/index'
                            });
                        }, 1500);
                    }
                    // 将错误继续传递下去，以便业务层捕获
                    return reject({ ...res.data, ...res, msg: errorMsg });
                }

                // 业务逻辑码处理。部分接口成功时直接返回 null，需要先兼容空响应体。
                if (res.data === null || res.data === undefined) {
                    return resolve(res.data);
                }

                const { code, Code } = res.data;

                // 如果code字段不存在，也视为成功（兼容直接返回数据的接口）
                if (code === undefined && Code === undefined) {
                    return resolve(res.data);
                }

                if (code === "0" || Code === "OK") {
                    return resolve(res.data);
                }

                // 对于业务逻辑错误，直接拒绝Promise，让调用方自行处理
                return reject({ ...res.data, msg: getErrorMessage(res.data) });
            },
            // 接口调用失败的回调函数
            fail(error) {
                if (url?.startsWith('/locker/')) {
                    console.log('[request] locker fail url:', debugUrl);
                    console.log('[request] locker fail error:', error);
                }
                console.log('请求错误：', error);
                uni.showToast({
                    icon: 'none',
                    duration: 3000,
                    title: '网络异常，请稍后重试！',
                });
                return reject(error);
            },
            // 接口调用结束的回调函数（调用成功、失败都会执行）
            complete() {
                // 仅在 showLoading 为 true 时隐藏加载框
                if (showLoading) {
                    uni.hideLoading();
                }
            },
        });
    });
};

// 向外暴露request
export default request;
