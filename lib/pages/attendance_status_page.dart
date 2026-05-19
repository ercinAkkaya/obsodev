import 'package:flutter/material.dart';

import '../data/academic_records.dart';
import '../data/user_credentials_repository.dart';

const Color _obsAppBar = Color(0xFF1C2F4F);

/// Drawer → Devamsızlık durumu.
class AttendanceStatusPage extends StatelessWidget {
  const AttendanceStatusPage({super.key});

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
              title: const Text('Devamsızlık Durumu'),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final list = AcademicJson.decodeAttendance(snap.data!.attendanceJson);
        return Scaffold(
          appBar: AppBar(
            backgroundColor: _obsAppBar,
            foregroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            title: const Text('Devamsızlık Durumu'),
          ),
          body: list.isEmpty
                    ? const SizedBox.shrink()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final a = list[i];
                    final pct = a.lessonHours > 0
                        ? (a.absentHours / a.lessonHours * 100).toStringAsFixed(1)
                        : '—';
                    return Card(
                      elevation: 0,
                      color: Colors.grey.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: ListTile(
                        title: Text(
                          a.courseName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Devamsız: ${a.absentHours} saat • Uygun süre: ${a.lessonHours} saat\n'
                            'Devamsızlık oranı: %$pct',
                          ),
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
