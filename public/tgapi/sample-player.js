/**
 *
 * device player
 *
 */

// 引用Tange API模块
import {
  DeviceConnection,
  DeviceLiveMediaSource,
  DeviceStorageMediaSource,
  CloudStorageMediaSource,
  DeviceMediaPlayer,
  DeviceTalkback,
} from './tgapi.es.min.js';

/**
 * 简化版 设备连接控制器 样例
 * 功能：
 * 1. 支持多个播放器（实时和卡录像）共享一个设备连接实例
 * 2. 支持保持连接模式，避免重复连接设备
 */
class DeviceConnectionController {
  // 启用保持连接模式
  enableKeepConnectedMode = false;

  // 实例
  deviceConnection = null;

  constructor(config = {}) {
    this.updateConfig(config);
  }

  updateConfig(config = {}) {
    const names = ['enableKeepConnectedMode'];
    names.forEach((name) => {
      const value = config[name];
      if (typeof value !== 'undefined') this[name] = value;
    });
  }

  obtainConnection() {
    let { deviceConnection } = this;
    if (!deviceConnection) {
      deviceConnection = new DeviceConnection();

      // 监听连接状态变动事件
      deviceConnection.on('connectionStateChange', (event) => {
        const { state, deviceId, message } = event;

        // state: new, connecting, connected, failed
        console.log('device connection state change to: ', state);
      });

      this.deviceConnection = deviceConnection;
    }

    return deviceConnection;
  }

  destroyConnection() {
    const { enableKeepConnectedMode, deviceConnection } = this;
    // 保持连接模式下，需自行调用disconnect方法断开连接
    if (enableKeepConnectedMode) {
      return;
    }

    // 断开连接，销毁连接实例
    if (deviceConnection) {
      deviceConnection.disconnect();
      this.deviceConnection = null;
    }
  }
}

// 实时播放器 样例
class DeviceLivePlayer {
  isPlaying = false;

  // 设备
  connectionController = null;
  deviceId = '';
  deviceConnectionString = '';
  cameras = []; // 摄像头

  // 音频
  enableAudio = true;
  audioPlayerIndex = 0;
  audioSampleRate = 8000;

  // 实例
  deviceLiveMediaSource = null;
  deviceTalkback = null;
  cameraPlayers = [];

  constructor(config = {}) {
    this.updateConfig(config);

    if (!config.connectionController) this.connectionController = new DeviceConnectionController();
  }

  updateConfig(config = {}) {
    const names = [
      'connectionController',
      'deviceId',
      'deviceConnectionString',
      'cameras',
      'enableAudio',
      'audioPlayerIndex',
      'audioSampleRate',
    ];
    names.forEach((name) => {
      const value = config[name];
      if (typeof value !== 'undefined') this[name] = value;
    });
  }

  // 初始化设备连接，媒体数据源和摄像头视频流模块，摄像头播放器，语音对讲模块
  init() {
    const { audioSampleRate, cameras } = this;

    // 创建一个设备连接模块
    const deviceConnection = this.connectionController.obtainConnection();
    // 绑定重连事件
    if (this.connectionController.enableReconnectMode) {
      this.connectionController.enableReconnectMode(() => {
        this.enableCameraPlayerProduce(true);
      });
    }

    // 创建一个实时直播数据源模块
    const deviceLiveMediaSource = new DeviceLiveMediaSource({ deviceConnection });

    // 创建一组摄像头播放器
    const cameraPlayers = cameras.map((cameraConfig = {}, index) => {
      const { cameraIndex = index, videoContainer } = cameraConfig;

      let videoContainerType = 'canvas';
      if (videoContainer && videoContainer.tagName === 'IFRAME') {
        videoContainerType = 'iframe-canvas';
      }

      // 从数据源模块获取一个摄像头的视频流
      const deviceLiveMediaStream = deviceLiveMediaSource.getStream({ cameraIndex });

      // 创建一个设备媒体播放模块
      let deviceMediaPlayer = null;
      switch (videoContainerType) {
        case 'iframe-canvas':
          const videoRenderIframe = videoContainer;
          deviceMediaPlayer = videoRenderIframe.contentWindow.createDeviceMediaPlayer(deviceLiveMediaStream);
          break;
        case 'canvas':
        default:
          deviceMediaPlayer = new DeviceMediaPlayer({
            canvasContainer: videoContainer,
            mediaStream: deviceLiveMediaStream,
          });
          break;
      }

      // 配置设备媒体播放模块的音频参数
      deviceMediaPlayer.setAudioConfiguration({ sampleRate: audioSampleRate });

      return { cameraIndex, deviceLiveMediaStream, deviceMediaPlayer };
    });

    // 创建一个语音对讲模块
    const deviceTalkback = new DeviceTalkback({ deviceConnection });
    // 配置对讲模块音频参数
    deviceTalkback.setAudioConfiguration({ sampleRate: audioSampleRate });

    // 保存实例
    this.deviceLiveMediaSource = deviceLiveMediaSource;
    this.cameraPlayers = cameraPlayers;
    this.deviceTalkback = deviceTalkback;
  }

  destroy() {
    if (this.connectionController) {
      this.connectionController.destroyConnection();
    }

    this.deviceLiveMediaSource = null;
    this.deviceTalkback = null;
    this.cameraPlayers = [];
  }

  enableCameraPlayerProduce(enable = true) {
    const { cameraPlayers, enableAudio, audioPlayerIndex } = this;

    // 启动或停止 音视频数据的传输与生产
    cameraPlayers.forEach(({ deviceLiveMediaStream, cameraIndex }, index) => {
      deviceLiveMediaStream.enableVideoProduce(enable);
      if (enableAudio && cameraIndex == audioPlayerIndex) deviceLiveMediaStream.enableAudioProduce(enable);
    });

    // 启动或停止 音视频解码和渲染的生产
    cameraPlayers.forEach(({ deviceMediaPlayer, cameraIndex }, index) => {
      deviceMediaPlayer.enableVideoProduce(enable);
      if (enableAudio && cameraIndex == audioPlayerIndex) deviceMediaPlayer.enableAudioProduce(enable);
    });
  }

  play() {
    console.log('play');
    if (this.isPlaying) return;

    const { deviceId, deviceConnectionString } = this;
    if (!deviceId) {
      console.error('no deviceId');
      return;
    }

    this.isPlaying = true;
    this.init(); // 初始化设备连接，媒体数据源和摄像头视频流模块，摄像头播放器，语音对讲模块

    // 连接设备
    const deviceConnection = this.connectionController.obtainConnection();
    deviceConnection
      .connect({
        deviceId, // 设备ID
        deviceConnectionString, // 设备连接信息字符串从接口获取，字符串中包含设备密码，p2p连接等配置
        // timeout: 15 * 1000, // 超时配置，单位ms
      })
      // 连接成功
      .then(() => {
        // 启动多个摄像头音视频数据的传输，解码和渲染
        this.enableCameraPlayerProduce(true);
      })
      .catch((error) => {
        console.log('failed to connect device: ', error);
      });
  }

  stop() {
    console.log('stop');

    this.enableCameraPlayerProduce(false); // 停止多个摄像头音视频数据的传输，解码和渲染
    this.stopTalkback(); // 停止对讲

    this.destroy();

    this.isPlaying = false;
  }

  startTalkback() {
    const { deviceTalkback } = this;
    if (!deviceTalkback) return;

    // 打开对讲模块，申请麦克风权限
    deviceTalkback.open().then(() => {
      // 开始对讲
      deviceTalkback.start().catch((error) => {
        console.log(error);
      });
    });
  }

  stopTalkback() {
    // 停止对讲
    if (this.deviceTalkback) this.deviceTalkback.stop();
  }
}

// 卡录像播放器 样例
class DeviceStoragePlayer {
  isPlaying = false;

  // 设备
  connectionController = null;
  deviceId = '';
  deviceConnectionString = '';
  cameras = []; // 摄像头

  // 音频
  enableAudio = true;
  audioPlayerIndex = 0;
  audioSampleRate = 8000;

  // 实例
  deviceStorageMediaSource = null;
  cameraPlayers = [];

  constructor(config = {}) {
    this.updateConfig(config);

    if (!config.connectionController) this.connectionController = new DeviceConnectionController();
  }

  updateConfig(config = {}) {
    const names = [
      'connectionController',
      'deviceId',
      'deviceConnectionString',
      'cameras',
      'enableAudio',
      'audioPlayerIndex',
      'audioSampleRate',
    ];
    names.forEach((name) => {
      const value = config[name];
      if (typeof value !== 'undefined') this[name] = value;
    });
  }

  // 初始化设备连接，媒体数据源和摄像头视频流模块，摄像头播放器
  init() {
    const { cameras } = this;

    // 创建一个设备连接模块
    const deviceConnection = this.connectionController.obtainConnection();

    // 创建一个本地录像数据源模块
    const deviceStorageMediaSource = new DeviceStorageMediaSource({ deviceConnection });

    // 创建一组摄像头播放器
    const cameraPlayers = cameras.map((cameraConfig = {}, index) => {
      const { cameraIndex = index, videoContainer } = cameraConfig;

      let videoContainerType = 'canvas';
      if (videoContainer && videoContainer.tagName === 'IFRAME') {
        videoContainerType = 'iframe-canvas';
      }

      // 从数据源模块获取一个摄像头的视频流
      const mediaStream = deviceStorageMediaSource.getStream({ cameraIndex });

      // 创建一个设备媒体播放模块
      let deviceMediaPlayer = null;
      switch (videoContainerType) {
        case 'iframe-canvas':
          const videoRenderIframe = videoContainer;
          deviceMediaPlayer = videoRenderIframe.contentWindow.createDeviceMediaPlayer(mediaStream);
          break;
        case 'canvas':
        default:
          deviceMediaPlayer = new DeviceMediaPlayer({
            canvasContainer: videoContainer,
            mediaStream,
          });
          break;
      }

      return { cameraIndex, mediaStream, deviceMediaPlayer };
    });

    // 保存实例
    this.deviceStorageMediaSource = deviceStorageMediaSource;
    this.cameraPlayers = cameraPlayers;
  }

  destroy() {
    if (this.connectionController) {
      this.connectionController.destroyConnection();
    }

    this.deviceStorageMediaSource = null;
    this.cameraPlayers = [];
  }

  enableCameraPlayerProduce(enable = true, { date = '' } = {}) {
    const { deviceStorageMediaSource, cameraPlayers, enableAudio, audioPlayerIndex } = this;

    // 启动或停止 音视频数据的传输与生产
    if (enable) {
      deviceStorageMediaSource.seek(date);
    } else {
      deviceStorageMediaSource.enableProduce(false);
    }

    // 启动或停止 音视频解码和渲染的生产
    cameraPlayers.forEach(({ deviceMediaPlayer, cameraIndex }, index) => {
      deviceMediaPlayer.enableVideoProduce(enable);
      if (enableAudio && cameraIndex == audioPlayerIndex) deviceMediaPlayer.enableAudioProduce(enable);
    });
  }

  play({ date = '' }) {
    console.log('play');
    if (this.isPlaying) return;

    const { deviceId, deviceConnectionString } = this;
    if (!deviceId) {
      console.error('no deviceId');
      return;
    }

    this.isPlaying = true;
    this.init(); // 初始化设备连接，媒体数据源和摄像头视频流模块，摄像头播放器

    // 连接设备
    const deviceConnection = this.connectionController.obtainConnection();
    deviceConnection
      .connect({
        deviceId, // 设备ID
        deviceConnectionString, // 设备连接信息字符串从接口获取，字符串中包含设备密码，p2p连接等配置
        // timeout: 15 * 1000, // 超时配置，单位ms
      })
      // 连接成功
      .then(() => {
        // 启动多个摄像头音视频数据的传输，解码和渲染
        this.enableCameraPlayerProduce(true, { date });
      })
      .catch((error) => {
        console.log('failed to connect device: ', error);
      });
  }

  stop() {
    console.log('stop');

    this.enableCameraPlayerProduce(false); // 停止多个摄像头音视频数据的传输，解码和渲染

    this.destroy();

    this.isPlaying = false;
  }
}

// 云录像播放器 样例
class CloudStoragePlayer {
  isPlaying = false;

  // 设备
  deviceId = '';
  cameras = []; // 摄像头

  // 音频
  enableAudio = true;
  audioPlayerIndex = 0;
  audioSampleRate = 8000;

  // 实例
  cloudStorageMediaSource = null;
  cameraPlayers = [];

  constructor(config = {}) {
    this.updateConfig(config);
  }

  updateConfig(config = {}) {
    const names = ['deviceId', 'cameras', 'enableAudio', 'audioPlayerIndex', 'audioSampleRate'];
    names.forEach((name) => {
      const value = config[name];
      if (typeof value !== 'undefined') this[name] = value;
    });
  }

  // 初始化媒体数据源和摄像头视频流模块，摄像头播放器
  init() {
    const { cameras } = this;

    // 创建一个云端录像数据源模块
    const cloudStorageMediaSource = new CloudStorageMediaSource();

    // 创建一组摄像头播放器
    const cameraPlayers = cameras.map((cameraConfig = {}, index) => {
      const { cameraIndex = index, videoContainer } = cameraConfig;

      let videoContainerType = 'canvas';
      if (videoContainer && videoContainer.tagName === 'IFRAME') {
        videoContainerType = 'iframe-canvas';
      }

      // 从数据源模块获取一个摄像头的视频流
      const mediaStream = cloudStorageMediaSource.getStream({ cameraIndex });

      // 创建一个设备媒体播放模块
      let deviceMediaPlayer = null;
      switch (videoContainerType) {
        case 'iframe-canvas':
          const videoRenderIframe = videoContainer;
          deviceMediaPlayer = videoRenderIframe.contentWindow.createDeviceMediaPlayer(mediaStream);
          break;
        case 'canvas':
        default:
          deviceMediaPlayer = new DeviceMediaPlayer({
            canvasContainer: videoContainer,
            mediaStream,
          });
          break;
      }

      return { cameraIndex, mediaStream, deviceMediaPlayer };
    });

    // 保存实例
    this.cloudStorageMediaSource = cloudStorageMediaSource;
    this.cameraPlayers = cameraPlayers;
  }

  destroy() {
    this.cloudStorageMediaSource = null;
    this.cameraPlayers = [];
  }

  enableCameraPlayerProduce(enable = true, { date = '' } = {}) {
    const { cloudStorageMediaSource, cameraPlayers, enableAudio, audioPlayerIndex } = this;

    // 启动或停止 音视频数据的下载与生产
    if (enable) {
      cloudStorageMediaSource.seek(date);
    } else {
      cloudStorageMediaSource.enableProduce(false);
    }

    // 启动或停止 音视频解码和渲染的生产
    cameraPlayers.forEach(({ deviceMediaPlayer, cameraIndex }, index) => {
      deviceMediaPlayer.enableVideoProduce(enable);
      if (enableAudio && cameraIndex == audioPlayerIndex) deviceMediaPlayer.enableAudioProduce(enable);
    });
  }

  play({ date = '', cloudEventId = '' }) {
    console.log('play');
    if (this.isPlaying) return;

    const { deviceId } = this;
    if (!deviceId) {
      console.error('no deviceId');
      return;
    }

    this.isPlaying = true;
    this.init(); // 初始化媒体数据源和摄像头视频流模块，摄像头播放器
    const { cloudStorageMediaSource } = this;
    cloudStorageMediaSource.setDeviceId(deviceId);

    if (date) {
      // 查询云端录像记录
      cloudStorageMediaSource.query(date).then((list = []) => {
        const dataSource = list[0];

        // 设置录像数据源，并seek
        cloudStorageMediaSource.setDataSource(dataSource);
        // 启动多个摄像头音视频数据的传输，解码和渲染
        this.enableCameraPlayerProduce(true, { date: dataSource.start_time });
      });
    } else if (cloudEventId) {
      // 从云事件获取录像数据源
      cloudStorageMediaSource.getDataSourceByCloudEvent({ id: cloudEventId }).then((dataSource) => {
        // 设置录像数据源，并seek
        cloudStorageMediaSource.setDataSource(dataSource);
        // 启动多个摄像头音视频数据的传输，解码和渲染
        this.enableCameraPlayerProduce(true, { date: dataSource.start_time });
      });
    }
  }

  pause() {
    console.log('pause cloud storage media');

    if (this.cloudStorageMediaSource) this.cloudStorageMediaSource.pause();
  }

  resume() {
    console.log('resume cloud storage media');

    if (this.cloudStorageMediaSource) this.cloudStorageMediaSource.resume();
  }

  stop() {
    console.log('stop');

    this.enableCameraPlayerProduce(false); // 停止多个摄像头音视频数据的传输，解码和渲染

    this.destroy();

    this.isPlaying = false;
  }
}

/**
 * 加强版 设备连接控制器 样例
 * 功能：
 * 1. 在 简化版设备连接控制器 基础上增加了重连机制
 */
class DeviceConnectionControllerPro {
  // 启用保持连接模式
  enableKeepConnectedMode = false;

  // 实例
  deviceConnection = null;

  // 重连
  enableReconnect = false; // 是否启用重连
  onReconnected = null; // 重连成功回调
  maxRetries = 10; // 最大重连次数
  currentRetries = 0; // 当前重连次数
  reconnectTimeoutMs = 1000; // 重连间隔时间

  constructor(config = {}) {
    this.updateConfig(config);
  }

  updateConfig(config = {}) {
    const names = ['enableKeepConnectedMode'];
    names.forEach((name) => {
      const value = config[name];
      if (typeof value !== 'undefined') this[name] = value;
    });
  }

  obtainConnection() {
    const { deviceConnection } = this;
    if (!deviceConnection) {
      this.deviceConnection = new DeviceConnection();
      this.addConnectionListener(this.deviceConnection);
    }

    return this.deviceConnection;
  }

  destroyConnection() {
    // 重置重连项
    this.enableReconnect = false;
    this.onReconnected = null;
    this.currentRetries = 0;
    this.reconnectTimeoutMs = 1000;

    const { enableKeepConnectedMode, deviceConnection } = this;
    // 保持连接模式下，需自行调用disconnect方法断开连接
    if (enableKeepConnectedMode) {
      return;
    }

    // 断开连接，销毁连接实例
    if (deviceConnection) {
      deviceConnection.disconnect();
      this.deviceConnection = null;
    }
  }

  addConnectionListener(deviceConnection) {
    if (!deviceConnection) return;

    // 监听连接状态变动事件
    deviceConnection.on('connectionStateChange', (event) => {
      const { state, deviceId, message } = event;
      console.log('device connection state change to: ', state);

      // state: new, connecting, connected, failed
      switch (state) {
        case 'new':
        case 'connecting':
          break;
        case 'connected':
          break;
        case 'failed':
          this.reconnect();
          break;
      }
    });
  }

  enableReconnectMode(success) {
    this.enableReconnect = true;

    if (success) this.onReconnected = success;
  }

  reconnect() {
    if (!this.enableReconnect) return;
    if (this.currentRetries >= this.maxRetries) return;

    this.currentRetries++;
    let { currentRetries, maxRetries, reconnectTimeoutMs } = this;
    setTimeout(() => {
      this.deviceConnection.connect().then(() => {
        console.log('successfully reconnected to the device.');
        if (this.onReconnected) this.onReconnected();

        // 重置重连项
        this.reconnectTimeoutMs = 1000;
        this.currentRetries = 0;
      });
    }, reconnectTimeoutMs);

    console.log(`reconnect(${currentRetries}/${maxRetries}) device will be attempted in ${reconnectTimeoutMs} ms. `);
    this.reconnectTimeoutMs = Math.min(10 * 1000, (reconnectTimeoutMs += reconnectTimeoutMs));
  }
}

export {
  DeviceConnectionController,
  DeviceConnectionControllerPro,
  DeviceLivePlayer,
  DeviceStoragePlayer,
  CloudStoragePlayer,
};
