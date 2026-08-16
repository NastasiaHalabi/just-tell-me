import 'package:flutter_test/flutter_test.dart';

import 'package:just_tell_me/core/actions/policy.dart';

void main() {
  test('policy engine never lowers send email to auto', () {
    expect(applyPolicyFloor('SEND_EMAIL', 'auto'), 'confirm');
  });

  test('whatsapp floor is handoff', () {
    expect(applyPolicyFloor('PREPARE_WHATSAPP', 'auto'), 'handoff');
  });

  test('higher confirmation is preserved', () {
    expect(applyPolicyFloor('CREATE_REMINDER', 'handoff'), 'handoff');
  });
}
