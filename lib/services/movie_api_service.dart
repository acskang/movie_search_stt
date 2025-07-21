import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie_result.dart';
import '../models/search_history.dart';
import '../utils/constants.dart';

class MovieApiService {
  static final MovieApiService _instance = MovieApiService._internal();
  factory MovieApiService() => _instance;
  MovieApiService._internal();

  // 캐시를 위한 Map
  final Map<String, List<MovieResult>> _cache = {};
  final List<String> _searchHistory = [];

  /// Django API를 통한 영화 검색 - 디버깅 강화 버전
  Future<List<MovieResult>> searchMovies(String query) async {
    if (query.isEmpty) return [];

    // 캐시 확인
    if (_cache.containsKey(query)) {
      print('📋 캐시에서 반환: $query');
      return _cache[query]!;
    }

    try {
      // 다양한 방법으로 API 호출 시도
      List<MovieResult> results = [];

      // 방법 1: queryParameters 사용 (가장 안전)
      try {
        print('🔍 방법 1: queryParameters 사용');
        final uri1 = Uri.parse(
          '${AppConstants.baseUrl}/api/search/',
        ).replace(queryParameters: {'q': query, 'limit': '20'});
        print('🌐 API 호출 (방법 1): $uri1');

        final response1 = await http
            .get(
              uri1,
              headers: {
                'Accept': 'application/json',
                'User-Agent': 'MoviePhraseSearch/1.0',
              },
            )
            .timeout(const Duration(seconds: 15));

        if (response1.statusCode == 200) {
          results = _parseResponse(response1, query);
          if (results.isNotEmpty) {
            print('✅ 방법 1 성공: ${results.length}개 결과');
            return results;
          }
        } else {
          print('❌ 방법 1 실패: ${response1.statusCode}');
          print('❌ 응답: ${response1.body}');
        }
      } catch (e) {
        print('❌ 방법 1 에러: $e');
      }

      // 방법 2: 수동 인코딩
      try {
        print('🔍 방법 2: 수동 인코딩');
        final encodedQuery = Uri.encodeQueryComponent(query);
        final uri2 = Uri.parse(
          '${AppConstants.baseUrl}/api/search/?q=$encodedQuery',
        );
        print('🌐 API 호출 (방법 2): $uri2');

        final response2 = await http
            .get(
              uri2,
              headers: {
                'Accept': 'application/json',
                'User-Agent': 'MoviePhraseSearch/1.0',
              },
            )
            .timeout(const Duration(seconds: 15));

        if (response2.statusCode == 200) {
          results = _parseResponse(response2, query);
          if (results.isNotEmpty) {
            print('✅ 방법 2 성공: ${results.length}개 결과');
            return results;
          }
        } else {
          print('❌ 방법 2 실패: ${response2.statusCode}');
          print('❌ 응답: ${response2.body}');
        }
      } catch (e) {
        print('❌ 방법 2 에러: $e');
      }

      // 방법 3: 레거시 API 사용
      try {
        print('🔍 방법 3: 레거시 API 사용');
        final uri3 = Uri.parse(
          '${AppConstants.baseUrl}/api/legacy/search/',
        ).replace(queryParameters: {'q': query});
        print('🌐 API 호출 (방법 3): $uri3');

        final response3 = await http
            .get(
              uri3,
              headers: {
                'Accept': 'application/json',
                'User-Agent': 'MoviePhraseSearch/1.0',
              },
            )
            .timeout(const Duration(seconds: 15));

        if (response3.statusCode == 200) {
          // 레거시 형식 파싱
          final List<dynamic> legacyData = json.decode(response3.body);
          results = legacyData
              .map((item) {
                if (item is Map<String, dynamic>) {
                  return MovieResult(
                    name: item['name'] ?? 'Unknown Movie',
                    startTime: item['startTime'] ?? '00:00:00',
                    text: item['text'] ?? '',
                    posterUrl: item['posterUrl'] ?? '',
                    videoUrl: item['videoUrl'] ?? '',
                  );
                }
                return null;
              })
              .where((movie) => movie != null)
              .cast<MovieResult>()
              .toList();

          if (results.isNotEmpty) {
            print('✅ 방법 3 (레거시) 성공: ${results.length}개 결과');
            // 캐시에 저장
            _cache[query] = results;
            // 검색 기록에 추가
            _addToSearchHistory(query);
            return results;
          }
        } else {
          print('❌ 방법 3 실패: ${response3.statusCode}');
          print('❌ 응답: ${response3.body}');
        }
      } catch (e) {
        print('❌ 방법 3 에러: $e');
      }

      print('⚠️ 모든 방법 실패 - 빈 결과 반환');
      return [];
    } catch (e, stackTrace) {
      print('🚨 전체 검색 에러: $e');
      print('🚨 스택 추적: $stackTrace');
      return [];
    }
  }

  /// 응답 파싱 헬퍼 메서드
  List<MovieResult> _parseResponse(http.Response response, String query) {
    try {
      // UTF-8로 디코딩 명시
      final responseBody = utf8.decode(response.bodyBytes);
      print('📡 API 응답 상태: ${response.statusCode}');

      final data = json.decode(responseBody);

      // 새로운 응답 구조 파싱
      if (data is Map<String, dynamic>) {
        // results 정보
        final resultsInfo = data['results'] as Map<String, dynamic>?;
        final List<dynamic> resultsData = resultsInfo?['data'] ?? [];
        final int count = resultsInfo?['count'] ?? 0;

        print('📊 결과: ${count}개 찾음');

        if (resultsData.isNotEmpty) {
          List<MovieResult> movies = resultsData
              .map((movie) {
                if (movie is Map<String, dynamic>) {
                  return MovieResult(
                    name:
                        movie['name'] ??
                        movie['fullMovieTitle'] ??
                        'Unknown Movie',
                    startTime: movie['startTime'] ?? '00:00:00',
                    text: movie['text'] ?? '',
                    posterUrl: movie['posterUrl'] ?? '',
                    videoUrl: movie['videoUrl'] ?? '',
                  );
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
          _addToSearchHistory(query);

          return movies;
        }
      }
    } catch (e) {
      print('❌ 응답 파싱 에러: $e');
    }

    return [];
  }

  void _addToSearchHistory(String query) {
    if (!_searchHistory.contains(query)) {
      _searchHistory.insert(0, query);
      if (_searchHistory.length > AppConstants.maxSearchHistory) {
        _searchHistory.removeLast();
      }
    }
  }

  /// 인기 검색어 가져오기 - 새로운 통계 API 활용
  Future<List<String>> getPopularSearches() async {
    try {
      // 새로운 검색 분석 API 사용
      final uri = Uri.parse('${AppConstants.baseUrl}/api/search/analytics/')
          .replace(
            queryParameters: {
              'days': '7', // 최근 7일
            },
          );

      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final popularQueries = data['popular_queries'] as List<dynamic>?;

        if (popularQueries != null) {
          return popularQueries
              .map((query) => query['phrase']?.toString() ?? '')
              .where((phrase) => phrase.isNotEmpty)
              .take(AppConstants.maxPopularSearches)
              .toList();
        }
      }
    } catch (e) {
      print('📊 통계 API 에러: $e');
    }

    // 통계 API로 대체 시도
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/api/statistics/');
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final popularSearches =
            data['cross_statistics']?['popular_searches'] as List<dynamic>?;

        if (popularSearches != null) {
          return popularSearches
              .map((search) => search['phrase']?.toString() ?? '')
              .where((phrase) => phrase.isNotEmpty)
              .take(AppConstants.maxPopularSearches)
              .toList();
        }
      }
    } catch (e) {
      print('📈 대체 통계 API 에러: $e');
    }

    // 더미 데이터 반환
    return [
      'Hello',
      'Love',
      'Good morning',
      'Thank you',
      'Goodbye',
      'How are you',
      'Nice to meet you',
      'See you later',
    ];
  }

  /// 최근 검색어 가져오기 - 새로운 RequestTable 활용
  Future<List<String>> getSearchHistory() async {
    try {
      // RequestTable 조회 API 사용
      final uri = Uri.parse('${AppConstants.baseUrl}/api/requests/').replace(
        queryParameters: {
          'limit': AppConstants.maxSearchHistory.toString(),
          'ordering': '-last_searched_at', // 최근 검색 순
        },
      );

      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // 페이지네이션 응답 구조 처리
        final results = data['results'] as List<dynamic>?;
        if (results != null) {
          return results
              .map((request) {
                // 전체 구문 사용 (full_request_phrase)
                return request['full_request_phrase']?.toString() ??
                    request['request_phrase']?.toString() ??
                    '';
              })
              .where((query) => query.isNotEmpty)
              .toList();
        }
      }
    } catch (e) {
      print('📜 검색기록 API 에러: $e');
    }

    // 로컬 검색 기록 반환
    return List.from(_searchHistory);
  }

  /// API 상태 확인 - 새로운 health 엔드포인트 활용
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(
            Uri.parse('${AppConstants.baseUrl}/api/health/'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(AppConstants.healthCheckTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final overall = data['overall'] as Map<String, dynamic>?;
        return overall?['status'] == 'healthy';
      }
    } catch (e) {
      print('🏥 헬스체크 에러: $e');
    }
    return false;
  }

  /// 시스템 상태 상세 정보 가져오기
  Future<Map<String, dynamic>?> getSystemHealth() async {
    try {
      final response = await http
          .get(
            Uri.parse('${AppConstants.baseUrl}/api/health/'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print('🏥 시스템 상태 API 에러: $e');
    }
    return null;
  }

  /// 통계 가져오기 - 새로운 통계 API 활용
  Future<Map<String, dynamic>?> getStatistics() async {
    try {
      final response = await http
          .get(
            Uri.parse('${AppConstants.baseUrl}/api/statistics/'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print('📈 통계 API 에러: $e');
    }
    return null;
  }

  /// 검색 분석 데이터 가져오기
  Future<Map<String, dynamic>?> getSearchAnalytics({int days = 7}) async {
    try {
      final uri = Uri.parse(
        '${AppConstants.baseUrl}/api/search/analytics/',
      ).replace(queryParameters: {'days': days.toString()});

      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print('📊 검색 분석 API 에러: $e');
    }
    return null;
  }

  /// 특정 영화의 구문들 가져오기 - 새로운 dialogues 엔드포인트 활용
  Future<List<MovieResult>> getMovieQuotes(int movieId) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/api/dialogues/').replace(
        queryParameters: {
          'movie_id': movieId.toString(),
          'translation_quality': 'excellent,good', // 우수/양호 품질만
          'has_korean': 'true', // 한글 번역 있는 것만
          'ordering': 'dialogue_start_time', // 시간순 정렬
        },
      );

      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List<dynamic>?;

        if (results != null) {
          return results
              .map((dialogue) {
                if (dialogue is Map<String, dynamic>) {
                  return MovieResult(
                    name:
                        dialogue['movie_title'] ??
                        dialogue['full_movie_title'] ??
                        '',
                    startTime: dialogue['dialogue_start_time'] ?? '',
                    text: dialogue['dialogue_phrase'] ?? '',
                    posterUrl: dialogue['movie_poster_url'] ?? '',
                    videoUrl:
                        dialogue['video_file_url'] ??
                        dialogue['video_url'] ??
                        '',
                  );
                }
                return null;
              })
              .where((movie) => movie != null)
              .cast<MovieResult>()
              .toList();
        }
      }
    } catch (e) {
      print('🎬 영화 구문 API 에러: $e');
    }
    return [];
  }

  /// API 정보 가져오기
  Future<Map<String, dynamic>?> getApiInfo() async {
    try {
      final response = await http
          .get(
            Uri.parse('${AppConstants.baseUrl}/api/info/'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print('ℹ️ API 정보 에러: $e');
    }
    return null;
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
