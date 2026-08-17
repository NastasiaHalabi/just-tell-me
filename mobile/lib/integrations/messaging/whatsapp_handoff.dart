/// Official WhatsApp click-to-chat URL. Requires a number; never scrapes the app UI.
Uri whatsAppHandoffUri({required String text, String? phone}) {
  final message = Uri.encodeComponent(text);
  final number = whatsAppNumber(phone);
  if (number == null) {
    return Uri.parse('https://wa.me/?text=$message');
  }
  return Uri.parse('https://wa.me/$number?text=$message');
}

/// Digits WhatsApp accepts in wa.me links (country code, no +).
String? whatsAppNumber(String? raw) {
  if (raw == null) return null;
  var digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return null;
  if (digits.startsWith('00')) {
    digits = digits.substring(2);
  }
  // Local Lebanese mobiles are stored as 03…; wa.me needs 9613…
  if (digits.startsWith('0') && digits.length >= 8 && digits.length <= 10) {
    digits = '961${digits.substring(1)}';
  }
  return digits;
}
