### Task 1: Create Validator Utils & Write Unit Tests

**Files:**
- Create: `lib/utils/validators.dart`
- Create: `test/validators_test.dart`

**Interfaces:**
- Consumes: None
- Produces: `Validators.validatePassword(String?)`, `Validators.validateConfirmPassword(String?, String)`

- [ ] **Step 1: Write the failing tests**
  Create `test/validators_test.dart` with:
  ```dart
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
     group('Validators Test', () {});
    });
  }
  ```

- [ ] **Step 2: Run test to verify it fails**
  Run: `flutter test test/validators_test.dart`
  Expected: Compile error because `validators.dart` does not exist yet.

- [ ] **Step 3: Write minimal implementation**
  Create `lib/utils/validators.dart` with:
  ```dart
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
  ```

- [ ] **Step 4: Run test to verify it passes**
  Run: `flutter test test/validators_test.dart`
  Expected: ALL TESTS PASSED

- [ ] **Step 5: Commit**
  Run: `git add lib/utils/validators.dart test/validators_test.dart; git commit -m "feat: add validators and tests"`
