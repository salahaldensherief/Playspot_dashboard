import '../../domain/entities/app_settings_entity.dart';

class AppSettingsModel extends AppSettingsEntity {
  const AppSettingsModel({
    super.id,
    required super.whatsappPhone,
    required super.supportPhone,
    required super.supportEmail,
    required super.vodafoneCashNumber,
    super.updatedAt,
  });

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) {
    return AppSettingsModel(
      id: json['id']?.toString(),
      whatsappPhone: json['whatsapp_phone'] as String? ?? '',
      supportPhone: json['support_phone'] as String? ?? '',
      supportEmail: json['support_email'] as String? ?? '',
      vodafoneCashNumber: json['vodafone_cash_number'] as String? ?? '',
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'whatsapp_phone': whatsappPhone,
      'support_phone': supportPhone,
      'support_email': supportEmail,
      'vodafone_cash_number': vodafoneCashNumber,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
