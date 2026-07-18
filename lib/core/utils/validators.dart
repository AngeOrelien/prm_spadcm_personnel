class Validators {
  Validators._();

  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "L'email est requis";
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Email invalide';
    }
    return null;
  }

  static String? otpCode(String? value, {int length = 6}) {
    if (value == null || value.trim().isEmpty) {
      return 'Le code est requis';
    }
    if (value.trim().length != length) {
      return 'Le code doit contenir $length chiffres';
    }
    if (!RegExp(r'^\d+$').hasMatch(value.trim())) {
      return 'Le code ne doit contenir que des chiffres';
    }
    return null;
  }
}
