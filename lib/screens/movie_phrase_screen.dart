import 'package:flutter/material.dart';
import '../services/movie_api_service.dart';
import '../services/translation_service.dart';
import '../models/movie_result.dart';
import '../models/search_history.dart';
import '../widgets/header_section.dart';
import '../widgets/search_section.dart';
import '../widgets/movie_results_section.dart';
import '../widgets/recent_searches_section.dart';
import '../widgets/statistics_section.dart';
import '../widgets/loading_indicator.dart';
import '../utils/constants.dart';

class MoviePhraseScreen extends StatefulWidget {
  const MoviePhraseScreen({super.key});

  @override
  State<MoviePhraseScreen> createState() => _MoviePhraseScreenState();
}

class _MoviePhraseScreenState extends State<MoviePhraseScreen> {
  final MovieApiService _apiService = MovieApiService();
  final TranslationService _translationService = TranslationService();
  final PageController _pageController = PageController();

  List<MovieResult> _movies = [];
  List<SearchHistory> _searchHistory = [];
  List<String> _statistics = [];

  bool _isLoading = false;
  bool _isTranslating = false;
  String _loadingMessage = '';
  String _currentQuery = '';
  String _originalQuery = '';
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = '초기 데이터 로딩 중...';
    });

    try {
      // 병렬로 데이터 로드
      await Future.wait([_loadSearchHistory(), _loadStatistics()]);
    } catch (e) {
      print('🚨 초기 데이터 로딩 에러: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSearchHistory() async {
    try {
      final history = await _apiService.getSearchHistory();
      setState(() {
        // List<String>을 List<SearchHistory>로 변환
        _searchHistory = history
            .map(
              (item) => SearchHistory(
                originalQuery: item,
                translatedQuery: item, // 기존 데이터는 번역되지 않은 것으로 처리
                timestamp: DateTime.now(),
                wasTranslated: false,
                searchCount: 1,
              ),
            )
            .toList();
      });
    } catch (e) {
      print('🚨 검색 기록 로딩 에러: $e');
    }
  }

  Future<void> _loadStatistics() async {
    try {
      final stats = await _apiService.getPopularSearches();
      setState(() {
        _statistics = stats;
      });
    } catch (e) {
      print('🚨 통계 로딩 에러: $e');
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    final originalQuery = query.trim();

    setState(() {
      _isLoading = true;
      _isTranslating = false;
      _loadingMessage = '검색어 처리 중...';
      _originalQuery = originalQuery;
      _movies.clear();
    });

    try {
      String searchQuery = originalQuery;
      bool wasTranslated = false;

      // 한국어 감지 및 번역
      if (_translationService.isKorean(originalQuery)) {
        setState(() {
          _isTranslating = true;
          _loadingMessage = '한국어를 영어로 번역 중...';
        });

        print('🌏 한국어 감지: $originalQuery');
        final translatedQuery = await _translationService.translateToEnglish(
          originalQuery,
        );

        if (translatedQuery != null && translatedQuery != originalQuery) {
          searchQuery = translatedQuery;
          wasTranslated = true;
          print('🌏 번역 완료: $originalQuery → $searchQuery');
        } else {
          print('🚨 번역 실패 또는 동일한 결과');
        }
      }

      setState(() {
        _isTranslating = false;
        _loadingMessage = '영화 검색 중...';
        _currentQuery = searchQuery;
      });

      print('🔍 Django API 검색 시작: $searchQuery');
      print('📤 Django로 전송할 검색어: "$searchQuery"');
      print('🌐 백엔드 URL: ${AppConstants.baseUrl}/api/search/?q=$searchQuery');

      // Django API 검색 수행
      final results = await _apiService.searchMovies(searchQuery);

      print('📥 Django 응답 결과: ${results.length}개');
      if (results.isNotEmpty) {
        print('🎬 첫 번째 영화: ${results.first.name}');
        print('⏰ 시작 시간: ${results.first.startTime}');
        print('💬 대사: ${results.first.text}');
        print('🖼️ 포스터 URL: ${results.first.posterUrl}');
        print('🎥 비디오 URL: ${results.first.videoUrl}');
        print('✅ 포스터 유효: ${results.first.hasValidPoster}');
        print('✅ 비디오 유효: ${results.first.hasValidVideo}');
      } else {
        print('⚠️ Django에서 빈 결과 반환됨');
      }

      setState(() {
        _movies = results;
        _currentPage = results.isNotEmpty ? 1 : 0;
      });

      // 검색 기록에 추가 (번역 정보 포함)
      _addToSearchHistoryLocal(
        originalQuery,
        wasTranslated ? searchQuery : null,
        wasTranslated,
        results.length,
      );

      // 검색 완료 후 결과 페이지로 이동
      if (results.isNotEmpty && _pageController.hasClients) {
        _pageController.animateToPage(
          1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }

      // 결과 메시지 표시
      if (wasTranslated) {
        _showTranslationSnackBar(originalQuery, searchQuery, results.length);
      }

      print('✅ 검색 완료: ${results.length}개 결과');
    } catch (e) {
      print('🚨 검색 에러: $e');
      _showErrorSnackBar('검색 중 오류가 발생했습니다: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
        _isTranslating = false;
      });
    }
  }

  void _addToSearchHistoryLocal(
    String originalQuery,
    String? translatedQuery,
    bool wasTranslated,
    int resultCount,
  ) {
    try {
      // SearchHistory 모델 구조에 맞게 생성
      final searchItem = SearchHistory(
        originalQuery: originalQuery,
        translatedQuery: translatedQuery ?? originalQuery,
        timestamp: DateTime.now(),
        wasTranslated: wasTranslated,
        searchCount: 1,
      );

      // 중복 제거 후 추가
      _searchHistory.removeWhere(
        (item) =>
            item.originalQuery.toLowerCase() == originalQuery.toLowerCase(),
      );
      _searchHistory.insert(0, searchItem);

      // 최대 20개까지만 유지
      if (_searchHistory.length > AppConstants.maxSearchHistory) {
        _searchHistory = _searchHistory
            .take(AppConstants.maxSearchHistory)
            .toList();
      }

      setState(() {});

      print(
        '✅ 검색 기록 로컬 저장 완료: $originalQuery ${wasTranslated ? "(번역됨: $translatedQuery)" : ""}',
      );
    } catch (e) {
      print('🚨 검색 기록 로컬 저장 에러: $e');
    }
  }

  void _showTranslationSnackBar(
    String original,
    String translated,
    int resultCount,
  ) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🌏 번역하여 검색했습니다',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('원문: "$original"'),
              Text('번역: "$translated"'),
              Text('결과: ${resultCount}개'),
            ],
          ),
          backgroundColor: Colors.green[700],
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: '확인',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red[700],
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: '확인',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  void _navigateToPage(int page) {
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 헤더 섹션
            const HeaderSection(),

            // 페이지 뷰
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  // 홈 페이지 (검색 + 기록 + 통계)
                  _buildHomePage(),

                  // 검색 결과 페이지
                  _buildResultsPage(),
                ],
              ),
            ),

            // 하단 네비게이션
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildHomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 검색 섹션
          SearchSection(
            onSearch: _performSearch,
            isLoading: _isLoading,
            translationService: _translationService,
          ),

          const SizedBox(height: 24),

          // 로딩 인디케이터
          if (_isLoading)
            LoadingIndicator(
              message: _loadingMessage,
              isTranslating: _isTranslating,
            ),

          // 최근 검색어 섹션 (클릭 기능 없음)
          if (!_isLoading && _searchHistory.isNotEmpty) ...[
            RecentSearchesSection(
              searchHistory: _searchHistory,
              onSearchTap: (query) {
                // 단순히 검색 필드에 입력만 하고 실행하지 않음
                print('📝 최근 검색어 선택: $query');
              },
            ),
            const SizedBox(height: 24),
          ],

          // 인기 검색어 섹션
          if (!_isLoading && _statistics.isNotEmpty)
            StatisticsSection(
              statistics: _statistics,
              onStatisticTap: _performSearch,
            ),
        ],
      ),
    );
  }

  Widget _buildResultsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 검색 결과 헤더
          if (_originalQuery.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConstants.cardColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppConstants.primaryColor.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '검색 결과',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_translationService.isKorean(_originalQuery)) ...[
                    // 번역된 검색어 표시
                    RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 14, color: Colors.grey[300]),
                        children: [
                          const TextSpan(text: '원문: '),
                          TextSpan(
                            text: '"$_originalQuery"',
                            style: TextStyle(
                              color: Colors.orange[300],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 14, color: Colors.grey[300]),
                        children: [
                          const TextSpan(text: '번역: '),
                          TextSpan(
                            text: '"$_currentQuery"',
                            style: TextStyle(
                              color: AppConstants.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(text: ' (${_movies.length}개 결과)'),
                        ],
                      ),
                    ),
                  ] else ...[
                    // 영어 검색어 표시
                    RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 14, color: Colors.grey[300]),
                        children: [
                          const TextSpan(text: '검색어: '),
                          TextSpan(
                            text: '"$_currentQuery"',
                            style: TextStyle(
                              color: AppConstants.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(text: ' (${_movies.length}개 결과)'),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 로딩 중일 때
          if (_isLoading)
            LoadingIndicator(
              message: _loadingMessage,
              isTranslating: _isTranslating,
            )
          else
            // 검색 결과
            MovieResultsSection(movies: _movies),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.cardColor.withValues(alpha: 0.1),
        border: Border(
          top: BorderSide(
            color: AppConstants.primaryColor.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            _buildNavButton(
              icon: Icons.home,
              label: '홈',
              isActive: _currentPage == 0,
              onTap: () => _navigateToPage(0),
            ),
            _buildNavButton(
              icon: Icons.movie,
              label: '검색결과',
              isActive: _currentPage == 1,
              onTap: () => _navigateToPage(1),
              badge: _movies.isNotEmpty ? _movies.length.toString() : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Icon(
                    icon,
                    color: isActive ? AppConstants.primaryColor : Colors.grey,
                    size: 24,
                  ),
                  if (badge != null)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? AppConstants.primaryColor : Colors.grey,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
