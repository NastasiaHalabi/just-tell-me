import 'package:flutter/material.dart';

import '../../core/storage/local_store.dart';

class MemoryScreen extends StatefulWidget {
  const MemoryScreen({super.key});

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  final _store = LocalStore();
  final _key = TextEditingController();
  final _value = TextEditingController();
  List<MemoryItem> _items = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final items = await _store.memory();
    if (mounted) setState(() => _items = items);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Memory')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Aliases and preferences you approve. Editable and deletable.'),
          const SizedBox(height: 12),
          TextField(controller: _key, decoration: const InputDecoration(labelText: 'Phrase (mama, my boss)')),
          TextField(controller: _value, decoration: const InputDecoration(labelText: 'Meaning')),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () async {
              if (_key.text.trim().isEmpty || _value.text.trim().isEmpty) return;
              await _store.upsertMemory(MemoryItem(key: _key.text.trim(), value: _value.text.trim()));
              _key.clear();
              _value.clear();
              await _reload();
            },
            child: const Text('Save memory'),
          ),
          const SizedBox(height: 16),
          ..._items.map(
            (item) => ListTile(
              title: Text(item.key),
              subtitle: Text(item.value),
              trailing: IconButton(
                tooltip: 'Delete memory',
                onPressed: () async {
                  await _store.deleteMemory(item.key);
                  await _reload();
                },
                icon: const Icon(Icons.delete_outline),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _key.dispose();
    _value.dispose();
    super.dispose();
  }
}
