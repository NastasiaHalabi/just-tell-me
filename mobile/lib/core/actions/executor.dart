import 'package:url_launcher/url_launcher.dart';

import '../storage/local_store.dart';
import '../../integrations/contracts.dart';
import '../../integrations/messaging/whatsapp_handoff.dart';
import 'models.dart';

class ExecutionResult {
  const ExecutionResult({required this.status, required this.detail});

  final String status;
  final String detail;
}

/// Maps validated action enums to handlers. Never executes raw LLM text.
class ActionExecutor {
  ActionExecutor({
    required this.store,
    this.notifications,
    this.contacts,
    this.calendar,
    this.launch,
  });

  final LocalStore store;
  final NotificationScheduler? notifications;
  final ContactDirectory? contacts;
  final CalendarAdapter? calendar;
  final Future<bool> Function(Uri uri)? launch;

  Future<ExecutionResult> execute(PlannedAction action, {String? planId, bool forceNow = false}) async {
    switch (action.type) {
      case 'CREATE_REMINDER':
        return _createReminder(action, planId: planId);
      case 'CREATE_TASK':
        return _createTask(action, planId: planId);
      case 'COMPLETE_TASK':
        await store.completeMatching(action.title ?? action.notes ?? '');
        return const ExecutionResult(status: 'completed', detail: 'Matching open tasks were marked done on this device.');
      case 'SAVE_NOTE':
        await store.addTask(title: action.notes ?? action.title ?? 'Note');
        return const ExecutionResult(status: 'completed', detail: 'Note saved on this device.');
      case 'QUERY_TASKS':
        return _queryTasks();
      case 'QUERY_MEMORY':
        return _queryMemory(action);
      case 'QUERY_CALENDAR':
        return _queryCalendar(action);
      case 'CREATE_CALENDAR_EVENT':
        return _createCalendar(action);
      case 'UPDATE_CALENDAR_EVENT':
        return _updateCalendar(action);
      case 'DELETE_CALENDAR_EVENT':
        return _deleteCalendar(action);
      case 'DRAFT_EMAIL':
      case 'SEND_EMAIL':
        return _mailHandoff(action);
      case 'SEARCH_EMAIL':
        return const ExecutionResult(
          status: 'unsupported',
          detail: 'Gmail search needs a connected Google account. Connect it in Settings when OAuth is configured.',
        );
      case 'CALL_CONTACT':
        return _launch(
          Uri(scheme: 'tel', path: action.recipient?.phone ?? ''),
          fallbackName: action.recipient?.displayName ?? 'contact',
          kind: 'call',
        );
      case 'PREPARE_SMS':
        return _sms(action);
      case 'PREPARE_WHATSAPP':
        return _whatsapp(action, forceNow: forceNow);
      case 'PREPARE_TELEGRAM':
        return _telegram(action);
      case 'SHARE_MEDIA':
        return const ExecutionResult(
          status: 'handed_off',
          detail: 'Use the system share sheet to send the selected photo. Media stays on the device.',
        );
      default:
        return ExecutionResult(
          status: 'unsupported',
          detail: 'I cannot run ${action.type} yet.',
        );
    }
  }

  Future<ExecutionResult> _createTask(PlannedAction action, {String? planId}) async {
    final due = _parse(action.scheduledFor ?? action.remindAt);
    await store.addTask(
      title: action.title ?? 'Task',
      dueAt: due,
      reminderAt: due,
      sourcePlanId: planId,
    );
    return ExecutionResult(status: 'completed', detail: 'Task saved: ${action.title ?? 'Task'}');
  }

  Future<ExecutionResult> _createReminder(PlannedAction action, {String? planId}) async {
    final when = _parse(action.remindAt ?? action.scheduledFor);
    final task = await store.addTask(
      title: action.title ?? 'Reminder',
      dueAt: when,
      reminderAt: when,
      sourcePlanId: planId,
    );
    if (when == null) {
      return ExecutionResult(status: 'completed', detail: 'Reminder saved without a time: ${task.title}');
    }
    final permission = await notifications?.ensurePermission();
    if (permission != null && !permission.granted) {
      return ExecutionResult(status: 'completed', detail: permission.message);
    }
    final scheduled = await notifications?.schedule(
          id: task.id,
          title: task.title,
          when: when,
        ) ??
        false;
    if (!scheduled) {
      return ExecutionResult(
        status: 'completed',
        detail: 'Reminder saved on this device. A lock-screen alert could not be scheduled.',
      );
    }
    return ExecutionResult(status: 'scheduled', detail: 'Reminder scheduled for ${when.toLocal()}.');
  }

  Future<ExecutionResult> _queryTasks() async {
    final forgotten = await store.forgotten(DateTime.now());
    if (forgotten.isEmpty) {
      return const ExecutionResult(
        status: 'completed',
        detail: 'Nothing overdue or unscheduled is stored on this device. I will not invent extra to-dos.',
      );
    }
    final lines = forgotten.map((task) {
      final when = task.dueAt ?? task.reminderAt;
      return when == null ? '• ${task.title}' : '• ${task.title} (${when.toLocal()})';
    }).join('\n');
    return ExecutionResult(status: 'completed', detail: 'Open items on this device:\n$lines');
  }

  Future<ExecutionResult> _queryMemory(PlannedAction action) async {
    final items = await store.memory();
    if (items.isEmpty) {
      return const ExecutionResult(status: 'completed', detail: 'Memory is empty.');
    }
    final query = (action.query ?? '').toLowerCase();
    final matches = query.isEmpty
        ? items
        : items.where((item) => item.key.toLowerCase().contains(query) || item.value.toLowerCase().contains(query));
    if (matches.isEmpty) {
      return const ExecutionResult(status: 'completed', detail: 'No matching memory.');
    }
    return ExecutionResult(
      status: 'completed',
      detail: matches.map((item) => '${item.key} → ${item.value}').join('\n'),
    );
  }

  Future<ExecutionResult> _queryCalendar(PlannedAction action) async {
    if (calendar == null) {
      return const ExecutionResult(
        status: 'failed',
        detail: 'Calendar access is not wired on this device. No events were invented.',
      );
    }
    final permission = await calendar!.ensurePermission();
    if (!permission.granted) {
      return ExecutionResult(status: 'failed', detail: permission.message);
    }
    final day = _parse(action.scheduledFor) ?? DateTime.now();
    final events = await calendar!.queryDay(day);
    if (events.isEmpty) {
      return ExecutionResult(
        status: 'completed',
        detail: 'No events on ${day.toLocal().toString().split(' ').first} in calendars you allowed.',
      );
    }
    final lines = events.map((event) => '• ${event.startAt.hour.toString().padLeft(2, '0')}:${event.startAt.minute.toString().padLeft(2, '0')} ${event.title}').join('\n');
    return ExecutionResult(status: 'completed', detail: lines);
  }

  Future<ExecutionResult> _createCalendar(PlannedAction action) async {
    if (calendar == null) {
      return const ExecutionResult(status: 'failed', detail: 'Native calendar is not available. Nothing was created.');
    }
    final start = _parse(action.startAt);
    if (start == null) {
      return const ExecutionResult(status: 'failed', detail: 'I need a date and time before creating a calendar event.');
    }
    final permission = await calendar!.ensurePermission();
    if (!permission.granted) {
      return ExecutionResult(status: 'failed', detail: permission.message);
    }
    final eventId = await calendar!.createEvent(
      title: action.title ?? 'Event',
      startAt: start,
      endAt: _parse(action.endAt),
      notes: action.notes,
    );
    if (eventId == null) {
      return const ExecutionResult(status: 'failed', detail: 'The OS did not confirm the calendar event. It is not marked created.');
    }
    return ExecutionResult(status: 'completed', detail: 'Calendar event created: ${action.title}');
  }

  Future<ExecutionResult> _updateCalendar(PlannedAction action) async {
    if (calendar == null) {
      return const ExecutionResult(status: 'failed', detail: 'Native calendar is not available. Nothing was changed.');
    }
    final permission = await calendar!.ensurePermission();
    if (!permission.granted) {
      return ExecutionResult(status: 'failed', detail: permission.message);
    }
    final ok = await calendar!.updateEvent(
      query: action.title ?? action.notes ?? '',
      newStart: _parse(action.startAt),
    );
    if (!ok) {
      return const ExecutionResult(status: 'failed', detail: 'I could not find that event, so nothing was changed.');
    }
    return const ExecutionResult(status: 'completed', detail: 'Calendar event updated after OS confirmation.');
  }

  Future<ExecutionResult> _deleteCalendar(PlannedAction action) async {
    if (calendar == null) {
      return const ExecutionResult(status: 'failed', detail: 'Native calendar is not available. Nothing was deleted.');
    }
    final permission = await calendar!.ensurePermission();
    if (!permission.granted) {
      return ExecutionResult(status: 'failed', detail: permission.message);
    }
    final ok = await calendar!.deleteEvent(query: action.title ?? action.notes ?? '');
    if (!ok) {
      return const ExecutionResult(status: 'failed', detail: 'I could not find that event, so nothing was deleted.');
    }
    return const ExecutionResult(status: 'completed', detail: 'Calendar event deleted after OS confirmation.');
  }

  Future<ExecutionResult> _whatsapp(PlannedAction action, {bool forceNow = false}) async {
    final when = _parse(action.scheduledFor);
    if (!forceNow && when != null && when.isAfter(DateTime.now().add(const Duration(seconds: 1)))) {
      final who = action.recipient?.displayName ?? 'them';
      await store.addTask(
        title: 'Message $who: ${action.message ?? 'Hi'}',
        dueAt: when,
        reminderAt: when,
        sourcePlanId: action.id,
      );
      await notifications?.ensurePermission();
      await notifications?.schedule(
        id: 'wa-${action.id}',
        title: 'Time to message $who',
        when: when,
        body: action.message ?? 'Hi',
      );
      return ExecutionResult(
        status: 'scheduled',
        detail:
            'I’ll prompt you at ${when.toLocal().hour.toString().padLeft(2, '0')}:${when.toLocal().minute.toString().padLeft(2, '0')}:${when.toLocal().second.toString().padLeft(2, '0')} to send:\n“${action.message ?? 'Hi'}”\nWhatsApp will open then. It is not sent until you tap send.',
      );
    }
    final composed = action.message ?? 'Hi';
    final who = action.recipient?.displayName;
    final phone = await _resolveWhatsAppPhone(action.recipient);
    if (phone == null && who != null && await store.findAlias(who) != null) {
      return ExecutionResult(
        status: 'failed',
        detail:
            'I remember $who, but I don’t have a phone number for them yet, so I can’t open their WhatsApp chat.',
      );
    }
    final uri = whatsAppHandoffUri(text: composed, phone: phone);
    final launched = await _tryLaunch(uri);
    if (!launched) {
      return ExecutionResult(
        status: 'failed',
        detail: "WhatsApp couldn't be opened. Copy this instead:\n$composed",
      );
    }
    final chat = phone == null ? 'WhatsApp' : 'the WhatsApp chat with $who';
    return ExecutionResult(
      status: 'handed_off',
      detail: '$chat is open with “$composed”. It is not marked sent until you tap send.',
    );
  }

  Future<String?> _resolveWhatsAppPhone(Recipient? recipient) async {
    final fromPlan = whatsAppNumber(recipient?.phone);
    if (fromPlan != null) return fromPlan;

    final name = recipient?.displayName;
    if (name == null || name.trim().isEmpty) return null;

    final memory = await store.findAlias(name);
    final fromMemory = whatsAppNumber(memory?.phone);
    if (fromMemory != null) return fromMemory;

    if (contacts == null) return null;
    final queries = <String>{
      name,
      if (memory != null) memory.key,
      if (memory != null) memory.value,
    };
    for (final query in queries) {
      final found = await contacts!.search(query);
      if (memory?.contactId != null) {
        for (final contact in found) {
          if (contact.id == memory!.contactId) {
            return whatsAppNumber(contact.phone);
          }
        }
      }
      if (found.length == 1) {
        return whatsAppNumber(found.first.phone);
      }
      final exact = found.where((contact) => contact.displayName.toLowerCase() == query.toLowerCase());
      if (exact.length == 1) {
        return whatsAppNumber(exact.first.phone);
      }
    }
    return null;
  }

  Future<ExecutionResult> _telegram(PlannedAction action) async {
    final text = Uri.encodeComponent(action.message ?? '');
    final uri = Uri.parse('https://t.me/share/url?url=&text=$text');
    final launched = await _tryLaunch(uri);
    if (!launched) {
      return const ExecutionResult(
        status: 'failed',
        detail: "Telegram couldn't be opened. Your message is still ready to copy.",
      );
    }
    return const ExecutionResult(
      status: 'handed_off',
      detail: 'Telegram share is open. Not marked sent.',
    );
  }

  Future<ExecutionResult> _sms(PlannedAction action) async {
    final uri = Uri(
      scheme: 'sms',
      path: action.recipient?.phone ?? '',
      queryParameters: {'body': action.message ?? ''},
    );
    final launched = await _tryLaunch(uri);
    return ExecutionResult(
      status: launched ? 'handed_off' : 'failed',
      detail: launched
          ? 'Messages app is open with the draft. Not marked sent.'
          : 'Could not open Messages. The text is still ready to copy.',
    );
  }

  Future<ExecutionResult> _mailHandoff(PlannedAction action) async {
    final uri = Uri(
      scheme: 'mailto',
      path: action.recipient?.email ?? '',
      queryParameters: {
        if (action.subject != null) 'subject': action.subject!,
        if (action.message != null) 'body': action.message!,
      },
    );
    final launched = await _tryLaunch(uri);
    return ExecutionResult(
      status: launched ? 'handed_off' : 'failed',
      detail: launched
          ? 'Your mail app has the draft. Gmail API send is not connected, so this is not marked sent.'
          : 'Could not open mail. The draft is still on screen.',
    );
  }

  Future<ExecutionResult> _launch(Uri uri, {required String fallbackName, required String kind}) async {
    if (uri.path.isEmpty) {
      return ExecutionResult(
        status: 'failed',
        detail: 'I need a phone number to $kind $fallbackName.',
      );
    }
    final launched = await _tryLaunch(uri);
    return ExecutionResult(
      status: launched ? 'handed_off' : 'failed',
      detail: launched
          ? 'Phone app opened. The call is not marked completed until the OS handles it.'
          : 'Could not open the phone app.',
    );
  }

  Future<bool> _tryLaunch(Uri uri) async {
    try {
      if (launch != null) return await launch!(uri);
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  DateTime? _parse(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}
