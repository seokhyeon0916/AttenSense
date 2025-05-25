import 'package:flutter/material.dart';

/// 스켈레톤 로딩 위젯
class SkeletonLoading extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<SkeletonLoading> createState() => _SkeletonLoadingState();
}

class _SkeletonLoadingState extends State<SkeletonLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.grey[300]?.withOpacity(_animation.value),
            borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
          ),
        );
      },
    );
  }
}

/// 출석 통계 카드 스켈레톤
class AttendanceStatsSkeletonCard extends StatelessWidget {
  const AttendanceStatsSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 스켈레톤
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonLoading(
                width: 100,
                height: 24,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
              SkeletonLoading(
                width: 24,
                height: 24,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 통계 카드들 스켈레톤
          Row(
            children: [
              Expanded(child: _buildStatSkeletonCard()),
              const SizedBox(width: 8),
              Expanded(child: _buildStatSkeletonCard()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatSkeletonCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoading(
            width: 40,
            height: 32,
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
          SizedBox(height: 8),
          SkeletonLoading(
            width: 80,
            height: 16,
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ],
      ),
    );
  }
}

/// 학생 리스트 스켈레톤
class StudentListSkeleton extends StatelessWidget {
  final int itemCount;

  const StudentListSkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: const Row(
            children: [
              // 아바타 스켈레톤
              SkeletonLoading(
                width: 40,
                height: 40,
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              SizedBox(width: 12),

              // 학생 정보 스켈레톤
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoading(
                      width: 120,
                      height: 16,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                    SizedBox(height: 4),
                    SkeletonLoading(
                      width: 80,
                      height: 14,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                  ],
                ),
              ),

              // 상태 뱃지 스켈레톤
              SkeletonLoading(
                width: 60,
                height: 24,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
