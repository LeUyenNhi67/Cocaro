class Validators {
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu mới.';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự.';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập lại mật khẩu mới.';
    }
    if (value != password) {
      return 'Mật khẩu xác nhận không khớp.';
    }
    return null;
  }
}
