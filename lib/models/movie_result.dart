class MovieResult {
  final String name; // movie.name
  final String startTime; // start_time
  final String text; // text (영어 구문)
  final String posterUrl; // posterUrl (포스터 이미지)
  final String videoUrl; // videoUrl (비디오 파일)

  MovieResult({
    required this.name,
    required this.startTime,
    required this.text,
    required this.posterUrl,
    required this.videoUrl,
  });

  // Django API 응답에서 MovieResult 객체 생성
  factory MovieResult.fromJson(Map<String, dynamic> json) {
    return MovieResult(
      name: json['name'] ?? 'Unknown Movie',
      startTime: json['startTime'] ?? '00:00:00',
      text: json['text'] ?? '',
      posterUrl: json['posterUrl'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
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
    };
  }

  // 복사본 생성 (필요시 일부 필드 변경)
  MovieResult copyWith({
    String? name,
    String? startTime,
    String? text,
    String? posterUrl,
    String? videoUrl,
  }) {
    return MovieResult(
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      text: text ?? this.text,
      posterUrl: posterUrl ?? this.posterUrl,
      videoUrl: videoUrl ?? this.videoUrl,
    );
  }

  @override
  String toString() {
    return 'MovieResult(name: $name, startTime: $startTime, text: $text)';
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
}
