import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class StudentPerformanceCard extends StatelessWidget {
  final Map<String, dynamic> student;
  final bool isTop3;
  final int index;

  const StudentPerformanceCard({
    Key? key,
    required this.student,
    required this.isTop3,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final rank = student['rank'] as int;
    final accuracy = student['accuracy'] as double;
    
    Color rankColor = AppTheme.greyLight;
    IconData rankIcon = Icons.emoji_events_outlined;
    
    switch (rank) {
      case 1:
        rankColor = const Color(0xFFFFD700); // Oro
        rankIcon = Icons.emoji_events;
        break;
      case 2:
        rankColor = const Color(0xFFC0C0C0); // Plata
        rankIcon = Icons.emoji_events;
        break;
      case 3:
        rankColor = const Color(0xFFCD7F32); // Bronce
        rankIcon = Icons.emoji_events;
        break;
    }

    return Container(
      margin: EdgeInsets.only(
        bottom: index < 4 ? 1 : 0,
        left: 16,
        right: 16,
        top: index == 0 ? 16 : 0,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isTop3 
            ? rankColor.withOpacity(0.05)
            : AppTheme.primaryBlack.withOpacity(0.3),
        border: isTop3 
            ? Border.all(color: rankColor.withOpacity(0.3), width: 1)
            : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Ranking
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isTop3 
                  ? rankColor.withOpacity(0.2)
                  : AppTheme.greyDark.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: isTop3 
                  ? Icon(
                      rankIcon,
                      color: rankColor,
                      size: 24,
                    )
                  : Text(
                      '#$rank',
                      style: const TextStyle(
                        color: AppTheme.greyLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.info.withOpacity(0.2),
            child: Text(
              _getInitials(student['name'] as String),
              style: const TextStyle(
                color: AppTheme.info,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Información del estudiante
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['name'] as String,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  student['email'] as String,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.greyLight,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${student['questionsAnswered']} preguntas respondidas',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.greyMedium,
                      ),
                ),
              ],
            ),
          ),
          
          // Precisión
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getAccuracyColor(accuracy).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getAccuracyColor(accuracy).withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${accuracy.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: _getAccuracyColor(accuracy),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  return Icon(
                    Icons.star,
                    size: 12,
                    color: index < _getStarCount(accuracy) 
                        ? AppTheme.warning 
                        : AppTheme.greyDark,
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 90) return AppTheme.success;
    if (accuracy >= 80) return AppTheme.info;
    if (accuracy >= 70) return AppTheme.warning;
    return AppTheme.error;
  }

  int _getStarCount(double accuracy) {
    if (accuracy >= 95) return 5;
    if (accuracy >= 90) return 4;
    if (accuracy >= 80) return 3;
    if (accuracy >= 70) return 2;
    if (accuracy >= 60) return 1;
    return 0;
  }
}