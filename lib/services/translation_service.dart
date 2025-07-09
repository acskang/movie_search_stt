import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  static const String _baseUrl = 'https://api.mymemory.translated.net';

  // 캐시를 위한 Map
  final Map<String, String> _cache = {};

  /// 한국어를 영어로 번역
  Future<String?> translateToEnglish(String text) async {
    if (text.isEmpty) return null;

    // 캐시 확인
    if (_cache.containsKey(text)) {
      return _cache[text];
    }

    // 이미 영어인 경우 그대로 반환
    if (isEnglish(text)) {
      _cache[text] = text;
      return text;
    }

    try {
      final response = await http
          .get(
            Uri.parse(
              '$_baseUrl/get?q=${Uri.encodeComponent(text)}&langpair=ko|en',
            ),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final translatedText =
            data['responseData']['translatedText'] as String?;

        if (translatedText != null && translatedText.isNotEmpty) {
          _cache[text] = translatedText;
          return translatedText;
        }
      }
    } catch (e) {
      print('Translation error: $e');
    }

    // 번역 실패시 원본 반환
    return text;
  }

  /// 영어를 한국어로 번역
  Future<String?> translateToKorean(String text) async {
    if (text.isEmpty) return null;

    // 캐시 확인
    if (_cache.containsKey(text)) {
      return _cache[text];
    }

    // 이미 한국어인 경우 그대로 반환
    if (isKorean(text)) {
      _cache[text] = text;
      return text;
    }

    try {
      final response = await http
          .get(
            Uri.parse(
              '$_baseUrl/get?q=${Uri.encodeComponent(text)}&langpair=en|ko',
            ),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final translatedText =
            data['responseData']['translatedText'] as String?;

        if (translatedText != null && translatedText.isNotEmpty) {
          _cache[text] = translatedText;
          return translatedText;
        }
      }
    } catch (e) {
      print('Translation error: $e');
    }

    // 번역 실패시 원본 반환
    return text;
  }

  /// 한국어 감지
  bool isKorean(String text) {
    return RegExp(r'[ㄱ-ㅎ|ㅏ-ㅣ|가-힣]').hasMatch(text);
  }

  /// 영어 감지 (수정된 부분)
  bool isEnglish(String text) {
    return RegExp(r'^[a-zA-Z\s\W]+$').hasMatch(text) && !isKorean(text);
  }

  /// 캐시 클리어
  void clearCache() {
    _cache.clear();
  }
}
