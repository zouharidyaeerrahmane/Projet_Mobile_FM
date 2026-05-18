import 'package:flutter/material.dart';
import '../models/models.dart';
import '../../core/constants/app_theme.dart';

// ── Badge d'état ───────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String status;
  final bool   small;
  const StatusBadge({super.key, required this.status, this.small = false});

  @override
  Widget build(BuildContext context) {
    final color = status.statusColor;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 12,
        vertical  : small ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color        : color.withValues(alpha: 0.12),
        borderRadius : BorderRadius.circular(20),
        border       : Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.statusIcon, size: small ? 11 : 13, color: color),
          const SizedBox(width: 4),
          Text(
            status.statusLabel,
            style: TextStyle(
              color      : color,
              fontSize   : small ? 11 : 12,
              fontWeight : FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Badge catégorie ────────────────────────────────────────────────
class CategoryBadge extends StatelessWidget {
  final String category;
  const CategoryBadge({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final color = category.categoryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color       : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(category.categoryIcon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(category.categoryLabel,
            style: TextStyle(
              color     : color,
              fontSize  : 11,
              fontWeight: FontWeight.w700,
            )),
        ],
      ),
    );
  }
}

// ── Badge urgence ──────────────────────────────────────────────────
class UrgenceBadge extends StatelessWidget {
  final String urgence;
  const UrgenceBadge({super.key, required this.urgence});

  @override
  Widget build(BuildContext context) {
    final color = urgence.urgenceColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color        : color.withValues(alpha: 0.1),
        borderRadius : BorderRadius.circular(6),
      ),
      child: Text(
        urgence.urgenceLabel,
        style: TextStyle(
          color     : color,
          fontSize  : 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Loading Shimmer ────────────────────────────────────────────────
class LoadingList extends StatelessWidget {
  final int count;
  const LoadingList({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding    : const EdgeInsets.all(16),
      itemCount  : count,
      itemBuilder: (_, __) => Container(
        margin       : const EdgeInsets.only(bottom: 12),
        height       : 110,
        decoration   : BoxDecoration(
          color        : Colors.white,
          borderRadius : BorderRadius.circular(16),
          border       : Border.all(color: const Color(0xFFE8EDF2)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _shimmer(height: 16, width: 200),
              const SizedBox(height: 10),
              _shimmer(height: 12, width: double.infinity),
              const SizedBox(height: 6),
              _shimmer(height: 12, width: 150),
              const SizedBox(height: 14),
              _shimmer(height: 24, width: 90, radius: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shimmer({required double height, required double width, double radius = 8}) {
    return TweenAnimationBuilder<double>(
      tween   : Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 900),
      builder : (_, val, __) => Container(
        height: height, width: width,
        decoration: BoxDecoration(
          color        : Color.lerp(const Color(0xFFE8EDF2), const Color(0xFFF8FAFC), val),
          borderRadius : BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String   title;
  final String   subtitle;
  final String?  actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color        : AppColors.primary.withValues(alpha: 0.08),
                shape        : BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: AppColors.primary.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 20),
            Text(title,
              style: const TextStyle(
                fontSize  : 17,
                fontWeight: FontWeight.w700,
                color     : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(subtitle,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child    : Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Carte réclamation réutilisable ─────────────────────────────────
class ComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;
  final VoidCallback   onTap;
  final bool           showUser;

  const ComplaintCard({
    super.key,
    required this.complaint,
    required this.onTap,
    this.showUser = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap       : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      complaint.title,
                      style: const TextStyle(
                        fontSize  : 15,
                        fontWeight: FontWeight.w700,
                        color     : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: complaint.status),
                ],
              ),
              const SizedBox(height: 8),
              // Description
              Text(
                complaint.description,
                maxLines : 2,
                overflow : TextOverflow.ellipsis,
                style    : const TextStyle(
                  fontSize: 13,
                  color   : AppColors.textSecondary,
                  height  : 1.5,
                ),
              ),
              const SizedBox(height: 8),
              CategoryBadge(category: complaint.category),
              const SizedBox(height: 10),
              // Footer
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(complaint.dateFormatted,
                    style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                  const SizedBox(width: 12),
                  const Icon(Icons.access_time_rounded, size: 13, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(complaint.timeFormatted,
                    style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                  if (showUser && complaint.user != null) ...[
                    const Spacer(),
                    const Icon(Icons.person_outline_rounded, size: 13, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        complaint.user!.fullName,
                        style    : const TextStyle(fontSize: 12, color: AppColors.textHint),
                        overflow : TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  if (complaint.image != null) ...[
                    const Spacer(),
                    const Icon(Icons.image_outlined, size: 13, color: AppColors.accent),
                    const SizedBox(width: 3),
                    const Text('Photo', style: TextStyle(fontSize: 12, color: AppColors.accent)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Avatar utilisateur ─────────────────────────────────────────────
class UserAvatar extends StatelessWidget {
  final UserModel user;
  final double    size;
  const UserAvatar({super.key, required this.user, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width : size, height: size,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
          begin : Alignment.topLeft,
          end   : Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          user.initials,
          style: TextStyle(
            color     : Colors.white,
            fontWeight: FontWeight.w700,
            fontSize  : size * 0.35,
          ),
        ),
      ),
    );
  }
}

// ── Stat card ─────────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String   label;
  final String   value;
  final IconData icon;
  final Color    color;
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color        : Colors.white,
        borderRadius : BorderRadius.circular(16),
        border       : Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width : 32, height: 32,
            decoration: BoxDecoration(
              color : color.withValues(alpha: 0.12),
              shape : BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 8),
          Text(value,
            style: const TextStyle(
              fontSize  : 24,
              fontWeight: FontWeight.w800,
              color     : AppColors.textPrimary,
            )),
          const SizedBox(height: 2),
          Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
