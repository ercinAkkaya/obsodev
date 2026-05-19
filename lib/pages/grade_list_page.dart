import 'package:flutter/material.dart';

import '../data/academic_records.dart';
import '../data/user_credentials_repository.dart';
import '../widgets/grade_status_table.dart';

const Color _obsAppBar = Color(0xFF1C2F4F);
const Color _tabAccent = Color(0xFF1C2F4F);

/// Çekmece › Not durumu — profildeki dönem çizelgeleri (OBS tablosu).
class GradeListPage extends StatefulWidget {
  const GradeListPage({super.key});

  @override
  State<GradeListPage> createState() => _GradeListPageState();
}

class _GradeListPageState extends State<GradeListPage> {
  int _selectedSheetIndex = 0;

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
              title: const Text('Not durumu'),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final profile = snap.data!;
        final sheets = AcademicJson.decodeGradeSheets(profile.gradesJson);

        if (sheets.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: _obsAppBar,
              foregroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              title: const Text('Not durumu'),
            ),
            body: const SizedBox.shrink(),
          );
        }

        if (_selectedSheetIndex >= sheets.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedSheetIndex = 0);
          });
        }

        final safeIndex = _selectedSheetIndex.clamp(0, sheets.length - 1);
        final sheet = sheets[safeIndex];
        final uni = sheet.universityName.trim().isNotEmpty
            ? sheet.universityName.trim()
            : profile.universityName.trim();
        final periodDetail = sheet.academicPeriod.trim();

        return Scaffold(
          appBar: AppBar(
            backgroundColor: _obsAppBar,
            foregroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            title: const Text('Not durumu'),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _NotDurumuTabStrip(),
              _PeriodTabBar(
                sheets: sheets,
                selectedIndex: safeIndex,
                onSelected: (i) => setState(() => _selectedSheetIndex = i),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(6, 4, 6, 16),
                  children: [
                    if (uni.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 2, 4, 4),
                        child: Text(
                          uni,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Colors.grey.shade900,
                          ),
                        ),
                      ),
                    ],
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sheet.selectorLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          if (periodDetail.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              periodDetail,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    GradeStatusTable(courses: sheet.courses),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

}

/// OBS üst sekmesi görünümü.
class _NotDurumuTabStrip extends StatelessWidget {
  const _NotDurumuTabStrip();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE8E8E8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Not Durumu',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              height: 3,
              width: 80,
              color: const Color(0xFFFFC107),
            ),
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }
}

/// Dönem seçimi — «1. Sınıf Güz», «2. Sınıf Bahar» vb.
class _PeriodTabBar extends StatelessWidget {
  const _PeriodTabBar({
    required this.sheets,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<GradeTermSheet> sheets;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            children: [
              for (var i = 0; i < sheets.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                _PeriodTab(
                  label: sheets[i].selectorLabel,
                  selected: i == selectedIndex,
                  onTap: () => onSelected(i),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PeriodTab extends StatelessWidget {
  const _PeriodTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _tabAccent : const Color(0xFFF0F0F0),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          constraints: const BoxConstraints(minWidth: 64),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : Colors.black87,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
