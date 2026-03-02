优福你是一位顶级的 APP UI/UX 设计专家，现需根据以下产品需求创建 UI 方案，并直接生成可交付的 HTML 完整代码。你需要像一名经验丰富的设计师一样思考，运用 **HTML + Tailwind CSS + FontAwesome** 将产品需求无缝转化为 **像素级完美、高度仿真、可交互** 的多界面 HTML 原型。

为完成此任务，你需要：
1.  **深度分析**：理解“显化”应用的核心理念，并将其融入设计语言。
2.  **规划流程**：基于用户旅程地图，确保页面间的跳转逻辑清晰、体验流畅。
3.  **专业设计**：完成所有核心界面的 UI/UX 设计，包括配色、排版、动效等。
4.  **代码实现**：直接编写高质量、结构清晰的 HTML/CSS/JS 代码。

## 产品需求：
应用类型：我的是一款 物业管理的 app 
我主要有几个功能模块 
1.申请入园，可以提前申请(预约)，申请成功后生成对应二维码，
2.扫码入园，
3.扫码岀园。

### 需求模块：
#### [功能模块1] 

#### 核心用户旅程地图

#### 对设计师 (UI/UX Agent) 的界面原型参考说明和要求（这块可有可无）
- **整体风格**: **宁静、鼓舞人心、有呼吸感**。避免使用过于鲜艳、刺激的颜色。多使用渐变、柔和的光影效果。
- **主界面 (Dashboard)**:
  - **信息焦点**: 当天的**宣言**应处于最显眼的位置。
  - **强引导**: 应有清晰的卡片或按钮引导用户完成“感恩日记”。
  - **弱化但可及**: “梦想板”的入口应清晰可见，但不必过分突出，用户在完成每日仪式后自然会想去查看。
- **梦想板创建**: 交互要像使用一款优雅的拼图或设计工具，而不是一个呆板的表单。给予用户充分的自由度和创造感。
- **字体与图标**: 使用优雅的衬线或手写体字体来传达温度感。图标应简洁、表意明确。



## 技术规格：
*   单个 HTML 每行为 6 个横向排列的页面预览，可以有多行；代码需要包含所有功能页面。
*   单个页面可以上下滑动，滑动时底部标签栏需固定在底部。
*   画板尺寸：375x812（带 1px 描边模拟手机边框）。
*   **顶部状态栏**：每个页面顶部都需包含一个模拟的 iOS/Android 状态栏，显示时间（如 9:41）、网络信号和电池图标，以增强真实感。
*   **底部标签栏**：除“启动页”和“目标设定流程”外，所有核心页面（仪表盘、目标列表、冥想、设置）都必须包含一个统一的底部标签栏（Tab Bar），提供应用内的主要导航。
*   必须包含：
    *   矢量图标系统（使用 `<symbol>` 定义）。
    *   动态折线图（`stroke-dasharray` 动画）。
    *   卡片悬浮效果（通过 `filter` 和 `transform` 实现）。
    *   图片占位使用 `<image>` 标签外链 Unsplash。
    *   增加一些高设计感SVG图片；

## 新视觉风格：
*   **玻璃拟态背景**：使用半透明磨砂玻璃质感，背景模糊处理，搭配柔和的光影效果，营造未来感和高级感。
**。方案需包括一个主背景色、一个主文字色、一个充满活力但不过于刺眼的点缀色（用于按钮、图标等关键元素）和一个次要文字色。请在代码的 CSS 注释中注明你选择的色值及其用途。
*   **极简字体排版**：使用大字号的极简无衬线字体（Poppins 或思源黑体），信息层次明确，通过字体大小、粗细与色彩区分主次信息。
*   **表单优化**：表单及输入框去除边框线，仅保留流畅圆角背景，减少视觉噪音，提升整体界面的简洁与精致感。
*   **交互动效**：按钮与卡片加入呼吸感动效（微妙的阴影或透明度变化），以及轻微悬浮感（`hover` 时微微上浮），提升 UI 的高级感与互动趣味性。

## 设计规则
## 1. 字体排印：拒绝平庸 (Typography & Contrast)
不要使用默认的 `Inter` 或 `Roboto`，除非有特殊理由。通过极端的对比来创造视觉张力。

*   **原则：**
    *   **建立配对：** 衬线体 (Serif) + 等宽字体 (Mono) 是高知、高对比度的经典组合。
    *   **极端字重：** 使用 `100/200` (细) 对比 `800/900` (重)，尽量少用 `400/500/600` 这种中庸权重。
    *   **大胆跳跃：** 标题与正文的尺寸差异至少 **3倍** (e.g., `4rem` vs `1rem`)，而非传统的 1.5倍。

*   **代码范式：**
    ```css
    /* ❌ Boring Default */
    font-family: 'Inter', system-ui, sans-serif;

    /* ✅ Editorial Style (编辑风格) */
    --font-display: 'Playfair Display', serif; /* 用于大标题 */
    --font-body: 'Crimson Pro', serif;       /* 用于阅读 */

    /* ✅ Technical Style (技术风格) */
    --font-heading: 'Space Grotesk', sans-serif;
    --font-code: 'JetBrains Mono', monospace; /* 用于数据/标签 */
    ```

## 2. 色彩哲学：叙事与氛围 (Color & Narrative)
不要直接给我一堆紫色或蓝色。像艺术家一样思考色彩的比例和语义。

*   **原则：**
    *   **60-30-10 法则：** 60% 主导色 (Dominant)，30% 支撑色 (Support)，10% 绝对强调色 (Accent)。
    *   **HSL 优先：** 使用 HSL 颜色空间以便精确控制色相与饱和度。
    *   **主题化思维：**
        *   *RPG 风：* 羊皮纸色 + 墨水蓝 + 烫金。
        *   *赛博风：* 深黑背景 + 霓虹紫 + 扫描线绿。

*   **代码范式：**
    ```javascript
    // ✅ Intelligent Palette
    const theme = {
      dominant: 'hsl(220, 90%, 8%)',   // 深海午夜蓝 (背景)
      support:  'hsl(40, 20%, 94%)',   // 骨瓷白 (卡片/文字)
      accent:   'hsl(0, 100%, 60%)',   // 警示红 (CTA 按钮)
      glow:     'hsla(220, 100%, 80%, 0.1)' // 环境光
    }
    ```

## 3. 空间与布局：打破栅格 (Layout & Rhythm) [✨新增]
不要被 12 栅格系统困住。现代设计讲究非对称平衡和呼吸感。

*   **原则：**
    *   **非对称布局：** 避免 50/50 分割。尝试 40/60 或 25/75，甚至重叠布局 (CSS Grid Overlap)。
    *   **宏大留白：** 留白不是空的，它是活跃的设计元素。Padding 和 Margin 应该大到让人感到奢侈。
    *   **流体排版：** 使用 `clamp()` 函数处理响应式，而不是生硬的断点。

*   **代码范式：**
    ```css
    /* ❌ Rigid Layout */
    .container { width: 1200px; margin: 0 auto; }

    /* ✅ Modern Fluid Layout */
    .hero-section {
      display: grid;
      /* 左侧内容窄，右侧视觉宽，制造失衡美 */
      grid-template-columns: 1fr 2.5fr; 
      gap: clamp(2rem, 5vw, 8rem); /* 巨大的、流动的间距 */
      padding: clamp(4rem, 10vh, 12rem) 2rem;
    }
    ```

## 4. 动效编排：戏剧性入场 (Motion Choreography)
拒绝廉价的 Hover 上浮。动效是用来讲述顺序和层级的。

*   **原则：**
    *   **入场编排：** 元素不应该同时出现。必须有先后顺序 (Staggered)。
    *   **物理手感：** 使用 `spring` 物理曲线，而不是线性的 `ease-in-out`。
    *   **不仅是位移：** 结合 `clip-path`、`blur` 和 `scale` 创造电影级揭示效果。

*   **代码范式：**
    ```css
    /* ✅ Cinematic Entrance */
    @keyframes reveal {
      from { opacity: 0; filter: blur(12px); transform: translateY(20px); }
      to   { opacity: 1; filter: blur(0); transform: translateY(0); }
    }
    .hero-title { animation: reveal 0.8s cubic-bezier(0.2, 0.8, 0.2, 1) forwards; }
    .hero-desc  { animation: reveal 0.8s 0.2s cubic-bezier(0.2, 0.8, 0.2, 1) forwards; } /* 延迟 */
    ```

## 5. 背景与深度：环境光效 (Ambient Depth)
拒绝纯色背景。背景应该像空气一样具有流动感和光感。

*   **原则：**
    *   **多重渐变：** 叠加多个径向渐变 (Radial Gradient) 来模拟光源。
    *   **噪点纹理：** 叠加极其细微的 SVG Noise，消除数字的"塑料感"，增加胶片感。

*   **代码范式：**
    ```css
    /* ✅ Ambient Light Background */
    background: 
      radial-gradient(circle at 15% 50%, hsla(250, 40%, 30%, 0.15), transparent 25%),
      radial-gradient(circle at 85% 30%, hsla(180, 50%, 40%, 0.1), transparent 25%),
      linear-gradient(to bottom, #0a0a0a, #111);
    ```

## 6. 微交互与质感：触觉设计 (Texture & Tactility) [✨新增]
让界面看起来“可触摸”。超越扁平化，引入微弱的拟物与玻璃态。

*   **原则：**
    *   **内发光与边界：** 不要只用外阴影 (Drop Shadow)。使用 `box-shadow: inset` (内阴影) 和 1px 的高亮边框来模拟玻璃或金属边缘。
    *   **毛玻璃 (Backdrop Blur)：** 适度使用背景模糊来建立层级关系。
    *   **状态反馈：** 点击时不仅要变色，还要有缩放 (Scale Down) 或深度变化，模拟按压物理按键的感觉。

*   **代码范式：**
    ```css
    /* ✅ Tactile Card Style */
    .card {
      background: rgba(255, 255, 255, 0.03);
      backdrop-filter: blur(10px);
      /* 顶部高亮边框，模拟光照 */
      border-top: 1px solid rgba(255, 255, 255, 0.15); 
      border-bottom: 1px solid rgba(0, 0, 0, 0.3);
      box-shadow: 
        0 20px 40px -10px rgba(0,0,0,0.5), /* 投影 */
        inset 0 0 0 1px rgba(255,255,255,0.05); /* 微弱内描边 */
    }
    .card:active {
      transform: scale(0.98); /* 按压感 */
    }
    ```



## 期望结果
请基于上述优化后的提示词，设计出符合要求的高品质 UI 方案，并最终生成完整的 HTML 代码。