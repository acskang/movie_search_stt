import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/movie_result.dart';
import '../services/translation_service.dart';
import '../utils/constants.dart';

class VideoModal extends StatefulWidget {
  // 필수 파라미터들
  final MovieResult? movie;
  final TranslationService? translationService;

  // movie_results_section.dart에서 사용하는 파라미터들
  final String? videoUrl;
  final String? title;
  final String? phrase;
  final String? timestamp;

  const VideoModal({
    super.key,
    this.movie,
    this.translationService,
    this.videoUrl,
    this.title,
    this.phrase,
    this.timestamp,
  });

  @override
  State<VideoModal> createState() => _VideoModalState();
}

class _VideoModalState extends State<VideoModal> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showControls = true;
  bool _showVolumeSlider = false; // 볼륨 슬라이더 표시 여부
  double _volume = 1.0; // 현재 볼륨 (0.0 ~ 1.0)
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _startControlsTimer();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    // videoUrl 파라미터 우선, 없으면 movie.videoUrl 사용
    final videoUrl = widget.videoUrl ?? widget.movie?.videoUrl;

    if (videoUrl == null || videoUrl.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = '비디오 URL이 없습니다.';
      });
      return;
    }

    try {
      print('🎥 비디오 초기화 시작: $videoUrl');

      // 이전 성공 방식: 단순한 NetworkUrl 생성 (옵션 없이)
      _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });

        // 자동 재생 및 반복, 초기 볼륨 설정
        await _controller!.play();
        await _controller!.setLooping(true);
        await _controller!.setVolume(_volume);

        print('✅ 비디오 초기화 성공');
        print('📐 AspectRatio: ${_controller!.value.aspectRatio}');
        print('📱 VideoSize: ${_controller!.value.size}');
        print('🔊 초기 볼륨: $_volume');
      }
    } catch (e) {
      print('🚨 비디오 초기화 에러: $e');

      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = '비디오를 로드할 수 없습니다: ${e.toString()}';
        });
      }
    }
  }

  void _startControlsTimer() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _showControls) {
        setState(() {
          _showControls = false;
          _showVolumeSlider = false; // 컨트롤 숨길 때 볼륨 슬라이더도 숨김
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (!_showControls) {
        _showVolumeSlider = false; // 컨트롤 숨길 때 볼륨 슬라이더도 숨김
      }
    });

    if (_showControls) {
      _startControlsTimer();
    }
  }

  Future<void> _togglePlayPause() async {
    print('🎮 재생/일시정지 버튼 클릭됨');

    if (_controller != null && _controller!.value.isInitialized) {
      try {
        if (_controller!.value.isPlaying) {
          await _controller!.pause();
          print('⏸️ 비디오 일시정지 완료');
        } else {
          await _controller!.play();
          print('▶️ 비디오 재생 시작 완료');
        }

        // 상태 변경 후 UI 업데이트
        if (mounted) {
          setState(() {});
        }
      } catch (e) {
        print('🚨 재생/일시정지 에러: $e');
      }
    } else {
      print('🚨 VideoController가 초기화되지 않음');
    }
  }

  Future<void> _seekTo(Duration position) async {
    try {
      await _controller?.seekTo(position);
      print('⏭️ 시간 이동: ${_formatDuration(position)}');
    } catch (e) {
      print('🚨 시간 이동 에러: $e');
    }
  }

  void _skipBackward() {
    print('⏪ 되감기 버튼 클릭됨');
    if (_controller != null && _controller!.value.isInitialized) {
      final current = _controller!.value.position;
      final newPosition = current - const Duration(seconds: 10);
      final targetPosition = newPosition > Duration.zero
          ? newPosition
          : Duration.zero;
      _seekTo(targetPosition);
    }
  }

  void _skipForward() {
    print('⏩ 빨리감기 버튼 클릭됨');
    if (_controller != null && _controller!.value.isInitialized) {
      final current = _controller!.value.position;
      final duration = _controller!.value.duration;
      final newPosition = current + const Duration(seconds: 10);
      final targetPosition = newPosition < duration ? newPosition : duration;
      _seekTo(targetPosition);
    }
  }

  // 🔊 볼륨 조절 기능
  Future<void> _setVolume(double volume) async {
    if (_controller != null && _controller!.value.isInitialized) {
      try {
        await _controller!.setVolume(volume);
        setState(() {
          _volume = volume;
        });
        print('🔊 볼륨 변경: ${(volume * 100).toInt()}%');
      } catch (e) {
        print('🚨 볼륨 설정 에러: $e');
      }
    }
  }

  void _toggleVolumeSlider() {
    print('🔊 볼륨 버튼 클릭됨');

    setState(() {
      _showVolumeSlider = !_showVolumeSlider;
      print('🔊 볼륨 슬라이더 표시: $_showVolumeSlider');
    });

    // 볼륨 슬라이더 표시 시 컨트롤도 표시
    if (_showVolumeSlider && !_showControls) {
      setState(() {
        _showControls = true;
      });
    }

    // 컨트롤 타이머 재시작
    if (_showControls) {
      _startControlsTimer();
    }
  }

  Future<void> _openInBrowser() async {
    print('🌐 브라우저 열기 버튼 클릭됨');
    final videoUrl = widget.videoUrl ?? widget.movie?.videoUrl;
    if (videoUrl != null) {
      try {
        final uri = Uri.parse(videoUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          print('🌐 브라우저에서 열기: $videoUrl');
        } else {
          print('🚨 브라우저에서 열 수 없는 URL: $videoUrl');
        }
      } catch (e) {
        print('🚨 브라우저 열기 실패: $e');
      }
    }
  }

  // 🚪 모달 닫기
  void _closeModal() {
    print('❌ 닫기 버튼 클릭됨');
    try {
      print('🚪 VideoModal 닫기');
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('🚨 모달 닫기 에러: $e');
      // 강제 종료 시도
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  IconData _getVolumeIconData() {
    if (_volume == 0) return Icons.volume_off;
    if (_volume < 0.5) return Icons.volume_down;
    return Icons.volume_up;
  }

  // 헬퍼 메서드들
  String get _displayTitle => widget.title ?? widget.movie?.name ?? '영화';
  String get _displayPhrase => widget.phrase ?? widget.movie?.text ?? '';
  String get _displayTimestamp =>
      widget.timestamp ?? widget.movie?.startTime ?? '';

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: WillPopScope(
        onWillPop: () async {
          _closeModal();
          return false; // 기본 뒤로가기 동작 방지
        },
        child: Stack(
          children: [
            // 비디오 플레이어 영역 (이전 성공 방식)
            Center(child: _buildVideoContent()),

            // 상단 영화 정보 오버레이
            if (_showControls) _buildTopOverlay(),

            // 하단 컨트롤 오버레이
            if (_showControls) _buildBottomOverlay(),

            // 볼륨 슬라이더 (오른쪽에 표시)
            if (_showVolumeSlider) _buildVolumeSlider(),

            // 터치 감지 영역 (조건부)
            if (!(_showControls && _showVolumeSlider))
              Positioned.fill(
                child: GestureDetector(
                  onTap: _toggleControls,
                  behavior: HitTestBehavior.translucent,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoContent() {
    if (_hasError) {
      return _buildErrorWidget();
    }

    if (!_isInitialized) {
      return _buildLoadingWidget();
    }

    // 이전 성공 방식: 단순한 AspectRatio + VideoPlayer
    return AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: VideoPlayer(_controller!),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Color(AppConstants.primaryColorValue),
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),
          Text(
            '비디오를 불러오는 중...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red[400], size: 64),
          const SizedBox(height: 24),
          Text(
            '비디오를 재생할 수 없습니다',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage,
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _initializeVideo,
                icon: Icon(Icons.refresh),
                label: Text('다시 시도'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(AppConstants.primaryColorValue),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _openInBrowser,
                icon: Icon(Icons.open_in_browser),
                label: Text('브라우저에서 열기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 40, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayTitle,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_displayTimestamp.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _displayTimestamp,
                          style: TextStyle(
                            color: Color(AppConstants.primaryColorValue),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      // 영화 정보 추가 (연도, 감독 등)
                      if (widget.movie != null &&
                          widget.movie!.movieInfo.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.movie!.movieInfo,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // 🔧 닫기 버튼 - 단순하고 작게 수정
                Container(
                  margin: EdgeInsets.all(4),
                  child: IconButton(
                    onPressed: () {
                      print('❌ 닫기 버튼 터치됨');
                      _closeModal();
                    },
                    icon: Icon(Icons.close, color: Colors.white, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.transparent, // 투명 배경
                      padding: EdgeInsets.all(8), // 작은 패딩
                      minimumSize: Size(36, 36), // 2/3 크기로 축소
                    ),
                  ),
                ),
              ],
            ),
            if (_displayPhrase.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🇺🇸 Original',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '"$_displayPhrase"',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    // Django에서 받은 한글 번역 표시 (있을 경우)
                    if (widget.movie != null &&
                        widget.movie!.hasKoreanTranslation) ...[
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            '🇰🇷 한글 번역',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[300],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (widget.movie!.hasGoodTranslation)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                widget.movie!.translationQualityDisplay,
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        '"${widget.movie!.koreanText}"',
                        style: TextStyle(
                          color: Colors.green[300],
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ]
                    // 번역 서비스가 있을 때만 실시간 번역 표시
                    else if (widget.translationService != null) ...[
                      SizedBox(height: 12),
                      Text(
                        '🇰🇷 한글 번역',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[300],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      FutureBuilder<String?>(
                        future: widget.translationService!.translateToKorean(
                          _displayPhrase,
                        ),
                        builder: (context, snapshot) {
                          String translationText = '번역 중...';
                          if (snapshot.hasData && snapshot.data != null) {
                            translationText = '"${snapshot.data}"';
                          } else if (snapshot.hasError) {
                            translationText = '번역 실패';
                          }

                          return Text(
                            translationText,
                            style: TextStyle(
                              color: Colors.green[300],
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
        child: Column(
          children: [
            // 진행률 바
            if (_controller != null && _controller!.value.isInitialized)
              VideoProgressIndicator(
                _controller!,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: Color(AppConstants.primaryColorValue),
                  bufferedColor: Colors.grey[600]!,
                  backgroundColor: Colors.grey[800]!,
                ),
              ),

            const SizedBox(height: 16),

            // 컨트롤 버튼들 (이전 성공 방식 - IconButton 직접 사용)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 10초 되감기
                IconButton(
                  onPressed: _skipBackward,
                  icon: Icon(Icons.replay_10, color: Colors.white, size: 32),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.3),
                    padding: EdgeInsets.all(12),
                  ),
                ),

                // 재생/일시정지 (이전 성공 방식)
                IconButton(
                  onPressed: _togglePlayPause,
                  icon: Icon(
                    _controller?.value.isPlaying == true
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    color: Colors.white,
                    size: 48,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Color(
                      AppConstants.primaryColorValue,
                    ).withValues(alpha: 0.8),
                    padding: EdgeInsets.all(8),
                  ),
                ),

                // 10초 빨리감기
                IconButton(
                  onPressed: _skipForward,
                  icon: Icon(Icons.forward_10, color: Colors.white, size: 32),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.3),
                    padding: EdgeInsets.all(12),
                  ),
                ),

                // 볼륨 버튼 (이전 성공 방식)
                IconButton(
                  onPressed: _toggleVolumeSlider,
                  icon: Icon(
                    _getVolumeIconData(),
                    color: Colors.white,
                    size: 28,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: _showVolumeSlider
                        ? Color(
                            AppConstants.primaryColorValue,
                          ).withValues(alpha: 0.5)
                        : Colors.black.withValues(alpha: 0.3),
                    padding: EdgeInsets.all(12),
                  ),
                ),

                // 외부에서 열기 버튼
                IconButton(
                  onPressed: _openInBrowser,
                  icon: Icon(
                    Icons.open_in_browser,
                    color: Colors.white,
                    size: 28,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.3),
                    padding: EdgeInsets.all(12),
                  ),
                ),
              ],
            ),

            // 재생 시간 및 볼륨 표시
            if (_controller != null && _controller!.value.isInitialized)
              Container(
                margin: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${_formatDuration(_controller!.value.position)} / ${_formatDuration(_controller!.value.duration)}",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.repeat, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text(
                            "무한반복",
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 현재 볼륨 표시
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getVolumeIconData(),
                            color: Colors.white,
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Text(
                            "${(_volume * 100).toInt()}%",
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 🔊 볼륨 슬라이더 위젯
  Widget _buildVolumeSlider() {
    return Positioned(
      right: 20,
      top: MediaQuery.of(context).size.height * 0.3,
      bottom: MediaQuery.of(context).size.height * 0.3,
      child: Container(
        width: 60,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 볼륨 최대 버튼 (이전 성공 방식)
            IconButton(
              onPressed: () {
                print('🔊 최대 볼륨 버튼 클릭됨');
                _setVolume(1.0);
              },
              icon: Icon(Icons.volume_up, color: Colors.white, size: 24),
            ),

            // 볼륨 슬라이더
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: RotatedBox(
                  quarterTurns: -1, // 세로로 회전
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Color(AppConstants.primaryColorValue),
                      inactiveTrackColor: Colors.grey[600],
                      thumbColor: Color(AppConstants.primaryColorValue),
                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
                      overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _volume,
                      min: 0.0,
                      max: 1.0,
                      divisions: 20,
                      onChanged: _setVolume,
                    ),
                  ),
                ),
              ),
            ),

            // 볼륨 최소 버튼 (이전 성공 방식)
            IconButton(
              onPressed: () {
                print('🔇 음소거 버튼 클릭됨');
                _setVolume(0.0);
              },
              icon: Icon(Icons.volume_off, color: Colors.white, size: 24),
            ),

            // 볼륨 퍼센트 표시
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${(_volume * 100).toInt()}%',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
