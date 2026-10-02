import 'dart:typed_data';
import 'package:equatable/equatable.dart';

class SubmitKycParams extends Equatable {
  final String userId;
  final String loungeId;
  final Uint8List idCardBytes;
  final String idCardName;
  final Uint8List? businessDocBytes;
  final String? businessDocName;

  const SubmitKycParams({
    required this.userId,
    required this.loungeId,
    required this.idCardBytes,
    required this.idCardName,
    this.businessDocBytes,
    this.businessDocName,
  });

  @override
  List<Object?> get props => [
    userId,
    loungeId,
    idCardBytes,
    idCardName,
    businessDocBytes,
    businessDocName,
  ];
}
