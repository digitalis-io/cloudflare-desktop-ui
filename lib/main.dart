import 'package:flutter/material.dart';

import 'cloudflare_api.dart';
import 'dns_page.dart';

void main() => runApp(const CloudflareDnsApp());

class CloudflareDnsApp extends StatelessWidget {
  const CloudflareDnsApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Cloudflare DNS',
    theme: ThemeData(colorSchemeSeed: Colors.orange, useMaterial3: true),
    darkTheme: ThemeData(
      colorSchemeSeed: Colors.orange,
      brightness: Brightness.dark,
      useMaterial3: true,
    ),
    home: DnsPage(api: CloudflareApi.fromEnv()),
  );
}
