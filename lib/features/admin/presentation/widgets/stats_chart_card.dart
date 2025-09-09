import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class StatsChartCard extends StatelessWidget {
  final String title;
  final String period;

  const StatsChartCard({
    Key? key,
    required this.title,
    required this.period,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Datos simulados según el período
    final chartData = _getChartData(period);

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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          
          // Gráfico simple (simulado)
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
                  '${_getAverage(chartData).toStringAsFixed(0)}',
                  Icons.trending_up,
                  AppTheme.success,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'Máximo',
                  '${_getMax(chartData).toStringAsFixed(0)}',
                  Icons.arrow_upward,
                  AppTheme.warning,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'Total',
                  '${_getTotal(chartData).toStringAsFixed(0)}',
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

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
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

  List<double> _getChartData(String period) {
    switch (period) {
      case '1d':
        return [45, 52, 38, 67, 73, 89, 94, 67, 78, 85, 92, 88, 76, 69, 82, 91, 87, 94, 78, 85, 92, 88, 76, 69];
      case '7d':
        return [234, 267, 298, 345, 312, 278, 356];
      case '30d':
        return [1234, 1567, 1432, 1678, 1890, 1756, 1923, 2156, 2034, 2234, 2456, 2312, 2567, 2634, 2789, 2456, 2678, 2345, 2567, 2789, 2456, 2678, 2890, 2567, 2789, 2456, 2678, 2345, 2567, 2234];
      case '90d':
        return [15234, 16567, 17432, 16678, 18890, 17756, 19923, 21156, 20034, 22234, 24456, 23312, 25567, 26634, 27789, 26456, 26678, 25345, 26567, 27789, 26456, 26678, 28890, 27567, 27789, 26456, 26678, 25345, 26567, 22234, 23456, 24567, 25678, 26789, 27890, 28456, 29567, 30678, 31789, 32890, 31456, 30567, 29678, 28789, 27890, 28456, 29567, 30678, 31789, 32890, 31456, 30567, 29678, 28789, 27890, 28456, 29567, 30678, 31789, 32890, 31456, 30567, 29678, 28789, 27890, 28456, 29567, 30678, 31789, 32890, 31456, 30567, 29678, 28789, 27890, 28456, 29567, 30678, 31789, 32890, 31456, 30567, 29678, 28789, 27890, 28456, 29567, 30678, 31789, 32890];
      default:
        return [234, 267, 298, 345, 312, 278, 356];
    }
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

    // Crear puntos del gráfico
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final normalizedValue = valueRange == 0 ? 0.5 : (data[i] - minValue) / valueRange;
      final y = size.height - (normalizedValue * size.height);
      points.add(Offset(x, y));
    }

    // Dibujar línea
    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      fillPath.moveTo(points.first.dx, size.height);
      fillPath.lineTo(points.first.dx, points.first.dy);

      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
        fillPath.lineTo(points[i].dx, points[i].dy);
      }

      // Cerrar el área de relleno
      fillPath.lineTo(points.last.dx, size.height);
      fillPath.close();

      // Dibujar área de relleno
      canvas.drawPath(fillPath, fillPaint);

      // Dibujar línea
      canvas.drawPath(path, paint);

      // Dibujar puntos
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