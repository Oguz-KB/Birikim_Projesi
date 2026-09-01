class UserRuleSettings {
  final String id;
  final String userId;
  final double selfTaxRate;
  final bool roundupEnabled;
  final double roundupUnit;
  final int waitingRoomHours;
  final double waitingRoomThreshold;
  final String validFrom;

  UserRuleSettings({
    required this.id,
    required this.userId,
    required this.selfTaxRate,
    required this.roundupEnabled,
    required this.roundupUnit,
    required this.waitingRoomHours,
    required this.waitingRoomThreshold,
    required this.validFrom,
  });

  factory UserRuleSettings.fromJson(Map<String, dynamic> json) {
    return UserRuleSettings(
      id: json['id'],
      userId: json['user_id'],
      selfTaxRate: double.tryParse(json['self_tax_rate'].toString()) ?? 0.0,
      roundupEnabled: json['roundup_enabled'] == true || json['roundup_enabled'] == 1,
      roundupUnit: double.tryParse(json['roundup_unit'].toString()) ?? 0.0,
      waitingRoomHours: json['waiting_room_hours'] is int ? json['waiting_room_hours'] : int.tryParse(json['waiting_room_hours'].toString()) ?? 0,
      waitingRoomThreshold: double.tryParse(json['waiting_room_threshold'].toString()) ?? 0.0,
      validFrom: json['valid_from'],
    );
  }
}

class UserRuleSettingsUpdate {
  final double? selfTaxRate;
  final bool? roundupEnabled;
  final double? roundupUnit;
  final int? waitingRoomHours;
  final double? waitingRoomThreshold;

  UserRuleSettingsUpdate({
    this.selfTaxRate,
    this.roundupEnabled,
    this.roundupUnit,
    this.waitingRoomHours,
    this.waitingRoomThreshold,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (selfTaxRate != null) data['self_tax_rate'] = selfTaxRate;
    if (roundupEnabled != null) data['roundup_enabled'] = roundupEnabled;
    if (roundupUnit != null) data['roundup_unit'] = roundupUnit;
    if (waitingRoomHours != null) data['waiting_room_hours'] = waitingRoomHours;
    if (waitingRoomThreshold != null) data['waiting_room_threshold'] = waitingRoomThreshold;
    return data;
  }
}
