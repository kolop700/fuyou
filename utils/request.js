import { useUserStore } from '@/store/modules/user';

// 根据环境设置baseURL
const BASE_URL = process.env.NODE_ENV === 'development' && process.env.UNI_PLATFORM === 'h5' 
  ? '' // 开发环境下H5使用代理
  : 'http://test2.yefiot.com'; // 其他环境使用完整URL

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
        uni.request({
            url: BASE_URL + url,
            data: method === 'get' ? params : data,
            method: method,
            header: headers,
            // 收到开发者服务器成功返回的回调函数
            success: (res) => {
                const globalErrorCodes = [401, 404, 408, 500];

                // 优先处理HTTP状态码错误
                if (res.statusCode && res.statusCode !== 200) {
                    const errorMsg = errorMessages[res.statusCode] || '请求失败，请稍后重试';

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
                    return reject({ msg: errorMsg, ...res });
                }

                // 业务逻辑码处理
                const { code, Code } = res.data;
                if (code === "0" || Code === "OK") {
                    return resolve(res.data);
                }

                // 对于业务逻辑错误，直接拒绝Promise，让调用方自行处理
                return reject(res.data);
            },
            // 接口调用失败的回调函数
            fail(error) {
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