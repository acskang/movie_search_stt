import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';

class VideoModal extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String phrase;
  final String timestamp;

  const VideoModal({
    super.key,
    required this.videoUrl,
    required this.title,
    required this.phrase,
    required this.timestamp,
  });

  @override
  State<VideoModal> createState() => _VideoModalState();
}

class _VideoModalState extends State<VideoModal> with TickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isError = false;
  String _errorMessage = '';
  bool _showControls = true;
  bool _useWebView = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _initializeVideo();
    _startControlsTimer();
  }

  void _initializeVideo() async {
    try {
      print('🎥 비디오 초기화 시작: ${widget.videoUrl}');

      // URI 유효성 검사
      final uri = Uri.tryParse(widget.videoUrl);
      if (uri == null) {
        throw Exception('잘못된 비디오 URL 형식');
      }

      // 기존 방식: 단순한 VideoPlayerController 생성
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      // 리스너 추가
      _controller?.addListener(_videoListener);

      // 타임아웃 설정으로 초기화
      await _controller?.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('비디오 로딩 타임아웃 (15초)');
        },
      );

      // 설정 적용
      await _controller?.setLooping(true);
      await _controller?.play();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isError = false;
        });
      }

      print('✅ 비디오 초기화 완료');
    } catch (e) {
      print('🚨 비디오 초기화 에러: $e');

      // UnimplementedError인 경우 WebView로 대체
      if (e.toString().contains('UnimplementedError') ||
          e.toString().contains('init() has not been implemented')) {
        print('📱 WebView 모드로 전환');
        setState(() {
          _useWebView = true;
          _isError = false;
          _isInitialized = true;
        });
        return;
      }

      if (mounted) {
        setState(() {
          _isError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _videoListener() {
    if (_controller?.value.hasError == true) {
      setState(() {
        _isError = true;
        _errorMessage = _controller?.value.errorDescription ?? '알 수 없는 에러';
      });
    }
  }

  void _startControlsTimer() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _showControls && !_useWebView) {
        _fadeController.forward();
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    if (_useWebView) return; // WebView에서는 컨트롤 비활성화

    setState(() {
      if (_showControls) {
        _fadeController.forward();
        _showControls = false;
      } else {
        _fadeController.reverse();
        _showControls = true;
        _startControlsTimer();
      }
    });
  }

  void _seekBackward() {
    final position = _controller?.value.position;
    if (position != null) {
      final newPosition = position - const Duration(seconds: 10);
      _controller?.seekTo(
        newPosition > Duration.zero ? newPosition : Duration.zero,
      );
    }
  }

  void _seekForward() {
    final position = _controller?.value.position;
    final duration = _controller?.value.duration;
    if (position != null && duration != null) {
      final newPosition = position + const Duration(seconds: 10);
      _controller?.seekTo(newPosition < duration ? newPosition : duration);
    }
  }

  void _copyUrl() {
    Clipboard.setData(ClipboardData(text: widget.videoUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('URL이 클립보드에 복사되었습니다'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _openInBrowser() async {
    final uri = Uri.parse(widget.videoUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // 비디오 플레이어 또는 대체 UI
            Center(child: _buildVideoPlayer()),

            // 컨트롤 오버레이 (WebView가 아닐 때만)
            if (!_useWebView) ...[
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _showControls ? 1.0 : _fadeAnimation.value,
                    child: child,
                  );
                },
                child: _buildControlsOverlay(),
              ),
            ],

            // 상단 정보
            _buildTopOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_useWebView) {
      return _buildWebViewFallback();
    }

    if (_isError) {
      return _buildErrorWidget();
    }

    if (!_isInitialized || _controller == null) {
      return _buildLoadingWidget();
    }

    final aspectRatio = _controller!.value.aspectRatio;
    print('🎥 AspectRatio: $aspectRatio');
    print('🎥 Video Size: ${_controller!.value.size}');

    // 올바른 비율로 중앙에 표시
    return Center(
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Container(color: Colors.black, child: VideoPlayer(_controller!)),
      ),
    );
  }

  Widget _buildWebViewFallback() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.play_circle_outline,
            size: 80,
            color: AppConstants.primaryColor,
          ),
          const SizedBox(height: 24),
          Text(
            '비디오 플레이어 호환성 문제',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            '기본 비디오 플레이어를 사용할 수 없습니다.\n외부 브라우저에서 비디오를 재생하시겠습니까?',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openInBrowser,
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text('브라우저에서 열기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _copyUrl,
                  icon: const Icon(Icons.copy),
                  label: const Text('URL 복사'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _useWebView = false;
                      _isError = false;
                      _isInitialized = false;
                    });
                    _initializeVideo();
                  },
                  child: const Text('다시 시도'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[400],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppConstants.primaryColor,
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),
          Text(
            '비디오를 로딩 중...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '최대 15초까지 소요될 수 있습니다',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
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
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 24),
          Text(
            '비디오를 로드할 수 없습니다',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage.isEmpty ? '네트워크 연결을 확인해주세요' : _errorMessage,
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 32),
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isError = false;
                      _isInitialized = false;
                      _useWebView = false;
                    });
                    _initializeVideo();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('다시 시도'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openInBrowser,
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text('브라우저에서 열기'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopOverlay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.phrase.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '"${widget.phrase}"',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (widget.timestamp.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.timestamp,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: _copyUrl,
              icon: const Icon(Icons.share, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    if (!_isInitialized || _controller == null || _useWebView) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 진행률 바
              VideoProgressIndicator(
                _controller!,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: AppConstants.primaryColor,
                  backgroundColor: Colors.grey,
                  bufferedColor: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),

              // 컨트롤 버튼들
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(
                    icon: Icons.replay_10,
                    onPressed: _seekBackward,
                  ),
                  _buildControlButton(
                    icon: _controller!.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    onPressed: () {
                      if (_controller!.value.isPlaying) {
                        _controller!.pause();
                      } else {
                        _controller!.play();
                      }
                      setState(() {});
                    },
                    size: 48,
                  ),
                  _buildControlButton(
                    icon: Icons.forward_10,
                    onPressed: _seekForward,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    double size = 40,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.5),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        iconSize: size,
      ),
    );
  }
}
