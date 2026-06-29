# Leaderboard, Player Rank & Match History Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a comprehensive player rank system with diamond rewards per match, match history tracking, and a dynamic Leaderboard accessible from the main screen.

**Architecture:** Diamonds and match history are updated in Supabase `user_metadata` at the end of each game session. A dedicated `RankService` / utility calculates ranks based on total diamonds (Bronze 🥉, Silver 🥈, Gold 🥇, Platinum 💎, Master 👑). A new `LeaderboardBottomSheet` and `MatchHistoryWidget` showcase rankings and recent match logs within the existing cyberpunk design system.

**Tech Stack:** Flutter (Dart), `supabase_flutter`, `dart:convert`.

## Global Constraints

- **Styling**: Cyberpunk dark mode with neon accents (`#00F2FE` primary, `#FF007F` secondary, `#0F172A` surface background).
- **Diamond Rewards**: Win (+10 diamonds, VS AI Hard +15), Draw (+3 diamonds), Loss (0 diamonds).
- **Persistence**: Save diamonds and match history logs inside Supabase `user_metadata` for seamless cross-device persistence.

---

### Task 1: Rank Model & Helper Service

**Files:**
- Create: `lib/models/rank_model.dart`
- Create: `lib/services/rank_service.dart`

**Interfaces:**
- Consumes: User metadata diamond count.
- Produces: Rank tier, icon, title, next rank progress calculation, and Supabase sync logic.

- [ ] **Step 1: Create `lib/models/rank_model.dart`**

Define `PlayerRank` enum (bronze, silver, gold, platinum, master) with title, icon, color, and diamond thresholds.

```dart
import 'package:flutter/material.dart';

enum RankTier { bronze, silver, gold, platinum, master }

class RankModel {
  final RankTier tier;
  final String title;
  final IconData icon;
  final Color color;
  final int minDiamonds;
  final int? maxDiamonds;

  const RankModel({
    required this.tier,
    required this.title,
    required this.icon,
    required this.color,
    required this.minDiamonds,
    this.maxDiamonds,
  });

  static const List<RankModel> ranks = [
    RankModel(
      tier: RankTier.bronze,
      title: 'Đồng 🥉',
      icon: Icons.shield_outlined,
      color: Color(0xFFCD7F32),
      minDiamonds: 0,
      maxDiamonds: 49,
    ),
    RankModel(
      tier: RankTier.silver,
      title: 'Bạc 🥈',
      icon: Icons.shield_amber_outlined,
      color: Color(0xFFC0C0C0),
      minDiamonds: 50,
      maxDiamonds: 149,
    ),
    RankModel(
      tier: RankTier.gold,
      title: 'Vàng 🥇',
      icon: Icons.workspace_premium_rounded,
      color: Color(0xFFFFD700),
      minDiamonds: 150,
      maxDiamonds: 299,
    ),
    RankModel(
      tier: RankTier.platinum,
      title: 'Bạch Kim 💎',
      icon: Icons.diamond_rounded,
      color: Color(0xFF00F2FE),
      minDiamonds: 300,
      maxDiamonds: 499,
    ),
    RankModel(
      tier: RankTier.master,
      title: 'Cao Thủ 👑',
      icon: Icons.military_tech_rounded,
      color: Color(0xFFFF007F),
      minDiamonds: 500,
    ),
  ];

  static RankModel getRankFromDiamonds(int diamonds) {
    for (int i = ranks.length - 1; i >= 0; i--) {
      if (diamonds >= ranks[i].minDiamonds) {
        return ranks[i];
      }
    }
    return ranks.first;
  }
}
```

- [ ] **Step 2: Create `lib/services/rank_service.dart`**

Implement helper functions to record game outcomes, calculate diamond awards, and append match history to Supabase `user_metadata`.

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/rank_model.dart';

class RankService {
  static Future<int> addMatchResult({
    required String mode,
    required String result, // 'WIN', 'LOSS', 'DRAW'
    required bool isHardAi,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return 0;

    int earned = 0;
    if (result == 'WIN') {
      earned = isHardAi ? 15 : 10;
    } else if (result == 'DRAW') {
      earned = 3;
    }

    final metadata = Map<String, dynamic>.from(user.userMetadata ?? {});
    final currentDiamonds = (metadata['diamonds'] as int?) ?? 0;
    final newDiamonds = currentDiamonds + earned;

    final List history = List.from(metadata['match_history'] ?? []);
    history.insert(0, {
      'mode': mode,
      'result': result,
      'diamonds': earned,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Keep last 30 matches
    if (history.length > 30) {
      history.removeRange(30, history.length);
    }

    await Supabase.instance.client.auth.updateUser(
      UserAttributes(data: {
        'diamonds': newDiamonds,
        'match_history': history,
      }),
    );

    return earned;
  }
}
```

- [ ] **Step 3: Commit Task 1**

```bash
git add lib/models/rank_model.dart lib/services/rank_service.dart
git commit -m "feat: add rank model and rank service for diamond calculation and match history"
```

---

### Task 2: Integrate Match Completion Rewards in GameScreen

**Files:**
- Modify: `lib/views/game_screen.dart`

**Interfaces:**
- Consumes: Game completion events from `GameController`.
- Produces: Automatic diamond awards and history recording when a game concludes.

- [ ] **Step 1: Trigger `RankService.addMatchResult` on game end**

In `lib/views/game_screen.dart`, when game state reaches game over (`_controller.state.isGameOver`), call `RankService.addMatchResult` and show earned diamonds in the game over dialog / toast.

- [ ] **Step 2: Commit Task 2**

```bash
git add lib/views/game_screen.dart
git commit -m "feat: record match history and award diamonds upon game completion"
```

---

### Task 3: Build Leaderboard & Match History UI on HomeScreen

**Files:**
- Create: `lib/views/widgets/leaderboard_modal.dart`
- Modify: `lib/views/home_screen.dart`

**Interfaces:**
- Consumes: Current user rank, diamonds, and match history.
- Produces: Interactive Leaderboard & History card/button on `HomeScreen` with neon cyberpunk visuals.

- [ ] **Step 1: Create `lib/views/widgets/leaderboard_modal.dart`**

Build a sleek glassmorphic bottom sheet containing two tabs: "BẢNG XẾP HẠNG" (Leaderboard) and "LỊCH SỬ ĐẤU" (Match History).

- [ ] **Step 2: Add Leaderboard Card / Action on HomeScreen**

Add a prominent Rank & Leaderboard card on `HomeScreen` displaying the user's current Rank Title, Icon, and Diamond total, with a button to open the Leaderboard modal.

- [ ] **Step 3: Commit Task 3**

```bash
git add lib/views/widgets/leaderboard_modal.dart lib/views/home_screen.dart
git commit -m "feat: add Leaderboard and Match History UI components to HomeScreen"
```

---

### Task 4: Verification

- [ ] **Step 1: Analyze and test**

Run `flutter analyze` to ensure code cleanliness and zero syntax/compile issues. Test playing games and verifying diamond/rank increments.
