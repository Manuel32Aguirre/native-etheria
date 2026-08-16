import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ResponsiveContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = 760,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class MatteCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;

  const MatteCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    return Card(
      color: color,
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onTap,
              child: content,
            ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

enum StatusTone { info, success, error, warning }

class StatusBanner extends StatelessWidget {
  final String message;
  final StatusTone tone;
  final IconData? icon;
  final Widget? action;

  const StatusBanner({
    super.key,
    required this.message,
    this.tone = StatusTone.info,
    this.icon,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      StatusTone.info => AppColors.teal,
      StatusTone.success => AppColors.success,
      StatusTone.error => AppColors.error,
      StatusTone.warning => AppColors.clay,
    };
    final resolvedIcon =
        icon ??
        switch (tone) {
          StatusTone.info => Icons.info_outline_rounded,
          StatusTone.success => Icons.check_circle_outline_rounded,
          StatusTone.error => Icons.error_outline_rounded,
          StatusTone.warning => Icons.notifications_none_rounded,
        };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: color.withValues(alpha: .25)),
      ),
      child: Row(
        children: [
          Icon(resolvedIcon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return MatteCard(
      color: AppColors.surfaceMuted.withValues(alpha: .65),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Column(
          children: [
            AppIconContainer(icon: icon, size: 54),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

class AppIconContainer extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const AppIconContainer({
    super.key,
    required this.icon,
    this.color = AppColors.teal,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(size * .3),
      ),
      child: Icon(icon, color: color, size: size * .5),
    );
  }
}
