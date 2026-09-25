enum BookingStatus { pending, pendingVerification, upcoming, completed, cancelled, rejected, inProgress }

extension BookingStatusX on BookingStatus {
  String toDbString() {
    switch (this) {
      case BookingStatus.pending:
        return 'pending';
      case BookingStatus.pendingVerification:
        return 'pending_verification';
      case BookingStatus.upcoming:
        return 'upcoming';
      case BookingStatus.completed:
        return 'completed';
      case BookingStatus.cancelled:
        return 'cancelled';
      case BookingStatus.rejected:
        return 'rejected';
      case BookingStatus.inProgress:
        return 'in_progress';
    }
  }

  static BookingStatus fromString(String? status) {
    if (status == null) return BookingStatus.pending;
    final clean = status.trim().toLowerCase().replaceAll(' ', '_');
    switch (clean) {
      case 'pending_verification':
      case 'pendingverification':
        return BookingStatus.pendingVerification;
      case 'upcoming':
        return BookingStatus.upcoming;
      case 'completed':
        return BookingStatus.completed;
      case 'rejected':
      case 'reject':
        return BookingStatus.rejected;
      case 'cancelled':
      case 'canceled':
      case 'no_show':
      case 'noshow':
        return BookingStatus.cancelled;
      case 'in_progress':
      case 'inprogress':
      case 'active':
        return BookingStatus.inProgress;
      case 'pending':
      default:
        return BookingStatus.pending;
    }
  }
}
