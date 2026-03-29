// ── LEAP Carrier — Shipment Models ────────────────────────────────────────

class CarrierLocation {
  final String locationName;
  final String city;
  final String provinceCode;
  final String postalCode;

  const CarrierLocation({
    required this.locationName,
    required this.city,
    required this.provinceCode,
    required this.postalCode,
  });

  factory CarrierLocation.fromJson(Map<String, dynamic>? j) {
    if (j == null) {
      return const CarrierLocation(
          locationName: '—', city: '', provinceCode: '', postalCode: '');
    }
    return CarrierLocation(
      locationName: j['locationName'] ?? '—',
      city: j['city'] ?? '',
      provinceCode: j['provinceCode'] ?? '',
      postalCode: j['postalCode'] ?? '',
    );
  }

  String get displayName => city.isNotEmpty ? city : locationName;
}

class CarrierWeight {
  final double value;
  final String unit;
  const CarrierWeight({required this.value, required this.unit});
  factory CarrierWeight.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const CarrierWeight(value: 0, unit: 'LB');
    return CarrierWeight(
        value: (j['value'] ?? 0).toDouble(), unit: j['unit'] ?? 'LB');
  }
  String get display => '${value.toStringAsFixed(0)} $unit';
}

class TenderItem {
  final String tenderXid;
  final String tenderStatus;
  final String servprovGid;
  final double? cost;
  final String currency;
  final DateTime? expiryDate;

  final int? iTransactionNo;
  final String tenderType;
  final DateTime? insertDate;
  final DateTime? expectedResponse;

  const TenderItem({
    required this.tenderXid,
    required this.tenderStatus,
    required this.servprovGid,
    this.cost,
    required this.currency,
    this.expiryDate,
    this.iTransactionNo,
    this.tenderType = '',
    this.insertDate,
    this.expectedResponse,
  });

  factory TenderItem.fromJson(Map<String, dynamic> j) {
    DateTime? expiry, insert, expectedResp;
    try {
      expiry = j['expiryDate']?['value'] != null
          ? DateTime.parse(j['expiryDate']['value'])
          : null;
    } catch (_) {}
    try {
      insert = j['insertDate']?['value'] != null
          ? DateTime.parse(j['insertDate']['value'])
          : null;
    } catch (_) {}
    try {
      expectedResp = j['expectedResponse']?['value'] != null
          ? DateTime.parse(j['expectedResponse']['value'])
          : null;
    } catch (_) {}

    // API returns plannedCost, not cost
    final costMap = j['plannedCost'] ?? j['cost'];

    return TenderItem(
      tenderXid: j['tenderXid'] ?? j['iTransactionNo']?.toString() ?? '',
      tenderStatus: j['tenderStatus'] ?? j['status'] ?? 'TENDERED',
      servprovGid: j['servprovGid'] ?? '',
      cost: costMap?['value'] != null
          ? (costMap['value'] as num).toDouble()
          : null,
      currency: costMap?['currency'] ?? 'USD',
      expiryDate: expiry,
      iTransactionNo: j['iTransactionNo'] != null
          ? (j['iTransactionNo'] as num).toInt()
          : null,
      tenderType: j['tenderType'] ?? '',
      insertDate: insert,
      expectedResponse: expectedResp,
    );
  }

  bool get isPending => tenderStatus == 'TENDERED';
  bool get isAccepted => tenderStatus == 'ACCEPTED';
  bool get isRejected => tenderStatus == 'REJECTED';
  bool get isOrdinary => tenderType == 'Ordinary';
  bool get isSpotBid => tenderType == 'Spot Bid';

  String? get respondByCountdown {
    if (expectedResponse == null) return null;
    final diff = expectedResponse!.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    final days = diff.inDays;
    final hours = diff.inHours.remainder(24);
    final mins = diff.inMinutes.remainder(60);
    if (days > 0) return '$days D $hours Hrs';
    if (hours > 0) return '$hours Hrs $mins Min';
    return '$mins Min';
  }
}

// ── Shipment Stop model ────────────────────────────────────────────────────

class ShipmentStop {
  final int stopSequence;
  final String stopXid;
  final String locationName;
  final String city;
  final String? stopType;
  final DateTime? scheduledArrival;
  final DateTime? actualArrival;
  final DateTime? scheduledDeparture;
  final DateTime? actualDeparture;

  const ShipmentStop({
    required this.stopSequence,
    required this.stopXid,
    required this.locationName,
    required this.city,
    this.stopType,
    this.scheduledArrival,
    this.actualArrival,
    this.scheduledDeparture,
    this.actualDeparture,
  });

  factory ShipmentStop.fromJson(Map<String, dynamic> j) {
    DateTime? schedArr, actArr, schedDep, actDep;

    // API returns plannedArrival / plannedDeparture
    try {
      schedArr = j['plannedArrival']?['value'] != null
          ? DateTime.parse(j['plannedArrival']['value'])
          : null;
    } catch (_) {}
    try {
      actArr = j['actualArrival']?['value'] != null
          ? DateTime.parse(j['actualArrival']['value'])
          : null;
    } catch (_) {}
    try {
      schedDep = j['plannedDeparture']?['value'] != null
          ? DateTime.parse(j['plannedDeparture']['value'])
          : null;
    } catch (_) {}
    try {
      actDep = j['actualDeparture']?['value'] != null
          ? DateTime.parse(j['actualDeparture']['value'])
          : null;
    } catch (_) {}

    // API returns locationGid as "DOMAIN.LOCATION" e.g. "DEMO.JAIPUR"
    // No nested location object — extract city/name from locationGid
    final locationGid = j['locationGid']?.toString() ?? '';
    final locationName = locationGid.contains('.')
        ? locationGid.split('.').last
        : (locationGid.isNotEmpty ? locationGid : '—');

    return ShipmentStop(
      stopSequence: (j['stopNum'] as num?)?.toInt() ?? 0,  // API uses stopNum not stopSequence
      stopXid: j['stopNum']?.toString() ?? '',
      locationName: locationName,
      city: locationName,   // use extracted name as city for displayName
      stopType: j['stopType']?.toString(),  // "P" or "D"
      scheduledArrival: schedArr,
      actualArrival: actArr,
      scheduledDeparture: schedDep,
      actualDeparture: actDep,
    );
  }

  String get displayName => city.isNotEmpty ? city : locationName;

  bool get isDeparted => actualDeparture != null;
  bool get isArrived => actualArrival != null;
  bool get isCompleted => isDeparted;

  String get typeLabel {
    switch (stopType?.toUpperCase()) {
      case 'P':
      case 'PU':
      case 'PICKUP':
        return 'Pickup';
      case 'D':
      case 'DELIVERY':
        return 'Delivery';
      default:
        return 'Stop';
    }
  }
}

class CarrierShipment {
  final String shipmentXid;
  final String domainName;
  final CarrierLocation source;
  final CarrierLocation dest;
  final CarrierWeight? totalWeight;
  final DateTime? startTime;
  final DateTime? endTime;
  final int numStops;
  final String status;
  final List<TenderItem> tenders;
  final List<ShipmentStop> stops;
  final double? marketCost;
  final double? totalActualCost;
  final String currency;
  final double? discountPercent;
  final String? equipment;
  final String? driverPhone;
  final String? driverName;
  final String? vehicleReg;
  final String? truckType;

  const CarrierShipment({
    required this.shipmentXid,
    required this.domainName,
    required this.source,
    required this.dest,
    this.totalWeight,
    this.startTime,
    this.endTime,
    required this.numStops,
    required this.status,
    required this.tenders,
    this.stops = const [],
    this.marketCost,
    this.totalActualCost,
    required this.currency,
    this.discountPercent,
    this.equipment,
    this.driverPhone,
    this.driverName,
    this.vehicleReg,
    this.truckType,
  });

  String get bareXid =>
      shipmentXid.contains('.') ? shipmentXid.split('.').last : shipmentXid;
  String get displayId => bareXid;

  factory CarrierShipment.fromJson(Map<String, dynamic> j) {
    DateTime? start, end;
    try {
      start = j['startTime']?['value'] != null
          ? DateTime.parse(j['startTime']['value'])
          : null;
    } catch (_) {}
    try {
      end = j['endTime']?['value'] != null
          ? DateTime.parse(j['endTime']['value'])
          : null;
    } catch (_) {}

    List<TenderItem> tendersList = [];
    try {
      final rawTenders = j['tenders'];
      List tItems = [];
      if (rawTenders is Map) {
        final ti = rawTenders['items'];
        tItems = ti is List ? ti : (ti is Map ? [ti] : []);
      } else if (rawTenders is List) {
        tItems = rawTenders;
      }
      for (final t in tItems) {
        if (t is Map<String, dynamic>) {
          try { tendersList.add(TenderItem.fromJson(t)); } catch (_) {}
        }
      }
    } catch (_) {}

    List<ShipmentStop> stopsList = [];
    try {
      final rawStops = j['stops'];
      List itemsList = [];
      if (rawStops is Map) {
        final si = rawStops['items'];
        itemsList = si is List ? si : (si is Map ? [si] : []);
      } else if (rawStops is List) {
        itemsList = rawStops;
      }
      for (final s in itemsList) {
        if (s is Map<String, dynamic>) {
          try {
            stopsList.add(ShipmentStop.fromJson(s));
          } catch (_) {}
        }
      }
      stopsList.sort((a, b) => a.stopSequence.compareTo(b.stopSequence));
    } catch (_) {}

    String status = 'new';
    final rawStatuses = j['statuses']?['items'];
    final statuses = rawStatuses is List
        ? rawStatuses
        : (rawStatuses is Map ? [rawStatuses] : []);
    if (statuses.isNotEmpty) {
      final sv =
          (statuses.first['statusValueGid'] ?? '').toString().toLowerCase();
      if (sv.contains('in_progress')) {
        status = 'active';
      } else if (sv.contains('completed')) {
        status = 'completed';
      } else if (sv.contains('tendered')) {
        status = 'tendered';
      } else if (sv.contains('spot')) {
        status = 'review';
      } else {
        status = 'new';
      }
    } else if (tendersList.any((t) => t.isAccepted)) {
      status = 'approved';
    } else if (tendersList.any((t) => t.isPending)) {
      status = 'tendered';
    }

    final mc = j['marketCost']?['value'] != null
        ? (j['marketCost']['value'] as num).toDouble()
        : null;
    final tac = j['totalActualCost']?['value'] != null
        ? (j['totalActualCost']['value'] as num).toDouble()
        : null;
    final disc = j['attributeNumber18'] != null
        ? (j['attributeNumber18'] as num).toDouble()
        : 0.0;
    String? equip;
    if (j['firstEquipmentGroupGid'] != null) {
      final s = j['firstEquipmentGroupGid'].toString();
      equip = s.contains('.') ? s.split('.').skip(1).join('.') : s;
    }

    return CarrierShipment(
      shipmentXid: j['shipmentXid'] ?? '',
      domainName: j['domainName'] ?? '',
      source: CarrierLocation.fromJson(
          j['sourceLocation'] as Map<String, dynamic>?),
      dest:
          CarrierLocation.fromJson(j['destLocation'] as Map<String, dynamic>?),
      totalWeight: j['totalWeight'] != null
          ? CarrierWeight.fromJson(j['totalWeight'] as Map<String, dynamic>)
          : null,
      startTime: start,
      endTime: end,
      numStops: j['numStops'] ?? 0,
      status: status,
      tenders: tendersList,
      stops: stopsList,
      marketCost: mc,
      totalActualCost: tac,
      currency: j['marketCost']?['currency'] ?? 'USD',
      discountPercent: disc,
      equipment: equip,
      // Parse driver fields directly from the inline remarks collection.
      // OTM includes remarks when expand=remarks is set on the query.
      // If absent (e.g. shipment detail calls that don't expand remarks),
      // all fields are null and copyWithDriverRemarks() can hydrate later.
      driverPhone: _remarkText(j, 'DRIVER_PHONE'),
      driverName:  _remarkText(j, 'DRIVER_NAME'),
      vehicleReg:  _remarkText(j, 'VEHICLE_REG'),
      truckType:   _remarkText(j, 'TRUCK_TYPE'),
    );
  }

  /// Extracts a single remark text from the inline remarks collection by qualifier.
  /// Returns null if remarks are absent or the qualifier is not found.
  static String? _remarkText(Map<String, dynamic> j, String qualGid) {
    try {
      final raw = j['remarks'];
      if (raw == null) return null;
      final items = raw['items'];
      final list = items is List ? items : (items is Map ? [items] : <dynamic>[]);
      for (final r in list) {
        if (r['remarkQualGid']?.toString() == qualGid) {
          final text = r['remarkText']?.toString() ?? '';
          return text.isNotEmpty ? text : null;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Returns a copy of this shipment with driver fields populated from remarks.
  CarrierShipment copyWithDriverRemarks({
    String? driverPhone,
    String? driverName,
    String? vehicleReg,
    String? truckType,
  }) => CarrierShipment(
    shipmentXid:     shipmentXid,
    domainName:      domainName,
    source:          source,
    dest:            dest,
    totalWeight:     totalWeight,
    startTime:       startTime,
    endTime:         endTime,
    numStops:        numStops,
    status:          status,
    tenders:         tenders,
    stops:           stops,
    marketCost:      marketCost,
    totalActualCost: totalActualCost,
    currency:        currency,
    discountPercent: discountPercent,
    equipment:       equipment,
    driverPhone:     driverPhone,
    driverName:      driverName,
    vehicleReg:      vehicleReg,
    truckType:       truckType,
  );

  double? get buyNowPrice {
    if (marketCost == null) return null;
    if (discountPercent != null && discountPercent! > 0) {
      return marketCost! * (1 - discountPercent! / 100);
    }
    return marketCost;
  }

  int? get progressPercent {
    if (stops.isEmpty) return null;
    final completed = stops.where((s) => s.isCompleted).length;
    return ((completed / stops.length) * 100).round();
  }

  DateTime? get eta {
    try {
      return stops.firstWhere((s) => !s.isCompleted).scheduledArrival;
    } catch (_) {
      return endTime;
    }
  }

  bool get hasDriverAssigned => driverPhone != null && driverPhone!.isNotEmpty;

  // ── Ordinary tender selection ─────────────────────────────────────────
  /// Latest Ordinary tender by insertDate — used for accept/decline.
  TenderItem? get activeTender {
    final ordinary = tenders.where((t) => t.tenderType == 'Ordinary').toList()
      ..sort((a, b) {
        if (a.insertDate == null && b.insertDate == null) return 0;
        if (a.insertDate == null) return 1;
        if (b.insertDate == null) return -1;
        return b.insertDate!.compareTo(a.insertDate!);
      });
    return ordinary.isNotEmpty ? ordinary.first : null;
  }

  // ── Spot Bid tender selection ─────────────────────────────────────────
  /// Latest Spot Bid tender by insertDate — always picks the newest open
  /// tender so we never submit against a withdrawn/old transaction.
  TenderItem? get spotBidTender {
    final spotBids = tenders.where((t) => t.tenderType == 'Spot Bid').toList()
      ..sort((a, b) {
        if (a.insertDate == null && b.insertDate == null) return 0;
        if (a.insertDate == null) return 1;
        if (b.insertDate == null) return -1;
        return b.insertDate!.compareTo(a.insertDate!);
      });
    return spotBids.isNotEmpty ? spotBids.first : null;
  }
}

class TrackingEventItem {
  final String id;
  final String statusCodeGid;
  final String description;
  final DateTime? eventDate;
  final String? reasonCode;
  final String? stopXid;
  final String? stopNum; // stop number for matching with ShipmentStop

  const TrackingEventItem({
    required this.id,
    required this.statusCodeGid,
    required this.description,
    this.eventDate,
    this.reasonCode,
    this.stopXid,
    this.stopNum,
  });

  factory TrackingEventItem.fromJson(Map<String, dynamic> j) {
    DateTime? dt;
    try {
      dt = j['eventdate']?['value'] != null
          ? DateTime.parse(j['eventdate']['value'])
          : null;
    } catch (_) {}
    return TrackingEventItem(
      id: j['id']?.toString() ?? '',
      statusCodeGid: j['statusCodeGid'] ?? '',
      description: j['statusCodeDescription'] ?? j['statusCodeGid'] ?? '',
      eventDate: dt,
      reasonCode: j['statusReasonCodeGid'],
      stopXid: j['stopXid']?.toString(),
      stopNum: j['stopNum']?.toString(),
    );
  }
}