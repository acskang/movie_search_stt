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

  bool get isListening => _isListening;
  bool get isAvailable => _isAvailable;
  String get lastWords => _lastWords;

  Future<bool> initialize() async {
    try {
      print('🎤 음성인식 초기화...');

      // 마이크 권한 요청
      final microphoneStatus = await Permission.microphone.request();
      if (microphoneStatus != PermissionStatus.granted) {
        print('❌ 마이크 권한 거부됨');
        return false;
      }

      // Speech-to-Text 초기화
      _isAvailable = await _speech.initialize(
        onError: (error) {
          print('🚨 음성인식 에러: ${error.errorMsg}');
          _isListening = false;
        },
        onStatus: (status) {
          _isListening = status == 'listening';
        },
      );

      if (_isAvailable) {
        print('✅ 음성인식 초기화 완료');
      } else {
        print('❌ 음성인식 사용 불가');
      }

      return _isAvailable;
    } catch (e) {
      print('🚨 음성인식 초기화 실패: $e');
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
      print('🚨 언어 목록 가져오기 실패: $e');
      return ['ko-KR', 'en-US']; // 기본값
    }
  }

  Future<String?> startListening({
    String language = 'ko-KR',
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      if (!_isAvailable) {
        final initialized = await initialize();
        if (!initialized) {
          throw Exception('음성인식 서비스를 초기화할 수 없습니다');
        }
      }

      if (_isListening) {
        await stopListening();
        await Future.delayed(const Duration(milliseconds: 500));
      }

      _lastWords = '';
      print('🎤 음성인식 시작 ($language, ${timeout.inSeconds}초)');

      // 🔧 최고 결과 추적 변수
      String bestResult = '';
      bool hasReceivedFinalResult = false;

      // 🔧 deprecated 해결: SpeechListenOptions 사용
      await _speech.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;

          // 🔧 가장 긴 결과만 추적 (로그 최적화)
          if (_lastWords.length > bestResult.length) {
            bestResult = _lastWords;
            print('🏆 새로운 최고: "$bestResult" (${bestResult.length}자)');
          }

          if (result.finalResult) {
            hasReceivedFinalResult = true;
            print('🏁 최종결과 수신');
          }
        },
        listenFor: timeout,
        pauseFor: const Duration(seconds: 8),
        localeId: language,
        listenOptions: stt.SpeechListenOptions(
          partialResults: true, // deprecated 해결
          cancelOnError: false, // deprecated 해결
          onDevice: false,
          listenMode: stt.ListenMode.confirmation,
        ),
        onSoundLevelChange: (level) {
          // 🔧 로그 최적화: 중요한 소리만 출력
          if (level > -25.0) {
            print('🔊 소리감지: ${level.toStringAsFixed(1)}dB');
          }
        },
      );

      // 🔧 대기 시스템 최적화
      int totalWaitTime = 0;
      final maxWaitTime = timeout.inMilliseconds + 5000;

      while (_isListening && totalWaitTime < maxWaitTime) {
        await Future.delayed(const Duration(milliseconds: 500)); // 500ms 간격
        totalWaitTime += 500;

        // 🔧 로그 최적화: 5초마다만 출력
        if (totalWaitTime % 5000 == 0) {
          print('⏰ ${totalWaitTime / 1000}초 경과 - 최고: "$bestResult"');
        }

        // 🔧 조기 종료 조건 최적화
        if (hasReceivedFinalResult &&
            bestResult.isNotEmpty &&
            bestResult.length >= 8 && // 최소 8글자
            totalWaitTime >= 6000) {
          // 최소 6초
          print('✅ 조건 만족 - 조기 종료');
          break;
        }
      }

      // 강제 종료 및 마지막 체크
      if (_isListening) {
        await _speech.stop();
        _isListening = false;

        // 종료 후 추가 대기
        await Future.delayed(const Duration(milliseconds: 1000));

        if (_lastWords.length > bestResult.length) {
          bestResult = _lastWords;
          print('🔄 종료 후 업데이트: "$bestResult"');
        }
      }

      // 🔧 최종 결과 처리
      final finalResult = bestResult.trim();

      if (finalResult.isNotEmpty) {
        final wordCount = finalResult.split(' ').length;
        print(
          '🎯 최종결과: "$finalResult" (${finalResult.length}자, ${wordCount}단어)',
        );

        if (wordCount >= 3) {
          print('✅ 음성인식 성공');
        } else {
          print('⚠️ 짧은 결과 - 재시도 권장');
        }

        return finalResult;
      } else {
        print('❌ 인식 실패');
        return null;
      }
    } catch (e) {
      print('🚨 음성인식 에러: $e');
      _isListening = false;
      return null;
    }
  }

  Future<void> stopListening() async {
    try {
      if (_isListening) {
        await _speech.stop();
        _isListening = false;
        print('⏹️ 음성인식 중지');
      }
    } catch (e) {
      print('🚨 음성인식 중지 에러: $e');
      _isListening = false;
    }
  }

  Future<void> cancel() async {
    try {
      await _speech.cancel();
      _isListening = false;
      _lastWords = '';
      print('❌ 음성인식 취소');
    } catch (e) {
      print('🚨 음성인식 취소 에러: $e');
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
      print('🗑️ 음성인식 서비스 해제');
    } catch (e) {
      print('🚨 서비스 해제 에러: $e');
    }
  }
}
