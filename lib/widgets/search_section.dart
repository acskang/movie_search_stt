import 'package:flutter/material.dart';
import '../services/speech_service.dart';
import '../services/translation_service.dart';
import '../utils/constants.dart';

class SearchSection extends StatefulWidget {
  final Function(String) onSearch;
  final bool isLoading;
  final TranslationService? translationService; // nullable로 변경

  const SearchSection({
    super.key,
    required this.onSearch,
    this.translationService, // optional로 변경
    this.isLoading = false,
  });

  @override
  State<SearchSection> createState() => _SearchSectionState();
}

class _SearchSectionState extends State<SearchSection> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final SpeechService _speechService = SpeechService();

  bool _isListening = false;
  bool _speechInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _initializeSpeech() async {
    try {
      final initialized = await _speechService.initialize();
      setState(() {
        _speechInitialized = initialized;
      });
      if (!initialized) {
        print('🚨 음성 인식 초기화 실패');
      }
    } catch (e) {
      print('🚨 음성 인식 초기화 에러: $e');
      setState(() {
        _speechInitialized = false;
      });
    }
  }

  void _performSearch() {
    final query = _controller.text.trim();
    if (query.isNotEmpty && !widget.isLoading) {
      widget.onSearch(query);
      _focusNode.unfocus();
    }
  }

  Future<void> _startListening() async {
    if (!_speechInitialized || _isListening || widget.isLoading) return;

    try {
      setState(() {
        _isListening = true;
      });

      // 한국어로 음성 인식 시작 (11.5초로 연장)
      final result = await _speechService.startListening(
        language: 'ko-KR',
        timeout: const Duration(seconds: 11, milliseconds: 500), // 1.5초 연장
      );

      if (result != null && result.isNotEmpty) {
        _controller.text = result;
        print('🎤 음성 인식 결과: $result');

        // 자동으로 검색 실행
        widget.onSearch(result);
      } else {
        _showSnackBar('음성이 인식되지 않았습니다. 다시 시도해주세요.');
      }
    } catch (e) {
      print('🚨 음성 인식 에러: $e');
      _showSnackBar('음성 인식 중 오류가 발생했습니다.');
    } finally {
      setState(() {
        _isListening = false;
      });
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.orange[700],
        ),
      );
    }
  }

  Widget _buildLanguageIndicator() {
    final text = _controller.text;
    if (text.isEmpty || widget.translationService == null)
      return const SizedBox.shrink();

    final isKorean = widget.translationService!.isKorean(text);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isKorean
            ? Colors.orange.withValues(alpha: 0.2)
            : Colors.blue.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isKorean
              ? Colors.orange.withValues(alpha: 0.5)
              : Colors.blue.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isKorean ? Icons.translate : Icons.language,
            size: 16,
            color: isKorean ? Colors.orange[300] : Colors.blue[300],
          ),
          const SizedBox(width: 6),
          Text(
            isKorean ? '🇰🇷 한국어 → 영어로 번역하여 검색' : '🇺🇸 영어로 바로 검색',
            style: TextStyle(
              fontSize: 12,
              color: isKorean ? Colors.orange[300] : Colors.blue[300],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.cardColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '영화 대사 검색',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // 검색 입력 필드
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _focusNode.hasFocus
                    ? AppConstants.primaryColor
                    : Colors.grey.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: '영화 대사를 입력하세요... (한국어/영어)',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppConstants.primaryColor,
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 음성 인식 버튼
                    Tooltip(
                      message: _speechInitialized
                          ? '음성으로 검색 (한국어, 11.5초)'
                          : '음성 인식 사용 불가',
                      child: IconButton(
                        onPressed: _speechInitialized && !widget.isLoading
                            ? _startListening
                            : null,
                        icon: _isListening
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.red[400],
                                ),
                              )
                            : Icon(
                                _speechInitialized ? Icons.mic : Icons.mic_off,
                                color: _speechInitialized
                                    ? (_isListening
                                          ? Colors.red[400]
                                          : Colors.orange[400])
                                    : Colors.grey[600],
                              ),
                      ),
                    ),

                    // 검색 버튼
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: IconButton(
                        onPressed: widget.isLoading ? null : _performSearch,
                        icon: widget.isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppConstants.primaryColor,
                                ),
                              )
                            : Icon(
                                Icons.send,
                                color: AppConstants.primaryColor,
                              ),
                      ),
                    ),
                  ],
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              onChanged: (value) {
                setState(() {}); // 언어 감지 업데이트
              },
              onSubmitted: (_) => _performSearch(),
              textInputAction: TextInputAction.search,
            ),
          ),

          // 언어 감지 인디케이터 (translationService가 있을 때만)
          if (widget.translationService != null) _buildLanguageIndicator(),

          const SizedBox(height: 12),

          // 검색 팁
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.blue.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.blue[300],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '💡 한국어로 입력하면 자동으로 영어로 번역하여 검색합니다!\n🎤 마이크 버튼을 눌러 음성으로도 검색 가능합니다. (11.5초)',
                    style: TextStyle(color: Colors.blue[300], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
