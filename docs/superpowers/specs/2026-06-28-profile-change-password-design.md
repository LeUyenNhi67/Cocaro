# Design: Profile & Change Password Feature

## 1. Overview
The goal is to implement a user profile screen that includes a "Change Password" functionality. Users will be able to navigate to the Profile screen from the main Home screen, view their information (e.g. email), and update their password by confirming their current password.

## 2. Architecture & Navigation
- **Navigation Update**: The existing `logout_rounded` icon button on the `HomeScreen` AppBar will be replaced with a `person` icon button. Tapping this button navigates to the new `ProfileScreen`.
- **Profile Screen**: 
  - Displays the user's email address (retrieved from `Supabase.instance.client.auth.currentUser`).
  - Contains a primary action button: "Đổi mật khẩu" (Change Password).
  - Contains a secondary action button: "Đăng xuất" (Logout).

## 3. UI/UX Design (Adhering to Existing Style)
- **Visual Style**: Inherits the app's cyberpunk/neon styling, utilizing the dark background (`Color(0xFF070B19)`), ambient glowing orbs (`Color(0xFF00F2FE)` and `Color(0xFFFF007F)`), and glassmorphism (using `BackdropFilter` with `ImageFilter.blur`). Buttons will use the existing `NeonButton` widget.
- **Change Password Flow**:
  - Tapping "Đổi mật khẩu" opens a modal `BottomSheet` with a glassmorphism effect.
  - The form contains three text fields:
    - Current Password (`mật khẩu hiện tại`)
    - New Password (`mật khẩu mới`)
    - Confirm New Password (`xác nhận mật khẩu mới`)
  - The form includes a "Xác nhận" (Confirm) button.

## 4. Data Flow & Authentication
- **Verifying Current Password**: Supabase's `updateUser` does not intrinsically verify the current password. We will verify it by calling `signInWithPassword(email: userEmail, password: currentPassword)`.
- **Updating Password**: If the verification succeeds and the new passwords match, call `updateUser(UserAttributes(password: newPassword))`.
- **Error Handling**: Show a `SnackBar` for:
  - Incorrect current password.
  - New passwords do not match.
  - Network/API errors.
- **Success State**: Show a success `SnackBar` and close the `BottomSheet`.

## 5. Components to Create/Modify
- `lib/views/home_screen.dart` [MODIFY]: Change the logout button to a profile navigation button.
- `lib/views/profile_screen.dart` [NEW]: The new profile screen component.
- `lib/views/widgets/change_password_bottom_sheet.dart` [NEW] (or implement inline within `ProfileScreen`): The glassmorphic bottom sheet containing the form.
