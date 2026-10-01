import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../art_core/widgets/app_cached_image.dart';

class KycDocumentPreview extends StatelessWidget {
  final String url;
  const KycDocumentPreview({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(url);
    if (uri?.path.toLowerCase().endsWith('.pdf') == true) {
      return OutlinedButton.icon(
        onPressed: () => _openPdf(context, uri!),
        icon: const Icon(Icons.picture_as_pdf),
        label: Text('kyc_snapshot.open_pdf'.tr()),
      );
    }
    return GestureDetector(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          child: InteractiveViewer(
            child: AppCachedImage(imageUrl: url, fit: BoxFit.contain),
          ),
        ),
      ),
      child: SizedBox(
        height: 280,
        width: double.infinity,
        child: AppCachedImage(imageUrl: url, fit: BoxFit.contain),
      ),
    );
  }

  Future<void> _openPdf(BuildContext context, Uri uri) async {
    try {
      if (uri.scheme == 'https' &&
          await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {
      /* Report failure below while keeping the review open. */
    }
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('kyc_snapshot.open_failed'.tr())));
    }
  }
}
