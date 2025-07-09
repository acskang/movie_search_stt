import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isAvailable = false;
  String _lastWords = '';

  bool get isListening => _isListening;
  bool get isAvailable => _isAvailable;
  String get lastWords => _lastWords;

  Future<bool> initialize() async {
    try {
      print('🎤 음성 인식 서비스 초기화 중...');

      // 마이크 권한 요청
      final microphoneStatus = await Permission.microphone.request();
      if (microphoneStatus != PermissionStatus.granted) {
        print('❌ 마이크 권한이 거부되었습니다');
        return false;
      }

      // Speech-to-Text 초기화
      _isAvailable = await _speech.initialize(
        onError: (error) {
          print('🚨 음성 인식 에러: ${error.errorMsg}');
          _isListening = false;
        },
        onStatus: (status) {
          print('📊 음성 인식 상태: $status');
          _isListening = status == 'listening';
        },
      );

      if (_isAvailable) {
        print('✅ 음성 인식 서비스 초기화 완료');
      } else {
        print('❌ 음성 인식 서비스를 사용할 수 없습니다');
      }

      return _isAvailable;
    } catch (e) {
      print('🚨 음성 인식 초기화 에러: $e');
      return false;
    }
  }

  Future<List<String>> getAvailableLanguages() async {
    try {
      if (!_isAvailable) {
        await initialize();
      }

      final locales = await _speech.locales();
      final languages = locales.map((locale) => locale.localeId).toList();

      // 한국어와 영어 우선 정렬
      languages.sort((a, b) {
        if (a.startsWith('ko')) return -1;
        if (b.startsWith('ko')) return 1;
        if (a.startsWith('en')) return -1;
        if (b.startsWith('en')) return 1;
        return a.compareTo(b);
      });

      return languages;
    } catch (e) {
      print('🚨 언어 목록 가져오기 에러: $e');
      return ['ko-KR', 'en-US']; // 기본값
    }
  }

  Future<String?> startListening({
    String language = 'ko-KR',
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      if (!_isAvailable) {
        final initialized = await initialize();
        if (!initialized) {
          throw Exception('음성 인식 서비스를 초기화할 수 없습니다');
        }
      }

      if (_isListening) {
        await stopListening();
        await Future.delayed(const Duration(milliseconds: 500));
      }

      _lastWords = '';

      print('🎤 음성 인식 시작 - 언어: $language');

      await _speech.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          print('🗣️ 인식된 텍스트: $_lastWords');
        },
        listenFor: timeout,
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: language,
        onSoundLevelChange: (level) {
          // 음성 레벨 로깅 (선택사항)
        },
      );

      // 음성 인식 완료까지 대기
      while (_isListening) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      print('✅ 음성 인식 완료: $_lastWords');
      return _lastWords.isNotEmpty ? _lastWords : null;
    } catch (e) {
      print('🚨 음성 인식 에러: $e');
      _isListening = false;
      return null;
    }
  }

  Future<void> stopListening() async {
    try {
      if (_isListening) {
        await _speech.stop();
        _isListening = false;
        print('⏹️ 음성 인식 중지');
      }
    } catch (e) {
      print('🚨 음성 인식 중지 에러: $e');
      _isListening = false;
    }
  }

  Future<void> cancel() async {
    try {
      await _speech.cancel();
      _isListening = false;
      _lastWords = '';
      print('❌ 음성 인식 취소');
    } catch (e) {
      print('🚨 음성 인식 취소 에러: $e');
    }
  }

  Future<bool> hasPermission() async {
    try {
      final status = await Permission.microphone.status;
      return status == PermissionStatus.granted;
    } catch (e) {
      print('🚨 권한 확인 에러: $e');
      return false;
    }
  }

  Future<bool> requestPermission() async {
    try {
      final status = await Permission.microphone.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      print('🚨 권한 요청 에러: $e');
      return false;
    }
  }

  void dispose() {
    try {
      _speech.cancel();
      _isListening = false;
      _lastWords = '';
      print('🗑️ 음성 인식 서비스 해제');
    } catch (e) {
      print('🚨 음성 인식 서비스 해제 에러: $e');
    }
  }
}
