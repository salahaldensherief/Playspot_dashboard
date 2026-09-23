enum BookingStatus { pending, upcoming, completed, cancelled, inProgress }

extension BookingStatusX on BookingStatus {
  String toDbString() {
    switch (this) {
      case BookingStatus.pending:
        return 'pending';
      case BookingStatus.upcoming:
        return 'upcoming';
      case BookingStatus.completed:
        return 'completed';
      case BookingStatus.cancelled:
        return 'cancelled';
      case BookingStatus.inProgress:
        return 'in_progress';
    }
  }

  static BookingStatus fromString(String? status) {
    if (status == null) return BookingStatus.pending;
    final clean = status.trim().toLowerCase().replaceAll(' ', '_');
    switch (clean) {
      case 'upcoming':
        return BookingStatus.upcoming;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
      case 'canceled':
      case 'rejected':
      case 'reject':
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
