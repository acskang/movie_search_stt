class SearchHistory {
  final String originalQuery;
  final String translatedQuery;
  final DateTime timestamp;
  final bool wasTranslated;
  final int searchCount;

  SearchHistory({
    required this.originalQuery,
    required this.translatedQuery,
    required this.timestamp,
    required this.wasTranslated,
    this.searchCount = 1,
  });

  // JSON 변환을 위한 메서드들
  Map<String, dynamic> toJson() {
    return {
      'originalQuery': originalQuery,
      'translatedQuery': translatedQuery,
      'timestamp': timestamp.toIso8601String(),
      'wasTranslated': wasTranslated,
      'searchCount': searchCount,
    };
  }

  factory SearchHistory.fromJson(Map<String, dynamic> json) {
    return SearchHistory(
      originalQuery: json['originalQuery'] ?? '',
      translatedQuery: json['translatedQuery'] ?? '',
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      wasTranslated: json['wasTranslated'] ?? false,
      searchCount: json['searchCount'] ?? 1,
    );
  }

  // 검색 횟수 증가를 위한 copyWith 메서드
  SearchHistory copyWith({
    String? originalQuery,
    String? translatedQuery,
    DateTime? timestamp,
    bool? wasTranslated,
    int? searchCount,
  }) {
    return SearchHistory(
      originalQuery: originalQuery ?? this.originalQuery,
      translatedQuery: translatedQuery ?? this.translatedQuery,
      timestamp: timestamp ?? this.timestamp,
      wasTranslated: wasTranslated ?? this.wasTranslated,
      searchCount: searchCount ?? this.searchCount,
    );
  }

  @override
  String toString() {
    return 'SearchHistory(original: $originalQuery, translated: $translatedQuery, wasTranslated: $wasTranslated, count: $searchCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchHistory &&
        other.originalQuery == originalQuery &&
        other.translatedQuery == translatedQuery;
  }

  @override
  int get hashCode {
    return originalQuery.hashCode ^ translatedQuery.hashCode;
  }
}
