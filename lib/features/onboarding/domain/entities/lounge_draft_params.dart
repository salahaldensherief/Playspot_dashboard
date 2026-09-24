import 'package:equatable/equatable.dart';

class LoungeDraftParams extends Equatable {
  final int step;
  final String name;
  final String description;
  final String city;
  final String address;
  final String opensAt;
  final String closesAt;
  final double? lat;
  final double? lng;
  final bool isChain;
  final String brandName;
  final int branchesCount;
  final String branchName;

  const LoungeDraftParams({
    this.step = 0,
    this.name = '',
    this.description = '',
    this.city = '',
    this.address = '',
    this.opensAt = '',
    this.closesAt = '',
    this.lat,
    this.lng,
    this.isChain = false,
    this.brandName = '',
    this.branchesCount = 1,
    this.branchName = '',
  });

  LoungeDraftParams copyWith({
    int? step,
    String? name,
    String? description,
    String? city,
    String? address,
    String? opensAt,
    String? closesAt,
    double? lat,
    double? lng,
    bool? isChain,
    String? brandName,
    int? branchesCount,
    String? branchName,
  }) {
    return LoungeDraftParams(
      step: step ?? this.step,
      name: name ?? this.name,
      description: description ?? this.description,
      city: city ?? this.city,
      address: address ?? this.address,
      opensAt: opensAt ?? this.opensAt,
      closesAt: closesAt ?? this.closesAt,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      isChain: isChain ?? this.isChain,
      brandName: brandName ?? this.brandName,
      branchesCount: branchesCount ?? this.branchesCount,
      branchName: branchName ?? this.branchName,
    );
  }

  Map<String, dynamic> toJson() => {
        'step': step,
        'name': name,
        'description': description,
        'city': city,
        'address': address,
        'opensAt': opensAt,
        'closesAt': closesAt,
        'lat': lat,
        'lng': lng,
        'isChain': isChain,
        'brandName': brandName,
        'branchesCount': branchesCount,
        'branchName': branchName,
      };

  factory LoungeDraftParams.fromJson(Map<String, dynamic> json) {
    return LoungeDraftParams(
      step: json['step'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      opensAt: json['opensAt']?.toString() ?? '',
      closesAt: json['closesAt']?.toString() ?? '',
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      isChain: json['isChain'] as bool? ?? false,
      brandName: json['brandName']?.toString() ?? '',
      branchesCount: json['branchesCount'] as int? ?? 1,
      branchName: json['branchName']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [
        step,
        name,
        description,
        city,
        address,
        opensAt,
        closesAt,
        lat,
        lng,
        isChain,
        brandName,
        branchesCount,
        branchName,
      ];
}
