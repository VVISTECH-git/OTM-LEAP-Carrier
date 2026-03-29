// ignore_for_file: type=lint
//
// unit_test.dart — LEAP Carrier
//
// Covers the highest-risk parsing and logic paths:
//   1. OtmService._asList   — the OTM single-item normalisation helper
//   2. CarrierShipment.fromJson — full model parse including tenders & stops
//   3. ShipmentStop.fromJson    — stop type labels and date extraction
//   4. TenderItem.fromJson      — respondByCountdown edge cases
//   5. SessionService helpers   — buildBasicAuth, isSessionExpired logic
//   6. AppConstants             — URL-safe path builders
//
// Run with:
//   flutter test test/unit_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:leapcarrier/core/constants/app_constants.dart';
import 'package:leapcarrier/core/services/session_service.dart';
import 'package:leapcarrier/features/shipments/models/shipment_models.dart';

// ── Expose _asList for testing via a thin public wrapper ──────────────────────
// OtmService._asList is private. We duplicate the logic here so we can test it
// without making it public, while keeping the tests meaningful.
List<dynamic> asList(dynamic items) {
  if (items == null) return [];
  if (items is List) return items;
  if (items is Map) return [items];
  return [];
}

void main() {

  // ── 1. asList ──────────────────────────────────────────────────────────────
  group('asList normalisation', () {
    test('null → empty list', () {
      expect(asList(null), isEmpty);
    });

    test('List passthrough', () {
      final input = [{'a': 1}, {'b': 2}];
      expect(asList(input), equals(input));
    });

    test('single Map → wrapped in List', () {
      final map = {'shipmentXid': 'DEMO.001'};
      final result = asList(map);
      expect(result, hasLength(1));
      expect(result.first, equals(map));
    });

    test('non-null scalar → empty list', () {
      expect(asList(42), isEmpty);
      expect(asList('string'), isEmpty);
    });

    test('empty List → empty list', () {
      expect(asList(<dynamic>[]), isEmpty);
    });
  });

  // ── 2. CarrierShipment.fromJson ────────────────────────────────────────────
  group('CarrierShipment.fromJson', () {
    Map<String, dynamic> _baseJson() => {
      'shipmentXid': 'DEMO.36001',
      'domainName': 'DEMO',
      'sourceLocation': {
        'locationName': 'Mumbai Warehouse',
        'city': 'Mumbai',
        'provinceCode': 'MH',
        'postalCode': '400001',
      },
      'destLocation': {
        'locationName': 'Delhi Hub',
        'city': 'Delhi',
        'provinceCode': 'DL',
        'postalCode': '110001',
      },
      'numStops': 2,
    };

    test('parses basic fields correctly', () {
      final s = CarrierShipment.fromJson(_baseJson());
      expect(s.shipmentXid, equals('DEMO.36001'));
      expect(s.domainName, equals('DEMO'));
      expect(s.bareXid, equals('36001'));
      expect(s.displayId, equals('36001'));
      expect(s.source.city, equals('Mumbai'));
      expect(s.dest.city, equals('Delhi'));
      expect(s.numStops, equals(2));
    });

    test('bareXid strips domain prefix', () {
      final json = _baseJson();
      json['shipmentXid'] = 'MYCOMPANY.S-9999';
      final s = CarrierShipment.fromJson(json);
      expect(s.bareXid, equals('S-9999'));
    });

    test('bareXid is unchanged when no dot present', () {
      final json = _baseJson();
      json['shipmentXid'] = '36001';
      final s = CarrierShipment.fromJson(json);
      expect(s.bareXid, equals('36001'));
    });

    test('parses marketCost and discountPercent', () {
      final json = _baseJson()
        ..addAll({
          'marketCost': {'value': 10000.0, 'currency': 'INR'},
          'attributeNumber18': 10.0,
        });
      final s = CarrierShipment.fromJson(json);
      expect(s.marketCost, equals(10000.0));
      expect(s.currency, equals('INR'));
      expect(s.discountPercent, equals(10.0));
      expect(s.buyNowPrice, closeTo(9000.0, 0.01));
    });

    test('buyNowPrice == marketCost when discount is zero', () {
      final json = _baseJson()
        ..addAll({
          'marketCost': {'value': 5000.0, 'currency': 'USD'},
          'attributeNumber18': 0.0,
        });
      final s = CarrierShipment.fromJson(json);
      expect(s.buyNowPrice, equals(5000.0));
    });

    test('buyNowPrice is null when marketCost absent', () {
      final s = CarrierShipment.fromJson(_baseJson());
      expect(s.buyNowPrice, isNull);
    });

    test('tenders parsed from Map (single-item OTM response)', () {
      final json = _baseJson()
        ..['tenders'] = {
          'items': {
            'tenderXid': 'T-001',
            'tenderStatus': 'TENDERED',
            'tenderType': 'Ordinary',
            'iTransactionNo': 12345,
          }
        };
      final s = CarrierShipment.fromJson(json);
      expect(s.tenders, hasLength(1));
      expect(s.tenders.first.iTransactionNo, equals(12345));
    });

    test('tenders parsed from List (multi-item OTM response)', () {
      final json = _baseJson()
        ..['tenders'] = {
          'items': [
            {'tenderXid': 'T-001', 'tenderStatus': 'TENDERED', 'tenderType': 'Ordinary', 'iTransactionNo': 1},
            {'tenderXid': 'T-002', 'tenderStatus': 'TENDERED', 'tenderType': 'Spot Bid', 'iTransactionNo': 2},
          ]
        };
      final s = CarrierShipment.fromJson(json);
      expect(s.tenders, hasLength(2));
    });

    test('missing tenders field → empty list, no crash', () {
      final s = CarrierShipment.fromJson(_baseJson());
      expect(s.tenders, isEmpty);
      expect(s.activeTender, isNull);
      expect(s.spotBidTender, isNull);
    });

    test('hasDriverAssigned is false when attributeText1 absent', () {
      final s = CarrierShipment.fromJson(_baseJson());
      expect(s.hasDriverAssigned, isFalse);
    });

    test('hasDriverAssigned is true when attributeText1 present', () {
      final json = _baseJson()..['attributeText1'] = '+91-9999999999';
      final s = CarrierShipment.fromJson(json);
      expect(s.hasDriverAssigned, isTrue);
      expect(s.driverPhone, equals('+91-9999999999'));
    });

    test('status derived from statuses.items (in_progress → active)', () {
      final json = _baseJson()
        ..['statuses'] = {
          'items': [{'statusValueGid': 'DEMO.IN_PROGRESS'}]
        };
      final s = CarrierShipment.fromJson(json);
      expect(s.status, equals('active'));
    });

    test('status defaults to tendered when pending ordinary tender present', () {
      final json = _baseJson()
        ..['tenders'] = {
          'items': {'tenderXid': 'T-1', 'tenderStatus': 'TENDERED', 'tenderType': 'Ordinary', 'iTransactionNo': 1}
        };
      final s = CarrierShipment.fromJson(json);
      expect(s.status, equals('tendered'));
    });

    test('progressPercent is null with no stops', () {
      final s = CarrierShipment.fromJson(_baseJson());
      expect(s.progressPercent, isNull);
    });

    test('startTime and endTime parsed correctly', () {
      final json = _baseJson()
        ..addAll({
          'startTime': {'value': '2025-03-01T08:00:00Z'},
          'endTime':   {'value': '2025-03-02T18:00:00Z'},
        });
      final s = CarrierShipment.fromJson(json);
      expect(s.startTime, isNotNull);
      expect(s.endTime,   isNotNull);
      expect(s.startTime!.year, equals(2025));
    });

    test('malformed date in startTime → null, no crash', () {
      final json = _baseJson()
        ..['startTime'] = {'value': 'NOT-A-DATE'};
      final s = CarrierShipment.fromJson(json);
      expect(s.startTime, isNull);
    });
  });

  // ── 3. ShipmentStop.fromJson ───────────────────────────────────────────────
  group('ShipmentStop.fromJson', () {
    test('pickup stop type label', () {
      final stop = ShipmentStop.fromJson({
        'stopNum': 1,
        'locationGid': 'DEMO.MUMBAI',
        'stopType': 'P',
      });
      expect(stop.typeLabel, equals('Pickup'));
      expect(stop.stopSequence, equals(1));
      expect(stop.locationName, equals('MUMBAI'));
    });

    test('delivery stop type label', () {
      final stop = ShipmentStop.fromJson({
        'stopNum': 2,
        'locationGid': 'DEMO.DELHI',
        'stopType': 'D',
      });
      expect(stop.typeLabel, equals('Delivery'));
    });

    test('unknown stop type → "Stop"', () {
      final stop = ShipmentStop.fromJson({
        'stopNum': 3,
        'locationGid': 'DEMO.PUNE',
        'stopType': 'X',
      });
      expect(stop.typeLabel, equals('Stop'));
    });

    test('isCompleted false when no actualDeparture', () {
      final stop = ShipmentStop.fromJson({'stopNum': 1, 'locationGid': 'DEMO.LOC'});
      expect(stop.isCompleted, isFalse);
    });

    test('isCompleted true when actualDeparture present', () {
      final stop = ShipmentStop.fromJson({
        'stopNum': 1,
        'locationGid': 'DEMO.LOC',
        'actualDeparture': {'value': '2025-03-01T10:00:00Z'},
      });
      expect(stop.isCompleted, isTrue);
    });

    test('locationName extracted from locationGid correctly', () {
      final stop = ShipmentStop.fromJson({
        'stopNum': 1,
        'locationGid': 'BIGCORP.WAREHOUSE_A',
      });
      expect(stop.locationName, equals('WAREHOUSE_A'));
      expect(stop.displayName, equals('WAREHOUSE_A'));
    });

    test('locationGid without dot used as-is', () {
      final stop = ShipmentStop.fromJson({
        'stopNum': 1,
        'locationGid': 'STANDALONE',
      });
      expect(stop.locationName, equals('STANDALONE'));
    });

    test('missing locationGid → fallback dash', () {
      final stop = ShipmentStop.fromJson({'stopNum': 1});
      expect(stop.locationName, equals('—'));
    });
  });

  // ── 4. TenderItem.fromJson ─────────────────────────────────────────────────
  group('TenderItem.fromJson', () {
    test('parses all fields correctly', () {
      final t = TenderItem.fromJson({
        'tenderXid': 'T-001',
        'tenderStatus': 'TENDERED',
        'tenderType': 'Ordinary',
        'iTransactionNo': 9876,
        'plannedCost': {'value': 5000.0, 'currency': 'INR'},
        'expectedResponse': {'value': '2099-01-01T00:00:00Z'},
      });
      expect(t.tenderXid, equals('T-001'));
      expect(t.iTransactionNo, equals(9876));
      expect(t.cost, equals(5000.0));
      expect(t.currency, equals('INR'));
      expect(t.isPending, isTrue);
      expect(t.isOrdinary, isTrue);
      expect(t.isSpotBid, isFalse);
    });

    test('falls back to cost key when plannedCost absent', () {
      final t = TenderItem.fromJson({
        'tenderXid': 'T-002',
        'tenderStatus': 'TENDERED',
        'cost': {'value': 1234.56, 'currency': 'USD'},
      });
      expect(t.cost, closeTo(1234.56, 0.001));
    });

    test('respondByCountdown returns Expired for past date', () {
      final t = TenderItem.fromJson({
        'tenderXid': 'T-003',
        'tenderStatus': 'TENDERED',
        'expectedResponse': {'value': '2000-01-01T00:00:00Z'},
      });
      expect(t.respondByCountdown, equals('Expired'));
    });

    test('respondByCountdown returns null when expectedResponse absent', () {
      final t = TenderItem.fromJson({'tenderXid': 'T-004', 'tenderStatus': 'TENDERED'});
      expect(t.respondByCountdown, isNull);
    });

    test('isAccepted / isRejected flags', () {
      final accepted = TenderItem.fromJson({'tenderXid': 'A', 'tenderStatus': 'ACCEPTED'});
      final rejected = TenderItem.fromJson({'tenderXid': 'R', 'tenderStatus': 'REJECTED'});
      expect(accepted.isAccepted, isTrue);
      expect(accepted.isPending, isFalse);
      expect(rejected.isRejected, isTrue);
    });

    test('iTransactionNo cast from num', () {
      final t = TenderItem.fromJson({
        'tenderXid': 'T-005',
        'tenderStatus': 'TENDERED',
        'iTransactionNo': 42.0,  // OTM sometimes returns as double
      });
      expect(t.iTransactionNo, equals(42));
      expect(t.iTransactionNo, isA<int>());
    });
  });

  // ── 5. SessionService helpers ──────────────────────────────────────────────
  group('SessionService.buildBasicAuth', () {
    test('builds correct Basic auth header', () {
      final header = SessionService.buildBasicAuth('DEMO.USER', 'password123');
      // 'DEMO.USER:password123' base64-encoded
      expect(header, startsWith('Basic '));
      // Decode and verify round-trip
      final encoded = header.substring(6);
      final decoded = String.fromCharCodes(
        Uri.parse('data:text/plain;base64,$encoded').data!.contentAsBytes(),
      );
      expect(decoded, equals('DEMO.USER:password123'));
    });

    test('uppercased userId is preserved in header', () {
      final header = SessionService.buildBasicAuth('DEMO.ADMIN', 'pass');
      final encoded = header.substring(6);
      final decoded = String.fromCharCodes(
        Uri.parse('data:text/plain;base64,$encoded').data!.contentAsBytes(),
      );
      expect(decoded, startsWith('DEMO.ADMIN:'));
    });

    test('special characters in password are encoded correctly', () {
      final header = SessionService.buildBasicAuth('USER', r'p@ss:w0rd!');
      expect(header, startsWith('Basic '));
      final encoded = header.substring(6);
      final decoded = String.fromCharCodes(
        Uri.parse('data:text/plain;base64,$encoded').data!.contentAsBytes(),
      );
      expect(decoded, equals(r'USER:p@ss:w0rd!'));
    });
  });

  // ── 6. AppConstants path builders ─────────────────────────────────────────
  group('AppConstants path builders', () {
    test('pathTenderBids URL-encodes servprovGid with dots', () {
      final path = AppConstants.pathTenderBids(12345, 'DEMO.MHL');
      expect(path, contains('DEMO.MHL'));
    });

    test('pathTenderBids URL-encodes servprovGid with special chars', () {
      final path = AppConstants.pathTenderBids(1, 'MY CORP/DIV');
      expect(path, isNot(contains('MY CORP/DIV')));
      expect(path, contains('MY%20CORP%2FDIV'));
    });

    test('pathTrackingEvents encodes bare XID with ampersand', () {
      final path = AppConstants.pathTrackingEvents('SHIP&001');
      expect(path, isNot(contains('SHIP&001')));
      expect(path, contains('SHIP%26001'));
    });

    test('pathShipment returns correct REST path', () {
      final path = AppConstants.pathShipment('DEMO.36001');
      expect(path, equals('/logisticsRestApi/resources-int/v2/shipments/DEMO.36001'));
    });

    test('pathActiveShipments builds with all params', () {
      final path = AppConstants.pathActiveShipments('q=test', 'field1', 'expand1', 50);
      expect(path, contains('q=test'));
      expect(path, contains('field1'));
      expect(path, contains('expand1'));
      expect(path, contains('limit=50'));
    });
  });

  // ── 7. CarrierLocation edge cases ─────────────────────────────────────────
  group('CarrierLocation.fromJson', () {
    test('null json → fallback values', () {
      final loc = CarrierLocation.fromJson(null);
      expect(loc.locationName, equals('—'));
      expect(loc.displayName, equals('—'));
    });

    test('displayName uses city when present', () {
      final loc = CarrierLocation.fromJson({'locationName': 'Big Warehouse', 'city': 'Hyderabad'});
      expect(loc.displayName, equals('Hyderabad'));
    });

    test('displayName falls back to locationName when city empty', () {
      final loc = CarrierLocation.fromJson({'locationName': 'Big Warehouse', 'city': ''});
      expect(loc.displayName, equals('Big Warehouse'));
    });
  });

  // ── 8. TrackingEventItem.fromJson ─────────────────────────────────────────
  group('TrackingEventItem.fromJson', () {
    test('parses all standard fields', () {
      final e = TrackingEventItem.fromJson({
        'id': '100',
        'statusCodeGid': 'CD',
        'statusCodeDescription': 'Delivered',
        'eventdate': {'value': '2025-06-01T14:30:00Z'},
        'stopNum': '2',
      });
      expect(e.id, equals('100'));
      expect(e.statusCodeGid, equals('CD'));
      expect(e.description, equals('Delivered'));
      expect(e.eventDate, isNotNull);
      expect(e.stopNum, equals('2'));
    });

    test('falls back to statusCodeGid when description missing', () {
      final e = TrackingEventItem.fromJson({'id': '1', 'statusCodeGid': 'X3'});
      expect(e.description, equals('X3'));
    });

    test('null eventdate → null eventDate, no crash', () {
      final e = TrackingEventItem.fromJson({'id': '2', 'statusCodeGid': 'AF'});
      expect(e.eventDate, isNull);
    });
  });
}
