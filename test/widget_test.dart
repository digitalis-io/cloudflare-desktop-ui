import 'dart:convert';

import 'package:cloudflare_dns/cloudflare_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('zones sorted and paginated', () async {
    final client = MockClient((req) async {
      final page = int.parse(req.url.queryParameters['page']!);
      expect(req.headers['Authorization'], 'Bearer t');
      return http.Response(
        jsonEncode({
          'success': true,
          'result': [
            {'id': '$page', 'name': page == 1 ? 'b.com' : 'a.com'}
          ],
          'result_info': {'total_pages': 2},
        }),
        200,
      );
    });
    final zones = await CloudflareApi('t', client: client).zones();
    expect(zones.map((z) => z.name), ['a.com', 'b.com']);
  });

  test('api error surfaces message', () async {
    final client = MockClient((_) async => http.Response(
        jsonEncode({
          'success': false,
          'errors': [
            {'message': 'Invalid token'}
          ]
        }),
        403));
    expect(CloudflareApi('t', client: client).zones(),
        throwsA(isA<CloudflareException>()));
  });

  test('missing token fails fast', () {
    expect(CloudflareApi('').zones(), throwsA(isA<CloudflareException>()));
  });
}
