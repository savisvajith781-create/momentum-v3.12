import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/core_providers.dart';

class PersonalNoteNotifier extends StateNotifier<String> {
  final Ref _ref;

  PersonalNoteNotifier(this._ref)
      : super(_ref.read(settingsServiceProvider).personalNote);

  Future<void> setNote(String note) async {
    state = note;
    await _ref.read(settingsServiceProvider).setPersonalNote(note);
  }
}

final personalNoteProvider =
    StateNotifierProvider<PersonalNoteNotifier, String>((ref) {
  return PersonalNoteNotifier(ref);
});
