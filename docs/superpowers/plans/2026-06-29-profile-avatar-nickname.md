# Profile Avatar & Nickname Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow users to update their profile picture (uploaded from device) and player nickname, persisting both in Supabase user metadata for future logins, styled seamlessly within the existing cyberpunk profile UI.

**Architecture:** Utilize `image_picker` to select an image from the user's device, encode it as a Base64 string (or store avatar URL/Base64), and update Supabase auth metadata via `Supabase.instance.client.auth.updateUser(UserAttributes(data: {...}))`. The `ProfileScreen` will load these values on initialization and reflect real-time updates.

**Tech Stack:** Flutter (Dart), `supabase_flutter`, `image_picker`, `dart:convert`, `dart:typed_data`.

## Global Constraints

- **Styling**: Cyberpunk dark mode with neon accents (`#00F2FE` primary, `#FF007F` secondary, `#0F172A` surface background).
- **Persistence**: Save nickname and avatar string into `user_metadata` so they are immediately restored whenever the user logs in on any session.
- **Error Handling**: Show descriptive glassmorphic/neon SnackBar notifications on success or failure.

---

### Task 1: Add `image_picker` dependency

**Files:**
- Modify: `pubspec.yaml`

**Interfaces:**
- Consumes: Flutter SDK pub package repository.
- Produces: `image_picker` package available across the project.

- [ ] **Step 1: Update pubspec.yaml with image_picker package**

Add `image_picker` under `dependencies` in `pubspec.yaml`.

```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.14.1
  image_picker: ^1.1.2
```

- [ ] **Step 2: Run flutter pub get**

Run command to fetch dependencies.

- [ ] **Step 3: Commit dependency changes**

```bash
git add pubspec.yaml
git commit -m "chore: add image_picker dependency for profile avatar upload"
```

---

### Task 2: Implement Avatar & Nickname state management in ProfileScreen

**Files:**
- Modify: `lib/views/profile_screen.dart`

**Interfaces:**
- Consumes: `Supabase.instance.client.auth`, `ImagePicker` from `image_picker`.
- Produces: Updated `_ProfileScreenState` managing `_nicknameController`, `_avatarBase64`, loading state, image picking, and Supabase synchronization.

- [ ] **Step 1: Add state variables and initialization in `ProfileScreen`**

In `lib/views/profile_screen.dart`, import `dart:convert`, `dart:typed_data`, and `package:image_picker/image_picker.dart`.
Add `TextEditingController _nicknameController`, `String? _avatarBase64`, and `bool _isLoading = false`.
In `initState()`, populate `_nicknameController.text` and `_avatarBase64` from `Supabase.instance.client.auth.currentUser?.userMetadata`.

```dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
```

- [ ] **Step 2: Implement `_pickAndSaveAvatar()` method**

Implement method to pick image from gallery using `ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 400, maxHeight: 400, imageQuality: 85)`. Convert bytes to Base64 string and update Supabase user metadata immediately.

```dart
Future<void> _pickAndSaveAvatar() async {
  final picker = ImagePicker();
  final XFile? pickedFile = await picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 400,
    maxHeight: 400,
    imageQuality: 85,
  );
  if (pickedFile == null) return;

  setState(() => _isLoading = true);
  try {
    final bytes = await pickedFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    
    await Supabase.instance.client.auth.updateUser(
      UserAttributes(data: {'avatar_base64': base64Image}),
    );
    
    setState(() {
      _avatarBase64 = base64Image;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật ảnh đại diện thành công!')),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi cập nhật ảnh đại diện: $e')),
      );
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
```

- [ ] **Step 3: Implement `_saveNickname()` method**

Implement method to save updated nickname from `_nicknameController.text` to Supabase user metadata.

```dart
Future<void> _saveNickname() async {
  final newName = _nicknameController.text.trim();
  if (newName.isEmpty) return;

  setState(() => _isLoading = true);
  try {
    await Supabase.instance.client.auth.updateUser(
      UserAttributes(data: {'nickname': newName}),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu biệt danh thành công!')),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi cập nhật biệt danh: $e')),
      );
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
```

- [ ] **Step 4: Commit state management changes**

```bash
git add lib/views/profile_screen.dart
git commit -m "feat: implement avatar picking and nickname save logic in ProfileScreen"
```

---

### Task 3: Redesign ProfileScreen UI for Interactive Avatar & Nickname Editing

**Files:**
- Modify: `lib/views/profile_screen.dart`

**Interfaces:**
- Consumes: `_avatarBase64`, `_nicknameController`, `_pickAndSaveAvatar()`, `_saveNickname()`.
- Produces: Glassmorphic UI layout with clickable avatar circle (camera overlay badge) and styled Nickname input field.

- [ ] **Step 1: Build interactive Avatar widget**

Replace static avatar icon with a GestureDetector wrapping a stack containing `CircleAvatar` (displaying `MemoryImage(base64Decode(_avatarBase64!))` if present, otherwise default icon) and a small camera icon badge at the bottom right.

```dart
Widget _buildAvatarWidget() {
  ImageProvider? imageProvider;
  if (_avatarBase64 != null && _avatarBase64!.isNotEmpty) {
    try {
      imageProvider = MemoryImage(base64Decode(_avatarBase64!));
    } catch (_) {}
  }

  return GestureDetector(
    onTap: _isLoading ? null : _pickAndSaveAvatar,
    child: Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF00F2FE),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00F2FE).withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipOval(
            child: imageProvider != null
                ? Image(image: imageProvider, fit: BoxFit.cover)
                : Container(
                    color: const Color(0xFF00F2FE).withOpacity(0.1),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Color(0xFF00F2FE),
                      size: 56,
                    ),
                  ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(
            color: Color(0xFFFF007F),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.camera_alt_rounded,
            color: Colors.white,
            size: 16,
          ),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 2: Build Nickname input field and update layout**

Update the card in `ProfileScreen` to include the Avatar widget, Nickname input field with a save icon/button, and user Email display.

```dart
// Inside Profile Card Column
_buildAvatarWidget(),
const SizedBox(height: 20),
// Nickname Input Field
TextField(
  controller: _nicknameController,
  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
  textAlign: TextAlign.center,
  decoration: InputDecoration(
    labelText: 'BIỆT DANH / NICKNAME',
    labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
    floatingLabelBehavior: FloatingLabelBehavior.always,
    suffixIcon: IconButton(
      icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF00F2FE)),
      onPressed: _isLoading ? null : _saveNickname,
    ),
    enabledBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
    ),
    focusedBorder: const UnderlineInputBorder(
      borderSide: BorderSide(color: Color(0xFF00F2FE)),
    ),
  ),
),
const SizedBox(height: 16),
// Email Display
```

- [ ] **Step 3: Commit UI changes**

```bash
git add lib/views/profile_screen.dart
git commit -m "feat: enhance ProfileScreen UI with interactive avatar upload and nickname field"
```

---

### Task 4: Verification

**Files:**
- Modify/Test: Manual validation in app

- [ ] **Step 1: Verify build and runtime execution**

Ensure code compiles cleanly with no Dart analysis or lint errors. Test picking an image and updating nickname. Verify persistence across screen re-entry or app restart.
