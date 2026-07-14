import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class SettingsService {
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  int get dailyTargetSeconds =>
      _prefs.getInt(AppConstants.keyDailyTarget) ??
      AppConstants.defaultDailyTargetSeconds;

  Future<void> setDailyTargetSeconds(int seconds) async {
    await _prefs.setInt(AppConstants.keyDailyTarget, seconds);
  }

  int get accentColor =>
      _prefs.getInt(AppConstants.keyAccentColor) ?? 0xFF4F8CFF;

  Future<void> setAccentColor(int colorValue) async {
    await _prefs.setInt(AppConstants.keyAccentColor, colorValue);
  }

  int get quoteFrequencyMinutes =>
      _prefs.getInt(AppConstants.keyQuoteFrequency) ??
      AppConstants.quoteRotationMinutes;

  Future<void> setQuoteFrequencyMinutes(int minutes) async {
    await _prefs.setInt(AppConstants.keyQuoteFrequency, minutes);
  }

  double get savedWindowWidth =>
      _prefs.getDouble(AppConstants.keyWindowWidth) ??
      AppConstants.defaultWindowWidth;

  Future<void> setWindowWidth(double width) async {
    await _prefs.setDouble(AppConstants.keyWindowWidth, width);
  }

  double get savedWindowHeight =>
      _prefs.getDouble(AppConstants.keyWindowHeight) ??
      AppConstants.defaultWindowHeight;

  Future<void> setWindowHeight(double height) async {
    await _prefs.setDouble(AppConstants.keyWindowHeight, height);
  }

  double? get savedWindowX => _prefs.getDouble(AppConstants.keyWindowX);
  double? get savedWindowY => _prefs.getDouble(AppConstants.keyWindowY);

  Future<void> setWindowPosition(double x, double y) async {
    await _prefs.setDouble(AppConstants.keyWindowX, x);
    await _prefs.setDouble(AppConstants.keyWindowY, y);
  }

  List<String> get studyStages {
    final saved = _prefs.getStringList(AppConstants.keyStudyStages);
    if (saved == null || saved.isEmpty) {
      return List<String>.from(AppConstants.defaultStudyStages);
    }
    return saved;
  }

  Future<void> setStudyStages(List<String> stages) async {
    await _prefs.setStringList(AppConstants.keyStudyStages, stages);
  }

  // --- Group Study ---

  String? get groupDisplayName => _prefs.getString(AppConstants.keyGroupDisplayName);
  Future<void> setGroupDisplayName(String name) async {
    await _prefs.setString(AppConstants.keyGroupDisplayName, name);
  }

  String? get groupMemberId => _prefs.getString(AppConstants.keyGroupMemberId);
  Future<void> setGroupMemberId(String id) async {
    await _prefs.setString(AppConstants.keyGroupMemberId, id);
  }

  String? get groupCode => _prefs.getString(AppConstants.keyGroupCode);
  Future<void> setGroupCode(String? code) async {
    if (code == null) {
      await _prefs.remove(AppConstants.keyGroupCode);
    } else {
      await _prefs.setString(AppConstants.keyGroupCode, code);
    }
  }

  String? get firebaseProjectId => _prefs.getString(AppConstants.keyFirebaseProjectId);
  Future<void> setFirebaseProjectId(String id) async {
    await _prefs.setString(AppConstants.keyFirebaseProjectId, id);
  }

  String? get firebaseApiKey => _prefs.getString(AppConstants.keyFirebaseApiKey);
  Future<void> setFirebaseApiKey(String key) async {
    await _prefs.setString(AppConstants.keyFirebaseApiKey, key);
  }

  bool get hasGroupCredentials =>
      firebaseProjectId != null &&
      firebaseProjectId!.isNotEmpty &&
      firebaseApiKey != null &&
      firebaseApiKey!.isNotEmpty;

  String get personalNote => _prefs.getString(AppConstants.keyPersonalNote) ?? '';
  Future<void> setPersonalNote(String note) async {
    await _prefs.setString(AppConstants.keyPersonalNote, note);
  }

  // --- Pending (in-progress) timer recovery ---

  Future<void> savePendingTimer({
    required String subjectId,
    required String subjectName,
    required String chapter,
    required String stage,
    String? notes,
    required DateTime startTime,
    required int elapsedSeconds,
    required String sessionId,
  }) async {
    await _prefs.setString(AppConstants.keyPendingTimerSubjectId, subjectId);
    await _prefs.setString(AppConstants.keyPendingTimerSubjectName, subjectName);
    await _prefs.setString(AppConstants.keyPendingTimerChapter, chapter);
    await _prefs.setString(AppConstants.keyPendingTimerStage, stage);
    if (notes != null) {
      await _prefs.setString(AppConstants.keyPendingTimerNotes, notes);
    } else {
      await _prefs.remove(AppConstants.keyPendingTimerNotes);
    }
    await _prefs.setString(
      AppConstants.keyPendingTimerStartTime,
      startTime.toIso8601String(),
    );
    await _prefs.setInt(AppConstants.keyPendingTimerElapsedSeconds, elapsedSeconds);
    await _prefs.setString(AppConstants.keyPendingTimerSessionId, sessionId);
  }

  /// Returns the leftover in-progress timer data, or null if there isn't
  /// one (the normal case — this only has data if the app was killed
  /// without a clean shutdown).
  Map<String, dynamic>? getPendingTimer() {
    final subjectId = _prefs.getString(AppConstants.keyPendingTimerSubjectId);
    final startTimeStr = _prefs.getString(AppConstants.keyPendingTimerStartTime);
    if (subjectId == null || startTimeStr == null) return null;

    return {
      'subjectId': subjectId,
      'subjectName': _prefs.getString(AppConstants.keyPendingTimerSubjectName) ?? '',
      'chapter': _prefs.getString(AppConstants.keyPendingTimerChapter) ?? '',
      'stage': _prefs.getString(AppConstants.keyPendingTimerStage) ?? 'Session',
      'notes': _prefs.getString(AppConstants.keyPendingTimerNotes),
      'startTime': DateTime.parse(startTimeStr),
      'elapsedSeconds': _prefs.getInt(AppConstants.keyPendingTimerElapsedSeconds) ?? 0,
      'sessionId': _prefs.getString(AppConstants.keyPendingTimerSessionId),
    };
  }

  Future<void> clearPendingTimer() async {
    await _prefs.remove(AppConstants.keyPendingTimerSubjectId);
    await _prefs.remove(AppConstants.keyPendingTimerSubjectName);
    await _prefs.remove(AppConstants.keyPendingTimerChapter);
    await _prefs.remove(AppConstants.keyPendingTimerStage);
    await _prefs.remove(AppConstants.keyPendingTimerNotes);
    await _prefs.remove(AppConstants.keyPendingTimerStartTime);
    await _prefs.remove(AppConstants.keyPendingTimerElapsedSeconds);
    await _prefs.remove(AppConstants.keyPendingTimerSessionId);
  }

  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
