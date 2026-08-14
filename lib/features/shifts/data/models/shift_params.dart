class CloseShiftParams {
  final String shiftId;
  final double actualCash;
  final String? notes;

  const CloseShiftParams({
    required this.shiftId,
    required this.actualCash,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'p_shift_id': shiftId,
      'p_actual_cash': actualCash,
      'p_notes': notes,
    };
  }
}

class OpenShiftParams {
  final String cashierId;
  final double startingCash;
  final String? notes;

  const OpenShiftParams({
    required this.cashierId,
    required this.startingCash,
    this.notes,
  });
}
