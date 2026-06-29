# Session Persistence & Prominent Home Profile Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ensure the user remains logged in across hot reloads, refreshes, and app restarts (only showing LoginScreen when explicitly logged out), and enlarge/highlight the profile button on HomeScreen with the player's avatar and nickname.

**Architecture:** Check `Supabase.instance.client.auth.currentSession` at app startup (`CaroApp` in `lib/main.dart`) to conditionally show `HomeScreen` or `LoginScreen`. Redesign the AppBar/Header in `lib/views/home_screen.dart` to render a prominent glowing profile badge with the avatar and nickname.

**Tech Stack:** Flutter (Dart), `supabase_flutter`, `dart:convert`.

## Global Constraints

- **Styling**: Cyberpunk dark mode with neon accents (`#00F2FE` primary, `#FF007F` secondary, `#0F172A` surface background).
- **Session Persistence**: Keep user logged in until explicit logout (`signOut`).
- **Realtime Refresh**: Immediately update avatar and nickname on HomeScreen when returning from ProfileScreen.

---

### Task 1: Persistent Authentication Routing in `lib/main.dart`

**Files:**
- Modify: `lib/main.dart`

**Interfaces:**
- Consumes: `Supabase.instance.client.auth.currentSession`.
- Produces: Persistent root widget routing based on session state.

- [ ] **Step 1: Update `CaroApp` home property**

Modify `lib/main.dart` to import `views/home_screen.dart` and check `Supabase.instance.client.auth.currentSession != null`.

```dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'views/home_screen.dart';
import 'views/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  runApp(const CaroApp());
}

class CaroApp extends StatelessWidget {
  const CaroApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      title: 'Cờ Caro - Gomoku',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF070B19),
        primaryColor: const Color(0xFF00F2FE),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00F2FE),
          secondary: Color(0xFFFF007F),
          surface: Color(0xFF0F172A),
        ),
        cardColor: const Color(0xFF0F172A),
        dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF0F172A)),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
      ),
      home: session != null ? const HomeScreen() : const LoginScreen(),
    );
  }
}
```

- [ ] **Step 2: Commit Task 1**

```bash
git add lib/main.dart
git commit -m "feat: enable persistent session routing on app launch"
```

---

### Task 2: Prominent Profile Header & Avatar Widget on HomeScreen

**Files:**
- Modify: `lib/views/home_screen.dart`

**Interfaces:**
- Consumes: `Supabase.instance.client.auth.currentUser`, Base64 decoding.
- Produces: Enriched AppBar with glowing Avatar circle, player nickname, and state refresh upon returning from ProfileScreen.

- [ ] **Step 1: Implement `_buildProfileHeaderAction()` in `HomeScreen`**

In `lib/views/home_screen.dart`, import `dart:convert`.
Replace the small icon button in `AppBar` actions with a prominent glowing action widget containing the user avatar and nickname.

```dart
Widget _buildProfileHeaderAction() {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return const SizedBox.shrink();

  final metadata = user.userMetadata;
  final nickname = metadata?['nickname'] as String? ?? user.email?.split('@').first ?? 'Người chơi';
  final avatarBase64 = metadata?['avatar_base64'] as String?;

  ImageProvider? imageProvider;
  if (avatarBase64 != null && avatarBase64.isNotEmpty) {
    try {
      imageProvider = MemoryImage(base64Decode(avatarBase64));
    } catch (_) {}
  }

  return InkWell(
    onTap: () async {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
      if (mounted) {
        setState(() {}); // Refresh avatar and nickname when returning
      }
    },
    borderRadius: BorderRadius.circular(20),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00F2FE).withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00F2FE).withOpacity(0.15),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: imageProvider != null
                  ? Image(image: imageProvider, fit: BoxFit.cover)
                  : Container(
                      color: const Color(0xFF00F2FE).withOpacity(0.2),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Color(0xFF00F2FE),
                        size: 20,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              nickname,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
  );
}
```

- [ ] **Step 2: Update AppBar configuration in `HomeScreen`**

Increase `toolbarHeight: 56` in `HomeScreen` AppBar and update `actions` to render `Padding(padding: const EdgeInsets.only(right: 16.0), child: Center(child: _buildProfileHeaderAction()))`.

- [ ] **Step 3: Commit Task 2**

```bash
git add lib/views/home_screen.dart
git commit -m "feat: add prominent glowing avatar and nickname header action on HomeScreen"
```

---

### Task 3: Verification

- [ ] **Step 1: Run flutter analyze**

Ensure code compiles with zero errors. Verify hot reload / app restart preserves session state and displays prominent avatar header.
