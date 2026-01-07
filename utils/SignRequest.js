import CryptoJS from 'crypto-js'
import dayjs from 'dayjs'

const isUni = typeof uni !== 'undefined' && !!uni.request;

export default class SignRequest {
  constructor(options = {}) {
    this.appId = options.appId || '';
    this.platform = options.platform || 'web';
    this.sdkVersion = options.sdkVersion || '1024';
    this.language = options.language || 'zh-cn';
    this.appStore = options.appStore || '';
    this.pkgname = options.pkgname || '';
    this.authorization = options.authorization || '';
    this.appVersion = options.appVersion || '';
  }

  // 生成签名头部
  getHeaders(extraHeaders = {}) {
    const date = dayjs().utc().format('YYYYMMDDTHHmmss') + 'Z';
    const headers = {
      'X-Tg-App-Id': this.appId,
      'X-Tg-Platform': this.platform,
      'X-Tg-Sdk-Version': this.sdkVersion,
      'Accept-Language': this.language,
      'X-Tg-App-Store': this.appStore,
      'X-Tg-App-Pkgname': this.pkgname,
      'Authorization': this.authorization,
      'X-Tg-Date': date,
      'X-Tg-App-Version': this.appVersion,
      ...extraHeaders
    };
    // 过滤掉空值
    Object.keys(headers).forEach(key => {
      if (headers[key] === '' || headers[key] == null) delete headers[key];
    });
    return headers;
  }

  // 发起请求
  async request(url, { method = 'GET', headers = {}, body = null, ...rest } = {}) {
    const allHeaders = this.getHeaders(headers);
    if (isUni) {
      // uni.request 方式
      return new Promise((resolve, reject) => {
        uni.request({
          url,
          method,
          header: allHeaders,
          data: body ? (typeof body === 'string' ? JSON.parse(body) : body) : {},
          ...rest,
          success: res => resolve({
            json: () => Promise.resolve(res.data),
            status: res.statusCode,
            ...res
          }),
          fail: reject
        });
      });
    } else {
      // fetch 方式
      const options = {
        method,
        headers: allHeaders,
        ...rest
      };
      if (body) {
        options.body = typeof body === 'string' ? body : JSON.stringify(body);
        if (!options.headers['Content-Type']) {
          options.headers['Content-Type'] = 'application/json';
        }
      }
      return fetch(url, options);
    }
  }

  // 生成服务端签名头部 (TGV1-HMAC-SHA256)
  static buildTangeHeadersAndBody({
    method = 'GET',
    uri = '/',
    params = {},
    headers = {},
    accessKey = '',
    accessSecret = '',
    appId = '',
  }) {
    method = method.toUpperCase();
    // 1. 构造 content/body
    let content = '';
    if (['POST', 'PUT', 'PATCH'].includes(method)) {
      content = JSON.stringify(params || {});
      headers['content-length'] = String(new TextEncoder().encode(content).length);
      headers['content-type'] = 'application/json';
    }
    // 2. x-tg- headers
    headers['x-tg-app-id'] = appId;
    headers['x-tg-algorithm'] = 'TGV1-HMAC-SHA256';
    headers['accept-language'] = 'zh-CN';
    headers['x-tg-date'] = dayjs().utc().format('YYYYMMDDTHHmmss') + 'Z';
    // 3. signed headers
    const signedHeaders = Object.keys(headers)
      .filter(k => k.startsWith('x-tg-') && !['x-tg-signed-headers', 'x-tg-credential', 'x-tg-signature'].includes(k) || ['content-length', 'content-type'].includes(k))
      .sort();
    headers['x-tg-signed-headers'] = signedHeaders.join(';');
    headers['x-tg-content-sha256'] = CryptoJS.SHA256(content).toString(CryptoJS.enc.Hex);
    // 4. canonical string
    let canonicalStr = `${method}\n${uri}\n`;
    if (['POST', 'PUT', 'PATCH'].includes(method)) {
      canonicalStr += '\n';
    } else {
      canonicalStr += new URLSearchParams(params).toString() + '\n';
    }
    canonicalStr += signedHeaders.map(k => `${k}:${headers[k]}\n`).join('');
    canonicalStr += `${headers['x-tg-signed-headers']}\n${headers['x-tg-content-sha256']}`;
    const signs = CryptoJS.SHA256(canonicalStr).toString(CryptoJS.enc.Hex);
    const now = dayjs().utc();
    const scope = now.add(7, 'day').format('YYYYMMDD');
    const today = now.format('YYYYMMDD');
    const strToSign = `TGV1-HMAC-SHA256\n${headers['x-tg-date']}\n${scope}/tgv1_request\n${signs}`;
    let signingKey = CryptoJS.HmacSHA256(today, `TGV1${accessSecret}`);
    signingKey = CryptoJS.HmacSHA256(uri, signingKey);
    signingKey = CryptoJS.HmacSHA256('tgv1_request', signingKey);
    const signature = CryptoJS.HmacSHA256(strToSign, signingKey).toString(CryptoJS.enc.Hex);
    headers['authorization'] = `TGV1-HMAC-SHA256 Credential=${accessKey}/${scope}/tgv1_request, SignedHeaders=${headers['x-tg-signed-headers']}, Signature=${signature}`;
    return {
      headers,
      body: ['POST', 'PUT', 'PATCH'].includes(method) ? content : undefined
    };
  }
}
