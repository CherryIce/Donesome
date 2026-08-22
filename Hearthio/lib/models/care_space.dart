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
  final normalized = name.trim();
  if (normalized == '浴室' || normalized == '洗手间') return '卫生间';
  for (final type in careSpaceTypeTemplates) {
    if (normalized == type) return type;
  }
  return '其他';
}

String _requiredSpaceString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Missing space $key');
  }
  return value.trim();
}
