import 'package:flutter/material.dart';

class AppColors {
  // Palette principale — bleu universitaire profond
  static const Color primary       = Color(0xFF0D47A1);
  static const Color primaryLight  = Color(0xFF1565C0);
  static const Color primaryDark   = Color(0xFF0A2E6E);
  static const Color accent        = Color(0xFF00ACC1);
  static const Color accentLight   = Color(0xFF26C6DA);

  static const Color background    = Color(0xFFF0F4F8);
  static const Color surface       = Color(0xFFFFFFFF);
  static const Color surfaceCard   = Color(0xFFFFFFFF);

  static const Color textPrimary   = Color(0xFF0D1B2A);
  static const Color textSecondary = Color(0xFF546E7A);
  static const Color textHint      = Color(0xFF90A4AE);

  static const Color success       = Color(0xFF2E7D32);
  static const Color warning       = Color(0xFFE65100);
  static const Color error         = Color(0xFFC62828);
  static const Color info          = Color(0xFF01579B);

  // États réclamation technique
  static const Color statusPending    = Color(0xFF1565C0);
  static const Color statusProgress   = Color(0xFFE65100);
  static const Color statusWaiting    = Color(0xFF6A1B9A);
  static const Color statusResolved   = Color(0xFF2E7D32);
  static const Color statusClosed     = Color(0xFF546E7A);
  static const Color statusCancelled  = Color(0xFFC62828);

  // États signalement bruit
  static const Color noiseReviewed    = Color(0xFF6A1B9A);
  static const Color noiseRejected    = Color(0xFFC62828);

  // Sécurité
  static const Color security         = Color(0xFF37474F);

  // Urgence
  static const Color urgenceLow      = Color(0xFF2E7D32);
  static const Color urgenceNormal   = Color(0xFF1565C0);
  static const Color urgenceHigh     = Color(0xFFE65100);
  static const Color urgenceCritical = Color(0xFFC62828);
}

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    fontFamily: 'Georgia',
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 0.3,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE8EDF2), width: 1),
      ),
      margin: const EdgeInsets.only(bottom: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDDE3EA)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDDE3EA)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textHint,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );
}

// ── Helpers status ────────────────────────────────────────────────
extension StatusStyle on String {
  Color get statusColor {
    switch (toLowerCase()) {
      case 'pending'     : return AppColors.statusPending;
      case 'in_progress' : return AppColors.statusProgress;
      case 'waiting'     : return AppColors.statusWaiting;
      case 'resolved'    : return AppColors.statusResolved;
      case 'closed'      : return AppColors.statusClosed;
      case 'cancelled'   : return AppColors.statusCancelled;
      case 'reviewed'    : return AppColors.noiseReviewed;
      case 'rejected'    : return AppColors.noiseRejected;
      default            : return AppColors.textSecondary;
    }
  }

  String get statusLabel {
    switch (toLowerCase()) {
      case 'pending'     : return 'En attente';
      case 'in_progress' : return 'En cours';
      case 'waiting'     : return 'En attente pièce';
      case 'resolved'    : return 'Résolu';
      case 'closed'      : return 'Clôturé';
      case 'cancelled'   : return 'Annulé';
      case 'reviewed'    : return 'Examiné';
      case 'rejected'    : return 'Rejeté';
      default            : return this;
    }
  }

  IconData get statusIcon {
    switch (toLowerCase()) {
      case 'pending'     : return Icons.schedule_rounded;
      case 'in_progress' : return Icons.engineering_rounded;
      case 'waiting'     : return Icons.hourglass_top_rounded;
      case 'resolved'    : return Icons.check_circle_rounded;
      case 'closed'      : return Icons.lock_rounded;
      case 'cancelled'   : return Icons.cancel_rounded;
      case 'reviewed'    : return Icons.visibility_rounded;
      case 'rejected'    : return Icons.block_rounded;
      default            : return Icons.info_rounded;
    }
  }

  Color get urgenceColor {
    switch (toLowerCase()) {
      case 'low'      : return AppColors.urgenceLow;
      case 'normal'   : return AppColors.urgenceNormal;
      case 'high'     : return AppColors.urgenceHigh;
      case 'critical' : return AppColors.urgenceCritical;
      default         : return AppColors.urgenceNormal;
    }
  }

  Color get categoryColor {
    switch (toLowerCase()) {
      case 'electricite'   : return const Color(0xFFE65100);
      case 'plomberie'     : return const Color(0xFF0277BD);
      case 'menuiserie'    : return const Color(0xFF4E342E);
      case 'climatisation' : return const Color(0xFF00838F);
      case 'internet'      : return const Color(0xFF283593);
      default              : return AppColors.textSecondary;
    }
  }

  String get categoryLabel {
    switch (toLowerCase()) {
      case 'electricite'   : return 'Électricité';
      case 'plomberie'     : return 'Plomberie';
      case 'menuiserie'    : return 'Menuiserie';
      case 'climatisation' : return 'Climatisation';
      case 'internet'      : return 'Internet/WiFi';
      default              : return 'Autre';
    }
  }

  IconData get categoryIcon {
    switch (toLowerCase()) {
      case 'electricite'   : return Icons.bolt_rounded;
      case 'plomberie'     : return Icons.water_drop_outlined;
      case 'menuiserie'    : return Icons.handyman_outlined;
      case 'climatisation' : return Icons.ac_unit_rounded;
      case 'internet'      : return Icons.wifi_rounded;
      default              : return Icons.build_outlined;
    }
  }

  String get urgenceLabel {
    switch (toLowerCase()) {
      case 'low'      : return 'Faible';
      case 'normal'   : return 'Normale';
      case 'high'     : return 'Haute';
      case 'critical' : return 'Critique';
      default         : return this;
    }
  }
}
