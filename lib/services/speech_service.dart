import 'dart:async';
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

  // 침묵 감지 관련 변수들
  Timer? _silenceTimer;
  DateTime? _lastSpeechTime;
  String _lastRecognizedText = '';
  bool _speechDetected = false;

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
          _stopSilenceDetection();
          _isListening = false;
        },
        onStatus: (status) {
          print('📊 음성 인식 상태: $status');
          _isListening = status == 'listening';
          if (!_isListening) {
            _stopSilenceDetection();
          }
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

  // 침묵 감지 시작
  void _startSilenceDetection() {
    _stopSilenceDetection(); // 기존 타이머 정리

    _lastSpeechTime = DateTime.now();
    _speechDetected = false;
    _lastRecognizedText = '';

    print('🔇 침묵 감지 시작 (4초 침묵 시 자동 종료)');

    _silenceTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!_isListening) {
        timer.cancel();
        return;
      }

      final now = DateTime.now();
      final timeSinceLastSpeech = _lastSpeechTime != null
          ? now.difference(_lastSpeechTime!).inMilliseconds
          : 0;

      // 음성이 한 번이라도 감지되었고, 4초 동안 침묵이면 자동 종료
      if (_speechDetected && timeSinceLastSpeech > 4000) {
        print('🔇 4초 침묵 감지 - 음성인식 자동 종료');
        print('📊 최종 인식 결과: "$_lastWords"');
        timer.cancel();
        _autoStopListening();
      }
    });
  }

  // 침묵 감지 중지
  void _stopSilenceDetection() {
    _silenceTimer?.cancel();
    _silenceTimer = null;
  }

  // 음성 활동 감지 업데이트
  void _updateSpeechActivity(String recognizedText, double soundLevel) {
    final now = DateTime.now();

    // 새로운 텍스트가 인식되었거나 소리 레벨이 높으면 음성 활동으로 간주
    bool hasNewText =
        recognizedText.isNotEmpty && recognizedText != _lastRecognizedText;
    bool hasSoundActivity = soundLevel > -30.0; // dB 기준 (조정 가능)

    if (hasNewText || hasSoundActivity) {
      _lastSpeechTime = now;
      _speechDetected = true;

      if (hasNewText) {
        _lastRecognizedText = recognizedText;
        print('🎯 새로운 음성 인식: "$recognizedText"');
      }

      if (hasSoundActivity) {
        print('🔊 음성 활동 감지: ${soundLevel.toStringAsFixed(1)}dB');
      }
    }
  }

  // 자동 중지 (침묵 감지로 인한)
  Future<void> _autoStopListening() async {
    try {
      if (_isListening) {
        await _speech.stop();
        _stopSilenceDetection();
        _isListening = false;
        print('✅ 침묵 감지로 음성 인식 자동 완료');
      }
    } catch (e) {
      print('🚨 자동 음성 인식 중지 에러: $e');
      _isListening = false;
    }
  }

  Future<String?> startListening({
    String language = 'ko-KR',
    Duration timeout = const Duration(seconds: 30), // 30초로 연장
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
      _lastRecognizedText = '';
      _speechDetected = false;

      print(
        '🎤 음성 인식 시작 - 언어: $language (최대 ${timeout.inSeconds}초, 침묵 4초 시 자동 종료)',
      );

      // 침묵 감지 시작
      _startSilenceDetection();

      await _speech.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;

          // 음성 활동 업데이트 (텍스트 기반)
          _updateSpeechActivity(_lastWords, 0.0);

          print('🗣️ 인식된 텍스트: "$_lastWords"');
          print('📊 신뢰도: ${(result.confidence * 100).toStringAsFixed(1)}%');

          // 최종 결과인 경우 자동 종료
          if (result.finalResult && _lastWords.isNotEmpty) {
            print('✅ 최종 결과 확정 - 음성인식 완료');
            _autoStopListening();
          }
        },
        listenFor: timeout, // 30초로 연장
        pauseFor: const Duration(seconds: 8), // Android 일시정지 시간도 연장
        partialResults: true, // 실시간 결과 중요!
        localeId: language,
        cancelOnError: true,
        onSoundLevelChange: (level) {
          // 음성 활동 업데이트 (소리 레벨 기반)
          _updateSpeechActivity(_lastWords, level);
        },
      );

      // 음성 인식 완료까지 대기
      while (_isListening) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      _stopSilenceDetection(); // 정리

      if (_lastWords.isNotEmpty) {
        print('✅ 음성 인식 완료: "$_lastWords"');
        return _lastWords;
      } else {
        print('⚠️ 음성이 인식되지 않았습니다');
        return null;
      }
    } catch (e) {
      print('🚨 음성 인식 에러: $e');
      _stopSilenceDetection();
      _isListening = false;
      return null;
    }
  }

  Future<void> stopListening() async {
    try {
      if (_isListening) {
        _stopSilenceDetection();
        await _speech.stop();
        _isListening = false;
        print('⏹️ 음성 인식 수동 중지');
      }
    } catch (e) {
      print('🚨 음성 인식 중지 에러: $e');
      _stopSilenceDetection();
      _isListening = false;
    }
  }

  Future<void> cancel() async {
    try {
      _stopSilenceDetection();
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
      _stopSilenceDetection();
      _speech.cancel();
      _isListening = false;
      _lastWords = '';
      print('🗑️ 음성 인식 서비스 해제');
    } catch (e) {
      print('🚨 음성 인식 서비스 해제 에러: $e');
    }
  }
}
