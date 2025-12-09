# Keyboard Done Button iOS Plugin - Implementation Notes

## 개요

iPhone 키보드 상단에 "Done" 버튼 툴바를 표시하는 Flutter iOS 플러그인입니다.
숫자 키패드처럼 Done 버튼이 없는 키보드에서 키보드를 닫을 수 있도록 합니다.

---

## 아키텍처

### 기술 스택
- **iOS**: Swift, UIKit
- **Flutter**: Dart, Platform Channels (MethodChannel)

### 핵심 구조

```
Flutter (Dart)                    iOS (Swift)
─────────────────────────────────────────────────────
KeyboardToolbar            →     KeyboardDoneButtonIosPlugin
  └─ show()               →       └─ pendingToolbarRequest = true
                                   └─ keyboardWillShow (Observer)
                                   └─ showToolbar() / hideToolbar()
```

### 왜 UIWindow를 사용하는가?

Flutter는 네이티브 `inputAccessoryView`에 직접 접근할 수 없습니다.
따라서 별도의 `UIWindow`를 생성하여 키보드 위에 오버레이로 표시합니다.

```swift
// 키보드보다 높은 windowLevel로 설정
window.windowLevel = UIWindow.Level(rawValue: UIWindow.Level.alert.rawValue - 1)
```

---

## 구현된 기능

### 1. One-shot 방식
- `showDoneButton()` 호출 시 플래그만 설정
- 다음 `keyboardWillShow`에서 플래그 확인 후 툴바 표시
- 사용 후 자동 리셋 → 명시적으로 호출한 TextField에서만 툴바 표시

```dart
// 사용 예시
TextField(
  keyboardType: TextInputType.number,
  onTap: () => KeyboardToolbar.show(),
)
```

### 2. iPad 자동 제외
- iPad는 숫자 키패드에도 Done 버튼이 기본 제공됨
- `UIDevice.current.userInterfaceIdiom == .pad` 체크로 완전 스킵
- Observer 등록 자체를 하지 않아 불필요한 코드 실행 방지

### 3. 다국어 로컬라이제이션
- 시스템 버튼(`.done`)을 사용하여 iOS가 자동으로 로컬라이즈
- 시스템 언어에 따라 자동 전환 (영어: "Done", 한국어: "완료", 일본어: "完了" 등)
- `Info.plist`에 `CFBundleAllowMixedLocalizations = YES` 설정 필요

### 4. Fade In/Out 애니메이션
- 네이티브 inputAccessoryView의 슬라이드 애니메이션은 구현 불가
- Fade 방식으로 이질감 최소화
- 키보드 애니메이션 duration과 동기화

### 5. 화면 회전 시 툴바 유지
- 디바이스 회전 시 키보드가 hide/show 되어도 툴바 유지
- Screen Bounds 비교 방식으로 회전 감지 (추가 Observer 불필요)
- `isToolbarActive` + `lastScreenBounds` 플래그로 상태 추적

```swift
// 회전 감지 로직
let currentScreenBounds = UIScreen.main.bounds
let didRotate = isToolbarActive &&
                lastScreenBounds != .zero &&
                lastScreenBounds != currentScreenBounds

let shouldShowToolbar = pendingToolbarRequest || didRotate
```

**동작 원리**:
- 세로 모드: bounds = (393, 852)
- 가로 모드: bounds = (852, 393)
- 회전 시 width/height가 바뀌므로 bounds 변경 감지 가능

---

## 해결한 문제들

### 1. Race Condition - Observer 등록 타이밍

**문제**: `showDoneButton()` 호출 후 Observer 등록하면 `keyboardWillShow`를 놓침

**해결**: 앱 시작 시 Observer를 미리 등록 (`register()` 메서드에서)

```swift
public static func register(with registrar: FlutterPluginRegistrar) {
  let instance = KeyboardDoneButtonIosPlugin()
  instance.registerKeyboardObservers()  // 앱 시작 시 등록
  // ...
}
```

### 2. 빠른 TextField 전환 시 툴바 사라짐

**문제**: Done 버튼 탭 → 빠르게 다른 TextField 탭 → 툴바 안 보임

**원인**: `hideToolbar()`의 completion block이 `showToolbar()` 이후에 실행되어 `isHidden = true` 설정

**해결**:
1. `showToolbar()`에서 `layer.removeAllAnimations()` 호출하여 진행 중인 hide 애니메이션 취소
2. `hideToolbar()` completion에서 `finished` 체크

```swift
// showToolbar()
toolbarWindow?.layer.removeAllAnimations()

// hideToolbar()
UIView.animate(...) { finished in
  guard finished else { return }  // 취소된 경우 스킵
  toolbarWindow.isHidden = true
}
```

### 3. 툴바 깜빡임 (이미 보이는 상태에서 재표시)

**문제**: 툴바가 이미 보이는 상태에서 다른 TextField로 전환 시 깜빡임

**원인**: 매번 `alpha = 0`으로 리셋 후 fade-in

**해결**: 이미 보이는 상태면 위치만 업데이트

```swift
let isAlreadyVisible = !toolbarWindow.isHidden && toolbarWindow.alpha == 1

if isAlreadyVisible {
  toolbarWindow.frame = CGRect(...)  // 위치만 변경
  return
}
```

### 4. rootViewController 관련 (iOS 13+)

**초기 우려**: iOS 13+에서 UIWindow에 rootViewController 없이 subview 추가 시 문제 발생 가능

**검증 결과**: 테스트 결과 rootViewController 없이도 정상 동작 확인

**결론**: 불필요한 코드 제거, `window.addSubview(toolbar)` 직접 사용

---

## 코드 구조

```
ios/Classes/
└── KeyboardDoneButtonIosPlugin.swift
    ├── Properties
    │   ├── toolbarWindow: UIWindow?
    │   ├── toolbar: UIToolbar?
    │   ├── pendingToolbarRequest: Bool (one-shot 플래그)
    │   ├── isObserversRegistered: Bool
    │   ├── isToolbarActive: Bool (회전 감지용)
    │   └── lastScreenBounds: CGRect (회전 감지용)
    │
    ├── Plugin Registration
    │   └── register() - Observer 등록, MethodChannel 설정
    │
    ├── Setup
    │   ├── registerKeyboardObservers() - iPad 체크 포함
    │   └── showDoneButton() - iPad 체크 포함
    │
    ├── Keyboard Handlers
    │   ├── keyboardWillShow() - 회전 감지 + 툴바 표시 로직
    │   └── keyboardWillHide() - 툴바 숨김 (isToolbarActive 유지)
    │
    ├── Toolbar Management
    │   ├── createToolbar() - UIToolbar + Done 버튼 생성
    │   ├── showToolbar() - 애니메이션 포함 표시
    │   └── hideToolbar() - 애니메이션 포함 숨김
    │
    └── Button Actions
        └── doneButtonTapped() - 키보드 닫기 + isToolbarActive 리셋
```

---

## Flutter 측 API

```dart
// 현재 API
class KeyboardToolbar {
  static Future<void> show() async {
    if (Platform.isIOS) {
      await _channel.invokeMethod('showDoneButton');
    }
  }
}

// Usage
TextField(
  keyboardType: TextInputType.number,
  onTap: () => KeyboardToolbar.show(),
)
```

---

## 향후 확장 가능 기능

### +/- 버튼 추가 (검토 완료, 미구현)

```dart
// 예상 API
KeyboardToolbar.show(showPlusMinus: true);

// iOS → Flutter callback
KeyboardToolbar.setOnPlusMinusTapped(() {
  // 부호 변경 로직
});
```

**구현 방식**:
- 커스텀 UIButton (파란 배경, 흰색 텍스트, 둥근 모서리)
- `channel.invokeMethod("onPlusMinusTapped")` 로 Flutter에 이벤트 전달

---

## 참고 사항

### 디자인 레퍼런스
- Zoho Inventory 앱의 키보드 툴바 참조

### 애니메이션 제한
- 네이티브 `inputAccessoryView`처럼 키보드와 함께 슬라이드되는 애니메이션은 기술적 한계로 구현 불가
- UIWindow 오버레이 방식의 한계

### iPad 동작
- iPad는 숫자 키패드에도 Done 버튼이 기본 제공
- 플러그인이 iPad에서 완전히 비활성화됨 (Observer 등록 스킵)

---

## 해결한 추가 문제

### 5. 화면 회전 시 툴바 사라짐

**문제**: 세로 모드에서 툴바 표시 → 가로 모드로 회전 → 툴바 사라짐

**원인 분석**:
```
1. 툴바 표시 중 (pendingToolbarRequest = false로 이미 리셋됨)
2. 회전 → keyboardWillHide 발생
3. keyboardWillShow 발생 → pendingToolbarRequest = false → 툴바 숨김
```

**해결**: Screen Bounds 비교로 회전 감지
```swift
private var isToolbarActive = false
private var lastScreenBounds: CGRect = .zero

// keyboardWillShow에서
let didRotate = isToolbarActive &&
                lastScreenBounds != .zero &&
                lastScreenBounds != currentScreenBounds

let shouldShowToolbar = pendingToolbarRequest || didRotate
```

**왜 Screen Bounds인가?**
| 방법 | 추가 설정 | 성능 영향 |
|------|----------|----------|
| `beginGeneratingDeviceOrientationNotifications` | 필요 | 가속도계 사용 |
| `statusBarOrientationNotification` | 불필요 | iOS 13 deprecated |
| **Screen Bounds 비교** | 불필요 | 없음 ✅ |

---

*마지막 업데이트: 2025-12*
