// lib/services/modern_speech_service.dart - Flutter 3.32.5 호환
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class SimpleSpeechService {
  final SpeechToText _speech = SpeechToText();

  // 상태 변수들
  bool _isListening = false;
  bool _isAvailable = false;
  String _currentLocale = 'ko_KR';
  List<LocaleName> _availableLocales = [];

  // 콜백 함수들
  Function(String)? onResult;
  Function(String)? onError;
  Function(bool)? onListeningStateChanged;
  Function(double)? onSoundLevelChanged;

  // Getter들
  bool get isListening => _isListening;
  bool get isAvailable => _isAvailable;
  String get currentLocale => _currentLocale;
  bool get isKorean => _currentLocale == 'ko_KR';
  String get currentLanguageText => isKorean ? '🇰🇷 한국어' : '🇺🇸 English';
  String get currentLanguageHint =>
      isKorean ? '한국어로 말해주세요' : 'Speak in English';

  // 플랫폼 지원 여부 확인
  bool get _isPlatformSupported {
    return kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  // 초기화 - 최신 API 사용
  Future<bool> initialize() async {
    if (!_isPlatformSupported) {
      _handleError('현재 플랫폼에서는 음성 인식이 지원되지 않습니다.');
      return false;
    }

    try {
      // 권한 요청 (최신 방식)
      if (!kIsWeb) {
        final microphoneStatus = await Permission.microphone.request();
        if (microphoneStatus != PermissionStatus.granted) {
          _handleError('마이크 권한이 필요합니다.');
          return false;
        }

        final speechStatus = await Permission.speech.request();
        if (speechStatus != PermissionStatus.granted) {
          _handleError('음성 인식 권한이 필요합니다.');
          return false;
        }
      }

      // STT 서비스 초기화 (최신 콜백 방식)
      _isAvailable = await _speech.initialize(
        onError: (errorNotification) {
          debugPrint('STT 에러: ${errorNotification.errorMsg}');
          _handleError('음성 인식 오류: ${errorNotification.errorMsg}');
          _setListeningState(false);
        },
        onStatus: (status) {
          debugPrint('STT 상태: $status');
          switch (status) {
            case 'listening':
              _setListeningState(true);
              break;
            case 'notListening':
            case 'done':
              _setListeningState(false);
              break;
            default:
              break;
          }
        },
        debugLogging: kDebugMode, // 디버그 모드에서만 로깅
      );

      if (_isAvailable) {
        // 사용 가능한 언어 목록 가져오기
        _availableLocales = await _speech.locales();
        debugPrint('사용 가능한 언어: ${_availableLocales.length}개');
        debugPrint('STT 초기화 성공');
        return true;
      } else {
        _handleError('음성 인식을 사용할 수 없습니다.');
        return false;
      }
    } catch (e) {
      debugPrint('STT 초기화 실패: $e');
      _handleError('음성 인식 초기화 실패');
      return false;
    }
  }

  // 에러 처리
  void _handleError(String message) {
    if (!_isPlatformSupported) {
      onError?.call('데스크톱에서는 음성 인식이 지원되지 않습니다. 웹 브라우저를 사용하세요.');
    } else {
      onError?.call(message);
    }
  }

  // 음성 인식 시작 (최신 API)
  Future<void> startListening() async {
    if (!_isPlatformSupported) {
      _handleError('현재 플랫폼에서는 음성 인식이 지원되지 않습니다.');
      return;
    }

    if (!_isAvailable) {
      _handleError('음성 인식을 사용할 수 없습니다.');
      return;
    }

    if (_isListening) {
      await stopListening();
      return;
    }

    try {
      final success = await _speech.listen(
        onResult: (result) {
          String recognizedText = result.recognizedWords;
          if (recognizedText.isNotEmpty) {
            debugPrint('인식된 텍스트: $recognizedText');
            debugPrint('최종 결과: ${result.finalResult}');
            onResult?.call(recognizedText);
          }
        },
        onSoundLevelChange: (level) {
          // 음성 레벨 변화 감지 (시각적 피드백용)
          onSoundLevelChanged?.call(level);
        },
        listenFor: const Duration(seconds: 10), // 최대 10초
        pauseFor: const Duration(seconds: 3), // 3초 무음시 중지
        partialResults: true, // 실시간 결과
        localeId: _currentLocale,
        cancelOnError: false,
        listenMode: ListenMode.confirmation, // 최신 모드
      );

      if (!success) {
        _handleError('음성 인식을 시작할 수 없습니다.');
      }
    } catch (e) {
      debugPrint('음성 인식 시작 실패: $e');
      _handleError('음성 인식을 시작할 수 없습니다');
    }
  }

  // 음성 인식 중지
  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _setListeningState(false);
    }
  }

  // 언어 전환 (사용 가능한 언어 중에서)
  void switchLanguage() {
    if (_availableLocales.isEmpty) {
      // 기본 전환
      _currentLocale = _currentLocale == 'ko_KR' ? 'en_US' : 'ko_KR';
    } else {
      // 사용 가능한 언어 중에서 전환
      final currentIndex = _availableLocales.indexWhere(
        (locale) => locale.localeId == _currentLocale,
      );

      if (currentIndex != -1 && currentIndex < _availableLocales.length - 1) {
        _currentLocale = _availableLocales[currentIndex + 1].localeId;
      } else {
        _currentLocale = _availableLocales.isNotEmpty
            ? _availableLocales[0].localeId
            : 'ko_KR';
      }
    }

    debugPrint('언어 변경: $_currentLocale');
  }

  // 특정 언어로 설정
  void setLanguage(String localeId) {
    if (_availableLocales.any((locale) => locale.localeId == localeId)) {
      _currentLocale = localeId;
      debugPrint('언어 설정: $_currentLocale');
    }
  }

  // 사용 가능한 언어 목록 반환
  List<LocaleName> getAvailableLanguages() {
    return _availableLocales;
  }

  // 듣기 상태 변경
  void _setListeningState(bool listening) {
    if (_isListening != listening) {
      _isListening = listening;
      onListeningStateChanged?.call(_isListening);
    }
  }

  // 음성 인식 중단 (강제)
  Future<void> cancel() async {
    await _speech.cancel();
    _setListeningState(false);
  }

  // 리소스 정리
  void dispose() {
    _speech.stop();
  }

  // 디바이스 정보
  String getPlatformInfo() {
    String platform = '';
    if (kIsWeb) {
      platform = 'Web';
    } else {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          platform = 'Android';
          break;
        case TargetPlatform.iOS:
          platform = 'iOS';
          break;
        case TargetPlatform.linux:
          platform = 'Linux (STT 미지원)';
          break;
        case TargetPlatform.windows:
          platform = 'Windows (STT 미지원)';
          break;
        case TargetPlatform.macOS:
          platform = 'macOS (STT 미지원)';
          break;
        default:
          platform = 'Unknown Platform';
      }
    }

    return '$platform - 언어: ${_availableLocales.length}개 지원';
  }
}
