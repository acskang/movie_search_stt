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

  // 침묵 감지 관련 변수들 (개선)
  Timer? _silenceTimer;
  DateTime? _lastSpeechTime;
  String _lastRecognizedText = '';
  bool _speechDetected = false;
  int _consecutiveSameResults = 0; // 동일한 결과 반복 횟수

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

  // 🔧 개선된 침묵 감지 시작
  void _startSilenceDetection() {
    _stopSilenceDetection(); // 기존 타이머 정리

    _lastSpeechTime = DateTime.now();
    _speechDetected = false;
    _lastRecognizedText = '';
    _consecutiveSameResults = 0;

    print('🔇 침묵 감지 시작 (6초 침묵 시 자동 종료)'); // 4초 → 6초로 증가

    _silenceTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!_isListening) {
        timer.cancel();
        return;
      }

      final now = DateTime.now();
      final timeSinceLastSpeech = _lastSpeechTime != null
          ? now.difference(_lastSpeechTime!).inMilliseconds
          : 0;

      // 🔧 조건 강화: 음성이 감지되고, 6초 침묵이고, 동일한 결과가 3번 이상 반복되면 종료
      if (_speechDetected &&
          timeSinceLastSpeech > 6000 && // 4초 → 6초로 증가
          _consecutiveSameResults >= 3 && // 안정성 확보
          _lastWords.trim().isNotEmpty) {
        print('🔇 6초 침묵 + 안정된 결과 감지 - 음성인식 자동 종료');
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

  // 🔧 개선된 음성 활동 감지 업데이트
  void _updateSpeechActivity(String recognizedText, double soundLevel) {
    final now = DateTime.now();

    // 새로운 텍스트가 인식되었거나 소리 레벨이 높으면 음성 활동으로 간주
    bool hasNewText =
        recognizedText.isNotEmpty && recognizedText != _lastRecognizedText;
    bool hasSoundActivity = soundLevel > -25.0; // -30dB → -25dB로 조정 (더 민감하게)

    if (hasNewText || hasSoundActivity) {
      _lastSpeechTime = now;
      _speechDetected = true;

      if (hasNewText) {
        // 🔧 동일한 결과 반복 횟수 체크
        if (recognizedText == _lastRecognizedText) {
          _consecutiveSameResults++;
        } else {
          _consecutiveSameResults = 1;
          _lastRecognizedText = recognizedText;
          print('🎯 새로운 음성 인식: "$recognizedText"');
        }
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
    Duration timeout = const Duration(seconds: 20), // 30초 → 20초로 적정화
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
      _consecutiveSameResults = 0;

      print(
        '🎤 음성 인식 시작 - 언어: $language (최대 ${timeout.inSeconds}초, 침묵 6초 시 자동 종료)',
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
          print('🔄 최종결과: ${result.finalResult}');

          // 🔧 finalResult 자동 종료 제거 - 너무 성급한 종료 방지
          // if (result.finalResult && _lastWords.isNotEmpty) {
          //   print('✅ 최종 결과 확정 - 음성인식 완료');
          //   _autoStopListening();
          // }
        },
        listenFor: timeout,
        pauseFor: const Duration(seconds: 3), // 8초 → 3초로 단축 (중요!)
        partialResults: true, // 실시간 결과 유지
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
