class CareSpace {
  const CareSpace({required this.id, required this.type, required this.name});

  final String id;
  final String type;
  final String name;

  CareSpace copyWith({String? type, String? name}) =>
      CareSpace(id: id, type: type ?? this.type, name: name ?? this.name);

  Map<String, dynamic> toJson() => {'id': id, 'type': type, 'name': name};

  factory CareSpace.fromJson(Map<String, dynamic> json) => CareSpace(
    id: _requiredSpaceString(json, 'id'),
    type: _requiredSpaceString(json, 'type'),
    name: _requiredSpaceString(json, 'name'),
  );
}

const careSpaceTypeTemplates = <String>[
  '客厅',
  '卧室',
  '厨房',
  '卫生间',
  '阳台',
  '书房',
  '餐厅',
  '储物间',
  '玄关',
  '其他',
];

String careSpaceTypeForLegacyName(String name) {
  return knownCareSpaceType(name) ?? '其他';
}

String? knownCareSpaceType(String value) => switch (value.trim()) {
  '客厅' || 'Living room' => '客厅',
  '卧室' || 'Bedroom' => '卧室',
  '厨房' || 'Kitchen' => '厨房',
  '卫生间' || '浴室' || '洗手间' || 'Bathroom' => '卫生间',
  '阳台' || 'Balcony' => '阳台',
  '书房' || 'Study' => '书房',
  '餐厅' || 'Dining room' => '餐厅',
  '储物间' || 'Storage room' => '储物间',
  '玄关' || 'Entryway' => '玄关',
  '其他' || 'Other' => '其他',
  _ => null,
};

bool careSpaceUsesDefaultName(CareSpace space) {
  final type = knownCareSpaceType(space.type);
  final nameType = knownCareSpaceType(space.name);
  return type != null && nameType == type;
}

String _requiredSpaceString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Missing space $key');
  }
  return value.trim();
}
