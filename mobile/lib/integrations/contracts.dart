class PermissionOutcome {
  const PermissionOutcome({
    required this.granted,
    required this.message,
  });

  final bool granted;
  final String message;
}

class DeviceContact {
  const DeviceContact({
    required this.id,
    required this.displayName,
    this.phone,
    this.email,
    this.aliases = const [],
  });

  final String id;
  final String displayName;
  final String? phone;
  final String? email;
  final List<String> aliases;

  Map<String, dynamic> toPlannerJson() => {
        'contact_id': id,
        'display_name': displayName,
        'phone': phone,
        'email': email,
        'aliases': aliases,
      };
}

abstract class ContactDirectory {
  Future<PermissionOutcome> ensurePermission();
  Future<List<DeviceContact>> search(String query);
}

class CalendarEventSummary {
  const CalendarEventSummary({
    required this.id,
    required this.title,
    required this.startAt,
    this.endAt,
  });

  final String id;
  final String title;
  final DateTime startAt;
  final DateTime? endAt;
}

abstract class CalendarAdapter {
  Future<PermissionOutcome> ensurePermission();
  Future<String?> createEvent({
    required String title,
    required DateTime startAt,
    DateTime? endAt,
    String? notes,
  });
  Future<bool> updateEvent({
    required String query,
    required DateTime? newStart,
  });
  Future<bool> deleteEvent({required String query});
  Future<List<CalendarEventSummary>> queryDay(DateTime day);
}

abstract class NotificationScheduler {
  Future<PermissionOutcome> ensurePermission();
  Future<bool> schedule({
    required String id,
    required String title,
    required DateTime when,
    String? body,
  });
  Future<void> cancel(String id);
}
