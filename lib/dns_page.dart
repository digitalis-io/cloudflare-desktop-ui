import 'package:flutter/material.dart';

import 'cloudflare_api.dart';

class DnsPage extends StatefulWidget {
  const DnsPage({super.key, required this.api});
  final CloudflareApi api;

  @override
  State<DnsPage> createState() => _DnsPageState();
}

class _DnsPageState extends State<DnsPage> {
  List<Zone> _zones = [];
  Zone? _zone;
  List<DnsRecord> _records = [];
  String _query = '';
  bool _loading = false;
  String? _error;
  int _loadSeq = 0;

  @override
  void initState() {
    super.initState();
    _loadZones();
  }

  Future<void> _loadZones() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final zones = await widget.api.zones();
      if (!mounted) return;
      setState(() => _zones = zones);
      if (zones.isNotEmpty) await _selectZone(zones.first);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectZone(Zone zone) async {
    final seq = ++_loadSeq;
    setState(() {
      _zone = zone;
      _records = [];
      _loading = true;
      _error = null;
    });
    try {
      final records = await widget.api.records(zone.id);
      if (mounted && seq == _loadSeq) setState(() => _records = records);
    } catch (e) {
      if (mounted && seq == _loadSeq) setState(() => _error = '$e');
    } finally {
      if (mounted && seq == _loadSeq) setState(() => _loading = false);
    }
  }

  List<DnsRecord> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _records;
    return _records
        .where(
          (r) =>
              r.name.toLowerCase().contains(q) ||
              r.type.toLowerCase().contains(q) ||
              r.content.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final rows = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.cloud),
            SizedBox(width: 8),
            Text('Cloudflare DNS'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<Zone>(
                    key: ValueKey(_zones.length),
                    initialValue: _zone,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Zone',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final z in _zones)
                        DropdownMenuItem(value: z, child: Text(z.name)),
                    ],
                    onChanged: (z) => z == null ? null : _selectZone(z),
                  ),
                ),
                IconButton(
                  tooltip: 'Reload',
                  icon: const Icon(Icons.refresh),
                  onPressed: _loading
                      ? null
                      : () =>
                            _zone == null ? _loadZones() : _selectZone(_zone!),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search name, type or content',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            if (_loading) const LinearProgressIndicator(),
            const SizedBox(height: 12),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            Expanded(
              child: Card(
                child: Column(
                  children: [
                    const _Row(
                      type: 'Type',
                      name: 'Name',
                      content: 'Content',
                      ttl: 'TTL',
                      proxy: 'Proxy',
                      header: true,
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.separated(
                        itemCount: rows.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final r = rows[i];
                          return _Row(
                            type: r.type,
                            name: r.name,
                            content: r.content,
                            ttl: r.ttl == 1 ? 'Auto' : '${r.ttl}',
                            proxy: r.proxied ? 'Proxied' : 'DNS only',
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('${rows.length} of ${_records.length} records'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.type,
    required this.name,
    required this.content,
    required this.ttl,
    required this.proxy,
    this.header = false,
  });
  final String type, name, content, ttl, proxy;
  final bool header;

  @override
  Widget build(BuildContext context) {
    final style = header ? const TextStyle(fontWeight: FontWeight.bold) : null;
    Widget text(String t) => SelectableText(t, style: style, maxLines: 2);
    Widget cell(String t, int flex) => Expanded(flex: flex, child: text(t));
    Widget fixed(String t, double w) => SizedBox(width: w, child: text(t));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          fixed(type, 90),
          cell(name, 4),
          cell(content, 6),
          fixed(ttl, 70),
          fixed(proxy, 100),
        ],
      ),
    );
  }
}
