import 'package:flutter/material.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final bool isDisabled;
  final IconData? icon;
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;
  final double elevation;
  final Widget? loadingWidget;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.isDisabled = false,
    this.icon,
    this.width,
    this.height = 56,
    this.borderRadius = 12,
    this.padding,
    this.textStyle,
    this.gradient,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
    this.elevation = 0,
    this.loadingWidget,
  }) : super(key: key);

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;
  late Animation<double> _opacityAnimation;

  bool _isPressed = false;

  // Colores del tema
  static const Color primaryRed = Color(0xFFDC2626);
  static const Color darkBackground = Color(0xFF1A1A1A);
  static const Color darkSurface = Color(0xFF2D2D2D);
  static const Color darkBorder = Color(0xFF404040);

  // Gradientes predefinidos
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );

  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
  );

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _shadowAnimation = Tween<double>(
      begin: widget.elevation,
      end: widget.elevation + 4,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
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

  bool get _isButtonEnabled =>
      !widget.isLoading && !widget.isDisabled && widget.onPressed != null;

  void _onTapDown(TapDownDetails details) {
    if (!_isButtonEnabled) return;
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _resetAnimation();
  }

  void _onTapCancel() {
    _resetAnimation();
  }

  void _resetAnimation() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  Color get _getBackgroundColor {
    if (widget.isOutlined) return Colors.transparent;
    if (widget.backgroundColor != null) return widget.backgroundColor!;
    if (!_isButtonEnabled) return darkSurface;
    return primaryRed;
  }

  Color get _getBorderColor {
    if (widget.borderColor != null) return widget.borderColor!;
    if (widget.isOutlined) {
      if (!_isButtonEnabled) return darkBorder;
      return widget.gradient != null ? primaryRed : primaryRed;
    }
    return Colors.transparent;
  }

  Color get _getTextColor {
    if (widget.textColor != null) return widget.textColor!;
    if (!_isButtonEnabled) return Colors.grey[600]!;
    if (widget.isOutlined) return Colors.white;
    return Colors.white;
  }

  Widget _buildButtonContent() {
    if (widget.isLoading) {
      return widget.loadingWidget ??
          SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.isOutlined ? primaryRed : Colors.white,
              ),
            ),
          );
    }

    final List<Widget> children = [];

    if (widget.icon != null) {
      children.add(
        Icon(
          widget.icon,
          color: _getTextColor,
          size: 20,
        ),
      );
      children.add(const SizedBox(width: 8));
    }

    children.add(
      Text(
        widget.text,
        style: widget.textStyle ??
            TextStyle(
              color: _getTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: AnimatedOpacity(
            opacity: _isButtonEnabled ? _opacityAnimation.value : 0.5,
            duration: const Duration(milliseconds: 150),
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                gradient: widget.isOutlined ? null : widget.gradient,
                color: widget.gradient == null ? _getBackgroundColor : null,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(
                  color: _getBorderColor,
                  width: widget.isOutlined ? 1.5 : 0,
                ),
                boxShadow: [
                  if (!widget.isOutlined && _isButtonEnabled)
                    BoxShadow(
                      color: (widget.gradient != null
                              ? primaryRed
                              : _getBackgroundColor)
                          .withOpacity(0.3),
                      spreadRadius: 0,
                      blurRadius: _shadowAnimation.value,
                      offset: const Offset(0, 4),
                    ),
                  if (_isPressed && !widget.isOutlined)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 0,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                child: Stack(
                  children: [
                    // Efecto de brillo sutil
                    if (!widget.isOutlined)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: widget.height * 0.4,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withOpacity(0.1),
                                Colors.white.withOpacity(0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    // Botón principal
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius:
                              BorderRadius.circular(widget.borderRadius),
                          onTapDown: _onTapDown,
                          onTapUp: _onTapUp,
                          onTapCancel: _onTapCancel,
                          onTap: _isButtonEnabled ? widget.onPressed : null,
                          splashColor: widget.isOutlined
                              ? primaryRed.withOpacity(0.1)
                              : Colors.white.withOpacity(0.1),
                          highlightColor: widget.isOutlined
                              ? primaryRed.withOpacity(0.05)
                              : Colors.white.withOpacity(0.05),
                          child: Container(
                            padding: widget.padding ??
                                const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                            child: Center(
                              child: _buildButtonContent(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Overlay de presionado
                    if (_isPressed)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: widget.isOutlined
                                ? primaryRed.withOpacity(0.1)
                                : Colors.black.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(widget.borderRadius),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Clase AppTheme para referencia (ajusta según tu implementación)
class AppTheme {
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );

  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
  );
}
