import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class FilterChipWidget extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Function(bool) onSelected;

  const FilterChipWidget({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.white : AppTheme.greyLight,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
        selected: isSelected,
        onSelected: onSelected,
        backgroundColor: AppTheme.greyDark.withOpacity(0.3),
        selectedColor: AppTheme.primaryRed,
        checkmarkColor: AppTheme.white,
        side: BorderSide(
          color: isSelected ? AppTheme.primaryRed : AppTheme.greyDark,
          width: 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        elevation: isSelected ? 4 : 0,
        shadowColor: isSelected ? AppTheme.primaryRed.withOpacity(0.3) : null,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
