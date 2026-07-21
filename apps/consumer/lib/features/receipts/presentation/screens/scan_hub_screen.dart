import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../core/widgets/receipt24_widgets.dart';
import '../../providers/receipt_providers.dart';

class ScanHubScreen extends ConsumerWidget {
  const ScanHubScreen({super.key});

  Future<void> _processFile(
    BuildContext context,
    WidgetRef ref, {
    required Uint8List bytes,
    required String fileName,
    required String receiptSource,
    required String uploadSource,
    required String fileType,
    required String bucket,
  }) async {
    final l10n = context.l10n;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: Receipt24Spacing.md),
            Expanded(child: Text(l10n.processingReceipt)),
          ],
        ),
      ),
    );

    try {
      final result = await ref.read(receiptServiceProvider).processUpload(
            userId: user.id,
            bytes: bytes,
            fileName: fileName,
            receiptSource: receiptSource,
            uploadSource: uploadSource,
            fileType: fileType,
            bucket: bucket,
          );

      ref.read(pendingCaptureProvider.notifier).state = PendingReceiptCapture(
        extraction: result.extraction,
        receiptSource: receiptSource,
        imagePath: bucket.contains('pdf') ? null : result.storagePath,
        pdfPath: bucket.contains('pdf') ? result.storagePath : null,
        bucket: bucket,
        uploadId: result.uploadId,
        previewBytes: fileType.startsWith('image') ? bytes : null,
      );

      if (context.mounted) {
        Navigator.of(context).pop();
        context.push('/receipts/review');
      }
    } catch (_) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.genericError)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final emailAsync = ref.watch(emailForwardingProvider);
    final picker = ImagePicker();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.captureTitle)),
      body: ListView(
        padding: const EdgeInsets.all(Receipt24Spacing.md),
        children: [
          _CaptureTile(
            icon: Icons.camera_alt,
            label: l10n.captureCamera,
            color: const Color(Receipt24Colors.primary),
            onTap: () async {
              final photo = await picker.pickImage(
                source: ImageSource.camera,
                imageQuality: 85,
              );
              if (photo == null) return;
              final bytes = await photo.readAsBytes();
              if (!context.mounted) return;
              await _processFile(
                context,
                ref,
                bytes: bytes,
                fileName: photo.name,
                receiptSource: 'camera_scan',
                uploadSource: 'camera',
                fileType: 'image_jpeg',
                bucket: 'receipt-images',
              );
            },
          ),
          _CaptureTile(
            icon: Icons.photo_library,
            label: l10n.captureGallery,
            onTap: () async {
              final image = await picker.pickImage(
                source: ImageSource.gallery,
                imageQuality: 85,
              );
              if (image == null) return;
              final bytes = await image.readAsBytes();
              if (!context.mounted) return;
              await _processFile(
                context,
                ref,
                bytes: bytes,
                fileName: image.name,
                receiptSource: 'image_upload',
                uploadSource: 'gallery',
                fileType: 'image_jpeg',
                bucket: 'receipt-images',
              );
            },
          ),
          _CaptureTile(
            icon: Icons.picture_as_pdf,
            label: l10n.capturePdf,
            onTap: () async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['pdf'],
                withData: true,
              );
              if (result == null || result.files.single.bytes == null) return;
              if (!context.mounted) return;
              await _processFile(
                context,
                ref,
                bytes: result.files.single.bytes!,
                fileName: result.files.single.name,
                receiptSource: 'pdf_upload',
                uploadSource: 'file_picker',
                fileType: 'application_pdf',
                bucket: 'receipt-pdfs',
              );
            },
          ),
          _CaptureTile(
            icon: Icons.edit_note,
            label: l10n.captureManual,
            onTap: () => context.push('/receipts/manual'),
          ),
          _CaptureTile(
            icon: Icons.qr_code_scanner,
            label: l10n.captureQr,
            onTap: () => context.push('/receipts/qr-scan'),
          ),
          const SizedBox(height: Receipt24Spacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Receipt24Spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.email_outlined,
                          color: Color(Receipt24Colors.primary)),
                      const SizedBox(width: Receipt24Spacing.sm),
                      Text(l10n.captureEmail,
                          style: Theme.of(context).textTheme.titleSmall),
                    ],
                  ),
                  const SizedBox(height: Receipt24Spacing.sm),
                  Text(l10n.emailForwardingHint,
                      style: const TextStyle(
                          color: Color(Receipt24Colors.textSecondary))),
                  const SizedBox(height: Receipt24Spacing.sm),
                  emailAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const Text('—'),
                    data: (email) => SelectableText(
                      email ?? '—',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CaptureTile extends StatelessWidget {
  const _CaptureTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: Receipt24Spacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (color ?? Theme.of(context).colorScheme.primary)
              .withValues(alpha: 0.15),
          child: Icon(icon, color: color ?? Theme.of(context).colorScheme.primary),
        ),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
