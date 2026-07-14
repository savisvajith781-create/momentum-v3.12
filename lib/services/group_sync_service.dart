import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/group_member_model.dart';

/// Talks to Google Firestore's plain REST API (no native SDK/plugin),
/// so this never touches Windows-native build tooling. Requires the
/// person to create their own free Firebase project and paste in the
/// Project ID + Web API Key via Settings.
class GroupSyncService {
  static const _baseUrl = 'https://firestore.googleapis.com/v1/projects';

  String _docUrl({
    required String projectId,
    required String apiKey,
    required String groupCode,
    String? memberId,
  }) {
    final path = memberId != null
        ? 'groups/$groupCode/members/$memberId'
        : 'groups/$groupCode/members';
    return '$_baseUrl/$projectId/databases/(default)/documents/$path?key=$apiKey';
  }

  /// Pushes this device's current status up to the shared group document.
  Future<bool> pushStatus({
    required String projectId,
    required String apiKey,
    required String groupCode,
    required String memberId,
    required GroupMemberModel status,
  }) async {
    try {
      final url = _docUrl(
        projectId: projectId,
        apiKey: apiKey,
        groupCode: groupCode,
        memberId: memberId,
      );

      final fields = <String, dynamic>{
        'name': {'stringValue': status.name},
        'hoursTodaySeconds': {'integerValue': status.hoursTodaySeconds.toString()},
        'isActive': {'booleanValue': status.isActive},
        'lastUpdated': {'stringValue': status.lastUpdated.toIso8601String()},
      };
      if (status.currentSubject != null) {
        fields['currentSubject'] = {'stringValue': status.currentSubject};
      } else {
        fields['currentSubject'] = {'nullValue': null};
      }

      final response = await http.patch(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'fields': fields}),
      );

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Fetches every member's latest status in the given group.
  Future<List<GroupMemberModel>> fetchGroupMembers({
    required String projectId,
    required String apiKey,
    required String groupCode,
  }) async {
    try {
      final url = _docUrl(
        projectId: projectId,
        apiKey: apiKey,
        groupCode: groupCode,
      );

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return [];

      final data = json.decode(response.body) as Map<String, dynamic>;
      final documents = data['documents'] as List<dynamic>? ?? [];

      return documents.map((doc) {
        final docMap = doc as Map<String, dynamic>;
        final name = docMap['name'] as String; // full resource path
        final memberId = name.split('/').last;
        final fields = docMap['fields'] as Map<String, dynamic>? ?? {};

        return GroupMemberModel.fromJson(memberId, {
          'name': fields['name']?['stringValue'],
          'hoursTodaySeconds':
              int.tryParse(fields['hoursTodaySeconds']?['integerValue']?.toString() ?? '0') ?? 0,
          'isActive': fields['isActive']?['booleanValue'] ?? false,
          'currentSubject': fields['currentSubject']?['stringValue'],
          'lastUpdated': fields['lastUpdated']?['stringValue'],
        });
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Simple connectivity/credentials check — tries to read the group's
  /// member list; if the request completes without throwing, the
  /// Project ID and API Key are valid and Firestore is reachable.
  Future<bool> verifyCredentials({
    required String projectId,
    required String apiKey,
  }) async {
    try {
      final url =
          '$_baseUrl/$projectId/databases/(default)/documents/groups?key=$apiKey';
      final response = await http.get(Uri.parse(url));
      // 200 = success, 404 with a well-formed Firestore error = still valid
      // credentials, just an empty/nonexistent collection.
      return response.statusCode == 200 || response.statusCode == 404;
    } catch (_) {
      return false;
    }
  }
}
