class Recipient {
  const Recipient({
    this.contactId,
    this.displayName,
    this.phone,
    this.email,
  });

  final String? contactId;
  final String? displayName;
  final String? phone;
  final String? email;

  factory Recipient.fromJson(Map<String, dynamic> json) {
    return Recipient(
      contactId: json['contact_id'] as String?,
      displayName: json['display_name'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'contact_id': contactId,
        'display_name': displayName,
        'phone': phone,
        'email': email,
      };
}

class Clarification {
  const Clarification({
    required this.prompt,
    required this.reason,
    this.options = const [],
  });

  final String prompt;
  final String reason;
  final List<String> options;

  factory Clarification.fromJson(Map<String, dynamic> json) {
    return Clarification(
      prompt: json['prompt'] as String,
      reason: json['reason'] as String,
      options: (json['options'] as List<dynamic>? ?? []).cast<String>(),
    );
  }
}

class PlannedAction {
  PlannedAction({
    required this.id,
    required this.type,
    required this.status,
    required this.confirmation,
    this.title,
    this.notes,
    this.recipient,
    this.message,
    this.subject,
    this.startAt,
    this.endAt,
    this.scheduledFor,
    this.remindAt,
    this.query,
    this.mediaRefs = const [],
    this.dependsOn = const [],
    this.metadata = const {},
  });

  final String id;
  final String type;
  String status;
  final String confirmation;
  final String? title;
  final String? notes;
  final Recipient? recipient;
  final String? message;
  final String? subject;
  final String? startAt;
  final String? endAt;
  final String? scheduledFor;
  final String? remindAt;
  final String? query;
  final List<String> mediaRefs;
  final List<String> dependsOn;
  final Map<String, dynamic> metadata;

  factory PlannedAction.fromJson(Map<String, dynamic> json) {
    return PlannedAction(
      id: json['id'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      confirmation: json['confirmation'] as String,
      title: json['title'] as String?,
      notes: json['notes'] as String?,
      recipient: json['recipient'] == null
          ? null
          : Recipient.fromJson(json['recipient'] as Map<String, dynamic>),
      message: json['message'] as String?,
      subject: json['subject'] as String?,
      startAt: json['start_at'] as String?,
      endAt: json['end_at'] as String?,
      scheduledFor: json['scheduled_for'] as String?,
      remindAt: json['remind_at'] as String?,
      query: json['query'] as String?,
      mediaRefs: (json['media_refs'] as List<dynamic>? ?? []).cast<String>(),
      dependsOn: (json['depends_on'] as List<dynamic>? ?? []).cast<String>(),
      metadata: (json['metadata'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(key, value),
      ),
    );
  }

  PlannedAction copyWith({String? scheduledFor, bool clearSchedule = false}) {
    return PlannedAction(
      id: id,
      type: type,
      status: status,
      confirmation: confirmation,
      title: title,
      notes: notes,
      recipient: recipient,
      message: message,
      subject: subject,
      startAt: startAt,
      endAt: endAt,
      scheduledFor: clearSchedule ? null : (scheduledFor ?? this.scheduledFor),
      remindAt: remindAt,
      query: query,
      mediaRefs: mediaRefs,
      dependsOn: dependsOn,
      metadata: metadata,
    );
  }
}

class ActionPlan {
  ActionPlan({
    required this.schemaVersion,
    required this.planId,
    required this.originalText,
    required this.summary,
    required this.actions,
    required this.needsClarification,
    required this.confidence,
    this.clarification,
  });

  final String schemaVersion;
  final String planId;
  final String originalText;
  final String summary;
  final List<PlannedAction> actions;
  final bool needsClarification;
  final Clarification? clarification;
  final double confidence;

  factory ActionPlan.fromJson(Map<String, dynamic> json) {
    return ActionPlan(
      schemaVersion: json['schema_version'] as String,
      planId: json['plan_id'] as String,
      originalText: json['original_text'] as String,
      summary: json['summary'] as String,
      actions: (json['actions'] as List<dynamic>)
          .map((item) => PlannedAction.fromJson(item as Map<String, dynamic>))
          .toList(),
      needsClarification: json['needs_clarification'] as bool,
      clarification: json['clarification'] == null
          ? null
          : Clarification.fromJson(json['clarification'] as Map<String, dynamic>),
      confidence: (json['confidence'] as num).toDouble(),
    );
  }
}

const knownActionTypes = {
  'CREATE_REMINDER',
  'CREATE_TASK',
  'COMPLETE_TASK',
  'CREATE_CALENDAR_EVENT',
  'UPDATE_CALENDAR_EVENT',
  'DELETE_CALENDAR_EVENT',
  'QUERY_CALENDAR',
  'DRAFT_EMAIL',
  'SEND_EMAIL',
  'SEARCH_EMAIL',
  'CALL_CONTACT',
  'PREPARE_SMS',
  'PREPARE_WHATSAPP',
  'PREPARE_TELEGRAM',
  'SHARE_MEDIA',
  'SAVE_NOTE',
  'QUERY_TASKS',
  'QUERY_MEMORY',
};
