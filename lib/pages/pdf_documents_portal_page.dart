import 'package:flutter/material.dart';

import '../data/academic_records.dart';
import '../data/user_credentials_repository.dart';
import '../widgets/pdf_inline_preview.dart';

const Color _obsAppBar = Color(0xFF1C2F4F);

enum PdfDocumentKind { yok, osym, digital }

/// Çekmece sayfaları — yalnızca üst üste PDF önizleme (başlık / metin yok).
class PdfDocumentsPortalPage extends StatelessWidget {
  const PdfDocumentsPortalPage({
    super.key,
    required this.title,
    required this.kind,
  });

  final String title;
  final PdfDocumentKind kind;

  static String _documentsJson(UserProfile p, PdfDocumentKind k) {
    switch (k) {
      case PdfDocumentKind.yok:
        return p.yokDocumentsJson;
      case PdfDocumentKind.osym:
        return p.osymDocumentsJson;
      case PdfDocumentKind.digital:
        return p.digitalIdDocumentsJson;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile>(
      future: UserCredentialsRepository.instance.getStored(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: _obsAppBar,
              foregroundColor: Colors.white,
              title: Text(title),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final docs = AcademicJson.decodeYokDocuments(_documentsJson(snap.data!, kind))
            .where((e) => e.storedPath.trim().isNotEmpty && isPdfPath(e.storedPath))
            .toList();

        return Scaffold(
          appBar: AppBar(
            backgroundColor: _obsAppBar,
            foregroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            title: Text(title),
          ),
          body: docs.isEmpty
              ? const SizedBox.shrink()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final path = docs[i].storedPath.trim();
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: ColoredBox(
                        color: Colors.grey.shade100,
                        child: PdfInlinePreview(
                          key: ValueKey<String>(path),
                          filePath: path,
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
