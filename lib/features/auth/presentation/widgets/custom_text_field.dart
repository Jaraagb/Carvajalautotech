import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final bool isPassword;
  final bool isPasswordVisible;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final bool enabled;
  final int maxLines;
  final int? maxLength;

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.label,
    required this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.isPassword = false,
    this.isPasswordVisible = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
  }) : super(key: key);

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _focusAnimation;
  late Animation<Color?> _colorAnimation;
  
  bool _isFocused = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _focusAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _colorAnimation = ColorTween(
      begin: AppTheme.greyDark,
      end: AppTheme.primaryRed,
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

  void _handleFocusChange(bool hasFocus) {
    setState(() {
      _isFocused = hasFocus;
    });

    if (hasFocus) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                widget.label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _isFocused || _hasError
                          ? (_hasError ? AppTheme.error : AppTheme.primaryRed)
                          : AppTheme.greyLight,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            
            // Campo de texto
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: _isFocused
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryRed.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Focus(
                onFocusChange: _handleFocusChange,
                child: TextFormField(
                  controller: widget.controller,
                  obscureText: widget.isPassword && !widget.isPasswordVisible,
                  keyboardType: widget.keyboardType,
                  enabled: widget.enabled,
                  maxLines: widget.maxLines,
                  maxLength: widget.maxLength,
                  style: const TextStyle(
                    color: AppTheme.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                  validator: (value) {
                    final error = widget.validator?.call(value);
                    setState(() {
                      _hasError = error != null;
                    });
                    return error;
                  },
                  onChanged: widget.onChanged,
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: TextStyle(
                      color: AppTheme.greyMedium.withOpacity(0.7),
                      fontSize: 16,
                    ),
                    filled: true,
                    fillColor: AppTheme.lightBlack,
                    
                    // Bordes
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.greyDark.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _colorAnimation.value ?? AppTheme.primaryRed,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.error,
                        width: 1,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.error,
                        width: 2,
                      ),
                    ),
                    
                    // Padding
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    
                    // Iconos
                    prefixIcon: widget.prefixIcon != null
                        ? Container(
                            margin: const EdgeInsets.only(right: 12),
                            child: Icon(
                              widget.prefixIcon,
                              color: _isFocused
                                  ? _colorAnimation.value
                                  : AppTheme.greyMedium,
                              size: 20,
                            ),
                          )
                        : null,
                    
                    suffixIcon: widget.suffixIcon != null
                        ? GestureDetector(
                            onTap: widget.onSuffixTap,
                            child: Container(
                              margin: const EdgeInsets.only(left: 12),
                              child: Icon(
                                widget.suffixIcon,
                                color: _isFocused
                                    ? _colorAnimation.value
                                    : AppTheme.greyMedium,
                                size: 20,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}