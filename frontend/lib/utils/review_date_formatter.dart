String formatReviewDate(DateTime? value) {
  if (value == null) return 'No scheduled reminder';

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final local = value.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '${months[local.month - 1]} ${local.day}, ${local.year} at $hour:$minute $period';
}

String formatTimeUntil(DateTime? value) {
  if (value == null) return '';
  final difference = value.toLocal().difference(DateTime.now());
  if (difference.isNegative) return 'Ready now';
  if (difference.inDays > 0) return 'in ${difference.inDays}d';
  if (difference.inHours > 0) return 'in ${difference.inHours}h';
  return 'in ${difference.inMinutes.clamp(1, 59)} min';
}
