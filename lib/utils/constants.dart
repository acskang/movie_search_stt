import 'package:flutter/material.dart';

class AppConstants {
  // 앱 정보
  static const String appTitle = 'Movie Phrase Search';
  static const String appVersion = '1.0.0';

  // Django API 관련 상수 (실제 백엔드 URL)
  // static const String baseUrl = 'https://movie.thesysm.com';
  static const String baseUrl = 'http://127.0.0.1:8000'; // 로컬 개발용

  // Django API 엔드포인트들 (새로운 API 구조에 맞춤)
  static const String searchEndpoint =
      '/api/search/'; // GET /api/search/?q=검색어&limit=20
  static const String statisticsEndpoint =
      '/api/statistics/'; // GET /api/statistics/
  static const String searchAnalyticsEndpoint =
      '/api/search/analytics/'; // GET /api/search/analytics/?days=7
  static const String healthEndpoint = '/api/health/'; // GET /api/health/
  static const String requestsEndpoint = '/api/requests/'; // GET /api/requests/
  static const String moviesEndpoint =
      '/api/movies-table/'; // GET /api/movies-table/
  static const String dialoguesEndpoint =
      '/api/dialogues/'; // GET /api/dialogues/
  static const String apiInfoEndpoint = '/api/info/'; // GET /api/info/

  // 색상 관련 상수
  static const int primaryColorValue = 0xFF6366f1; // 인디고 블루
  static const int secondaryColorValue = 0xFF8b5cf6; // 퍼플
  static const int accentColorValue = 0xFF06b6d4; // 시안
  static const int backgroundColorValue = 0xFF1e293b; // 다크 배경
  static const int cardColorValue = 0xFF334155; // 카드 배경

  static const Color primaryColor = Color(primaryColorValue);
  static const Color secondaryColor = Color(secondaryColorValue);
  static const Color accentColor = Color(accentColorValue);
  static const Color backgroundColor = Color(backgroundColorValue);
  static const Color cardColor = Color(cardColorValue);

  // 그라데이션 색상 (Django 웹사이트와 유사한 색상)
  static const List<Color> backgroundGradient = [
    Color(0xFF0f172a), // dark - Django 웹사이트 색상
    Color(0xFF1e293b), // 다크 슬레이트
    Color(0xFF334155), // 슬레이트
  ];

  // 텍스트 스타일
  static const TextStyle headerTextStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle subHeaderTextStyle = TextStyle(
    fontSize: 16,
    color: Colors.white70,
  );

  // 애니메이션 지속 시간
  static const Duration shortAnimationDuration = Duration(milliseconds: 300);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 600);
  static const Duration longAnimationDuration = Duration(milliseconds: 1000);

  // 기본 패딩 및 마진
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // 카드 스타일
  static const double cardElevation = 8.0;
  static const double cardBorderRadius = 16.0;

  // 외부 링크 (Django 웹사이트와 동일)
  static const String playPhraseUrl = 'https://www.playphrase.me';
  static const String imdbUrl = 'https://www.imdb.com';
  static const String githubUrl =
      'https://github.com/username/movie-phrase-search';
  static const String manualUrl =
      'https://ahading.tistory.com/155'; // Django 웹사이트의 매뉴얼 링크

  // 음성 인식 관련 설정
  static const List<String> supportedLanguages = ['ko-KR', 'en-US'];
  static const String defaultLanguage = 'ko-KR';

  // API 타임아웃 설정
  static const Duration apiTimeout = Duration(seconds: 15);
  static const Duration healthCheckTimeout = Duration(seconds: 5);

  // 검색 관련 설정
  static const int maxSearchResults = 5; // Django API의 기본 limit
  static const int maxSearchHistory = 10; // 최대 검색 기록 수
  static const int maxPopularSearches = 8; // 최대 인기 검색어 수

  // 캐시 설정
  static const Duration cacheExpiration = Duration(hours: 1);
  static const int maxCacheSize = 100;

  // UI 메시지
  static const String searchPlaceholder = '영화 대사를 검색하세요... (음성 또는 텍스트)';
  static const String voiceSearchHint = '🎤 마이크 버튼을 눌러 음성으로 검색하세요';
  static const String noResultsMessage = '검색 결과가 없습니다. 다른 키워드를 시도해보세요.';
  static const String networkErrorMessage = '네트워크 연결을 확인해주세요.';
  static const String serverErrorMessage = '서버에 문제가 있습니다. 잠시 후 다시 시도해주세요.';

  // 검색 팁 메시지
  static const List<String> searchTips = [
    '영어 단어: "Hello", "Love", "Good morning"',
    '한국어 단어: "안녕하세요", "사랑해", "좋은 아침"',
    '음성 인식으로도 검색할 수 있습니다',
    '짧은 구문이 더 정확한 결과를 제공합니다',
  ];

  // 개발자 정보
  static const String developerName = 'Ahading';
  static const String appDescription = 'Django 백엔드와 연동된 영화 대사 검색 앱';
}
