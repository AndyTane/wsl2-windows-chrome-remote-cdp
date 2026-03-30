# Runbook

See the packaged executable procedure below.

---

# OpenClaw WSL2 → Windows Chrome Remote CDP Runbook（脱敏版，可执行）

## 1. 目标

本说明用于让其他维护者或 Agent **快速理解、复现并维护**如下工作链路：

- OpenClaw Gateway 运行在 **WSL2 Ubuntu** 中
- 被控制的浏览器运行在 **Windows Chrome** 中
- OpenClaw 不直接控制 Linux 本地浏览器
- OpenClaw 通过 **Remote CDP** 控制 Windows Chrome

本文强调：
- 明确配置
- 明确步骤
- 明确命令
- 明确验证点
- 明确排障顺序

## 2. 最终工作链路（一句话）

```text
OpenClaw (WSL2) -> browser profile: remote -> http://172.17.32.1:9223
-> Windows portproxy -> 127.0.0.1:9222 -> Windows Chrome (CDP)
```

关键固定点：

```text
profile = remote
cdpUrl  = http://172.17.32.1:9223
```

## 3. Mermaid 链路图

```mermaid
flowchart LR
    A[WSL2 Ubuntu\nOpenClaw Gateway / CLI] --> B[Browser Profile: remote]
    B --> C[CDP URL\nhttp://172.17.32.1:9223]
    C --> D[Windows portproxy\n0.0.0.0:9223 -> 127.0.0.1:9222]
    D --> E[Windows Chrome\n--remote-debugging-port=9222]
    E --> F[Chrome DevTools Protocol\nTabs / Pages / DOM / JS / Network]
```

## 4. Mermaid 分层结构图

```mermaid
flowchart TB
    subgraph L1[WSL2 Linux侧]
        A1[openclaw CLI]
        A2[openclaw gateway]
        A3[browser profile: remote]
    end

    subgraph L2[WSL2 -> Windows 宿主机访问层]
        B1[Host gateway IP\n172.17.32.1]
        B2[访问端口 9223]
    end

    subgraph L3[Windows 转发层]
        C1[netsh portproxy]
        C2[listen 0.0.0.0:9223]
        C3[forward to 127.0.0.1:9222]
        C4[Windows firewall allow 9223]
    end

    subgraph L4[Windows 浏览器层]
        D1[Chrome]
        D2[remote debugging port 9222]
        D3[DevTools HTTP + WebSocket]
    end

    A1 --> A2 --> A3 --> B1 --> B2 --> C1 --> C2 --> C3 --> C4 --> D1 --> D2 --> D3
```

## 5. Mermaid 数据流图

```mermaid
sequenceDiagram
    participant OC as OpenClaw in WSL2
    participant RP as remote profile
    participant GW as 172.17.32.1:9223
    participant PP as Windows portproxy
    participant CH as Chrome 127.0.0.1:9222

    OC->>RP: 选择 profile=remote
    RP->>GW: GET /json/version
    GW->>PP: 命中 9223 转发口
    PP->>CH: 转发到 127.0.0.1:9222
    CH-->>PP: 返回 Browser / webSocketDebuggerUrl
    PP-->>GW: 回传
    GW-->>RP: 回传
    RP->>GW: WebSocket /devtools/browser/<id>
    GW->>PP: 转发 WebSocket
    PP->>CH: 进入 Chrome DevTools Protocol
    CH-->>PP: 返回 tabs / pages / DOM / JS / navigation 结果
    PP-->>GW: 回传
    GW-->>RP: 回传
    RP-->>OC: 浏览器控制成功
```

## 6. 关键配置

### 6.1 OpenClaw JSON 配置片段

文件：

```text
~/.openclaw/openclaw.json
```

关键配置片段：

```json
{
  "browser": {
    "enabled": true,
    "defaultProfile": "remote",
    "profiles": {
      "remote": {
        "cdpUrl": "http://172.17.32.1:9223",
        "attachOnly": true,
        "color": "#00AA00"
      }
    }
  }
}
```

## 7. 可执行步骤（按顺序）

### Step 1：在 Windows 启动 Chrome 调试端口 9222

```powershell
& 'C:\Program Files\Google\Chrome\Application\chrome.exe' --remote-debugging-port=9222
```

### Step 2：在 Windows 本机确认 9222 确实可用

```powershell
curl http://127.0.0.1:9222/json/version
curl http://127.0.0.1:9222/json/list
netstat -ano | findstr 9222
```

### Step 3：在 Windows 建立 9223 → 9222 的 portproxy 转发

```powershell
netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=9223 connectaddress=127.0.0.1 connectport=9222
```

查看：

```powershell
netsh interface portproxy show all
```

删除：

```powershell
netsh interface portproxy delete v4tov4 listenaddress=0.0.0.0 listenport=9223
```

### Step 4：在 Windows 放行 9223 防火墙规则

```powershell
netsh advfirewall firewall add rule name="ChromeCDP9223" dir=in action=allow protocol=TCP localport=9223
```

查看：

```powershell
netsh advfirewall firewall show rule name="ChromeCDP9223"
```

删除：

```powershell
netsh advfirewall firewall delete rule name="ChromeCDP9223"
```

### Step 5：在 WSL 验证 9223 是否已打通

```bash
curl --connect-timeout 3 --max-time 5 http://172.17.32.1:9223/json/version
curl --connect-timeout 3 --max-time 5 http://172.17.32.1:9223/json/list
```

### Step 6：重启后自动恢复 remote CDP（推荐）

优先使用 skill 自带脚本，而不是每次手工改 JSON：

```bash
~/bin/update-openclaw-remote-cdp.sh --dry-run
~/bin/update-openclaw-remote-cdp.sh --apply --set-default
```

如果你只是想快速看当前宿主机 IP 与推导出来的 CDP URL：

```bash
~/bin/show-openclaw-remote-cdp.sh
```

建议将 skill 中的脚本复制到：

```bash
mkdir -p ~/bin
cp scripts/update-openclaw-remote-cdp.sh ~/bin/
cp scripts/show-openclaw-remote-cdp.sh ~/bin/
chmod +x ~/bin/update-openclaw-remote-cdp.sh ~/bin/show-openclaw-remote-cdp.sh
```

### Step 7：确认 OpenClaw 配置已指向 remote CDP

```bash
grep -n 'defaultProfile\|cdpUrl\|attachOnly' ~/.openclaw/openclaw.json
```

### Step 8：重启 OpenClaw Gateway

```bash
openclaw gateway restart
```

### Step 9：验证 OpenClaw 已接上 remote profile

```bash
openclaw browser profiles
openclaw browser --browser-profile remote status
```

### Step 10：验证 OpenClaw 对 Windows Chrome 的控制能力

```bash
openclaw browser --browser-profile remote tabs
openclaw browser --browser-profile remote open https://example.com
openclaw browser --browser-profile remote snapshot
openclaw browser --browser-profile remote navigate https://example.org
```
