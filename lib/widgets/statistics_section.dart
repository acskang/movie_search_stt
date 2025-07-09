import 'package:flutter/material.dart';
import '../utils/constants.dart';

class StatisticsSection extends StatelessWidget {
  final List<String>? statistics;
  final Function(String)? onStatisticTap;

  const StatisticsSection({
    Key? key,
    this.statistics,
    this.onStatisticTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (statistics == null || statistics!.isEmpty) {
      return const SizedBox.shrink();
    }

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 헤더
          Row(
            children: [
              const Icon(
                Icons.trending_up,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                '인기 검색어',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppConstants.accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'TOP 8',
                  style: TextStyle(
                    color: AppConstants.accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 인기 검색어 그리드
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: statistics!.length > 8 ? 8 : statistics!.length,
            itemBuilder: (context, index) {
              return _buildStatisticItem(statistics![index], index + 1);
            },
          ),

          // 더보기 버튼 (8개 이상인 경우)
          if (statistics!.length > 8)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: TextButton.icon(
                  onPressed: () {
                    _showAllStatistics(context);
                  },
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppConstants.accentColor,
                  ),
                  label: Text(
                    '더 보기 (${statistics!.length - 8}개)',
                    style: const TextStyle(
                      color: AppConstants.accentColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatisticItem(String searchTerm, int rank) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getRankColors(rank),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _getRankColors(rank)[0].withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onStatisticTap?.call(searchTerm),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // 순위 표시
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // 검색어
                Expanded(
                  child: Text(
                    searchTerm,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // 트렌딩 아이콘
                if (rank <= 3)
                  Icon(
                    Icons.local_fire_department,
                    color: Colors.white.withValues(alpha: 0.8),
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _getRankColors(int rank) {
    switch (rank) {
      case 1:
        return [Colors.amber, Colors.orange]; // 금색
      case 2:
        return [Colors.grey.shade300, Colors.grey.shade500]; // 은색
      case 3:
        return [Colors.brown.shade300, Colors.brown.shade600]; // 동색
      default:
        return [
          AppConstants.primaryColor.withValues(alpha: 0.8),
          AppConstants.accentColor.withValues(alpha: 0.8)
        ]; // 기본 그라데이션
    }
  }

  void _showAllStatistics(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Color(0xFF1e293b),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // 핸들
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // 헤더
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.trending_up,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '전체 인기 검색어',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // 전체 리스트
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: statistics!.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: _buildStatisticListItem(
                        context, statistics![index], index + 1),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticListItem(
      BuildContext context, String searchTerm, int rank) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.pop(context);
            onStatisticTap?.call(searchTerm);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 순위
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _getRankColors(rank),
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // 검색어
                Expanded(
                  child: Text(
                    searchTerm,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                // 순위 변화 표시 (상위 10개만)
                if (rank <= 10)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'HOT',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white54,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
