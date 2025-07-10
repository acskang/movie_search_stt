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

  // 🔍 모든 검색 요청에 대해 확인 절차를 거침
  void _performSearch() {
    final query = _controller.text.trim();
    if (query.isNotEmpty && !widget.isLoading) {
      // 텍스트 확인 다이얼로그 표시 (키보드 입력)
      _showInputConfirmationDialog(query, false);
      _focusNode.unfocus();
    }
  }

  Future<void> _startListening() async {
    if (!_speechInitialized || _isListening || widget.isLoading) return;

    try {
      setState(() {
        _isListening = true;
      });

      // 한국어로 음성 인식 시작 (30초, 침묵 4초 시 자동 종료)
      final result = await _speechService.startListening(
        language: 'ko-KR',
        timeout: const Duration(seconds: 30),
      );

      if (result != null && result.isNotEmpty) {
        print('🎤 음성 인식 결과: $result');

        // 음성인식 결과 확인 다이얼로그 표시
        _showInputConfirmationDialog(result, true);
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

  // 📋 모든 입력에 대한 통합 확인 다이얼로그
  void _showInputConfirmationDialog(String inputText, bool isFromSpeech) {
    // 한국어인지 확인
    final isKorean = widget.translationService?.isKorean(inputText) ?? false;

    showDialog(
      context: context,
      barrierDismissible: false, // 뒤로가기로 닫기 방지
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppConstants.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                isFromSpeech ? Icons.mic : Icons.keyboard,
                color: AppConstants.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                isFromSpeech ? '음성인식 결과 확인' : '검색어 확인',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isFromSpeech ? '다음과 같이 인식되었습니다:' : '다음 검색어로 영화를 찾으시겠습니까?',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),

              // 입력된 텍스트 표시
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isKorean
                      ? Colors.orange.withValues(alpha: 0.1)
                      : AppConstants.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isKorean
                        ? Colors.orange.withValues(alpha: 0.3)
                        : AppConstants.primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isFromSpeech
                              ? (isKorean ? Icons.record_voice_over : Icons.mic)
                              : (isKorean ? Icons.translate : Icons.language),
                          color: isKorean
                              ? Colors.orange[300]
                              : Colors.blue[300],
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isFromSpeech
                              ? (isKorean ? '🎤 한국어 음성인식' : '🎤 영어 음성인식')
                              : (isKorean ? '⌨️ 한국어 키보드 입력' : '⌨️ 영어 키보드 입력'),
                          style: TextStyle(
                            color: isKorean
                                ? Colors.orange[300]
                                : Colors.blue[300],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '"$inputText"',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // 번역 결과 표시 (한국어인 경우만)
              if (isKorean) ...[
                const SizedBox(height: 12),

                // 번역 화살표
                Center(
                  child: Icon(
                    Icons.arrow_downward,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                ),

                const SizedBox(height: 12),

                // 번역된 영어 결과
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.language,
                            color: Colors.blue[300],
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '🇺🇸 영어 번역 (검색에 사용됨)',
                            style: TextStyle(
                              color: Colors.blue[300],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // 번역 결과 또는 로딩 표시
                      FutureBuilder<String?>(
                        future: widget.translationService?.translateToEnglish(
                          inputText,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.blue[300],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '번역 중...',
                                  style: TextStyle(
                                    color: Colors.blue[300],
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            );
                          } else if (snapshot.hasError || !snapshot.hasData) {
                            return Text(
                              '"번역 실패 - 원문 사용"',
                              style: TextStyle(
                                color: Colors.red[300],
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          } else {
                            return Text(
                              '"${snapshot.data}"',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
              ] else ...[
                const SizedBox(height: 16),
              ],

              // 데이터 품질 안내 메시지
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified, color: Colors.green[300], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '데이터 품질 향상을 위해 모든 검색어를 확인합니다.',
                        style: TextStyle(
                          color: Colors.green[300],
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Text(
                '이 텍스트로 검색하시겠습니까?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            // No 버튼 (빨간색) - 더 명확한 레이블
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _handleInputRejection(isFromSpeech);
              },
              icon: Icon(Icons.edit, color: Colors.red[400]),
              label: Text(
                isFromSpeech ? '다시 인식' : '수정하기',
                style: TextStyle(
                  color: Colors.red[400],
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),

            // Yes 버튼 (초록색)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _handleInputConfirmation(inputText, isFromSpeech);
              },
              icon: Icon(Icons.search, size: 18),
              label: Text('검색하기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ 사용자가 입력 결과를 확인한 경우
  void _handleInputConfirmation(String inputText, bool isFromSpeech) {
    print('✅ 사용자가 ${isFromSpeech ? "음성인식" : "키보드 입력"} 결과 확인: "$inputText"');

    // 텍스트 필드에 입력 (음성인식인 경우만)
    if (isFromSpeech) {
      _controller.text = inputText;
    }

    // 성공 메시지 표시
    _showSnackBar('✅ 검색을 시작합니다.');

    // 백엔드로 검색 실행
    widget.onSearch(inputText);
  }

  // ❌ 사용자가 입력 결과를 거부한 경우
  void _handleInputRejection(bool isFromSpeech) {
    print('❌ 사용자가 ${isFromSpeech ? "음성인식" : "키보드 입력"} 결과 거부');

    if (isFromSpeech) {
      // 음성인식인 경우: 텍스트 필드 초기화
      _controller.clear();
      _showSnackBar('🎤 음성인식을 다시 시도해주세요.');
    } else {
      // 키보드 입력인 경우: 텍스트 필드에 포커스
      _focusNode.requestFocus();
      _showSnackBar('✏️ 검색어를 수정해주세요.');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
          backgroundColor: message.startsWith('✅')
              ? Colors.green[700]
              : message.startsWith('🎤') || message.startsWith('✏️')
              ? Colors.orange[700]
              : Colors.orange[700],
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
                          ? '음성으로 검색 (한국어, 최대 30초, 침묵 4초 시 자동 종료)\n인식 후 확인 단계를 거칩니다'
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

          // 검색 팁 (업데이트됨)
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
                    '💡 데이터 품질 향상을 위해 모든 검색어를 확인합니다!\n🎤 음성인식 및 ⌨️ 키보드 입력 모두 확인 절차를 거칩니다.',
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
