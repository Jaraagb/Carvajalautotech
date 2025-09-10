import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class StatsChartCard extends StatelessWidget {
  final String title;
  final String period;
  final List<Map<String, dynamic>> data;

  const StatsChartCard({
    Key? key,
    required this.title,
    required this.period,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Transformamos la data de Supabase en lista de valores
    final chartData = data.map<double>((e) {
      final val = e['answers'];
      return val is int ? val.toDouble() : (val as double);
    }).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.lightBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.greyDark.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.info.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.info.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  _getPeriodLabel(period),
                  style: const TextStyle(
                    color: AppTheme.info,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Gráfico real
          SizedBox(
            height: 120,
            child: CustomPaint(
              size: const Size(double.infinity, 120),
              painter: SimpleChartPainter(
                data: chartData,
                color: AppTheme.info,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Leyenda y estadísticas
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Promedio',
                  chartData.isEmpty
                      ? '0'
                      : _getAverage(chartData).toStringAsFixed(0),
                  Icons.trending_up,
                  AppTheme.success,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'Máximo',
                  chartData.isEmpty
                      ? '0'
                      : _getMax(chartData).toStringAsFixed(0),
                  Icons.arrow_upward,
                  AppTheme.warning,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'Total',
                  chartData.isEmpty
                      ? '0'
                      : _getTotal(chartData).toStringAsFixed(0),
                  Icons.analytics,
                  AppTheme.primaryRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.greyLight,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  String _getPeriodLabel(String period) {
    switch (period) {
      case '1d':
        return 'Últimas 24 horas';
      case '7d':
        return 'Última semana';
      case '30d':
        return 'Último mes';
      case '90d':
        return 'Últimos 3 meses';
      default:
        return 'Período seleccionado';
    }
  }

  double _getAverage(List<double> data) {
    return data.reduce((a, b) => a + b) / data.length;
  }

  double _getMax(List<double> data) {
    return data.reduce((a, b) => a > b ? a : b);
  }

  double _getTotal(List<double> data) {
    return data.reduce((a, b) => a + b);
  }
}

class SimpleChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  SimpleChartPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color.withOpacity(0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final minValue = data.reduce((a, b) => a < b ? a : b);
    final valueRange = maxValue - minValue;

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final normalizedValue =
          valueRange == 0 ? 0.5 : (data[i] - minValue) / valueRange;
      final y = size.height - (normalizedValue * size.height);
      points.add(Offset(x, y));
    }

    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      fillPath.moveTo(points.first.dx, size.height);
      fillPath.lineTo(points.first.dx, points.first.dy);

      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
        fillPath.lineTo(points[i].dx, points[i].dy);
      }

      fillPath.lineTo(points.last.dx, size.height);
      fillPath.close();

      canvas.drawPath(fillPath, fillPaint);
      canvas.drawPath(path, paint);

      final pointPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      for (final point in points) {
        canvas.drawCircle(point, 3, pointPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
