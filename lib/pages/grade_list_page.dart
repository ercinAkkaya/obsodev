import 'package:flutter/material.dart';

import '../data/academic_records.dart';
import '../data/user_credentials_repository.dart';

const Color _obsAppBar = Color(0xFF1C2F4F);

String _dashCell(String s) {
  final t = s.trim();
  return t.isEmpty ? '—' : t;
}

/// Drawer → Not listesi (profilden tablo).
class GradeListPage extends StatelessWidget {
  const GradeListPage({super.key});

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
              title: const Text('Not listesi'),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final list = AcademicJson.decodeGrades(snap.data!.gradesJson);
        return Scaffold(
          appBar: AppBar(
            backgroundColor: _obsAppBar,
            foregroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            title: const Text('Not listesi'),
          ),
          body: list.isEmpty
              ? _hint(context)
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: _GradeTableWithHorizontalScroll(
                        list: list,
                        minWidth: constraints.maxWidth,
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _hint(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fact_check_outlined, size: 56, color: Colors.grey.shade500),
            const SizedBox(height: 16),
            Text(
              'Not kaydı görünmüyor',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Profil › «Not listesi» bölümünden vize / final / büt ve isteğe bağlı harf notunu ekleyin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}

/// `Scrollbar.thumbVisibility: true` için [ScrollController] zorunlu.
class _GradeTableWithHorizontalScroll extends StatefulWidget {
  const _GradeTableWithHorizontalScroll({
    required this.list,
    required this.minWidth,
  });

  final List<GradeRecord> list;
  final double minWidth;

  @override
  State<_GradeTableWithHorizontalScroll> createState() =>
      _GradeTableWithHorizontalScrollState();
}

class _GradeTableWithHorizontalScrollState
    extends State<_GradeTableWithHorizontalScroll> {
  final ScrollController _horizontal = ScrollController();

  @override
  void dispose() {
    _horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.list;
    return Scrollbar(
      controller: _horizontal,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _horizontal,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: widget.minWidth),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.blueGrey.shade50),
            border: TableBorder.all(color: Colors.grey.shade300),
            columns: const [
              DataColumn(label: Text('Kod')),
              DataColumn(label: Text('Ders')),
              DataColumn(label: Text('Vize'), numeric: true),
              DataColumn(label: Text('Final'), numeric: true),
              DataColumn(label: Text('Büt'), numeric: true),
              DataColumn(label: Text('Harf')),
              DataColumn(label: Text('AKTS'), numeric: true),
            ],
            rows: [
              for (final g in list)
                DataRow(
                  cells: [
                    DataCell(Text(g.courseCode)),
                    DataCell(
                      SizedBox(
                        width: 200,
                        child: Text(
                          g.courseName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(Text(_dashCell(g.vizeGrade))),
                    DataCell(Text(_dashCell(g.finalGrade))),
                    DataCell(Text(_dashCell(g.butExam))),
                    DataCell(Text(
                      g.letterGrade.trim().isEmpty
                          ? '—'
                          : g.letterGrade.trim().toUpperCase(),
                    )),
                    DataCell(Text(g.courseAkts == null ? '—' : '${g.courseAkts}')),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
