import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class HistoryItem {
  HistoryItem({
    required this.utterance,
    required this.summary,
    required this.status,
    required this.timestamp,
    this.error,
  });

  final String utterance;
  final String summary;
  final String status;
  final DateTime timestamp;
  final String? error;

  Map<String, dynamic> toJson() => {
        'utterance': utterance,
        'summary': summary,
        'status': status,
        'timestamp': timestamp.toIso8601String(),
        'error': error,
      };

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      utterance: json['utterance'] as String,
      summary: json['summary'] as String,
      status: json['status'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      error: json['error'] as String?,
    );
  }
}

class MemoryItem {
  MemoryItem({
    required this.key,
    required this.value,
    this.contactId,
    this.preferredChannel,
  });

  final String key;
  final String value;
  final String? contactId;
  final String? preferredChannel;

  Map<String, dynamic> toJson() => {
        'key': key,
        'value': value,
        'contact_id': contactId,
        'preferred_channel': preferredChannel,
      };

  factory MemoryItem.fromJson(Map<String, dynamic> json) {
    return MemoryItem(
      key: json['key'] as String,
      value: json['value'] as String,
      contactId: json['contact_id'] as String?,
      preferredChannel: json['preferred_channel'] as String?,
    );
  }
}

class LocalTask {
  LocalTask({
    required this.id,
    required this.title,
    this.dueAt,
    this.reminderAt,
    this.status = 'open',
    this.sourcePlanId,
    this.recurrence,
  });

  final String id;
  final String title;
  final DateTime? dueAt;
  final DateTime? reminderAt;
  final String status;
  final String? sourcePlanId;
  final String? recurrence;

  bool get isOpen => status == 'open';

  bool isForgotten(DateTime now) {
    if (!isOpen) return false;
    final when = dueAt ?? reminderAt;
    if (when == null) return false;
    return !when.isAfter(now);
  }

  bool isUpcoming(DateTime now) {
    if (!isOpen) return false;
    final when = dueAt ?? reminderAt;
    return when != null && when.isAfter(now);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'due_at': dueAt?.toIso8601String(),
        'reminder_at': reminderAt?.toIso8601String(),
        'status': status,
        'source_plan_id': sourcePlanId,
        'recurrence': recurrence,
      };

  factory LocalTask.fromJson(Map<String, dynamic> json) {
    return LocalTask(
      id: json['id'] as String? ?? const Uuid().v4(),
      title: json['title'] as String? ?? '',
      dueAt: json['due_at'] == null ? null : DateTime.tryParse(json['due_at'] as String),
      reminderAt: json['reminder_at'] == null ? null : DateTime.tryParse(json['reminder_at'] as String),
      status: json['status'] as String? ?? 'open',
      sourcePlanId: json['source_plan_id'] as String?,
      recurrence: json['recurrence'] as String?,
    );
  }

  LocalTask copyWith({String? status}) {
    return LocalTask(
      id: id,
      title: title,
      dueAt: dueAt,
      reminderAt: reminderAt,
      status: status ?? this.status,
      sourcePlanId: sourcePlanId,
      recurrence: recurrence,
    );
  }
}

class LocalStore {
  static const _historyKey = 'local_history';
  static const _memoryKey = 'memory_items';
  static const _tasksKey = 'local_tasks';

  Future<List<HistoryItem>> history() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_historyKey) ?? [];
    return raw.map((row) => HistoryItem.fromJson(jsonDecode(row) as Map<String, dynamic>)).toList();
  }

  Future<void> addHistory(HistoryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_historyKey) ?? [];
    current.insert(0, jsonEncode(item.toJson()));
    await prefs.setStringList(_historyKey, current.take(100).toList());
  }

  Future<List<MemoryItem>> memory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_memoryKey) ?? [];
    return raw.map((row) => MemoryItem.fromJson(jsonDecode(row) as Map<String, dynamic>)).toList();
  }

  Future<void> upsertMemory(MemoryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await memory();
    items.removeWhere((row) => row.key.toLowerCase() == item.key.toLowerCase());
    items.add(item);
    await prefs.setStringList(_memoryKey, items.map((row) => jsonEncode(row.toJson())).toList());
  }

  Future<void> deleteMemory(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await memory();
    items.removeWhere((row) => row.key == key);
    await prefs.setStringList(_memoryKey, items.map((row) => jsonEncode(row.toJson())).toList());
  }

  Future<MemoryItem?> findAlias(String phrase) async {
    final needle = phrase.toLowerCase();
    final items = await memory();
    for (final item in items) {
      if (item.key.toLowerCase() == needle) return item;
    }
    return null;
  }

  Future<LocalTask> addTask({
    required String title,
    DateTime? dueAt,
    DateTime? reminderAt,
    String? sourcePlanId,
    String? recurrence,
  }) async {
    final task = LocalTask(
      id: const Uuid().v4(),
      title: title,
      dueAt: dueAt,
      reminderAt: reminderAt,
      sourcePlanId: sourcePlanId,
      recurrence: recurrence,
    );
    final items = await tasks();
    items.insert(0, task);
    await _saveTasks(items);
    return task;
  }

  Future<List<LocalTask>> tasks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_tasksKey) ?? [];
    return raw.map((row) {
      final json = jsonDecode(row) as Map<String, dynamic>;
      if (json.containsKey('id')) {
        return LocalTask.fromJson(json);
      }
      return LocalTask(
        id: const Uuid().v4(),
        title: json['title'] as String? ?? '',
        dueAt: json['due_at'] == null ? null : DateTime.tryParse(json['due_at'] as String),
      );
    }).toList();
  }

  Future<void> completeMatching(String titleQuery) async {
    final needle = titleQuery.toLowerCase();
    final items = await tasks();
    final updated = items
        .map((task) => task.title.toLowerCase().contains(needle) ? task.copyWith(status: 'done') : task)
        .toList();
    await _saveTasks(updated);
  }

  Future<List<LocalTask>> forgotten(DateTime now) async {
    final items = await tasks();
    return items.where((task) => task.isForgotten(now)).toList();
  }

  Future<List<LocalTask>> upcoming(DateTime now) async {
    final items = await tasks();
    return items.where((task) => task.isUpcoming(now)).toList();
  }

  Future<void> _saveTasks(List<LocalTask> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_tasksKey, items.map((task) => jsonEncode(task.toJson())).toList());
  }
}
