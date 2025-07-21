import 'package:flutter/material.dart';
import '../utils/constants.dart';

class HeaderSection extends StatelessWidget {
  final VoidCallback? onReset; // 초기화 콜백 추가

  const HeaderSection({super.key, this.onReset});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppConstants.primaryColor.withValues(alpha: 0.1),
            AppConstants.secondaryColor.withValues(alpha: 0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppConstants.primaryColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // 왼쪽 아이콘 (cskang.jpg) - 클릭 시 초기화
            GestureDetector(
              onTap: () => _showResetDialog(context),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppConstants.primaryColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.asset(
                    'assets/images/cskang.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // 이미지 로드 실패시 기본 아이콘 표시
                      return Container(
                        color: AppConstants.primaryColor.withValues(alpha: 0.2),
                        child: Icon(
                          Icons.refresh,
                          color: AppConstants.primaryColor,
                          size: 28,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // 앱 제목과 서브타이틀
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '많이 듣자, 영어!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '영화 대사로 찾는 명장면',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            // 오른쪽 액션 버튼들
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 설정 버튼
                IconButton(
                  onPressed: () {
                    // 설정 기능 추가 가능
                    print('⚙️ 설정 버튼 클릭됨');
                  },
                  icon: Icon(
                    Icons.settings_outlined,
                    color: Colors.grey[400],
                    size: 24,
                  ),
                  tooltip: '설정',
                ),

                // 도움말 버튼
                IconButton(
                  onPressed: () {
                    // 도움말 기능 추가 가능
                    _showHelpDialog(context);
                  },
                  icon: Icon(
                    Icons.help_outline,
                    color: Colors.grey[400],
                    size: 24,
                  ),
                  tooltip: '도움말',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.cardColor,
        title: Row(
          children: [
            Icon(Icons.refresh, color: AppConstants.primaryColor, size: 24),
            const SizedBox(width: 8),
            Text('앱 초기화', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '앱을 초기 상태로 되돌리시겠습니까?',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange[300],
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '초기화 효과:',
                        style: TextStyle(
                          color: Colors.orange[300],
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• 🎤 음성인식 서비스 완전 재시작\n• 🔄 검색 상태 초기화\n• 📱 홈 화면으로 이동\n• 🧹 임시 데이터 정리',
                    style: TextStyle(color: Colors.orange[200], fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '음성인식이 제대로 작동하지 않을 때 유용합니다.',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _performReset(context);
            },
            icon: Icon(Icons.refresh, size: 18),
            label: Text('초기화'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _performReset(BuildContext context) {
    print('🔄 앱 초기화 시작...');

    // 초기화 진행 상황을 보여주는 SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Text('🔄 앱 초기화 중...'),
          ],
        ),
        backgroundColor: AppConstants.primaryColor,
        duration: const Duration(seconds: 2),
      ),
    );

    // 초기화 콜백 실행
    if (onReset != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        onReset!();
        print('✅ 앱 초기화 완료');

        // 완료 메시지
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text('✅ 초기화가 완료되었습니다!'),
              ],
            ),
            backgroundColor: Colors.green[600],
            duration: const Duration(seconds: 2),
          ),
        );
      });
    }
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.cardColor,
        title: Text('도움말', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🎬 Movie Phrase Search 사용법:',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildHelpItem('🔍', '텍스트 검색', '영화 대사를 직접 입력하여 검색'),
            _buildHelpItem('🎤', '음성 검색', '마이크 버튼으로 최대 30초, 침묵 4초 시 자동 종료'),
            _buildHelpItem('🌏', '자동 번역', '한국어 입력시 영어로 자동 번역'),
            _buildHelpItem('🎥', '비디오 재생', '포스터 클릭하여 해당 장면 시청'),
            _buildHelpItem('📜', '검색 기록', '최근 검색어를 다시 클릭하여 재검색'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.refresh, color: Colors.blue[300], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '왼쪽 프로필 이미지를 클릭하면 앱을 초기화할 수 있습니다.',
                      style: TextStyle(color: Colors.blue[300], fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '확인',
              style: TextStyle(color: AppConstants.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
