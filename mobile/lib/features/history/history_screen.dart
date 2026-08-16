import 'package:flutter/material.dart';

import '../../core/storage/local_store.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _store = LocalStore();
  List<HistoryItem> _items = [];

  @override
  void initState() {
    super.initState();
    _store.history().then((items) {
      if (mounted) setState(() => _items = items);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Action history')),
      body: _items.isEmpty
          ? const Center(child: Text('No history yet.'))
          : ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _items[index];
                return ListTile(
                  title: Text(item.utterance),
                  subtitle: Text('${item.status}\n${item.summary}'),
                  isThreeLine: true,
                  trailing: Text(
                    '${item.timestamp.hour.toString().padLeft(2, '0')}:${item.timestamp.minute.toString().padLeft(2, '0')}',
                  ),
                );
              },
            ),
    );
  }
}
