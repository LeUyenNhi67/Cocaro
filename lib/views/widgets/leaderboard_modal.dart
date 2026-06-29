import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/rank_model.dart';
import '../../services/rank_service.dart';

class LeaderboardModal extends StatefulWidget {
  const LeaderboardModal({Key? key}) : super(key: key);

  @override
  State<LeaderboardModal> createState() => _LeaderboardModalState();
}

class _LeaderboardModalState extends State<LeaderboardModal>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final currentDiamonds = RankService.getUserDiamonds();
    final currentRank = RankService.getUserRank();
    final history = RankService.getMatchHistory();
    final nickname =
        user?.userMetadata?['nickname'] as String? ?? user?.email?.split('@').first ?? 'Người chơi';

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Rank Status Header Banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withOpacity(0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: currentRank.color.withOpacity(0.5), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: currentRank.color.withOpacity(0.15),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: currentRank.color.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(currentRank.icon, color: currentRank.color, size: 32),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nickname,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  'Hạng: ${currentRank.title}',
                                  style: TextStyle(
                                    color: currentRank.color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const Spacer(),
                                const Icon(Icons.diamond_rounded, color: Color(0xFF00F2FE), size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '$currentDiamonds',
                                  style: const TextStyle(
                                    color: Color(0xFF00F2FE),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF00F2FE),
                labelColor: const Color(0xFF00F2FE),
                unselectedLabelColor: Colors.white38,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(text: 'BẢNG XẾP HẠNG'),
                  Tab(text: 'LỊCH SỬ ĐẤU'),
                ],
              ),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Leaderboard
                    _buildLeaderboardTab(nickname, currentDiamonds, currentRank),
                    // Tab 2: Match History
                    _buildHistoryTab(history),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardTab(String currentName, int currentDiamonds, RankModel currentRank) {
    // Generated global leaderboard data featuring current user and top players
    final topPlayers = [
      {'name': 'CyberMaster 👑', 'diamonds': 1250, 'rank': 'Cao Thủ 👑'},
      {'name': 'GomokuPro 💎', 'diamonds': 890, 'rank': 'Cao Thủ 👑'},
      {'name': 'NeonKnight ⚡', 'diamonds': 540, 'rank': 'Cao Thủ 👑'},
      {'name': currentName, 'diamonds': currentDiamonds, 'rank': currentRank.title, 'isUser': true},
      {'name': 'ShadowX 🎯', 'diamonds': 210, 'rank': 'Vàng 🥇'},
      {'name': 'PixelPro 🎮', 'diamonds': 95, 'rank': 'Bạc 🥈'},
    ]..sort((a, b) => (b['diamonds'] as int).compareTo(a['diamonds'] as int));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: topPlayers.length,
      itemBuilder: (context, index) {
        final player = topPlayers[index];
        final isUser = player['isUser'] == true;
        final rankNum = index + 1;

        Color numColor = Colors.white54;
        if (rankNum == 1) numColor = const Color(0xFFFFD700);
        if (rankNum == 2) numColor = const Color(0xFFC0C0C0);
        if (rankNum == 3) numColor = const Color(0xFFCD7F32);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isUser
                ? const Color(0xFF00F2FE).withOpacity(0.12)
                : const Color(0xFF1E293B).withOpacity(0.4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isUser ? const Color(0xFF00F2FE).withOpacity(0.5) : Colors.white10,
              width: isUser ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '#$rankNum',
                  style: TextStyle(
                    color: numColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player['name'] as String,
                      style: TextStyle(
                        color: isUser ? const Color(0xFF00F2FE) : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      player['rank'] as String,
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.diamond_rounded, color: Color(0xFF00F2FE), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${player['diamonds']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab(List<Map<String, dynamic>> history) {
    if (history.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có lịch sử thi đấu nào.',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        final result = item['result'] as String? ?? 'WIN';
        final mode = item['mode'] as String? ?? 'Đấu với Máy';
        final diamonds = item['diamonds'] as int? ?? 0;
        final timestampStr = item['timestamp'] as String?;

        String timeFormatted = '';
        if (timestampStr != null) {
          final dt = DateTime.tryParse(timestampStr);
          if (dt != null) {
            timeFormatted = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} ${dt.day}/${dt.month}';
          }
        }

        Color resColor = Colors.greenAccent;
        String resText = 'THẮNG 🏆';
        if (result == 'LOSS') {
          resColor = Colors.redAccent;
          resText = 'THUA ❌';
        } else if (result == 'DRAW') {
          resColor = Colors.amber;
          resText = 'HÒA 🤝';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: resColor.withOpacity(0.3), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: resColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  resText,
                  style: TextStyle(
                    color: resColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (timeFormatted.isNotEmpty)
                      Text(
                        timeFormatted,
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                  ],
                ),
              ),
              if (diamonds > 0)
                Row(
                  children: [
                    const Icon(Icons.diamond_rounded, color: Color(0xFF00F2FE), size: 15),
                    const SizedBox(width: 2),
                    Text(
                      '+$diamonds',
                      style: const TextStyle(
                        color: Color(0xFF00F2FE),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
