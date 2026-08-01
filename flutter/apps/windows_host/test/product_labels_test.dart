import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_windows_host/labels/product_labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('displaySynergyTypeWire title-cases wire tokens', () {
    expect(displaySynergyTypeWire('melee'), 'Melee');
    expect(displaySynergyTypeWire('exotic_armor'), 'Exotic Armor');
  });

  test('displaySetType uses product labels', () {
    expect(displaySetType(SetType.weapon), 'Weapon');
    expect(displaySetTypeWire('armor'), 'Armor');
  });

  test('displayGuardianClass uses product labels', () {
    expect(displayGuardianClass(GuardianClass.hunter), 'Hunter');
    expect(displayGuardianClass(GuardianClass.titan), 'Titan');
  });

  test('displaySynergyDraft formats type and subtype', () {
    expect(displaySynergyDraft('super'), 'Super');
    expect(displaySynergyDraft('melee', 'Base'), 'Melee · Base');
  });
}
