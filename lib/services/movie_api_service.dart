import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie_result.dart';
import '../utils/constants.dart';

class MovieApiService {
  static final MovieApiService _instance = MovieApiService._internal();
  factory MovieApiService() => _instance;
  MovieApiService._internal();

  // 캐시를 위한 Map
  final Map<String, List<MovieResult>> _cache = {};
  final List<String> _searchHistory = [];

  /// Django API를 통한 영화 검색
  /// GET /api/search/?q=검색어&limit=5
  Future<List<MovieResult>> searchMovies(String query) async {
    if (query.isEmpty) return [];

    // 캐시 확인
    if (_cache.containsKey(query)) {
      print('📋 캐시에서 반환: $query');
      return _cache[query]!;
    }

    try {
      // Django API 엔드포인트 호출
      final uri = Uri.parse('${AppConstants.baseUrl}/api/search/').replace(
        queryParameters: {
          'q': query,
          'limit': '5',
        },
      );

      print('🌐 API 호출: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'MoviePhraseSearch/1.0',
        },
      ).timeout(AppConstants.apiTimeout);

      print('📡 API 응답 상태: ${response.statusCode}');
      print('📄 API 응답 내용: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Django API 응답 구조에 맞춰 파싱
        if (data is Map<String, dynamic>) {
          final List<dynamic> results = data['results'] ?? [];
          final int count = data['count'] ?? 0;
          final String originalQuery = data['query'] ?? query;
          final String? translatedQuery = data['translated_query'];

          print('🔍 검색어: $originalQuery');
          if (translatedQuery != null) {
            print('🔄 번역됨: $originalQuery → $translatedQuery');
          }
          print('📊 결과 개수: $count개');

          if (results.isNotEmpty) {
            List<MovieResult> movies = results
                .map((movie) {
                  if (movie is Map<String, dynamic>) {
                    return MovieResult.fromJson(movie);
                  } else {
                    print('❌ 잘못된 영화 데이터 형식: $movie');
                    return null;
                  }
                })
                .where((movie) => movie != null)
                .cast<MovieResult>()
                .toList();

            print('✅ 성공적으로 파싱된 영화: ${movies.length}개');

            // 캐시에 저장
            _cache[query] = movies;

            // 검색 기록에 추가
            if (!_searchHistory.contains(query)) {
              _searchHistory.insert(0, query);
              if (_searchHistory.length > AppConstants.maxSearchHistory) {
                _searchHistory.removeLast();
              }
            }

            return movies;
          } else {
            print('📭 검색 결과 없음');
            final String? message = data['message'];
            if (message != null) {
              print('💬 서버 메시지: $message');
            }
          }
        }
      } else {
        print('❌ API 에러: 상태 ${response.statusCode}, 내용: ${response.body}');
      }
    } catch (e) {
      print('🚨 네트워크/파싱 에러: $e');
    }

    // API 실패시 빈 리스트 반환
    return [];
  }

  /// 인기 검색어 가져오기
  /// GET /api/search-history/?type=popular&limit=8
  Future<List<String>> getPopularSearches() async {
    try {
      final uri =
          Uri.parse('${AppConstants.baseUrl}/api/search-history/').replace(
        queryParameters: {
          'type': 'popular',
          'limit': AppConstants.maxPopularSearches.toString(),
        },
      );

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> searches = data['searches'] ?? [];

        return searches
            .map((search) {
              if (search is Map<String, dynamic>) {
                return search['original_query']?.toString() ?? '';
              }
              return search.toString();
            })
            .where((query) => query.isNotEmpty)
            .toList();
      }
    } catch (e) {
      print('📊 통계 API 에러: $e');
    }

    // 더미 인기 검색어 반환
    return [
      'Hello',
      'Love',
      'Good morning',
      'Thank you',
      'Goodbye',
      'How are you',
      'Nice to meet you',
      'See you later'
    ];
  }

  /// 최근 검색어 가져오기
  /// GET /api/search-history/?type=recent&limit=10
  Future<List<String>> getSearchHistory() async {
    try {
      final uri =
          Uri.parse('${AppConstants.baseUrl}/api/search-history/').replace(
        queryParameters: {
          'type': 'recent',
          'limit': AppConstants.maxSearchHistory.toString(),
        },
      );

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> searches = data['searches'] ?? [];

        return searches
            .map((search) {
              if (search is Map<String, dynamic>) {
                return search['original_query']?.toString() ?? '';
              }
              return search.toString();
            })
            .where((query) => query.isNotEmpty)
            .toList();
      }
    } catch (e) {
      print('📜 검색기록 API 에러: $e');
    }

    // 로컬 검색 기록 반환
    return List.from(_searchHistory);
  }

  /// API 상태 확인
  /// GET /api/health/
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/health/'),
        headers: {'Accept': 'application/json'},
      ).timeout(AppConstants.healthCheckTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'healthy';
      }
    } catch (e) {
      print('🏥 헬스체크 에러: $e');
    }
    return false;
  }

  /// 검색 통계 가져오기
  /// GET /api/statistics/
  Future<Map<String, dynamic>?> getStatistics() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/statistics/'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print('📈 통계 API 에러: $e');
    }
    return null;
  }

  /// 특정 영화의 구문들 가져오기
  /// GET /api/movies/{movieId}/quotes/
  Future<List<MovieResult>> getMovieQuotes(int movieId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/movies/$movieId/quotes/'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> quotes = data['quotes'] ?? [];

        return quotes
            .map((quote) {
              if (quote is Map<String, dynamic>) {
                return MovieResult.fromJson(quote);
              }
              return null;
            })
            .where((movie) => movie != null)
            .cast<MovieResult>()
            .toList();
      }
    } catch (e) {
      print('🎬 영화 구문 API 에러: $e');
    }
    return [];
  }

  /// 캐시 관리
  void clearCache() {
    _cache.clear();
    print('🗑️ 캐시가 삭제되었습니다');
  }

  void clearSearchHistory() {
    _searchHistory.clear();
    print('🗑️ 검색 기록이 삭제되었습니다');
  }

  /// 캐시 크기 확인
  int get cacheSize => _cache.length;

  /// 검색 기록 크기 확인
  int get searchHistorySize => _searchHistory.length;

  /// 캐시된 검색어 목록
  List<String> get cachedQueries => _cache.keys.toList();

  /// 서비스 정리
  void dispose() {
    clearCache();
    clearSearchHistory();
    print('🔄 MovieApiService 정리 완료');
  }
}
