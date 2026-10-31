import 'dart:convert';
import 'file_download_mobile.dart'
    if (dart.library.js_interop) 'file_download_web.dart';

class FileDownloadHelper {
  static void downloadCsv(String csvContent, String fileName) {
    if (csvContent.isEmpty) return;
    final bytes = utf8.encode(csvContent);
    downloadFileFromBytes(
      bytes,
      fileName.endsWith('.csv') ? fileName : '$fileName.csv',
      'text/csv;charset=utf-8;',
    );
  }
}
