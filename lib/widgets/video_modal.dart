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

        // 자동 재생 및 반복
        _controller!.play();
        _controller!.setLooping(true);

        print('✅ 비디오 초기화 성공');
        print('📐 AspectRatio: ${_controller!.value.aspectRatio}');
        print('📱 VideoSize: ${_controller!.value.size}');
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
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });

    if (_showControls) {
      _startControlsTimer();
    }
  }

  void _togglePlayPause() {
    if (_controller != null && _controller!.value.isInitialized) {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
      setState(() {});
    }
  }

  void _seekTo(Duration position) {
    _controller?.seekTo(position);
  }

  void _skipBackward() {
    if (_controller != null) {
      final current = _controller!.value.position;
      final newPosition = current - const Duration(seconds: 10);
      _seekTo(newPosition > Duration.zero ? newPosition : Duration.zero);
    }
  }

  void _skipForward() {
    if (_controller != null) {
      final current = _controller!.value.position;
      final duration = _controller!.value.duration;
      final newPosition = current + const Duration(seconds: 10);
      _seekTo(newPosition < duration ? newPosition : duration);
    }
  }

  Future<void> _openInBrowser() async {
    final videoUrl = widget.videoUrl ?? widget.movie?.videoUrl;
    if (videoUrl != null) {
      try {
        final uri = Uri.parse(videoUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        print('브라우저 열기 실패: $e');
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
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
      child: Stack(
        children: [
          // 비디오 플레이어 영역 (이전 성공 방식)
          Center(child: _buildVideoContent()),

          // 상단 영화 정보 오버레이
          if (_showControls) _buildTopOverlay(),

          // 하단 컨트롤 오버레이
          if (_showControls) _buildBottomOverlay(),

          // 터치 감지 영역
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleControls,
              behavior: HitTestBehavior.translucent,
            ),
          ),
        ],
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
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Colors.white, size: 28),
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
                    // 번역 서비스가 있을 때만 번역 표시
                    if (widget.translationService != null) ...[
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

            // 컨트롤 버튼들
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 10초 되감기
                IconButton(
                  onPressed: _skipBackward,
                  icon: Icon(Icons.replay_10, color: Colors.white, size: 32),
                ),

                // 재생/일시정지
                IconButton(
                  onPressed: _togglePlayPause,
                  icon: Icon(
                    _controller?.value.isPlaying == true
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    color: Color(AppConstants.primaryColorValue),
                    size: 48,
                  ),
                ),

                // 10초 빨리감기
                IconButton(
                  onPressed: _skipForward,
                  icon: Icon(Icons.forward_10, color: Colors.white, size: 32),
                ),

                // 외부에서 열기 버튼
                IconButton(
                  onPressed: _openInBrowser,
                  icon: Icon(
                    Icons.open_in_browser,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),

            // 재생 시간 표시
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
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
