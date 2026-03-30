# Wait Patterns for Browser Automation

本文档整理 OpenClaw browser 等待模式，借鉴 agent-browser 的分类方式，适配当前 remote CDP 链路。

---

## 等待模式分类

### 1. 等待元素出现

```bash
# 等待特定文本出现
openclaw browser wait --text "Welcome"

# 等待 CSS 选择器匹配的元素
openclaw browser wait --selector ".dashboard-loaded"

# 等待 ref 对应的元素（先用 snapshot 查看 refs）
openclaw browser wait --selector "[ref=e12]"
```

---

### 2. 等待时间

```bash
# 等待固定毫秒
openclaw browser wait 3000
```

**适用场景**：
- 简单的动画/过渡
- 不确定其他条件时的兜底

**不推荐**作为首选，因为不够精确。

---

### 3. 等待 URL 变化

```bash
# 等待 URL 包含特定路径
openclaw browser wait --url "**/dashboard"

# 等待 URL 完全匹配
openclaw browser wait --url "https://example.com/home"
```

**适用场景**：
- 导航完成后继续
- 登录跳转后继续

---

### 4. 等待网络空闲

```bash
# 等待网络空闲（推荐）
openclaw browser wait --load networkidle

# 等待 DOM 加载完成
openclaw browser wait --load domcontentloaded

# 等待 load 事件
openclaw browser wait --load load
```

**推荐**：`networkidle` 最稳定，适合大多数 SPA。

---

### 5. 等待 JS 条件

```bash
# 等待全局变量
openclaw browser wait --fn "window.appReady === true"

# 等待元素存在
openclaw browser wait --fn "document.querySelector('.loaded') !== null"

# 等待复杂条件
openclaw browser wait --fn "window.data && window.data.length > 0"
```

**适用场景**：
- 应用自定义就绪信号
- 复杂异步加载完成

---

## 组合等待模式

### 推荐组合

```bash
# 1. 导航后等待网络空闲
openclaw browser navigate https://example.com
openclaw browser wait --load networkidle

# 2. 点击后等待文本出现
openclaw browser click @e12
openclaw browser wait --text "Success"

# 3. 提交后等待 URL 跳转
openclaw browser type @e1 "username"
openclaw browser press Enter
openclaw browser wait --url "**/dashboard"
```

---

## 等待超时处理

默认超时是 30 秒。如需调整：

```bash
openclaw browser --timeout 60000 wait --text "Welcome"
```

---

## 调试技巧

### 1. 先用 snapshot 查看当前状态

```bash
openclaw browser --browser-profile remote snapshot --interactive --limit 100
```

### 2. 检查页面是否已加载

```bash
openclaw browser --browser-profile remote evaluate --fn "document.readyState"
# 应返回 "complete"
```

### 3. 查看当前 URL

```bash
openclaw browser --browser-profile remote evaluate --fn "window.location.href"
```

---

## 常见陷阱

### ❌ 只等待固定时间

```bash
# 不推荐：不够精确，容易失败
openclaw browser wait 5000
openclaw browser click @e12
```

### ✅ 等待明确条件

```bash
# 推荐：等待元素出现后再操作
openclaw browser wait --text "Welcome"
openclaw browser click @e12
```

---

### ❌ 等待不存在的元素

```bash
# 如果选择器错了，会一直超时
openclaw browser wait --selector ".non-existent"
```

### ✅ 先用 snapshot 验证 refs

```bash
openclaw browser snapshot --interactive --limit 100
# 确认元素存在后再等待
```

---

## 最佳实践总结

1. **优先等待条件，而不是时间**
2. **导航后先等 `networkidle`**
3. **操作前先用 snapshot 验证元素存在**
4. **复杂场景用 JS 条件等待**
5. **超时时间根据场景调整（默认 30s）**

---

## 与 agent-browser 对比

| 模式 | agent-browser | 当前 OpenClaw |
|------|---------------|---------------|
| 等待元素 | `wait @e2` | `wait --selector "[ref=e2]"` |
| 等待时间 | `wait 1000` | `wait 1000` |
| 等待文本 | `wait --text "Welcome"` | `wait --text "Welcome"` |
| 等待 URL | `wait --url "**/dashboard"` | `wait --url "**/dashboard"` |
| 等待网络 | `wait --load networkidle` | `wait --load networkidle` |
| 等待 JS | `wait --fn "..."` | `wait --fn "..."` |

**结论**：功能基本对齐，语法略有差异。
