import 'models.dart';

const _rank = {'auto': 0, 'confirm': 1, 'handoff': 2};

const defaultFloors = {
  'CREATE_REMINDER': 'auto',
  'CREATE_TASK': 'auto',
  'COMPLETE_TASK': 'auto',
  'CREATE_CALENDAR_EVENT': 'auto',
  'UPDATE_CALENDAR_EVENT': 'confirm',
  'DELETE_CALENDAR_EVENT': 'confirm',
  'QUERY_CALENDAR': 'auto',
  'DRAFT_EMAIL': 'auto',
  'SEND_EMAIL': 'confirm',
  'SEARCH_EMAIL': 'auto',
  'CALL_CONTACT': 'confirm',
  'PREPARE_SMS': 'handoff',
  'PREPARE_WHATSAPP': 'handoff',
  'PREPARE_TELEGRAM': 'handoff',
  'SHARE_MEDIA': 'confirm',
  'SAVE_NOTE': 'auto',
  'QUERY_TASKS': 'auto',
  'QUERY_MEMORY': 'auto',
};

/// Rules engine. Planner output cannot lower confirmation below the floor.
String applyPolicyFloor(String actionType, String proposed) {
  final floor = defaultFloors[actionType] ?? 'confirm';
  final proposedRank = _rank[proposed] ?? 0;
  final floorRank = _rank[floor] ?? 1;
  return proposedRank >= floorRank ? proposed : floor;
}

bool needsUserGoAhead(PlannedAction action) {
  final policy = applyPolicyFloor(action.type, action.confirmation);
  return policy != 'auto';
}
