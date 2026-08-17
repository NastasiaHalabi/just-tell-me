import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:just_tell_me/core/actions/executor.dart';
import 'package:just_tell_me/core/actions/models.dart';
import 'package:just_tell_me/core/storage/local_store.dart';
import 'package:just_tell_me/integrations/contracts.dart';
import 'package:just_tell_me/integrations/messaging/whatsapp_handoff.dart';

class FakeContacts implements ContactDirectory {
  FakeContacts(this.people);

  final List<DeviceContact> people;

  @override
  Future<PermissionOutcome> ensurePermission() async {
    return const PermissionOutcome(granted: true, message: 'ok');
  }

  @override
  Future<List<DeviceContact>> search(String query) async {
    final needle = query.toLowerCase();
    return people.where((person) => person.displayName.toLowerCase().contains(needle)).toList();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('local Lebanese numbers become wa.me country-code links', () {
    expect(whatsAppNumber('03 123 456'), '9613123456');
    expect(
      whatsAppHandoffUri(text: 'Hi Maya', phone: '+961 3 123 456').toString(),
      'https://wa.me/9613123456?text=Hi%20Maya',
    );
  });

  test('memory with a phone opens that WhatsApp chat, not the picker', () async {
    final store = LocalStore();
    await store.upsertMemory(
      MemoryItem(key: 'Maya', value: 'Maya Khoury', phone: '03123456'),
    );
    Uri? opened;
    final executor = ActionExecutor(
      store: store,
      launch: (uri) async {
        opened = uri;
        return true;
      },
    );
    final result = await executor.execute(
      PlannedAction(
        id: 'a1',
        type: 'PREPARE_WHATSAPP',
        status: 'planned',
        confirmation: 'handoff',
        message: 'Hi Maya',
        recipient: const Recipient(displayName: 'Maya'),
      ),
    );
    expect(result.status, 'handed_off');
    expect(opened.toString(), contains('https://wa.me/9613123456'));
    expect(opened.toString(), isNot(contains('https://wa.me/?')));
  });

  test('memory without a number looks up the unique device contact', () async {
    final store = LocalStore();
    await store.upsertMemory(MemoryItem(key: 'mama', value: 'Maya'));
    Uri? opened;
    final executor = ActionExecutor(
      store: store,
      contacts: FakeContacts(const [
        DeviceContact(id: 'c1', displayName: 'Maya', phone: '+96170111222'),
        DeviceContact(id: 'c2', displayName: 'Karim', phone: '+96170333444'),
      ]),
      launch: (uri) async {
        opened = uri;
        return true;
      },
    );
    final result = await executor.execute(
      PlannedAction(
        id: 'a1',
        type: 'PREPARE_WHATSAPP',
        status: 'planned',
        confirmation: 'handoff',
        message: 'Hi Maya',
        recipient: const Recipient(displayName: 'mama'),
      ),
    );
    expect(result.status, 'handed_off');
    expect(opened.toString(), contains('https://wa.me/96170111222'));
  });
}
