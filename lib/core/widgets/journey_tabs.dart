import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';

/// Patient journey tab selector
class JourneyTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int>? onTabChanged;
  final List<String>? customTabs;

  const JourneyTabs({
    super.key,
    required this.selectedIndex,
    this.onTabChanged,
    this.customTabs,
  });

  static const List<String> defaultTabs = [
    AppStrings.admission,
    AppStrings.bloc,
    AppStrings.postop,
    AppStrings.discharge,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tabs = customTabs ?? defaultTabs;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = index == selectedIndex;

          return Expanded(
            child: GestureDetector(
              onTap: onTabChanged != null ? () => onTabChanged!(index) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 35,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: isSelected
                      ? Border.all(color: AppColors.border)
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.shadowColor,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    tabs[index],
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isSelected
                          ? AppColors.primaryDark
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
