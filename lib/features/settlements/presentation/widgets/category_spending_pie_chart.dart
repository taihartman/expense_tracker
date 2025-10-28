import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:decimal/decimal.dart';
import '../../domain/models/category_spending.dart';
import '../../../../core/models/currency_code.dart';
import '../../../../core/utils/formatters.dart' show Formatters;
import '../../../../core/theme/app_theme.dart';

/// Pie chart visualization of category spending breakdown
///
/// Shows spending distribution across categories with color-coded segments
class CategorySpendingPieChart extends StatelessWidget {
  final List<CategorySpending> categoryBreakdown;
  final CurrencyCode currency;

  const CategorySpendingPieChart({
    super.key,
    required this.categoryBreakdown,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    // Handle empty state
    if (categoryBreakdown.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.pie_chart_outline,
                size: 48,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: AppTheme.spacing1),
              Text(
                'No expenses yet',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Sort by amount descending and limit to top 5 + Other
    final sortedCategories = List<CategorySpending>.from(categoryBreakdown)
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final top5 = sortedCategories.take(5).toList();
    final hasMore = sortedCategories.length > 5;

    // Calculate "Other" if needed
    CategorySpending? otherCategory;
    if (hasMore) {
      final otherAmount = sortedCategories
          .skip(5)
          .fold(Decimal.zero, (sum, c) => sum + c.amount);
      otherCategory = CategorySpending(
        categoryId: 'other',
        categoryName: 'Other',
        amount: otherAmount,
        color: '#9E9E9E', // Grey
      );
    }

    final displayCategories = [
      ...top5,
      if (otherCategory != null) otherCategory,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pie chart
        AspectRatio(
          aspectRatio: 1.3,
          child: PieChart(
            PieChartData(
              sections: _buildSections(displayCategories, context),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacing2),
        // Legend
        _buildLegend(displayCategories, context),
      ],
    );
  }

  List<PieChartSectionData> _buildSections(
    List<CategorySpending> categories,
    BuildContext context,
  ) {
    final total = categories.fold(
      Decimal.zero,
      (sum, category) => sum + category.amount,
    );

    return categories.map((category) {
      final percentage = ((category.amount / total).toDouble() * 100);
      final color =
          _parseColor(category.color) ??
          _getDefaultColor(categories.indexOf(category));

      return PieChartSectionData(
        color: color,
        value: percentage,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegend(List<CategorySpending> categories, BuildContext context) {
    return Wrap(
      spacing: AppTheme.spacing2,
      runSpacing: AppTheme.spacing1,
      children: categories.map((category) {
        final color =
            _parseColor(category.color) ??
            _getDefaultColor(categories.indexOf(category));

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(
              category.categoryName,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(width: 4),
            Text(
              Formatters.formatCurrency(category.amount, currency),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        );
      }).toList(),
    );
  }

  Color? _parseColor(String? hexColor) {
    if (hexColor == null) return null;
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return null;
    }
  }

  Color _getDefaultColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
    ];
    return colors[index % colors.length];
  }
}
