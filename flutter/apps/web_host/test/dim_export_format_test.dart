import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_web_host/dim_export/dim_export_format.dart';
import 'package:test/test.dart';

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
            instanceId: 'i1',
          ),
        ),
        contains('owned pin'),
      );
      expect(
        formatDimExportPinStatusLabel(
          const PinStatus(
            slot: EquipmentSlot.arms,
            status: PinStatusKind.stale,
            instanceId: 'i2',
            reason: PinStaleReason.instanceMissing,
          ),
        ),
        contains('stale'),
      );
    });
  });

  group('formatDimExportReadySummary', () {
    test('ready and not ready', () {
      expect(
        formatDimExportReadySummary(
          const EquipReadyResult(equipReady: true, pinStatuses: [
            PinStatus(
              slot: EquipmentSlot.primary,
              status: PinStatusKind.pinned,
              instanceId: 'a',
            ),
          ]),
        ),
        contains('DIM export allowed'),
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
          loading: false,
          hasVariant: false,
        ),
        isFalse,
      );
      expect(
        canEnableDimExportCta(
          equipReady: true,
          exporting: false,
          loading: false,
          hasVariant: true,
          finishComplete: false,
        ),
        isFalse,
      );
      expect(
        canEnableDimExportCta(
          equipReady: true,
          exporting: false,
          loading: false,
          hasVariant: true,
          finishComplete: true,
        ),
        isTrue,
      );
    });
  });

  group('encodeDimExportJson + truncate', () {
    test('pretty prints loadout envelope', () {
      final json = encodeDimExportJson({
        'loadout': {
          'id': 'x',
          'name': 'Test',
          'equipped': [
            {'hash': 1, 'id': 'i1'},
          ],
          'unequipped': <Object>[],
        },
      });
      expect(json, contains('"loadout"'));
      expect(json, contains('\n'));
    });

    test('truncates long preview', () {
      final long = 'a' * 200;
      final t = truncateDimExportPreview(long, maxChars: 100);
      expect(t.length, lessThanOrEqualTo(101));
      expect(t.endsWith('…'), isTrue);
    });
  });
}
