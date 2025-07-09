// lib/models/search_statistics.dart
class SearchStatistics {
  final int totalSearches;
  final int totalMovies;
  final int totalQuotes;
  final int koreanSearches;
  final double koreanPercentage;

  SearchStatistics({
    required this.totalSearches,
    required this.totalMovies,
    required this.totalQuotes,
    required this.koreanSearches,
    required this.koreanPercentage,
  });

  factory SearchStatistics.fromJson(Map<String, dynamic> json) {
    return SearchStatistics(
      totalSearches: json['total_searches'] ?? 0,
      totalMovies: json['total_movies'] ?? 0,
      totalQuotes: json['total_quotes'] ?? 0,
      koreanSearches: json['korean_searches'] ?? 0,
      koreanPercentage: (json['korean_percentage'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_searches': totalSearches,
      'total_movies': totalMovies,
      'total_quotes': totalQuotes,
      'korean_searches': koreanSearches,
      'korean_percentage': koreanPercentage,
    };
  }

  @override
  String toString() {
    return 'SearchStatistics(totalSearches: $totalSearches, totalMovies: $totalMovies, totalQuotes: $totalQuotes, koreanPercentage: $koreanPercentage%)';
  }
}
