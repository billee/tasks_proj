// lib/utils/email_validator.dart
class EmailValidator {
  /// Validates if the given string is a valid email address
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;

    // Basic email regex pattern
    final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      caseSensitive: false,
    );

    return emailRegex.hasMatch(email);
  }
}
