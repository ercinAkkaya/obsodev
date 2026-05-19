import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

const double kPdfPreviewHeight = 400;

bool isPdfPath(String path) => path.trim().toLowerCase().endsWith('.pdf');

/// Yalnızca PDF dosyalarını uygulama içinde gösterir.
class PdfInlinePreview extends StatefulWidget {
  const PdfInlinePreview({
    super.key,
    required this.filePath,
    this.height = kPdfPreviewHeight,
  });

  final String filePath;
  final double height;

  @override
  State<PdfInlinePreview> createState() => _PdfInlinePreviewState();
}

class _PdfInlinePreviewState extends State<PdfInlinePreview> {
  PdfControllerPinch? _controller;

  @override
  void initState() {
    super.initState();
    _openPdf();
  }

  void _openPdf() {
    final fp = widget.filePath.trim();
    if (!isPdfPath(fp) || !File(fp).existsSync()) {
      _controller?.dispose();
      _controller = null;
      return;
    }
    _controller?.dispose();
    _controller = PdfControllerPinch(document: PdfDocument.openFile(fp));
  }

  @override
  void didUpdateWidget(covariant PdfInlinePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filePath != widget.filePath) _openPdf();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fp = widget.filePath.trim();
    if (fp.isEmpty || !File(fp).existsSync()) {
      return SizedBox(
        height: 48,
        child: Center(
          child: Text(
            'Dosya bulunamadı',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ),
      );
    }
    if (!isPdfPath(fp)) {
      return SizedBox(
        height: 48,
        child: Center(
          child: Text(
            'Yalnızca PDF önizlenir',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ),
      );
    }

    final c = _controller;
    if (c == null) {
      return SizedBox(
        height: widget.height,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: PdfViewPinch(
        controller: c,
        builders: PdfViewPinchBuilders(
          options: const DefaultBuilderOptions(),
          errorBuilder: (context, error) => Center(
            child: Text(
              'PDF açılamadı',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }
}
