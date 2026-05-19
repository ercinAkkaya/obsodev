import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:pdfx/pdfx.dart';

import '../data/academic_records.dart';
import '../data/user_credentials_repository.dart';

const Color _obsAppBar = Color(0xFF1C2F4F);

const double _kYokPreviewMaxHeight = 420;

enum _YokPreviewKind { pdf, image, unsupported }

_YokPreviewKind _yokPreviewKindForPath(String path) {
  switch (p.extension(path).toLowerCase()) {
    case '.pdf':
      return _YokPreviewKind.pdf;
    case '.jpg':
    case '.jpeg':
    case '.png':
    case '.gif':
    case '.webp':
    case '.bmp':
      return _YokPreviewKind.image;
    default:
      return _YokPreviewKind.unsupported;
  }
}

Future<void> _tryOpenYokDocument(BuildContext context, YokDocumentRecord r) async {
  final fp = r.storedPath.trim();
  if (fp.isEmpty) return;
  if (!File(fp).existsSync()) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dosya bulunamadı. Profilden silip yeniden ekleyin.')),
    );
    return;
  }
  final res = await OpenFilex.open(fp);
  if (!context.mounted || res.type == ResultType.done) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
}

/// Profildeki YÖK belge kopyasının uygulama içi önizlemesi (PDF / yaygın görseller).
class _YokDocInlinePreview extends StatefulWidget {
  const _YokDocInlinePreview({super.key, required this.filePath});

  final String filePath;

  @override
  State<_YokDocInlinePreview> createState() => _YokDocInlinePreviewState();
}

class _YokDocInlinePreviewState extends State<_YokDocInlinePreview> {
  PdfControllerPinch? _pdfController;

  @override
  void initState() {
    super.initState();
    _attachPdfIfNeeded();
  }

  void _attachPdfIfNeeded() {
    if (_yokPreviewKindForPath(widget.filePath) != _YokPreviewKind.pdf) {
      _pdfController?.dispose();
      _pdfController = null;
      return;
    }
    _pdfController?.dispose();
    _pdfController = PdfControllerPinch(
      document: PdfDocument.openFile(widget.filePath),
    );
  }

  @override
  void didUpdateWidget(covariant _YokDocInlinePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filePath != widget.filePath) {
      _attachPdfIfNeeded();
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fp = widget.filePath.trim();
    final file = File(fp);
    if (fp.isEmpty || !file.existsSync()) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: Text(
          'Dosya bulunamadı.',
          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
        ),
      );
    }

    final kind = _yokPreviewKindForPath(fp);
    switch (kind) {
      case _YokPreviewKind.pdf:
        final c = _pdfController;
        if (c == null) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: _kYokPreviewMaxHeight,
              width: double.infinity,
              child: PdfViewPinch(
                controller: c,
                builders: PdfViewPinchBuilders(
                  options: const DefaultBuilderOptions(),
                  errorBuilder: (context, error) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'PDF önizlemesi açılamadı.\nHarici uygulamada açmayı deneyin.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade800, height: 1.35),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      case _YokPreviewKind.image:
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SizedBox(
                  height: _kYokPreviewMaxHeight,
                  width: constraints.maxWidth,
                  child: InteractiveViewer(
                    minScale: 0.25,
                    maxScale: 5,
                    child: Center(
                      child: Image.file(
                        file,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                        errorBuilder: (_, __, ___) => Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Görsel önizlemesi yapılamadı. «Harici aç» ile görüntüleyin.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade800, height: 1.35),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      case _YokPreviewKind.unsupported:
        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bu dosya türü uygulama içinde önizlenemez.',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.35),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _tryOpenYokDocument(
                    context,
                    YokDocumentRecord(storedPath: fp),
                  ),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('Harici uygulamada aç'),
                ),
              ),
            ],
          ),
        );
    }
  }
}

String _dash(String s) {
  final t = s.trim();
  return t.isEmpty ? '—' : t;
}

const Color _kInfoTableHeader = Color(0xFF5C5C5C);
const Color _kInfoTableBorder = Color(0xFFD0D0D0);

/// Profil özet alanları — etiket | değer tablosu.
Widget _profileInfoTable(List<({String label, String value})> rows) {
  if (rows.isEmpty) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          '—',
          style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
        ),
      ),
    );
  }

  return Padding(
    padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
    child: Table(
      columnWidths: const {
        0: FixedColumnWidth(132),
        1: FlexColumnWidth(),
      },
      border: TableBorder.all(color: _kInfoTableBorder, width: 1),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: const BoxDecoration(color: _kInfoTableHeader),
          children: [
            _infoTableHeaderCell('Alan'),
            _infoTableHeaderCell('Bilgi'),
          ],
        ),
        for (var i = 0; i < rows.length; i++)
          TableRow(
            decoration: BoxDecoration(
              color: i.isOdd ? const Color(0xFFF5F5F5) : Colors.white,
            ),
            children: [
              _infoTableLabelCell(rows[i].label),
              _infoTableValueCell(_dash(rows[i].value)),
            ],
          ),
      ],
    ),
  );
}

Widget _infoTableHeaderCell(String text) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 11.5,
        height: 1.15,
      ),
    ),
  );
}

Widget _infoTableLabelCell(String text) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    child: Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 12,
        height: 1.25,
        color: Colors.grey.shade800,
      ),
    ),
  );
}

Widget _infoTableValueCell(String text) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    child: SelectableText(
      text,
      style: TextStyle(fontSize: 12.5, height: 1.3, color: Colors.grey.shade900),
    ),
  );
}

/// Profildeki serbest metin alanları — çekmece maddeleri.
class PortalProfileTextPage extends StatelessWidget {
  const PortalProfileTextPage({
    super.key,
    required this.title,
    required this.emptyHint,
    required this.textOf,
  });

  final String title;
  final String emptyHint;
  final String Function(UserProfile p) textOf;

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
        final text = textOf(snap.data!).trim();
        return Scaffold(
          appBar: AppBar(
            backgroundColor: _obsAppBar,
            foregroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            title: Text(title),
          ),
          body: text.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Text(
                      emptyHint,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700, height: 1.35),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: SelectableText(
                    text,
                    style: const TextStyle(fontSize: 15, height: 1.45),
                  ),
                ),
        );
      },
    );
  }
}

/// Çekmece › YÖK — metin ve eklenmiş belge dosyaları.
class YokApplicationsPortalPage extends StatelessWidget {
  const YokApplicationsPortalPage({super.key});

  String _docTitle(YokDocumentRecord r) {
    final n = r.displayName.trim();
    if (n.isNotEmpty) return n;
    final path = r.storedPath.trim();
    if (path.isEmpty) return 'Belge';
    return p.basename(path);
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
              surfaceTintColor: Colors.transparent,
              title: const Text('Başvurular ve sonuçları'),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final p0 = snap.data!;
        final text = p0.yokAppsInfo.trim();
        final docs = AcademicJson.decodeYokDocuments(p0.yokDocumentsJson)
            .where((e) => e.storedPath.trim().isNotEmpty)
            .toList();
        final noText = text.isEmpty;
        final noDocs = docs.isEmpty;

        if (noText && noDocs) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: _obsAppBar,
              foregroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              title: const Text('Başvurular ve sonuçları'),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Text(
                  'Henüz içerik yok. Akademik bilgiler (zil) › «Menü, YÖK ve ÖSYM» bölümünde '
                  'metin yazın ve isteğe bağlı PDF / belge ekleyip Kaydet\'e basın.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700, height: 1.38),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: _obsAppBar,
            foregroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            title: const Text('Başvurular ve sonuçları'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
            children: [
              if (!noText) ...[
                Text(
                  'Başvuru ve sonuç metni',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 10),
                SelectableText(
                  text,
                  style: const TextStyle(fontSize: 15, height: 1.45),
                ),
              ],
              if (!noDocs) ...[
                if (!noText) const SizedBox(height: 24),
                Text(
                  'Yüklenen belgeler',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 10),
                ...docs.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      elevation: 0,
                      color: Colors.grey.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 10, 4, 0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _docTitle(e),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        p.basename(e.storedPath),
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.open_in_new_rounded),
                                  tooltip: 'Harici uygulamada aç',
                                  onPressed: () => _tryOpenYokDocument(context, e),
                                ),
                              ],
                            ),
                          ),
                          _YokDocInlinePreview(
                            key: ValueKey<String>(e.storedPath),
                            filePath: e.storedPath,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Çekmece › ÖSYM — profildeki sınav listesi ve isteğe bağlı ek not.
class OsymExamsPortalPage extends StatelessWidget {
  const OsymExamsPortalPage({super.key});

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
              surfaceTintColor: Colors.transparent,
              title: const Text('ÖSYM sonuçları başvuruları'),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final p = snap.data!;
        final exams = AcademicJson.decodeOsymExams(p.osymExamsJson);
        final extra = p.osymInfo.trim();

        if (exams.isEmpty && extra.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: _obsAppBar,
              foregroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              title: const Text('ÖSYM sonuçları başvuruları'),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Text(
                  'Henüz kayıt yok. Ana sayfa › zil simgesi › akademik bilgiler bölümünde '
                  '«ÖSYM sınavları» altından sınav ekleyip Kaydet\'e basın. İsterseniz '
                  'listenin altına ek not da yazabilirsiniz.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700, height: 1.38),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: _obsAppBar,
            foregroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            title: const Text('ÖSYM sonuçları başvuruları'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              if (exams.isNotEmpty) ...[
                Text(
                  'Sınavlar',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 10),
                ...exams.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      elevation: 0,
                      color: Colors.grey.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SelectableText(
                              e.examName.isEmpty ? '—' : e.examName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Tarih',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      SelectableText(
                                        e.examDate.trim().isEmpty ? '—' : e.examDate.trim(),
                                        style: const TextStyle(fontSize: 14, height: 1.35),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Puan / not',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      SelectableText(
                                        e.score.trim().isEmpty ? '—' : e.score.trim(),
                                        style: const TextStyle(fontSize: 14, height: 1.35),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (e.note.trim().isNotEmpty) ...[
                              const SizedBox(height: 10),
                              SelectableText(
                                e.note.trim(),
                                style: TextStyle(
                                  fontSize: 13.5,
                                  height: 1.4,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (extra.isNotEmpty) const SizedBox(height: 8),
              ],
              if (extra.isNotEmpty) ...[
                Text(
                  exams.isNotEmpty ? 'Ek notlar' : 'Metin',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 10),
                SelectableText(
                  extra,
                  style: const TextStyle(fontSize: 15, height: 1.45),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Çekmece › Aktif akademik dönem bilgileri (profilden).
class ActiveAcademicPeriodPage extends StatelessWidget {
  const ActiveAcademicPeriodPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile>(
      future: UserCredentialsRepository.instance.getStored(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            appBar: _ActiveScaffoldTitle(title: Text('Aktif akademik dönem bilgileri')),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final p = snap.data!;
        return Scaffold(
          appBar: const _ActiveScaffoldTitle(title: Text('Aktif akademik dönem bilgileri')),
          body: ListView(
            children: [
              if (p.universityName.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Text(
                    p.universityName.trim(),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Colors.grey.shade900,
                    ),
                  ),
                ),
              _profileInfoTable([
                (label: 'Eğitim-öğretim yılı', value: p.academicYear),
                (label: 'Yarıyıl / dönem', value: p.academicTerm),
                (label: 'Kayıt tarihi', value: p.registrationDate),
                (label: 'Danışman', value: p.advisorInfo),
                (label: 'Genel AGNO', value: p.overallGpa),
              ]),
            ],
          ),
        );
      },
    );
  }
}

/// Çekmece › Aktif öğrenim bilgileri (profilden).
class ActiveStudyInfoPage extends StatelessWidget {
  const ActiveStudyInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile>(
      future: UserCredentialsRepository.instance.getStored(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            appBar: _ActiveScaffoldTitle(title: Text('Aktif öğrenim bilgileri')),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final p = snap.data!;
        return Scaffold(
          appBar: const _ActiveScaffoldTitle(title: Text('Aktif öğrenim bilgileri')),
          body: ListView(
            children: [
              if (p.universityName.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Text(
                    p.universityName.trim(),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Colors.grey.shade900,
                    ),
                  ),
                ),
              _profileInfoTable([
                (label: 'Fakülte / birim', value: p.eduFaculty),
                (label: 'Bölüm / program', value: p.eduDepartment),
                (label: 'Sınıf', value: p.eduGrade),
                (label: 'Eğitim-öğretim yılı', value: p.academicYear),
                (label: 'Yarıyıl / dönem', value: p.academicTerm),
                (label: 'Danışman', value: p.advisorInfo),
                (label: 'Kayıt tarihi', value: p.registrationDate),
              ]),
            ],
          ),
        );
      },
    );
  }
}

class _ActiveScaffoldTitle extends StatelessWidget implements PreferredSizeWidget {
  const _ActiveScaffoldTitle({required this.title});

  final Widget title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: _obsAppBar,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      title: title,
    );
  }
}
