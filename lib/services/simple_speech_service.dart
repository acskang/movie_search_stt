// lib/services/simple_speech_service.dart
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class SimpleSpeechService {
  final SpeechToText _speech = SpeechToText();

  // 상태 변수들
  bool _isListening = false;
  bool _isAvailable = false;
  String _currentLocale = 'ko_KR'; // 기본값: 한국어

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

  // 초기화
  Future<bool> initialize() async {
    try {
      // 마이크 권한 요청
      PermissionStatus permission = await Permission.microphone.request();
      if (permission != PermissionStatus.granted) {
        onError?.call('마이크 권한이 필요합니다.');
        return false;
      }

      // STT 서비스 초기화
      _isAvailable = await _speech.initialize(
        onError: (error) {
          print('STT 에러: ${error.errorMsg}');
          onError?.call('음성 인식 오류: ${error.errorMsg}');
          _setListeningState(false);
        },
        onStatus: (status) {
          print('STT 상태: $status');
          if (status == 'notListening') {
            _setListeningState(false);
          }
        },
      );

      if (_isAvailable) {
        print('STT 초기화 성공');
        return true;
      } else {
        onError?.call('음성 인식을 사용할 수 없습니다.');
        return false;
      }
    } catch (e) {
      print('STT 초기화 실패: $e');
      onError?.call('음성 인식 초기화 실패: $e');
      return false;
    }
  }

  // 음성 인식 시작
  Future<void> startListening() async {
    if (!_isAvailable) {
      onError?.call('음성 인식을 사용할 수 없습니다.');
      return;
    }

    if (_isListening) {
      await stopListening();
      return;
    }

    try {
      await _speech.listen(
        onResult: (result) {
          String recognizedText = result.recognizedWords;
          if (recognizedText.isNotEmpty) {
            print('인식된 텍스트: $recognizedText');
            onResult?.call(recognizedText);
          }
        },
        listenFor: const Duration(seconds: 10), // 10초간 듣기
        pauseFor: const Duration(seconds: 3), // 3초 무음시 정지
        localeId: _currentLocale,
        cancelOnError: false,
        partialResults: true, // 실시간 결과 표시
      );

      _setListeningState(true);
    } catch (e) {
      print('음성 인식 시작 실패: $e');
      onError?.call('음성 인식을 시작할 수 없습니다: $e');
    }
  }

  // 음성 인식 중지
  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _setListeningState(false);
    }
  }

  // 언어 전환 (한국어 ↔ 영어)
  void switchLanguage() {
    if (_currentLocale == 'ko_KR') {
      _currentLocale = 'en_US';
    } else {
      _currentLocale = 'ko_KR';
    }
    print('언어 변경: $_currentLocale');
  }

  // 듣기 상태 변경
  void _setListeningState(bool listening) {
    _isListening = listening;
    onListeningStateChanged?.call(_isListening);
  }

  // 리소스 정리
  void dispose() {
    _speech.stop();
  }

  // 사용 가능한 언어 목록 가져오기
  Future<List<String>> getAvailableLanguages() async {
    if (!_isAvailable) return [];

    try {
      var locales = await _speech.locales();
      return locales.map((locale) => locale.localeId).toList();
    } catch (e) {
      print('언어 목록 가져오기 실패: $e');
      return ['ko_KR', 'en_US']; // 기본값
    }
  }
}
