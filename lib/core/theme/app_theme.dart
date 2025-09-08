import 'package:flutter/material.dart';

class AppTheme {
  // Paleta de colores negro/rojo modernista
  static const Color primaryRed = Color(0xFFE53E3E);
  static const Color darkRed = Color(0xFFB91C1C);
  static const Color lightRed = Color(0xFFEF4444);
  
  static const Color primaryBlack = Color(0xFF1A1A1A);
  static const Color darkBlack = Color(0xFF0A0A0A);
  static const Color lightBlack = Color(0xFF2D2D2D);
  
  static const Color greyDark = Color(0xFF404040);
  static const Color greyMedium = Color(0xFF6B7280);
  static const Color greyLight = Color(0xFF9CA3AF);
  
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF9FAFB);
  
  // Colores de estado
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF3B82F6);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      brightness: Brightness.dark,
      
      colorScheme: const ColorScheme.dark(
        primary: primaryRed,
        secondary: lightRed,
        background: primaryBlack,
        surface: lightBlack,
        onPrimary: white,
        onSecondary: white,
        onBackground: white,
        onSurface: white,
      ),
      
      scaffoldBackgroundColor: primaryBlack,
      
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBlack,
        foregroundColor: white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: white,
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRed,
          foregroundColor: white,
          elevation: 8,
          shadowColor: primaryRed.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryRed,
          side: const BorderSide(color: primaryRed, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryRed,
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightBlack,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: greyDark, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        hintStyle: const TextStyle(
          color: greyMedium,
          fontFamily: 'Poppins',
        ),
        labelStyle: const TextStyle(
          color: greyLight,
          fontFamily: 'Poppins',
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      
      cardTheme: CardTheme(
        color: lightBlack,
        elevation: 8,
        shadowColor: primaryBlack.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      dialogTheme: DialogTheme(
        backgroundColor: lightBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: const TextStyle(
          color: white,
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: const TextStyle(
          color: greyLight,
          fontFamily: 'Poppins',
          fontSize: 16,
        ),
      ),
    );
  }

  // Gradientes personalizados
  static const Gradient primaryGradient = LinearGradient(
    colors: [primaryRed, darkRed],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient backgroundGradient = LinearGradient(
    colors: [primaryBlack, lightBlack],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Sombras personalizadas
  static BoxShadow get primaryShadow => BoxShadow(
    color: primaryRed.withOpacity(0.3),
    blurRadius: 8,
    offset: const Offset(0, 4),
  );

  static BoxShadow get cardShadow => BoxShadow(
    color: primaryBlack.withOpacity(0.3),
    blurRadius: 12,
    offset: const Offset(0, 6),
  );
}