#!/bin/bash
# sleepwatcher 없이: S4(최대 절전)에서 깨어난 뒤 화면을 자동으로 한 번 껐다가 다시 켜요.
# - 작은 Swift 프로그램이 macOS의 깨어남 알림(NSWorkspace.didWakeNotification)을 받아
#   on-wake.sh 를 실행해요. 이벤트가 올 때만 실행되고 주기적으로 확인하지 않아요.
# - LaunchAgent 로 등록해서 로그인할 때마다 자동으로 켜져요.
# - Xcode(또는 Command Line Tools)의 swiftc 가 필요해요.
#
# 사용법:  bash install-s4-display-toggle-native.sh            # 설치
#          bash install-s4-display-toggle-native.sh uninstall  # 제거
set -eo pipefail

LABEL="com.user.s4-display-toggle"
DIR="$HOME/Library/Application Support/s4-display-toggle"
BIN="$DIR/s4-wake-agent"
SCRIPT="$DIR/on-wake.sh"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
LOG="$HOME/Library/Logs/s4-display-toggle.log"
DOMAIN="gui/$(id -u)"

if [ "${1:-}" = "uninstall" ]; then
  launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null || true
  rm -f "$PLIST"
  rm -rf "$DIR"
  echo "제거했어요."
  exit 0
fi

command -v swiftc >/dev/null || { echo "swiftc가 없어요. Xcode를 설치하거나 'xcode-select --install' 을 실행하세요."; exit 1; }
mkdir -p "$DIR" "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"

# 1) 깨어남 알림을 받는 프로그램
cat > "$DIR/s4-wake-agent.swift" <<'EOF'
import Cocoa

// argv[1]: 깨어날 때 실행할 스크립트
let script = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ""

func runScript() {
    guard !script.isEmpty else { return }
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/bash")
    process.arguments = [script]
    do {
        try process.run()
    } catch {
        NSLog("s4-wake-agent: cannot run \(script): \(error)")
    }
}

NSWorkspace.shared.notificationCenter.addObserver(
    forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { _ in
    runScript()
}

NSLog("s4-wake-agent: waiting for wake notifications")
RunLoop.main.run()
EOF
swiftc -O -o "$BIN" "$DIR/s4-wake-agent.swift"

# 2) 깨어날 때 실행할 스크립트 (S4 판단 + 화면 껐다 켜기)
cat > "$SCRIPT" <<'EOF'
#!/bin/bash
LOG="$HOME/Library/Logs/s4-display-toggle.log"
ALWAYS=0      # 1 로 바꾸면 S3 포함 모든 깨어남에서 실행
SETTLE=4      # 깨어난 뒤 기다리는 시간(초)
OFF_TIME=2    # 화면을 꺼 두는 시간(초)

# 마지막 Sleep 이후의 Wake/DarkWake 기록. 최대 절전에서 깨면
# "... from Standby" 또는 "Hibernate" 가 들어간 줄이 남아요.
wakes=$(pmset -g log | awk '
  /^[0-9-]+ [0-9:]+ [+-][0-9]+ +Sleep /               { buf = ""; next }
  /^[0-9-]+ [0-9:]+ [+-][0-9]+ +(Wake|DarkWake) / && !/Wake Requests/ { buf = buf $0 "\n" }
  END { printf "%s", buf }')
last_wake=$(printf "%s" "$wakes" | tail -1)

is_hibernate=0
if printf "%s" "$wakes" | grep -q -i -E "hibernat|standby"; then
  is_hibernate=1
fi

echo "$(date '+%F %T') wake: $last_wake | hibernate=$is_hibernate" >> "$LOG"

if [ "$ALWAYS" = "1" ] || [ "$is_hibernate" = "1" ]; then
  sleep "$SETTLE"
  pmset displaysleepnow
  sleep "$OFF_TIME"
  caffeinate -u -t 2      # 사용자 활동으로 알려서 화면을 다시 켬
  echo "$(date '+%F %T') display toggled" >> "$LOG"
fi
EOF
chmod +x "$SCRIPT"

# 3) 로그인할 때 자동 실행 (LaunchAgent)
cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$BIN</string>
        <string>$SCRIPT</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>ProcessType</key>
    <string>Background</string>
    <key>StandardErrorPath</key>
    <string>$LOG</string>
</dict>
</plist>
EOF

launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null || true
launchctl bootstrap "$DOMAIN" "$PLIST"
echo "설치했어요."
echo "- 프로그램: $BIN"
echo "- 깨어날 때 실행: $SCRIPT"
echo "- 기록: $LOG"
launchctl print "$DOMAIN/$LABEL" | grep -E "state =|pid =" || true
