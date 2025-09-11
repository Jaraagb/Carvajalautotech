import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class CategoryQuizCard extends StatefulWidget {
  final Map<String, dynamic> category;
  final VoidCallback onTap;
  final bool isResultsPublished;

  const CategoryQuizCard({
    Key? key,
    required this.category,
    required this.onTap,
    this.isResultsPublished = false,
  }) : super(key: key);

  @override
  State<CategoryQuizCard> createState() => _CategoryQuizCardState();
}

class _CategoryQuizCardState extends State<CategoryQuizCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  bool _isPressed = false;

  /// 🔹 Lista de colores para asignar por categoría
  final List<Color> _categoryColors = [
    Colors.blue,
    Colors.green,
    Colors.purple,
    Colors.orange,
    Colors.red,
    Colors.teal,
    Colors.indigo,
    Colors.pink,
    Colors.amber,
    Colors.cyan,
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  /// 🔹 Función que asegura que el progreso nunca sea NaN o Infinity
  double _safeProgress(int completed, int total) {
    if (total <= 0) return 0.0;
    final progress = completed / total;
    return progress.clamp(0.0, 1.0);
  }

  /// 🔹 Obtiene un color en base al nombre de la categoría
  Color _getCategoryColor(String name) {
    final index = name.codeUnitAt(0) % _categoryColors.length;
    return _categoryColors[index];
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.category['name'] as String;
    final completed =
        widget.category['completed'] ?? 0; // Preguntas respondidas
    final questionCount =
        widget.category['questionCount'] ?? 0; // Total de preguntas
    final progress = _safeProgress(completed, questionCount);

    print('🔹 Mostrando categoría: $name');
    print('   - Preguntas respondidas: $completed');
    print('   - Total de preguntas: $questionCount');
    print('   - Progreso calculado: $progress');

    final color = _getCategoryColor(name);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.lightBlack,
                    color.withOpacity(0.05),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // 🔹 Recuadro con la primera letra
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : "?",
                      style: const TextStyle(
                        color: AppTheme.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Información
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppTheme.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.category['description'] as String,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.greyLight,
                                  ),
                        ),
                        const SizedBox(height: 12),

                        // Progreso y estado de publicación
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Progreso: $completed/$questionCount',
                                        style: const TextStyle(
                                          color: AppTheme.greyLight,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (completed > 0) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: widget.isResultsPublished
                                                ? AppTheme.success
                                                    .withOpacity(0.2)
                                                : AppTheme.warning
                                                    .withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                widget.isResultsPublished
                                                    ? Icons.visibility
                                                    : Icons.visibility_off,
                                                size: 10,
                                                color: widget.isResultsPublished
                                                    ? AppTheme.success
                                                    : AppTheme.warning,
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                widget.isResultsPublished
                                                    ? 'Resultados visibles'
                                                    : 'Resultados pendientes',
                                                style: TextStyle(
                                                  color:
                                                      widget.isResultsPublished
                                                          ? AppTheme.success
                                                          : AppTheme.warning,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  // Mostrar puntuación solo si está publicado y hay respuestas
                                  if (widget.isResultsPublished &&
                                      completed > 0 &&
                                      widget.category['lastScore'] != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Puntuación: ${(widget.category['lastScore'] as double).toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        color: _getScoreColor(
                                            (widget.category['lastScore']
                                                    as double)
                                                .round()),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor:
                                        AppTheme.greyDark.withOpacity(0.3),
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(color),
                                    minHeight: 4,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return AppTheme.success;
    if (score >= 80) return AppTheme.info;
    if (score >= 70) return AppTheme.warning;
    return AppTheme.error;
  }
}
