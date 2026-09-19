import 'package:equatable/equatable.dart';

class AppSettingsEntity extends Equatable {
  final String? id;
  final String whatsappPhone;
  final String supportPhone;
  final String supportEmail;
  final String vodafoneCashNumber;
  final DateTime? updatedAt;

  const AppSettingsEntity({
    this.id,
    required this.whatsappPhone,
    required this.supportPhone,
    required this.supportEmail,
    required this.vodafoneCashNumber,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        whatsappPhone,
        supportPhone,
        supportEmail,
        vodafoneCashNumber,
        updatedAt,
      ];
}
