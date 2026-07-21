import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Lightweight PostHog-compatible analytics client.
/// No-ops when [apiKey] is empty.
class AnalyticsService {
  AnalyticsService({
    required this.apiKey,
    this.host = 'https://app.posthog.com',
    this.debug = false,
    this.appName = 'receipt24',
  });

  final String apiKey;
  final String host;
  final bool debug;
  final String appName;

  String? _distinctId;

  bool get isEnabled => apiKey.isNotEmpty;

  void identify(String userId, {Map<String, Object?>? traits}) {
    _distinctId = userId;
    if (!isEnabled) return;
    _capture('\$identify', {
      '\$set': traits ?? {},
      'distinct_id': userId,
    });
  }

  void track(String event, {Map<String, Object?>? properties}) {
    if (!isEnabled) {
      if (debug) {
        debugPrint('[analytics] $event ${properties ?? {}}');
      }
      return;
    }
    _capture(event, {
      ...?properties,
      'app': appName,
    });
  }

  void screen(String screenName, {Map<String, Object?>? properties}) {
    track('\$screen', {
      'screen_name': screenName,
      ...?properties,
    });
  }

  void reset() {
    _distinctId = null;
  }

  void _capture(String event, Map<String, Object?> properties) {
    final uri = Uri.parse('$host/capture/');
    final body = jsonEncode({
      'api_key': apiKey,
      'event': event,
      'properties': {
        ...properties,
        if (_distinctId != null) 'distinct_id': _distinctId,
      },
    });

    http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    ).catchError((Object e) {
      if (debug) debugPrint('[analytics] capture failed: $e');
      return http.Response('', 500);
    });
  }
}
