import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/actions/executor.dart';
import '../../core/actions/models.dart';
import '../../core/actions/policy.dart';
import '../../core/api/client.dart';
import '../../core/storage/local_store.dart';
import '../../integrations/contracts.dart';
import '../../integrations/speech/speech_provider.dart';
import '../../theme/app_theme.dart';
import '../history/history_screen.dart';
import '../memory/memory_screen.dart';
import '../settings/settings_screen.dart';

enum CommandUiState {
  idle,
  listening,
  transcribing,
  planning,
  awaitingConfirmation,
  executing,
  completed,
  partialFailure,
  failed,
}

class CommandScreen extends StatefulWidget {
  const CommandScreen({
    super.key,
    required this.api,
    this.notifications,
    this.contacts,
    this.calendar,
    this.speech,
  });

  final JustTellMeApi api;
  final NotificationScheduler? notifications;
  final ContactDirectory? contacts;
  final CalendarAdapter? calendar;
  final SpeechToTextProvider? speech;

  @override
  State<CommandScreen> createState() => _CommandScreenState();
}

class _CommandScreenState extends State<CommandScreen> {
  final _textController = TextEditingController();
  final _store = LocalStore();
  late final ActionExecutor _executor;

  CommandUiState _state = CommandUiState.idle;
  String? _error;
  ActionPlan? _plan;
  final Map<String, String> _results = {};
  bool _backendUp = false;
  List<HistoryItem> _recent = [];
  List<LocalTask> _upcoming = [];
  List<DeviceContact> _choices = [];
  String? _pendingUtterance;
  Timer? _handoffTimer;
  Duration? _handoffIn;
  String? _handoffLabel;

  @override
  void initState() {
    super.initState();
    _executor = ActionExecutor(
      store: _store,
      notifications: widget.notifications,
      contacts: widget.contacts,
      calendar: widget.calendar,
    );
    _refresh();
  }

  Future<void> _toggleMic() async {
    if (_state == CommandUiState.listening) {
      setState(() => _state = CommandUiState.transcribing);
      final spoken = await widget.speech?.stopAndTranscribe() ?? '';
      if (spoken.isEmpty) {
        setState(() {
          _state = CommandUiState.idle;
          _error = 'I didn’t catch that. Tap the mic again, or type it.';
        });
        return;
      }
      _textController.text = spoken;
      await _submit(spoken);
      return;
    }

    final speech = widget.speech;
    if (speech == null) {
      setState(() => _error = 'Voice isn’t available on this device. Type your command instead.');
      return;
    }
    try {
      final ready = await speech.initialize();
      if (!ready) {
        setState(() {
          _error =
              'Voice works on your Galaxy phone. On this Windows window, type instead. Allow the microphone when Android asks.';
        });
        return;
      }
      setState(() {
        _state = CommandUiState.listening;
        _error = null;
      });
      await speech.start(
        languageHints: ['ar-LB', 'en', 'ar'],
        onPartial: (words) {
          if (!mounted) return;
          setState(() => _textController.text = words);
        },
      );
    } catch (_) {
      setState(() {
        _state = CommandUiState.idle;
        _error = 'Couldn’t start the microphone. Check mic permission in Android settings.';
      });
    }
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  String get _statusLabel {
    switch (_state) {
      case CommandUiState.planning:
        return 'Understanding you…';
      case CommandUiState.awaitingConfirmation:
        return 'Does this look right?';
      case CommandUiState.executing:
        return 'Working on it…';
      case CommandUiState.completed:
        return 'Consider it handled.';
      case CommandUiState.partialFailure:
        return 'Some of that needs a second look.';
      case CommandUiState.failed:
        return 'I couldn’t finish that.';
      case CommandUiState.listening:
        return 'Listening… tap the mic when you’re done.';
      case CommandUiState.transcribing:
        return 'Got it, reading that back…';
      default:
        return _backendUp ? 'Say it in your own words.' : 'Planner is offline — start the backend.';
    }
  }

  Future<void> _refresh() async {
    final up = await widget.api.health();
    final recent = await _store.history();
    final upcoming = await _store.upcoming(DateTime.now());
    if (!mounted) return;
    setState(() {
      _backendUp = up;
      _recent = recent.take(4).toList();
      _upcoming = upcoming.take(4).toList();
    });
  }

  bool _looksLikePeopleCommand(String text) {
    return RegExp(
      r'call|de2|دق|ask|email|whatsapp|ابعت|eb3at|message|tell|اسأل',
      caseSensitive: false,
    ).hasMatch(text);
  }

  Future<List<Map<String, dynamic>>> _memoryCandidates() async {
    final memory = await _store.memory();
    return memory
        .map(
          (item) => {
            'contact_id': item.contactId ?? 'memory:${item.key}',
            'display_name': item.value,
            'aliases': [item.key],
          },
        )
        .toList();
  }

  Future<void> _submit(String text) async {
    final utterance = text.trim();
    if (utterance.isEmpty) return;
    setState(() {
      _state = CommandUiState.planning;
      _error = null;
      _plan = null;
      _results.clear();
      _choices = [];
      _pendingUtterance = utterance;
    });
    try {
      var candidates = await _memoryCandidates();
      if (_looksLikePeopleCommand(utterance) && widget.contacts != null) {
        final permission = await widget.contacts!.ensurePermission();
        if (!permission.granted && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(permission.message)));
        }
      }
      var plan = await widget.api.createPlan(
        text: utterance,
        localNow: DateTime.now(),
        candidateContacts: candidates,
      );
      final names = plan.actions.map((action) => action.recipient?.displayName).whereType<String>();
      final name = names.isEmpty ? null : names.first;
      if (name != null && widget.contacts != null) {
        final found = await widget.contacts!.search(name);
        if (found.length > 1) {
          setState(() {
            _plan = plan;
            _choices = found;
            _state = CommandUiState.awaitingConfirmation;
          });
          return;
        }
        if (found.length == 1) {
          candidates = [...candidates, found.first.toPlannerJson()];
          plan = await widget.api.createPlan(
            text: utterance,
            localNow: DateTime.now(),
            candidateContacts: candidates,
          );
        }
      }
      await _presentPlan(plan);
    } catch (error) {
      setState(() {
        _state = CommandUiState.failed;
        _error = 'I couldn’t reach the planner. Is the backend running?';
      });
      await _store.addHistory(
        HistoryItem(
          utterance: utterance,
          summary: 'Planning failed',
          status: 'failed',
          timestamp: DateTime.now(),
          error: error.toString(),
        ),
      );
    }
  }

  Future<void> _presentPlan(ActionPlan plan) async {
    final needsConfirm = plan.actions.any(needsUserGoAhead) || plan.needsClarification;
    setState(() {
      _plan = plan;
      _state = needsConfirm ? CommandUiState.awaitingConfirmation : CommandUiState.executing;
    });
    if (!needsConfirm) {
      await _runPlan(plan);
    }
  }

  Future<void> _chooseContact(DeviceContact contact) async {
    final utterance = _pendingUtterance;
    if (utterance == null) return;
    await _store.upsertMemory(
      MemoryItem(
        key: contact.displayName.split(' ').first,
        value: contact.displayName,
        contactId: contact.id,
      ),
    );
    final candidates = [...await _memoryCandidates(), contact.toPlannerJson()];
    final plan = await widget.api.createPlan(
      text: utterance,
      localNow: DateTime.now(),
      candidateContacts: candidates,
    );
    setState(() => _choices = []);
    await _presentPlan(plan);
  }

  void _armDelayedHandoff(PlannedAction action, DateTime when) {
    _handoffTimer?.cancel();
    _handoffLabel = action.recipient?.displayName ?? 'them';
    _handoffTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final left = when.difference(DateTime.now());
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (left <= Duration.zero) {
        timer.cancel();
        setState(() => _handoffIn = Duration.zero);
        final result = await _executor.execute(action.copyWith(clearSchedule: true), forceNow: true);
        if (!mounted) return;
        setState(() {
          _results[action.id] = result.detail;
          action.status = result.status;
          _handoffIn = null;
        });
        return;
      }
      setState(() => _handoffIn = left);
    });
  }

  Future<void> _runPlan(ActionPlan plan) async {
    setState(() => _state = CommandUiState.executing);
    var failures = 0;
    for (final action in plan.actions) {
      applyPolicyFloor(action.type, action.confirmation);
      action.status = 'executing';
      final result = await _executor.execute(action, planId: plan.planId);
      action.status = result.status;
      _results[action.id] = result.detail;
      if (result.status == 'scheduled' && action.type == 'PREPARE_WHATSAPP') {
        final when = DateTime.tryParse(action.scheduledFor ?? '');
        if (when != null) {
          _armDelayedHandoff(action, when);
        }
      }
      if (result.status == 'failed' || result.status == 'unsupported') {
        failures += 1;
      }
    }
    final status = failures == 0
        ? 'completed'
        : failures == plan.actions.length
            ? 'failed'
            : 'partial_failure';
    await _store.addHistory(
      HistoryItem(
        utterance: plan.originalText,
        summary: plan.summary,
        status: status,
        timestamp: DateTime.now(),
      ),
    );
    if (!mounted) return;
    setState(() {
      _state = status == 'completed'
          ? CommandUiState.completed
          : status == 'failed'
              ? CommandUiState.failed
              : CommandUiState.partialFailure;
    });
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final arabic = RegExp(r'[\u0600-\u06FF]').hasMatch(_textController.text);
    return Directionality(
      textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF7F2E8), Color(0xFFE9F0EA), Color(0xFFF4EFE6)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _topBar(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
                    children: [
                      Text(_greeting, style: GoogleFonts.fraunces(fontSize: 32, height: 1.15, color: AppColors.forest)),
                      const SizedBox(height: 6),
                      Text(_statusLabel, style: const TextStyle(color: AppColors.muted, fontSize: 16)),
                      const SizedBox(height: 28),
                      _micButton(),
                      const SizedBox(height: 22),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _chip('Remind me later'),
                          _chip('Message Nour'),
                          _chip('What’s tomorrow?'),
                        ],
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ],
                      if (_handoffIn != null) ...[
                        const SizedBox(height: 20),
                        _countdownCard(),
                      ],
                      if (_upcoming.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text('Coming up', style: GoogleFonts.fraunces(fontSize: 20, color: AppColors.forest)),
                        const SizedBox(height: 8),
                        ..._upcoming.map(_upcomingTile),
                      ],
                      if (_choices.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text('Which person?', style: GoogleFonts.fraunces(fontSize: 20, color: AppColors.forest)),
                        ..._choices.map(
                          (contact) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: AppColors.sand,
                              child: Text(contact.displayName.isEmpty ? '?' : contact.displayName[0].toUpperCase()),
                            ),
                            title: Text(contact.displayName),
                            subtitle: Text(contact.phone ?? 'Pick in WhatsApp if needed'),
                            onTap: () => _chooseContact(contact),
                          ),
                        ),
                      ],
                      if (_plan != null) ...[
                        const SizedBox(height: 24),
                        Text(
                          _plan!.actions.length == 1 ? 'I understood this' : 'I understood ${_plan!.actions.length} things',
                          style: GoogleFonts.fraunces(fontSize: 20, color: AppColors.forest),
                        ),
                        const SizedBox(height: 10),
                        ..._plan!.actions.map(_actionCard),
                        if (_state == CommandUiState.awaitingConfirmation && _choices.isEmpty) ...[
                          const SizedBox(height: 8),
                          FilledButton(onPressed: () => _runPlan(_plan!), child: const Text('Go ahead')),
                          TextButton(
                            onPressed: () => setState(() {
                              _state = CommandUiState.idle;
                              _plan = null;
                            }),
                            child: const Text('Not now'),
                          ),
                        ],
                      ],
                      if (_recent.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        Text('Recent', style: GoogleFonts.fraunces(fontSize: 20, color: AppColors.forest)),
                        const SizedBox(height: 8),
                        ..._recent.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              item.utterance,
                              style: const TextStyle(color: AppColors.muted),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _composer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Text('Just Tell Me', style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.forest)),
          const Spacer(),
          IconButton(
            tooltip: 'History',
            onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const HistoryScreen())),
            icon: const Icon(Icons.history_rounded),
          ),
          IconButton(
            tooltip: 'Memory',
            onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const MemoryScreen())),
            icon: const Icon(Icons.favorite_outline_rounded),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => SettingsScreen(api: widget.api)),
            ),
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
    );
  }

  Widget _micButton() {
    return Center(
      child: Semantics(
        button: true,
        label: 'Microphone. Tap to speak, tap again when you are done.',
        child: GestureDetector(
          onTap: _toggleMic,
          child: Container(
            width: 124,
            height: 124,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _state == CommandUiState.listening ? AppColors.gold : AppColors.forest,
              boxShadow: [
                BoxShadow(
                  color: AppColors.forest.withOpacity(0.22),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(
              _state == CommandUiState.listening ? Icons.graphic_eq_rounded : Icons.mic_rounded,
              size: 46,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String label) {
    return ActionChip(
      label: Text(label),
      backgroundColor: AppColors.card,
      side: BorderSide.none,
      onPressed: () {
        _textController.text = label == 'Message Nour'
            ? 'send a hi message for Nour'
            : label == 'Remind me later'
                ? 'remind me in 10 minutes to stretch'
                : 'shu 3ande bokra?';
        _textController.selection = TextSelection.collapsed(offset: _textController.text.length);
      },
    );
  }

  Widget _countdownCard() {
    final seconds = _handoffIn?.inSeconds ?? 0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.forest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sending to ${_handoffLabel ?? 'them'}', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          Text(
            seconds <= 0 ? 'Opening WhatsApp…' : 'in $seconds seconds',
            style: GoogleFonts.fraunces(fontSize: 28, color: Colors.white),
          ),
          const Text('WhatsApp will open with a prepared hello. You still tap send.', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _upcomingTile(LocalTask task) {
    final when = task.dueAt ?? task.reminderAt;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.schedule_rounded, color: AppColors.leaf),
      title: Text(task.title),
      subtitle: Text(when == null ? '' : DateFormat('h:mm a').format(when.toLocal())),
    );
  }

  Widget _actionCard(PlannedAction action) {
    final who = action.recipient?.displayName;
    final when = action.startAt ?? action.scheduledFor ?? action.remindAt;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.forest.withOpacity(0.06), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_friendlyType(action.type), style: const TextStyle(color: AppColors.leaf, fontWeight: FontWeight.w600)),
          if (action.title != null) Text(action.title!, style: GoogleFonts.fraunces(fontSize: 20)),
          if (who != null) Text('For $who', style: const TextStyle(color: AppColors.muted)),
          if (action.message != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(16)),
              child: Text('“${action.message}”'),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: action.message!));
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message copied.')));
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Copy'),
              ),
            ),
          ],
          if (when != null && action.message == null) Text(when, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          if (_results[action.id] != null) ...[
            const SizedBox(height: 8),
            Text(_results[action.id]!, style: const TextStyle(height: 1.35)),
          ],
        ],
      ),
    );
  }

  Widget _composer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: _submit,
              decoration: const InputDecoration(hintText: 'Just tell me…'),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: AppColors.forest,
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: 'Send command',
              onPressed: () => _submit(_textController.text),
              icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _friendlyType(String type) {
    switch (type) {
      case 'PREPARE_WHATSAPP':
        return 'WhatsApp';
      case 'CREATE_REMINDER':
        return 'Reminder';
      case 'CREATE_TASK':
        return 'Task';
      case 'CREATE_CALENDAR_EVENT':
        return 'Calendar';
      case 'SEND_EMAIL':
      case 'DRAFT_EMAIL':
        return 'Email';
      case 'CALL_CONTACT':
        return 'Call';
      default:
        return type.replaceAll('_', ' ').toLowerCase();
    }
  }

  @override
  void dispose() {
    _handoffTimer?.cancel();
    _textController.dispose();
    super.dispose();
  }
}
