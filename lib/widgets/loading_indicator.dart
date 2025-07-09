import 'package:flutter/material.dart';
import '../utils/constants.dart';

class LoadingIndicator extends StatefulWidget {
  final String? message;
  final String? subtitle;
  final bool isTranslating;

  const LoadingIndicator({
    super.key,
    this.message,
    this.subtitle,
    this.isTranslating = false,
  });

  @override
  _LoadingIndicatorState createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rotationController.repeat();
    _pulseController.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 로딩 애니메이션
          AnimatedBuilder(
            animation: _rotationAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationAnimation.value * 2 * 3.14159,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: widget.isTranslating
                                ? [Colors.orange, Colors.deepOrange]
                                : [
                                    AppConstants.primaryColor,
                                    AppConstants.accentColor
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (widget.isTranslating
                                      ? Colors.orange
                                      : AppConstants.primaryColor)
                                  .withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.isTranslating ? Icons.translate : Icons.search,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // 로딩 메시지
          if (widget.message != null)
            Text(
              widget.message!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),

          if (widget.message != null) const SizedBox(height: 8),

          // 상태별 추가 정보
          Text(
            widget.subtitle ?? _getSubMessage(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // 점들 애니메이션
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  double delay = index * 0.3;
                  double animationValue =
                      (_pulseController.value + delay) % 1.0;

                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.white
                          .withValues(alpha: 0.3 + (animationValue * 0.7)),
                      shape: BoxShape.circle,
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  String _getSubMessage() {
    if (widget.isTranslating) {
      return '한국어를 영어로 번역하고 있습니다...';
    }

    String message = widget.message ?? '';
    switch (message) {
      case '음성 인식 중...':
        return '마이크를 통해 음성을 듣고 있습니다';
      case '번역 중...':
        return '언어를 번역하고 있습니다';
      case '검색 중...':
      case '영화 검색 중...':
        return '영화 데이터베이스에서 검색하고 있습니다';
      case '비디오 로딩 중...':
        return '영화 클립을 준비하고 있습니다';
      default:
        return '잠시만 기다려주세요';
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}
