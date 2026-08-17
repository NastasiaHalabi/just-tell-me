import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../actions/models.dart';

class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class JustTellMeApi {
  JustTellMeApi({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://192.168.10.118:8080',
            );

  static const _prefsKey = 'api_base_url';

  final http.Client _client;
  String baseUrl;

  Future<void> loadSavedUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null && saved.trim().isNotEmpty) {
      baseUrl = saved.trim();
    }
  }

  Future<void> saveBaseUrl(String url) async {
    baseUrl = url.trim().replaceAll(RegExp(r'/$'), '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, baseUrl);
  }

  Future<bool> health() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<ActionPlan> createPlan({
    required String text,
    required DateTime localNow,
    String timezone = 'Asia/Beirut',
    List<Map<String, dynamic>> candidateContacts = const [],
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/v1/plan'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'text': text,
        'client_local_datetime': localNow.toIso8601String(),
        'timezone': timezone,
        'locale_hints': ['en', 'ar-LB'],
        'context': {
          'candidate_contacts': candidateContacts,
          'relevant_events': <Map<String, dynamic>>[],
        },
      }),
    );
    if (response.statusCode != 200) {
      throw ApiException('Planner is unavailable (${response.statusCode}).');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final plan = ActionPlan.fromJson(json);
    for (final action in plan.actions) {
      if (!knownActionTypes.contains(action.type)) {
        throw ApiException('Unknown action type was rejected: ${action.type}');
      }
    }
    return plan;
  }
}
