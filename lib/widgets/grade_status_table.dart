import 'package:flutter/material.dart';

import '../data/academic_records.dart';

const Color _kHeaderBg = Color(0xFF5C5C5C);
const Color _kBorder = Color(0xFFD0D0D0);
const EdgeInsets _kCellPad = EdgeInsets.symmetric(horizontal: 5, vertical: 6);
const EdgeInsets _kHeaderPad = EdgeInsets.symmetric(horizontal: 5, vertical: 7);

String _cell(String s) {
  final t = s.trim();
  return t.isEmpty ? '—' : t;
}

/// OBS «Not Durumu» çizelgesi — eşit satır yüksekliği, sıkı sütunlar.
class GradeStatusTable extends StatelessWidget {
  const GradeStatusTable({super.key, required this.courses});

  final List<GradeCourseRow> courses;

  static const Map<int, TableColumnWidth> _columns = {
    0: FixedColumnWidth(58),
    1: FixedColumnWidth(128),
    2: FixedColumnWidth(78),
    3: FixedColumnWidth(82),
    4: FixedColumnWidth(50),
    5: FixedColumnWidth(54),
  };

  static final TableBorder _border = TableBorder.all(color: _kBorder, width: 1);

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Text(
          'Bu dönem için ders satırı yok.',
          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
        ),
      );
    }

    return ClipRect(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          columnWidths: _columns,
          border: _border,
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: const BoxDecoration(color: _kHeaderBg),
              children: [
                _headerCell('Ders\nKodu'),
                _headerCell('Ders Adı'),
                _headerCell('Sonuç\nDurumu'),
                _headerCell('Sınav\nNotları'),
                _headerCell('Ort\nNot', align: Alignment.centerRight),
                _headerCell('Durumu', align: Alignment.centerRight),
              ],
            ),
            for (var i = 0; i < courses.length; i++)
              _dataRow(courses[i], shaded: i.isOdd),
          ],
        ),
      ),
    );
  }

  static Widget _headerCell(String label, {Alignment align = Alignment.centerLeft}) {
    return TableCell(
      child: Padding(
        padding: _kHeaderPad,
        child: Align(
          alignment: align,
          child: Text(
            label,
            textAlign: align == Alignment.centerRight ? TextAlign.right : TextAlign.left,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 10.5,
              height: 1.15,
            ),
          ),
        ),
      ),
    );
  }

  static TableRow _dataRow(GradeCourseRow row, {required bool shaded}) {
    final ortParts = <String>[];
    if (row.averageGrade.trim().isNotEmpty) ortParts.add(row.averageGrade.trim());
    if (row.letterGrade.trim().isNotEmpty) {
      ortParts.add(row.letterGrade.trim().toUpperCase());
    }
    final ortText = ortParts.isEmpty ? '—' : ortParts.join(' ');

    final examLines = <String>[
      if (row.vizeGrade.trim().isNotEmpty) 'Vize: ${row.vizeGrade.trim()}',
      if (row.finalGrade.trim().isNotEmpty) 'Final: ${row.finalGrade.trim()}',
      if (row.butExam.trim().isNotEmpty) 'Büt: ${row.butExam.trim()}',
    ];

    return TableRow(
      decoration: BoxDecoration(
        color: shaded ? const Color(0xFFF5F5F5) : Colors.white,
      ),
      children: [
        _dataCell(Text(_cell(row.courseCode), style: _bodyStyle)),
        _dataCell(
          Text(
            _cell(row.courseName),
            style: _bodyStyle,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _dataCell(
          Text(
            _cell(row.resultStatus),
            style: _bodyStyle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _dataCell(
          examLines.isEmpty
              ? Text('—', style: _bodyStyle)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final line in examLines)
                      Text(line, style: _examLineStyle),
                  ],
                ),
        ),
        _dataCell(
          Text(ortText, style: _bodyStyle, textAlign: TextAlign.right),
          align: Alignment.centerRight,
        ),
        _dataCell(
          Text(_cell(row.passStatus), style: _bodyStyle, textAlign: TextAlign.right),
          align: Alignment.centerRight,
        ),
      ],
    );
  }

  static const TextStyle _bodyStyle = TextStyle(
    fontSize: 11.5,
    height: 1.2,
    color: Colors.black87,
  );

  static const TextStyle _examLineStyle = TextStyle(
    fontSize: 11,
    height: 1.18,
    color: Colors.black87,
  );

  static Widget _dataCell(Widget child, {Alignment align = Alignment.centerLeft}) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Padding(
        padding: _kCellPad,
        child: Align(
          alignment: align,
          child: child,
        ),
      ),
    );
  }
}
