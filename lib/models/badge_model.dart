import 'package:flutter/material.dart';

class BadgeModel {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const BadgeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

const List<BadgeModel> allBadges = [
  BadgeModel(
    id: 'first_win',
    title: 'Chiến Công Đầu',
    description: 'Giành chiến thắng trận đầu tiên.',
    icon: Icons.emoji_events_rounded,
    color: Color(0xFFF59E0B), // Amber
  ),
  BadgeModel(
    id: 'win_3x3',
    title: 'Tập Sự Caro',
    description: 'Chiến thắng trên bàn cờ cỡ nhỏ 3x3.',
    icon: Icons.school_rounded,
    color: Color(0xFF10B981), // Emerald
  ),
  BadgeModel(
    id: 'win_20x20',
    title: 'Kẻ Chinh Phục',
    description: 'Chiến thắng trên bàn cờ khổng lồ 20x20.',
    icon: Icons.workspace_premium_rounded,
    color: Color(0xFF8B5CF6), // Purple
  ),
  BadgeModel(
    id: 'beat_ai',
    title: 'Khắc Tinh AI',
    description: 'Hạ gục thành công Máy AI thông minh.',
    icon: Icons.smart_toy_rounded,
    color: Color(0xFF06B6D4), // Cyan
  ),
  BadgeModel(
    id: 'grandmaster',
    title: 'Đại Kiện Tướng',
    description: 'Giành tổng cộng từ 5 trận thắng trở lên.',
    icon: Icons.stars_rounded,
    color: Color(0xFFEF4444), // Red
  ),
  BadgeModel(
    id: 'draw_game',
    title: 'Sứ Giả Hòa Bình',
    description: 'Kết thúc ván đấu với kết quả Hòa.',
    icon: Icons.handshake_rounded,
    color: Color(0xFF3B82F6), // Blue
  ),
];
