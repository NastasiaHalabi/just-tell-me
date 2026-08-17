import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:just_tell_me/core/actions/executor.dart';
import 'package:just_tell_me/core/actions/models.dart';
import 'package:just_tell_me/core/storage/local_store.dart';
import 'package:just_tell_me/integrations/contracts.dart';

class FakeNotifications implements NotificationScheduler {
  bool scheduled = false;

  @override
  Future<PermissionOutcome> ensurePermission() async {
    return const PermissionOutcome(granted: true, message: 'ok');
  }

  @override
  Future<bool> schedule({
    required String id,
    required String title,
    required DateTime when,
    String? body,
  }) async {
    scheduled = true;
    return true;
  }

  @override
  Future<void> cancel(String id) async {}
}

class DeniedCalendar implements CalendarAdapter {
  @override
  Future<PermissionOutcome> ensurePermission() async {
    return const PermissionOutcome(granted: false, message: 'Calendar permission is required.');
  }

  @override
  Future<String?> createEvent({
    required String title,
    required DateTime startAt,
    DateTime? endAt,
    String? notes,
  }) async =>
      null;

  @override
  Future<bool> deleteEvent({required String query}) async => false;

  @override
  Future<List<CalendarEventSummary>> queryDay(DateTime day) async => [];

  @override
  Future<bool> updateEvent({required String query, required DateTime? newStart}) async => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('forgotten tasks come only from stored items', () async {
    final store = LocalStore();
    await store.addTask(title: 'Buy shampoo', dueAt: DateTime.now().subtract(const Duration(hours: 1)));
    await store.addTask(title: 'Future thing', dueAt: DateTime.now().add(const Duration(days: 2)));
    final forgotten = await store.forgotten(DateTime.now());
    expect(forgotten.map((task) => task.title), ['Buy shampoo']);
  });

  test('reminder schedules a local notification after save', () async {
    final store = LocalStore();
    final notifications = FakeNotifications();
    final executor = ActionExecutor(store: store, notifications: notifications);
    final result = await executor.execute(
      PlannedAction(
        id: 'a1',
        type: 'CREATE_REMINDER',
        status: 'planned',
        confirmation: 'auto',
        title: 'Pick up the car',
        remindAt: DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
      ),
    );
    expect(result.status, 'scheduled');
    expect(notifications.scheduled, isTrue);
    expect((await store.tasks()).single.title, 'Pick up the car');
  });

  test('denied calendar permission does not report created', () async {
    final executor = ActionExecutor(
      store: LocalStore(),
      calendar: DeniedCalendar(),
    );
    final result = await executor.execute(
      PlannedAction(
        id: 'a1',
        type: 'CREATE_CALENDAR_EVENT',
        status: 'planned',
        confirmation: 'auto',
        title: 'Session with Maya',
        startAt: DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      ),
    );
    expect(result.status, 'failed');
    expect(result.detail.toLowerCase(), contains('permission'));
  });

  test('open tasks can be deleted and edited', () async {
    final store = LocalStore();
    final task = await store.addTask(
      title: 'Message Maya',
      dueAt: DateTime.now().add(const Duration(hours: 2)),
    );
    await store.updateTask(task.copyWith(title: 'Message Maya about the session'));
    expect((await store.upcoming(DateTime.now())).single.title, 'Message Maya about the session');
    await store.deleteTask(task.id);
    expect(await store.upcoming(DateTime.now()), isEmpty);
  });

  test('recent history can be deleted', () async {
    final store = LocalStore();
    final item = HistoryItem(
      utterance: 'Remind me later',
      summary: 'Reminder',
      status: 'completed',
      timestamp: DateTime.now(),
    );
    await store.addHistory(item);
    expect((await store.history()).single.utterance, 'Remind me later');
    await store.deleteHistory(item.id);
    expect(await store.history(), isEmpty);
  });
}
