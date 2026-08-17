import 'package:flutter/material.dart';

import '../../core/api/client.dart';
import '../../theme/theme_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.api, this.themeController});

  final JustTellMeApi api;
  final ThemeController? themeController;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _url;
  String? _status;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _url = TextEditingController(text: widget.api.baseUrl);
  }

  Future<void> _saveAndTest() async {
    setState(() {
      _checking = true;
      _status = null;
    });
    await widget.api.saveBaseUrl(_url.text);
    final ok = await widget.api.health();
    if (!mounted) return;
    setState(() {
      _checking = false;
      _status = ok
          ? 'Connected to ${widget.api.baseUrl}'
          : 'Could not reach ${widget.api.baseUrl}. Keep the PC planner running on the same Wi‑Fi.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Planner address'),
          const SizedBox(height: 6),
          const Text(
            'On your phone this is your PC’s Wi‑Fi IP, like http://192.168.10.118:8080',
            style: TextStyle(color: Color(0xFF6B736E)),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(hintText: 'http://192.168.10.118:8080'),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: _checking ? null : _saveAndTest,
            child: Text(_checking ? 'Checking…' : 'Save and test'),
          ),
          if (_status != null) ...[
            const SizedBox(height: 8),
            Text(_status!),
          ],
          const Divider(height: 36),
          const Text('Appearance'),
          const SizedBox(height: 10),
          if (widget.themeController != null)
            ListenableBuilder(
              listenable: widget.themeController!,
              builder: (context, _) {
                return SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('Dark'), icon: Icon(Icons.dark_mode_rounded)),
                    ButtonSegment(value: false, label: Text('Light'), icon: Icon(Icons.light_mode_rounded)),
                  ],
                  selected: {widget.themeController!.isDark},
                  onSelectionChanged: (selection) => widget.themeController!.setDark(selection.first),
                );
              },
            ),
          const SizedBox(height: 8),
          const Text('Dark is black with lime accents. Light keeps the same lime on a white background.'),
          const Divider(height: 36),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Notifications'),
            subtitle: Text('Used only to fire reminders you asked for. If permission is denied, the task is still saved locally.'),
          ),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Contacts'),
            subtitle: Text('Requested when a command names a person. Matching stays on-device.'),
          ),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Calendar'),
            subtitle: Text('Native calendar writes only after OS permission and confirmation.'),
          ),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Speech'),
            subtitle: Text('Uses your phone’s built-in speech recognition. Tap the mic, speak, tap again.'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }
}
