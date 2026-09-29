import 'dart:convert';
import 'dart:js_interop';

@JS('eval')
external void _jsEval(String code);

void downloadFileFromBytes(List<int> bytes, String filename, String mimeType) {
  try {
    final base64Content = base64Encode(bytes);
    final dataUri = 'data:$mimeType;base64,$base64Content';
    final script = '''
      (function() {
        var link = document.createElement('a');
        link.href = "$dataUri";
        link.download = "$filename";
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
      })();
    ''';
    _jsEval(script);
  } catch (_) {}
}
