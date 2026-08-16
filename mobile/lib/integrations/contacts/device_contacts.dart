import 'package:flutter_contacts/flutter_contacts.dart';

import '../contracts.dart';

class DeviceContactDirectory implements ContactDirectory {
  @override
  Future<PermissionOutcome> ensurePermission() async {
    try {
      final granted = await FlutterContacts.requestPermission(readonly: true);
      if (!granted) {
        return const PermissionOutcome(
          granted: false,
          message: 'Contacts access is needed to match names like Maya. I did not upload your address book.',
        );
      }
      return const PermissionOutcome(granted: true, message: 'Contacts allowed.');
    } catch (_) {
      return const PermissionOutcome(
        granted: false,
        message: 'Contacts are not available on this device yet.',
      );
    }
  }

  @override
  Future<List<DeviceContact>> search(String query) async {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return [];
    try {
      final contacts = await FlutterContacts.getContacts(withProperties: true);
      return contacts
          .where((contact) {
            final hay = [
              contact.displayName,
              ...contact.phones.map((phone) => phone.number),
              ...contact.emails.map((email) => email.address),
            ].join(' ').toLowerCase();
            return hay.contains(needle);
          })
          .map(
            (contact) => DeviceContact(
              id: contact.id,
              displayName: contact.displayName,
              phone: contact.phones.isEmpty ? null : contact.phones.first.number,
              email: contact.emails.isEmpty ? null : contact.emails.first.address,
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }
}
