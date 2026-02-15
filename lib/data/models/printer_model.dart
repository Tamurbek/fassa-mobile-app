class PrinterModel {
  final String id;
  final String name;
  final String? ipAddress;
  final int port;
  final String connectionType;
  final bool isActive;
  final String cafeId;
  final String? preparationAreaId;

  PrinterModel({
    required this.id,
    required this.name,
    this.ipAddress,
    this.port = 9100,
    this.connectionType = 'NETWORK',
    this.isActive = true,
    required this.cafeId,
    this.preparationAreaId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'ip_address': ipAddress,
    'port': port,
    'connection_type': connectionType,
    'is_active': isActive,
    'cafe_id': cafeId,
    'preparation_area_id': preparationAreaId,
  };

  factory PrinterModel.fromJson(Map<String, dynamic> json) => PrinterModel(
    id: json['id'],
    name: json['name'],
    ipAddress: json['ip_address'],
    port: json['port'] ?? 9100,
    connectionType: json['connection_type'] ?? 'NETWORK',
    isActive: json['is_active'] ?? true,
    cafeId: json['cafe_id'] ?? '',
    preparationAreaId: json['preparation_area_id'],
  );
}
