import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0XFF1b374d);
  static const Color secondaryColor = Color(0XFFFFFFFF);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color secondaryBackgroundColor = Color(0xFFFFFFFF);

  static const Color textPrimaryColor = Color(0XFF1b374d);
  static const Color textSecondaryColor = Color(0XFFFFFFFF);
  static const Color errorColor = Color(0XFFF62440);
  static const Color successColor = Color(0XFF499A13);

  static const Color secondaryButtonColor = Color(0xFFD90000);

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.black,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      brightness: Brightness.dark, // Light container fill
    ),

    textTheme: const TextTheme(
      // Header 1
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textSecondaryColor,
      ),

      // Header 2
      headlineMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: textSecondaryColor,
      ),

      // Header 3
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textSecondaryColor,
      ),

      // Body text
      bodyLarge: TextStyle(fontSize: 14, color: textSecondaryColor),

      // Subtext / Caption
      bodySmall: TextStyle(fontSize: 14, color: textSecondaryColor),
    ),
    inputDecorationTheme: InputDecorationTheme(
      floatingLabelStyle: TextStyle(
        color: secondaryColor,
        fontWeight: FontWeight.bold,
      ),
      prefixIconColor: secondaryColor,
      suffixIconColor: secondaryColor,
      labelStyle: TextStyle(color: secondaryColor),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: secondaryColor, width: 0.5),
      ),

      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400, width: 1.0),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: secondaryColor, width: 1),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: secondaryColor, width: 2),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: errorColor, width: 1),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: errorColor, width: 2),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: secondaryButtonColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0), // Adjust radius value here
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        textStyle: TextStyle(color: secondaryColor),
      ),
    ),

    iconTheme: IconThemeData(color: secondaryColor),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: secondaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0), // Adjust radius value here
        ),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all<Color>(primaryColor),
      trackColor: WidgetStateProperty.all<Color>(secondaryColor),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: primaryColor,
      selectedItemColor: Color(0XFFFFFFFF),
      unselectedItemColor: Colors.grey,
    ),

    bottomAppBarTheme: const BottomAppBarThemeData(color: primaryColor),

    cardTheme: CardThemeData(
      color: Colors.black,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: secondaryColor, // Border color
        ),
      ),
    ),

    appBarTheme: const AppBarTheme(
      centerTitle: true,
      backgroundColor: Colors.black,
      scrolledUnderElevation: 0.0,
      iconTheme: IconThemeData(color: secondaryColor),
      titleTextStyle: TextStyle(
        fontSize: 26,
        color: secondaryColor,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: backgroundColor,

    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
    ),

    textTheme: const TextTheme(
      // Header 1
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),

      // Header 2
      headlineMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),

      // Header 3
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
      ),

      // Body text
      bodyLarge: TextStyle(fontSize: 14, color: textPrimaryColor),

      // Subtext / Caption
      bodySmall: TextStyle(fontSize: 14, color: Colors.grey),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      floatingLabelStyle: TextStyle(
        color: primaryColor,
        fontWeight: FontWeight.bold,
      ),
      prefixIconColor: primaryColor,
      suffixIconColor: primaryColor,
      labelStyle: TextStyle(color: primaryColor),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: primaryColor, width: 0.5),
      ),

      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400, width: 1.0),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: primaryColor, width: 1),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: errorColor, width: 1),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: errorColor, width: 2),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: secondaryButtonColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0), // Adjust radius value here
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: primaryColor),
    ),

    iconTheme: IconThemeData(color: primaryColor),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all<Color>(secondaryColor),
      trackColor: WidgetStateProperty.all<Color>(primaryColor),
      trackOutlineColor: WidgetStateProperty.all<Color>(primaryColor),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0), // Adjust radius value here
        ),
      ),
    ),

    cardTheme: CardThemeData(
      color: secondaryColor,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: secondaryColor, // Border color
        ),
      ),
    ),

    appBarTheme: const AppBarTheme(
      centerTitle: true,
      backgroundColor: backgroundColor,
      scrolledUnderElevation: 0.0,
      iconTheme: IconThemeData(color: primaryColor),
      titleTextStyle: TextStyle(
        fontSize: 26,
        color: primaryColor,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
