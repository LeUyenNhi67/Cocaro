import 'package:flutter_test/flutter_test.dart';
import 'package:co_caro/utils/validators.dart';

void main() {
  group('Validators Test', () {
    test('Password validator works correctly', () {
      expect(Validators.validatePassword(null), 'Vui lòng nhập mật khẩu mới.');
      expect(Validators.validatePassword(''), 'Vui lòng nhập mật khẩu mới.');
      expect(Validators.validatePassword('12345'), 'Mật khẩu phải có ít nhất 6 ký tự.');
      expect(Validators.validatePassword('123456'), null);
    });

    test('Confirm Password validator works correctly', () {
      expect(Validators.validateConfirmPassword(null, '123456'), 'Vui lòng nhập lại mật khẩu mới.');
      expect(Validators.validateConfirmPassword('123', '123456'), 'Mật khẩu xác nhận không khớp.');
      expect(Validators.validateConfirmPassword('123456', '123456'), null);
    });
  });
}
