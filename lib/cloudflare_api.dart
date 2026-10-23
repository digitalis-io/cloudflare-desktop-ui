import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class Zone {
  Zone(this.id, this.name);
  final String id;
  final String name;
}

class DnsRecord {
  DnsRecord({
    required this.type,
    required this.name,
    required this.content,
    required this.ttl,
    required this.proxied,
  });

  factory DnsRecord.fromJson(Map<String, dynamic> j) => DnsRecord(
    type: j['type'] as String,
    name: j['name'] as String,
    content: (j['content'] ?? '') as String,
    ttl: j['ttl'] as int,
    proxied: (j['proxied'] ?? false) as bool,
  );

  final String type;
  final String name;
  final String content;
  final int ttl; // 1 = automatic
  final bool proxied;
}

class CloudflareException implements Exception {
  CloudflareException(this.message);
  final String message;
  @override
  String toString() => message;
}

class CloudflareApi {
  CloudflareApi(this.token, {http.Client? client})
    : _client = client ?? http.Client();

  factory CloudflareApi.fromEnv() =>
      CloudflareApi(Platform.environment['CLOUDFLARE_API_TOKEN'] ?? '');

  static const _base = 'https://api.cloudflare.com/client/v4';
  final String token;
  final http.Client _client;

  Future<List<Zone>> zones() async {
    final items = await _paged('/zones', {});
    return items
        .map((j) => Zone(j['id'] as String, j['name'] as String))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<List<DnsRecord>> records(String zoneId) async {
    final items = await _paged('/zones/$zoneId/dns_records', {});
    return items.map(DnsRecord.fromJson).toList();
  }

  Future<List<Map<String, dynamic>>> _paged(
    String path,
    Map<String, String> query,
  ) async {
    if (token.isEmpty) {
      throw CloudflareException('CLOUDFLARE_API_TOKEN is not set');
    }
    final out = <Map<String, dynamic>>[];
    for (var page = 1; ; page++) {
      final uri = Uri.parse('$_base$path').replace(
        queryParameters: {...query, 'page': '$page', 'per_page': '100'},
      );
      final res = await _client
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 30));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode != 200 || body['success'] != true) {
        final errors =
            (body['errors'] as List?)
                ?.map((e) => (e as Map)['message'])
                .join('; ') ??
            'HTTP ${res.statusCode}';
        throw CloudflareException(errors);
      }
      out.addAll((body['result'] as List).cast<Map<String, dynamic>>());
      final info = body['result_info'] as Map<String, dynamic>?;
      if (info == null || page >= (info['total_pages'] as int? ?? 1)) break;
    }
    return out;
  }
}
