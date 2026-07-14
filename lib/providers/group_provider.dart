import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/group_member_model.dart';
import '../services/group_sync_service.dart';
import '../services/settings_service.dart';
import 'core_providers.dart';
import 'timer_provider.dart';

final groupSyncServiceProvider = Provider<GroupSyncService>((ref) {
  return GroupSyncService();
});

class GroupState {
  final bool hasCredentials;
  final String? groupCode;
  final String displayName;
  final List<GroupMemberModel> members;
  final bool isLoading;
  final String? error;

  const GroupState({
    this.hasCredentials = false,
    this.groupCode,
    this.displayName = '',
    this.members = const [],
    this.isLoading = false,
    this.error,
  });

  bool get isInGroup => groupCode != null && groupCode!.isNotEmpty;

  GroupState copyWith({
    bool? hasCredentials,
    String? groupCode,
    String? displayName,
    List<GroupMemberModel>? members,
    bool? isLoading,
    String? error,
    bool clearGroupCode = false,
    bool clearError = false,
  }) {
    return GroupState(
      hasCredentials: hasCredentials ?? this.hasCredentials,
      groupCode: clearGroupCode ? null : (groupCode ?? this.groupCode),
      displayName: displayName ?? this.displayName,
      members: members ?? this.members,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class GroupNotifier extends StateNotifier<GroupState> {
  final Ref _ref;
  final SettingsService _settings;
  final GroupSyncService _sync;
  Timer? _pollTimer;
  Timer? _pushTimer;
  final _random = Random();

  GroupNotifier(this._ref, this._settings, this._sync)
      : super(GroupState(
          hasCredentials: _settings.hasGroupCredentials,
          groupCode: _settings.groupCode,
          displayName: _settings.groupDisplayName ?? '',
        )) {
    if (state.isInGroup && state.hasCredentials) {
      _startPolling();
      _startAutoPush();
    }
  }

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (_) => chars[_random.nextInt(chars.length)]).join();
  }

  Future<void> saveCredentials(String projectId, String apiKey) async {
    await _settings.setFirebaseProjectId(projectId);
    await _settings.setFirebaseApiKey(apiKey);
    state = state.copyWith(hasCredentials: true);
  }

  Future<void> setDisplayName(String name) async {
    await _settings.setGroupDisplayName(name);
    state = state.copyWith(displayName: name);
  }

  Future<String> createGroup() async {
    final code = _generateCode();
    await _settings.setGroupCode(code);
    if (_settings.groupMemberId == null) {
      await _settings.setGroupMemberId(const Uuid().v4());
    }
    state = state.copyWith(groupCode: code);
    _startPolling();
    _startAutoPush();
    await refreshMembers();
    return code;
  }

  Future<void> joinGroup(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return;
    await _settings.setGroupCode(normalized);
    if (_settings.groupMemberId == null) {
      await _settings.setGroupMemberId(const Uuid().v4());
    }
    state = state.copyWith(groupCode: normalized, clearError: true);
    _startPolling();
    _startAutoPush();
    await refreshMembers();
  }

  Future<void> leaveGroup() async {
    _pollTimer?.cancel();
    _pushTimer?.cancel();
    await _settings.setGroupCode(null);
    state = state.copyWith(clearGroupCode: true, members: []);
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      refreshMembers();
    });
  }

  void _startAutoPush() {
    _pushTimer?.cancel();
    _pushTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      pushMyStatus();
    });
    // Push immediately too.
    pushMyStatus();
  }

  Future<void> refreshMembers() async {
    if (!state.isInGroup || !state.hasCredentials) return;
    state = state.copyWith(isLoading: true, clearError: true);

    final projectId = _settings.firebaseProjectId!;
    final apiKey = _settings.firebaseApiKey!;

    final members = await _sync.fetchGroupMembers(
      projectId: projectId,
      apiKey: apiKey,
      groupCode: state.groupCode!,
    );

    members.sort((a, b) => b.hoursTodaySeconds.compareTo(a.hoursTodaySeconds));

    state = state.copyWith(members: members, isLoading: false);
  }

  Future<void> pushMyStatus() async {
    if (!state.isInGroup || !state.hasCredentials) return;

    final memberId = _settings.groupMemberId;
    if (memberId == null) return;

    final name = state.displayName.isNotEmpty ? state.displayName : 'Anonymous';
    final todaySeconds =
        await _ref.read(sessionRepositoryProvider).getTodayTotalSeconds();
    final timerState = _ref.read(timerProvider);

    final status = GroupMemberModel(
      memberId: memberId,
      name: name,
      hoursTodaySeconds: todaySeconds +
          (timerState.isActive ? timerState.elapsedSeconds : 0),
      isActive: timerState.isRunning,
      currentSubject: timerState.isActive ? timerState.subject?.name : null,
      lastUpdated: DateTime.now(),
    );

    await _sync.pushStatus(
      projectId: _settings.firebaseProjectId!,
      apiKey: _settings.firebaseApiKey!,
      groupCode: state.groupCode!,
      memberId: memberId,
      status: status,
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pushTimer?.cancel();
    super.dispose();
  }
}

final groupProvider = StateNotifierProvider<GroupNotifier, GroupState>((ref) {
  return GroupNotifier(
    ref,
    ref.read(settingsServiceProvider),
    ref.read(groupSyncServiceProvider),
  );
});
