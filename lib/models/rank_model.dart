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
      icon: Icons.shield_rounded,
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
