import 'package:flutter_test/flutter_test.dart';

import 'package:just_tell_me/core/actions/models.dart';
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

  test('known messaging identity skips the extra go-ahead tap', () {
    final action = PlannedAction(
      id: 'a1',
      type: 'PREPARE_WHATSAPP',
      status: 'planned',
      confirmation: 'handoff',
    );
    expect(needsUserGoAhead(action), isTrue);
    expect(needsUserGoAhead(action, identityConfirmed: true), isFalse);
  });

  test('email still needs go-ahead even when the person is known', () {
    final action = PlannedAction(
      id: 'a1',
      type: 'SEND_EMAIL',
      status: 'planned',
      confirmation: 'confirm',
    );
    expect(needsUserGoAhead(action, identityConfirmed: true), isTrue);
  });
}
