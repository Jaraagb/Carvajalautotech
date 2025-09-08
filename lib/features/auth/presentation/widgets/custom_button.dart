import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final Gradient? gradient;
  final double? width;
  final double height;
  final EdgeInsetsGeometry? padding;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.gradient,
    this.width,
    this.height = 56,
    this.padding,
  }) : super(key: key);

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
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

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() {
        _isPressed = true;
      });
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isPressed) {
      setState(() {
        _isPressed = false;
      });
      _animationController.reverse();
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() {
        _isPressed = false;
      });
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onPressed != null && !widget.isLoading;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: GestureDetector(
              onTapDown: _handleTapDown,
              onTapUp: _handleTapUp,
              onTapCancel: _handleTapCancel,
              onTap: isEnabled ? widget.onPressed : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: widget.width ?? double.infinity,
                height: widget.height,
                padding: widget.padding,
                decoration: BoxDecoration(
                  gradient: widget.isOutlined ? null : (
                    widget.gradient ?? 
                    (isEnabled 
                        ? AppTheme.primaryGradient 
                        : LinearGradient(
                            colors: [
                              AppTheme.greyDark,
                              AppTheme.greyDark.withOpacity(0.8),
                            ],
                          ))
                  ),
                  color: widget.isOutlined 
                      ? Colors.transparent 
                      : (widget.backgroundColor ?? (isEnabled ? null : AppTheme.greyDark)),
                  borderRadius: BorderRadius.circular(12),
                  border: widget.isOutlined
                      ? Border.all(
                          color: isEnabled 
                              ? (widget.gradient != null 
                                  ? AppTheme.primaryRed 
                                  : (widget.backgroundColor ?? AppTheme.primaryRed))
                              : AppTheme.greyDark,
                          width: 2,
                        )
                      : null,
                  boxShadow: !widget.isOutlined && isEnabled
                      ? [
                          BoxShadow(
                            color: (widget.gradient != null 
                                ? AppTheme.primaryRed 
                                : (widget.backgroundColor ?? AppTheme.primaryRed))
                                .withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    alignment: Alignment.center,
                    child: widget.isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                widget.isOutlined 
                                    ? AppTheme.primaryRed
                                    : AppTheme.white,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.icon != null) ...[
                                Icon(
                                  widget.icon,
                                  color: widget.isOutlined
                                      ? (isEnabled 
                                          ? AppTheme.primaryRed 
                                          : AppTheme.greyMedium)
                                      : (widget.textColor ?? AppTheme.white),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                widget.text,
                                style: TextStyle(
                                  color: widget.isOutlined
                                      ? (isEnabled 
                                          ? AppTheme.primaryRed 
                                          : AppTheme.greyMedium)
                                      : (widget.textColor ?? AppTheme.white),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
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
}