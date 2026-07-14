class GroupMemberModel {
  final String memberId;
  final String name;
  final int hoursTodaySeconds;
  final bool isActive;
  final String? currentSubject;
  final DateTime lastUpdated;

  const GroupMemberModel({
    required this.memberId,
    required this.name,
    required this.hoursTodaySeconds,
    required this.isActive,
    this.currentSubject,
    required this.lastUpdated,
  });

  String get formattedHoursToday {
    final h = hoursTodaySeconds ~/ 3600;
    final m = (hoursTodaySeconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  Duration get sinceLastUpdate => DateTime.now().difference(lastUpdated);

  /// A member is considered genuinely "live" only if their last sync was
  /// recent — otherwise they've likely closed the app.
  bool get isLive => isActive && sinceLastUpdate.inMinutes < 3;

  String get statusLabel {
    if (isLive) return 'Studying now';
    final mins = sinceLastUpdate.inMinutes;
    if (mins < 1) return 'Just now';
    if (mins < 60) return 'Active ${mins}m ago';
    final hours = sinceLastUpdate.inHours;
    if (hours < 24) return 'Active ${hours}h ago';
    return 'Inactive';
  }

  factory GroupMemberModel.fromJson(String memberId, Map<String, dynamic> json) {
    return GroupMemberModel(
      memberId: memberId,
      name: json['name'] as String? ?? 'Unknown',
      hoursTodaySeconds: json['hoursTodaySeconds'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? false,
      currentSubject: json['currentSubject'] as String?,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.tryParse(json['lastUpdated'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'hoursTodaySeconds': hoursTodaySeconds,
      'isActive': isActive,
      'currentSubject': currentSubject,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}
