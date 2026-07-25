import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_windows_host/dim_export/dim_export_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatDimExportPinStatusLabel', () {
    test('wishlist / pinned / stale', () {
      expect(
        formatDimExportPinStatusLabel(
          const PinStatus(
            slot: EquipmentSlot.primary,
            status: PinStatusKind.wishlist,
          ),
        ),
        contains('wishlist'),
      );
      expect(
        formatDimExportPinStatusLabel(
          const PinStatus(
            slot: EquipmentSlot.helmet,
            status: PinStatusKind.pinned,
          ),
        ),
        contains('owned pin'),
      );
      expect(
        formatDimExportPinStatusLabel(
          const PinStatus(
            slot: EquipmentSlot.special,
            status: PinStatusKind.stale,
            reason: PinStaleReason.instanceMissing,
          ),
        ),
        contains('stale'),
      );
    });
  });

  group('formatDimExportReadySummary', () {
    test('ready vs not ready', () {
      expect(
        formatDimExportReadySummary(
          const EquipReadyResult(equipReady: true, pinStatuses: [
            PinStatus(
              slot: EquipmentSlot.primary,
              status: PinStatusKind.pinned,
            ),
          ]),
        ),
        contains('allowed'),
      );
      expect(
        formatDimExportReadySummary(
          const EquipReadyResult(equipReady: false, pinStatuses: [
            PinStatus(
              slot: EquipmentSlot.primary,
              status: PinStatusKind.wishlist,
            ),
          ]),
        ),
        contains('export blocked'),
      );
      expect(
        formatDimExportReadySummary(
          const EquipReadyResult(equipReady: false),
        ),
        contains('no combat pins'),
      );
    });
  });

  group('canEnableDimExportCta', () {
    test('requires equip-ready + variant + not busy', () {
      expect(
        canEnableDimExportCta(
          equipReady: true,
          exporting: false,
          loading: false,
          hasVariant: true,
        ),
        isTrue,
      );
      expect(
        canEnableDimExportCta(
          equipReady: false,
          exporting: false,
          loading: false,
          hasVariant: true,
        ),
        isFalse,
      );
      expect(
        canEnableDimExportCta(
          equipReady: true,
          exporting: true,
          loading: false,
          hasVariant: true,
        ),
        isFalse,
      );
      expect(
        canEnableDimExportCta(
          equipReady: true,
          exporting: false,
          loading: true,
          hasVariant: true,
        ),
        isFalse,
      );
      expect(
        canEnableDimExportCta(
          equipReady: true,
          exporting: false,
          loading: false,
          hasVariant: false,
        ),
        isFalse,
      );
    });
  });

  group('encodeDimExportJson + truncate', () {
    test('pretty encodes loadout envelope', () {
      final json = encodeDimExportJson({
        'loadout': {
          'id': 'fixed',
          'name': 'Test',
          'classType': 1,
          'equipped': [
            {'hash': 1, 'id': 'a'},
          ],
          'unequipped': <Object>[],
        },
      });
      expect(json, contains('"loadout"'));
      expect(json, contains('"id": "fixed"'));
      expect(json, contains('\n'));
    });

    test('truncate adds ellipsis when long', () {
      final long = 'x' * 600;
      final t = truncateDimExportPreview(long, maxChars: 100);
      expect(t.length, 101); // 100 + …
      expect(t.endsWith('…'), isTrue);
    });
  });
}
