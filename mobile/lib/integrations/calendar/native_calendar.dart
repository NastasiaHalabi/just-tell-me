import 'package:device_calendar/device_calendar.dart';

import '../contracts.dart';

class NativeCalendarAdapter implements CalendarAdapter {
  NativeCalendarAdapter({DeviceCalendarPlugin? plugin}) : _plugin = plugin ?? DeviceCalendarPlugin();

  final DeviceCalendarPlugin _plugin;

  @override
  Future<PermissionOutcome> ensurePermission() async {
    try {
      var permissions = await _plugin.hasPermissions();
      if (permissions.isSuccess && permissions.data == true) {
        return const PermissionOutcome(granted: true, message: 'Calendar allowed.');
      }
      permissions = await _plugin.requestPermissions();
      final granted = permissions.isSuccess && permissions.data == true;
      if (!granted) {
        return const PermissionOutcome(
          granted: false,
          message: 'Calendar permission is required. I did not create or change any event.',
        );
      }
      return const PermissionOutcome(granted: true, message: 'Calendar allowed.');
    } catch (_) {
      return const PermissionOutcome(
        granted: false,
        message: 'Native calendar is not available on this device yet. Nothing was created.',
      );
    }
  }

  Future<String?> _writableCalendarId() async {
    final calendars = await _plugin.retrieveCalendars();
    if (!calendars.isSuccess || calendars.data == null) return null;
    for (final calendar in calendars.data!) {
      if (calendar.isReadOnly == false && calendar.id != null) {
        return calendar.id;
      }
    }
    return calendars.data!.isEmpty ? null : calendars.data!.first.id;
  }

  @override
  Future<String?> createEvent({
    required String title,
    required DateTime startAt,
    DateTime? endAt,
    String? notes,
  }) async {
    final permission = await ensurePermission();
    if (!permission.granted) return null;
    final calendarId = await _writableCalendarId();
    if (calendarId == null) return null;
    final event = Event(
      calendarId,
      title: title,
      description: notes,
      start: TZDateTime.from(startAt, local),
      end: TZDateTime.from(endAt ?? startAt.add(const Duration(hours: 1)), local),
    );
    final result = await _plugin.createOrUpdateEvent(event);
    if (result == null || !result.isSuccess) return null;
    return result.data;
  }

  @override
  Future<List<CalendarEventSummary>> queryDay(DateTime day) async {
    final permission = await ensurePermission();
    if (!permission.granted) return [];
    final calendars = await _plugin.retrieveCalendars();
    if (!calendars.isSuccess || calendars.data == null) return [];
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final events = <CalendarEventSummary>[];
    for (final calendar in calendars.data!) {
      if (calendar.id == null) continue;
      final result = await _plugin.retrieveEvents(
        calendar.id,
        RetrieveEventsParams(startDate: start, endDate: end),
      );
      if (!result.isSuccess || result.data == null) continue;
      for (final event in result.data!) {
        final when = event.start;
        if (when == null) continue;
        events.add(
          CalendarEventSummary(
            id: event.eventId ?? '',
            title: event.title ?? 'Untitled',
            startAt: when,
            endAt: event.end,
          ),
        );
      }
    }
    events.sort((a, b) => a.startAt.compareTo(b.startAt));
    return events;
  }

  @override
  Future<bool> updateEvent({required String query, required DateTime? newStart}) async {
    final permission = await ensurePermission();
    if (!permission.granted || newStart == null) return false;
    final match = await _find(query);
    if (match == null) return false;
    match.start = TZDateTime.from(newStart, local);
    if (match.end != null) {
      match.end = TZDateTime.from(newStart.add(const Duration(hours: 1)), local);
    }
    final result = await _plugin.createOrUpdateEvent(match);
    return result != null && result.isSuccess;
  }

  @override
  Future<bool> deleteEvent({required String query}) async {
    final permission = await ensurePermission();
    if (!permission.granted) return false;
    final match = await _find(query);
    if (match == null || match.calendarId == null || match.eventId == null) return false;
    final result = await _plugin.deleteEvent(match.calendarId, match.eventId);
    return result.isSuccess && result.data == true;
  }

  Future<Event?> _find(String query) async {
    final needle = query.toLowerCase();
    final calendars = await _plugin.retrieveCalendars();
    if (!calendars.isSuccess || calendars.data == null) return null;
    final start = DateTime.now().subtract(const Duration(days: 7));
    final end = DateTime.now().add(const Duration(days: 30));
    for (final calendar in calendars.data!) {
      if (calendar.id == null) continue;
      final result = await _plugin.retrieveEvents(
        calendar.id,
        RetrieveEventsParams(startDate: start, endDate: end),
      );
      if (!result.isSuccess || result.data == null) continue;
      for (final event in result.data!) {
        final title = (event.title ?? '').toLowerCase();
        if (title.contains(needle) || needle.contains(title)) {
          return event;
        }
      }
    }
    return null;
  }
}
