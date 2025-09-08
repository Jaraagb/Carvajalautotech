import 'package:carvajal_autotech/core/models/question_models.dart';
import 'package:flutter/material.dart';

class CategoryCard extends StatefulWidget {
  final Category category;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final bool showActions;
  final EdgeInsetsGeometry? margin;

  const CategoryCard({
    Key? key,
    required this.category,
    this.onEdit,
    this.onDelete,
    this.onTap,
    this.showActions = true,
    this.margin,
  }) : super(key: key);

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  late Animation<double> _borderAnimation;

  bool _isHovered = false;
  bool _isPressed = false;

  // Colores del tema
  static const Color primaryRed = Color(0xFFDC2626);
  static const Color darkBackground = Color(0xFF1A1A1A);
  static const Color darkSurface = Color(0xFF2D2D2D);
  static const Color darkBorder = Color(0xFF404040);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color infoColor = Color(0xFF3B82F6);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _elevationAnimation = Tween<double>(
      begin: 4.0,
      end: 12.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _borderAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
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

  void _onHoverChanged(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
    if (isHovered) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
  }

  void _onTapCancel() {
    setState(() {
      _isPressed = false;
    });
  }

  Color _getCategoryColor() {
    // Puedes personalizar esto según tu lógica de colores por categoría
    final colorIndex = widget.category.name.hashCode % 4;
    switch (colorIndex.abs()) {
      case 0:
        return primaryRed;
      case 1:
        return successColor;
      case 2:
        return infoColor;
      case 3:
        return warningColor;
      default:
        return primaryRed;
    }
  }

  IconData _getCategoryIcon() {
    // Puedes personalizar esto según el tipo de categoría
    final name = widget.category.name.toLowerCase();
    if (name.contains('matemática') || name.contains('math')) {
      return Icons.calculate_outlined;
    } else if (name.contains('ciencia') || name.contains('science')) {
      return Icons.science_outlined;
    } else if (name.contains('historia') || name.contains('history')) {
      return Icons.history_edu_outlined;
    } else if (name.contains('geografía') || name.contains('geography')) {
      return Icons.public_outlined;
    } else if (name.contains('literatura') || name.contains('language')) {
      return Icons.menu_book_outlined;
    } else if (name.contains('arte') || name.contains('art')) {
      return Icons.palette_outlined;
    } else if (name.contains('música') || name.contains('music')) {
      return Icons.music_note_outlined;
    } else if (name.contains('deporte') || name.contains('sport')) {
      return Icons.sports_outlined;
    } else {
      return Icons.category_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor();
    final categoryIcon = _getCategoryIcon();

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: widget.margin ?? const EdgeInsets.all(8),
            child: MouseRegion(
              onEnter: (_) => _onHoverChanged(true),
              onExit: (_) => _onHoverChanged(false),
              child: GestureDetector(
                onTapDown: _onTapDown,
                onTapUp: _onTapUp,
                onTapCancel: _onTapCancel,
                onTap: widget.onTap,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        darkBackground,
                        darkSurface,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isHovered
                          ? categoryColor.withOpacity(0.5)
                          : darkBorder
                              .withOpacity(_borderAnimation.value * 0.5),
                      width: 1 + _borderAnimation.value,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: categoryColor
                            .withOpacity(0.1 + _borderAnimation.value * 0.1),
                        spreadRadius: 0,
                        blurRadius: _elevationAnimation.value,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 0,
                        blurRadius: _elevationAnimation.value * 1.5,
                        offset: const Offset(0, 8),
                      ),
                      if (_isPressed)
                        BoxShadow(
                          color: categoryColor.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        // Efecto de brillo sutil
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 60,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withOpacity(0.05),
                                  Colors.white.withOpacity(0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Contenido principal
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header con ícono y acciones
                              Row(
                                children: [
                                  // Ícono de categoría
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: categoryColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: categoryColor.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      categoryIcon,
                                      color: categoryColor,
                                      size: 24,
                                    ),
                                  ),
                                  const Spacer(),
                                  // Botones de acción
                                  if (widget.showActions) ...[
                                    _ActionButton(
                                      icon: Icons.edit_outlined,
                                      color: infoColor,
                                      onPressed: widget.onEdit,
                                      tooltip: 'Editar',
                                    ),
                                    const SizedBox(width: 8),
                                    _ActionButton(
                                      icon: Icons.delete_outline,
                                      color: const Color(0xFFEF4444),
                                      onPressed: widget.onDelete,
                                      tooltip: 'Eliminar',
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Nombre de la categoría
                              Text(
                                widget.category.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              // Descripción
                              Expanded(
                                child: Text(
                                  widget.category.description ??
                                      'Sin descripción',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    height: 1.4,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Footer con estadísticas
                              Row(
                                children: [
                                  _StatItem(
                                    icon: Icons.quiz_outlined,
                                    value:
                                        '${widget.category.questionCount ?? 0}',
                                    label: 'Preguntas',
                                    color: categoryColor,
                                  ),
                                  if (widget.category.createdAt != null) ...[
                                    const SizedBox(width: 16),
                                    _StatItem(
                                      icon: Icons.schedule_outlined,
                                      value: _formatDate(
                                          widget.category.createdAt),
                                      label: 'Creada',
                                      color: Colors.grey[500]!,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Ripple effect
                        Positioned.fill(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              splashColor: categoryColor.withOpacity(0.1),
                              highlightColor: categoryColor.withOpacity(0.05),
                              onTap:
                                  null, // El tap se maneja en el GestureDetector
                            ),
                          ),
                        ),
                        // Línea decorativa inferior
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 4,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Colors.transparent,
                                  categoryColor.withOpacity(0.8),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Overlay de presionado
                        if (_isPressed)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: categoryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return 'Hoy';
    if (difference == 1) return 'Ayer';
    if (difference < 7) return '${difference}d';
    if (difference < 30) return '${(difference / 7).floor()}sem';
    if (difference < 365) return '${(difference / 30).floor()}m';
    return '${(difference / 365).floor()}a';
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final String tooltip;

  const _ActionButton({
    required this.icon,
    required this.color,
    this.onPressed,
    required this.tooltip,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        onTap: widget.onPressed,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.color.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.color,
                  size: 18,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color,
          size: 14,
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// // Modelo Category para referencia (ajusta según tu implementación)
// class Category {
//   final String id;
//   final String name;
//   final String? description;
//   final DateTime? createdAt;
//   final int? questionCount;
//   final bool isActive;

//   Category({
//     required this.id,
//     required this.name,
//     this.description,
//     this.createdAt,
//     this.questionCount,
//     this.isActive = true,
//   });
// }
