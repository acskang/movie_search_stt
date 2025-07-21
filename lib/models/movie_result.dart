class MovieResult {
  final String name; // movie.name 또는 fullMovieTitle
  final String startTime; // start_time 또는 startTime
  final String text; // text (영어 구문)
  final String posterUrl; // posterUrl (포스터 이미지)
  final String videoUrl; // videoUrl (비디오 파일)

  // 새로운 필드들 추가
  final String? koreanText; // 한글 번역
  final String? releaseYear; // 개봉연도
  final String? director; // 감독
  final String? fullDirector; // 전체 감독명
  final String? productionCountry; // 제작국가
  final String? imdbUrl; // IMDB URL
  final String? translationQuality; // 번역 품질
  final int? playCount; // 재생 횟수

  MovieResult({
    required this.name,
    required this.startTime,
    required this.text,
    required this.posterUrl,
    required this.videoUrl,
    this.koreanText,
    this.releaseYear,
    this.director,
    this.fullDirector,
    this.productionCountry,
    this.imdbUrl,
    this.translationQuality,
    this.playCount,
  });

  // Django API 응답에서 MovieResult 객체 생성 - 새로운 응답 구조 대응
  factory MovieResult.fromJson(Map<String, dynamic> json) {
    return MovieResult(
      name: json['fullMovieTitle'] ?? json['name'] ?? 'Unknown Movie',
      startTime: json['startTime'] ?? '00:00:00',
      text: json['text'] ?? '',
      posterUrl: json['posterUrl'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      // 새로운 필드들
      koreanText: json['koreanText'],
      releaseYear: json['releaseYear'],
      director: json['director'],
      fullDirector: json['fullDirector'],
      productionCountry: json['productionCountry'],
      imdbUrl: json['imdbUrl'],
      translationQuality: json['translationQuality'],
      playCount: json['playCount'] is int ? json['playCount'] : null,
    );
  }

  // DialogueTable 응답에서 생성 (dialogues 엔드포인트용)
  factory MovieResult.fromDialogueTable(Map<String, dynamic> json) {
    return MovieResult(
      name: json['full_movie_title'] ?? json['movie_title'] ?? 'Unknown Movie',
      startTime: json['dialogue_start_time'] ?? '00:00:00',
      text: json['dialogue_phrase'] ?? '',
      posterUrl: json['movie_poster_url'] ?? '',
      videoUrl: json['video_file_url'] ?? json['video_url'] ?? '',
      // 추가 필드들
      koreanText: json['dialogue_phrase_ko'],
      releaseYear: json['movie_release_year'],
      director: json['movie_director'],
      fullDirector: json['full_director'],
      translationQuality: json['translation_quality'],
      playCount: json['play_count'] is int ? json['play_count'] : null,
    );
  }

  // MovieResult를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'startTime': startTime,
      'text': text,
      'posterUrl': posterUrl,
      'videoUrl': videoUrl,
      'koreanText': koreanText,
      'releaseYear': releaseYear,
      'director': director,
      'fullDirector': fullDirector,
      'productionCountry': productionCountry,
      'imdbUrl': imdbUrl,
      'translationQuality': translationQuality,
      'playCount': playCount,
    };
  }

  // 복사본 생성 (필요시 일부 필드 변경)
  MovieResult copyWith({
    String? name,
    String? startTime,
    String? text,
    String? posterUrl,
    String? videoUrl,
    String? koreanText,
    String? releaseYear,
    String? director,
    String? fullDirector,
    String? productionCountry,
    String? imdbUrl,
    String? translationQuality,
    int? playCount,
  }) {
    return MovieResult(
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      text: text ?? this.text,
      posterUrl: posterUrl ?? this.posterUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      koreanText: koreanText ?? this.koreanText,
      releaseYear: releaseYear ?? this.releaseYear,
      director: director ?? this.director,
      fullDirector: fullDirector ?? this.fullDirector,
      productionCountry: productionCountry ?? this.productionCountry,
      imdbUrl: imdbUrl ?? this.imdbUrl,
      translationQuality: translationQuality ?? this.translationQuality,
      playCount: playCount ?? this.playCount,
    );
  }

  @override
  String toString() {
    return 'MovieResult(name: $name, startTime: $startTime, text: $text, korean: $koreanText)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MovieResult &&
        other.name == name &&
        other.startTime == startTime &&
        other.text == text;
  }

  @override
  int get hashCode {
    return name.hashCode ^ startTime.hashCode ^ text.hashCode;
  }

  // 포스터 이미지가 유효한지 확인
  bool get hasValidPoster {
    return posterUrl.isNotEmpty &&
        (posterUrl.startsWith('http') || posterUrl.startsWith('https'));
  }

  // 비디오 URL이 유효한지 확인
  bool get hasValidVideo {
    return videoUrl.isNotEmpty &&
        (videoUrl.startsWith('http') || videoUrl.startsWith('https'));
  }

  // 영화 정보가 완전한지 확인
  bool get isComplete {
    return name.isNotEmpty &&
        startTime.isNotEmpty &&
        text.isNotEmpty &&
        hasValidPoster &&
        hasValidVideo;
  }

  // 한글 번역이 있는지 확인
  bool get hasKoreanTranslation {
    return koreanText != null && koreanText!.isNotEmpty;
  }

  // 번역 품질이 양호한지 확인
  bool get hasGoodTranslation {
    return translationQuality == 'excellent' || translationQuality == 'good';
  }

  // 시간 포맷팅 (예: "00:01:23" -> "1분 23초")
  String get formattedTime {
    try {
      final parts = startTime.split(':');
      if (parts.length >= 3) {
        final hours = int.tryParse(parts[0]) ?? 0;
        final minutes = int.tryParse(parts[1]) ?? 0;
        final seconds = int.tryParse(parts[2]) ?? 0;

        if (hours > 0) {
          return '${hours}시간 ${minutes}분 ${seconds}초';
        } else if (minutes > 0) {
          return '${minutes}분 ${seconds}초';
        } else {
          return '${seconds}초';
        }
      }
    } catch (e) {
      // 파싱 실패시 원본 반환
    }
    return startTime;
  }

  // 대사 미리보기 (50자 제한)
  String get textPreview {
    if (text.length <= 50) return text;
    return '${text.substring(0, 50)}...';
  }

  // 한글 대사 미리보기
  String get koreanTextPreview {
    if (koreanText == null || koreanText!.isEmpty) return '';
    if (koreanText!.length <= 50) return koreanText!;
    return '${koreanText!.substring(0, 50)}...';
  }

  // 영화 정보 표시용 문자열
  String get movieInfo {
    List<String> info = [];
    if (releaseYear != null) info.add(releaseYear!);
    if (director != null) info.add('감독: $director');
    if (productionCountry != null) info.add(productionCountry!);
    return info.join(' | ');
  }

  // 번역 품질 표시용 문자열
  String get translationQualityDisplay {
    switch (translationQuality) {
      case 'excellent':
        return '우수';
      case 'good':
        return '양호';
      case 'fair':
        return '보통';
      case 'poor':
        return '미흡';
      default:
        return '미확인';
    }
  }
}
