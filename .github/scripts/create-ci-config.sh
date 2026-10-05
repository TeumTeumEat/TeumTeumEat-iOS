#!/usr/bin/env bash
# CI 전용: gitignore된 설정 파일(xcconfig, GoogleService-Info.plist)을 더미 값으로 생성
# 단위 테스트는 네트워크를 사용하지 않으므로 실제 키 없이 빌드/실행만 가능하면 된다.
# 이미 파일이 있으면(로컬 환경) 덮어쓰지 않는다.
set -euo pipefail

RESOURCES_DIR="${1:-TeumTeumEat/TeumTeumEat/Resources}"

write_if_missing() {
  local path="$1"
  if [[ -f "$path" ]]; then
    echo "skip: $path (already exists)"
    return
  fi
  cat > "$path"
  echo "created: $path"
}

# AdMob ID는 Google 공식 테스트 ID (형식이 틀리면 MobileAds.start()에서 크래시)
write_if_missing "$RESOURCES_DIR/Config.xcconfig" <<'XCCONFIG'
KAKAO_API_KEY = ci_dummy_kakao_api_key
KAKAO_NATIVE_APPKEY = ci_dummy_kakao_native_appkey
ADMOB_APP_ID = ca-app-pub-3940256099942544~1458002511
ADMOB_REWARDED_AD_UNIT_ID = ca-app-pub-3940256099942544/1712485313
XCCONFIG

# xcconfig에서 '//'는 주석이므로 URL은 '/$()/'로 끊어서 작성
for config in Debug Release; do
  write_if_missing "$RESOURCES_DIR/Config.$config.xcconfig" <<'XCCONFIG'
#include "Config.xcconfig"

BASE_URL = https:/$()/example.com
DEV_BASE_URL = https:/$()/example.com
XCCONFIG
done

# FirebaseApp.configure()가 형식 검증을 통과하도록 올바른 형식의 더미 값 사용
# (API_KEY: 'A' + 38자, GOOGLE_APP_ID: '1:<숫자>:ios:<hex>')
write_if_missing "$RESOURCES_DIR/GoogleService-Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>API_KEY</key>
	<string>AIzaSyCI0000000000000000000000000000000</string>
	<key>GCM_SENDER_ID</key>
	<string>000000000000</string>
	<key>PLIST_VERSION</key>
	<string>1</string>
	<key>BUNDLE_ID</key>
	<string>com.TeumTeumEat</string>
	<key>PROJECT_ID</key>
	<string>teumteumeat-ci</string>
	<key>STORAGE_BUCKET</key>
	<string>teumteumeat-ci.appspot.com</string>
	<key>IS_ADS_ENABLED</key>
	<false/>
	<key>IS_ANALYTICS_ENABLED</key>
	<false/>
	<key>IS_APPINVITE_ENABLED</key>
	<false/>
	<key>IS_GCM_ENABLED</key>
	<true/>
	<key>IS_SIGNIN_ENABLED</key>
	<false/>
	<key>GOOGLE_APP_ID</key>
	<string>1:000000000000:ios:0000000000000000000000</string>
</dict>
</plist>
PLIST
