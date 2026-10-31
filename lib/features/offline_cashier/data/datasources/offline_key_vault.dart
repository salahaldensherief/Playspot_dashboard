abstract class OfflineKeyVault {
  Future<String?> read(String name);
  Future<void> write(String name, String value);
}
