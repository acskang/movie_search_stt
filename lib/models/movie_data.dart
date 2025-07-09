class MovieData {
  final String title;
  final String phrase;
  final String? character;
  final String? year;
  final String? genre;
  final String? director;
  final String? videoUrl;
  final String? posterUrl;
  final double? rating;

  MovieData({
    required this.title,
    required this.phrase,
    this.character,
    this.year,
    this.genre,
    this.director,
    this.videoUrl,
    this.posterUrl,
    this.rating,
  });

  /// movie.thesysm.com API 응답에서 생성
  factory MovieData.fromApiResponse(Map<String, dynamic> json) {
    return MovieData(
      title: json['title']?.toString() ?? 'Unknown Title',
      phrase:
          json['quote']?.toString() ??
          json['phrase']?.toString() ??
          'No quote available',
      character: json['character']?.toString(),
      year: json['year']?.toString(),
      genre: json['genre']?.toString(),
      director: json['director']?.toString(),
      videoUrl: json['video_url']?.toString() ?? json['videoUrl']?.toString(),
      posterUrl:
          json['poster_url']?.toString() ?? json['posterUrl']?.toString(),
      rating: _parseRating(json['rating']),
    );
  }

  /// 일반 JSON에서 생성 (호환성)
  factory MovieData.fromJson(Map<String, dynamic> json) {
    return MovieData.fromApiResponse(json);
  }

  /// 평점 파싱 헬퍼
  static double? _parseRating(dynamic rating) {
    if (rating == null) return null;
    if (rating is double) return rating;
    if (rating is int) return rating.toDouble();
    if (rating is String) {
      return double.tryParse(rating);
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'quote': phrase,
      'character': character,
      'year': year,
      'genre': genre,
      'director': director,
      'video_url': videoUrl,
      'poster_url': posterUrl,
      'rating': rating,
    };
  }

  @override
  String toString() {
    return 'MovieData(title: $title, phrase: $phrase, character: $character)';
  }
}
