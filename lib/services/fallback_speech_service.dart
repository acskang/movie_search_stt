// lib/services/fallback_speech_service.dart
// STT 패키지 문제시 사용할 대체 서비스

import 'package:flutter/foundation.dart';

class SimpleSpeechService {
  // 상태 변수들
  bool _isListening = false;
  bool _isAvailable = false;
  String _currentLocale = 'ko_KR';

  // 콜백 함수들
  Function(String)? onResult;
  Function(String)? onError;
  Function(bool)? onListeningStateChanged;

  // Getter들
  bool get isListening => _isListening;
  bool get isAvailable => _isAvailable;
  String get currentLocale => _currentLocale;
  bool get isKorean => _currentLocale == 'ko_KR';
  String get currentLanguageText => isKorean ? '🇰🇷 한국어' : '🇺🇸 English';

  // 초기화 - STT 기능은 비활성화하고 키보드만 사용
  Future<bool> initialize() async {
    try {
      // 실제 STT 패키지 사용 시도
      if (kIsWeb ||
          defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        // 웹이나 모바일에서만 STT 시도
        _isAvailable = await _initializeRealSTT();
      } else {
        _isAvailable = false;
      }

      if (!_isAvailable) {
        print('STT 사용 불가 - 키보드 입력만 사용');
        onError?.call('음성 인식을 사용할 수 없습니다. 키보드 입력을 사용하세요.');
      }

      return true; // STT 실패해도 앱은 계속 실행
    } catch (e) {
      print('STT 초기화 실패, 키보드 모드로 전환: $e');
      _isAvailable = false;
      return true; // 앱은 계속 실행
    }
  }

  // 실제 STT 초기화 시도
  Future<bool> _initializeRealSTT() async {
    try {
      // speech_to_text 패키지를 동적으로 로드 시도
      // 패키지가 없거나 문제가 있으면 false 반환
      return false; // 현재는 안전을 위해 비활성화
    } catch (e) {
      return false;
    }
  }

  // 음성 인식 시작 - 비활성화 상태
  Future<void> startListening() async {
    if (!_isAvailable) {
      onError?.call('음성 인식 기능이 비활성화되었습니다. 키보드를 사용하세요.');
      return;
    }

    // 실제 STT 코드는 패키지 문제 해결 후 구현
    onError?.call('STT 기능이 일시적으로 비활성화되었습니다.');
  }

  // 음성 인식 중지
  Future<void> stopListening() async {
    _isListening = false;
    onListeningStateChanged?.call(false);
  }

  // 언어 전환
  void switchLanguage() {
    if (_currentLocale == 'ko_KR') {
      _currentLocale = 'en_US';
    } else {
      _currentLocale = 'ko_KR';
    }
    print('언어 변경: $_currentLocale (STT 비활성화 상태)');
  }

  // 리소스 정리
  void dispose() {
    // 아무것도 하지 않음
  }

  // 플랫폼 정보
  String getPlatformInfo() {
    if (kIsWeb) return 'Web (키보드 입력)';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'Android (키보드 입력)';
      case TargetPlatform.iOS:
        return 'iOS (키보드 입력)';
      default:
        return 'Desktop (키보드 입력)';
    }
  }
}
