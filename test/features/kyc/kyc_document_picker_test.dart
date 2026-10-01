import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_image_picker.dart';

class _PdfPicker extends FilePicker {
  final Uint8List bytes = Uint8List.fromList('%PDF-1.7'.codeUnits);
  FileType? requestedType;
  List<String>? requestedExtensions;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    requestedType = type;
    requestedExtensions = allowedExtensions;
    return FilePickerResult([
      PlatformFile(name: 'identity.pdf', size: bytes.length, bytes: bytes),
    ]);
  }
}

void main() {
  testWidgets('identity PDF bytes reach submission without image decoding', (
    tester,
  ) async {
    final picker = _PdfPicker();
    FilePicker.platform = picker;
    Uint8List? selected;
    String? selectedName;
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(1920, 1080),
        builder: (context, child) => MaterialApp(
          home: Scaffold(
            body: AppImagePicker(
              label: 'Identity',
              fontSize: 16,
              height: 160,
              allowPdf: true,
              onImageSelected: (bytes, name) {
                selected = bytes;
                selectedName = name;
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();
    expect(picker.requestedType, FileType.custom);
    expect(picker.requestedExtensions, contains('pdf'));
    expect(selected, picker.bytes);
    expect(selectedName, 'identity.pdf');
    expect(find.text('identity.pdf'), findsOneWidget);
    expect(find.byIcon(Icons.picture_as_pdf_outlined), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
