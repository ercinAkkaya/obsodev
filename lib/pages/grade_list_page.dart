import 'package:flutter/material.dart';

import '../data/academic_records.dart';
import '../data/user_credentials_repository.dart';

const Color _obsAppBar = Color(0xFF1C2F4F);

/// Drawer → Not listesi.
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
              title: const Text('Not Listesi'),
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
            title: const Text('Not Listesi'),
          ),
          body: list.isEmpty
              ? _hint(context)
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final g = list[i];
                    return Card(
                      elevation: 0,
                      color: Colors.grey.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: ListTile(
                        title: Text(
                          '${g.courseCode} · ${g.courseName}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: g.courseAkts != null
                            ? Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('AKTS: ${g.courseAkts}'),
                              )
                            : null,
                        trailing: Chip(
                          label: Text(
                            g.letterGrade.toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          backgroundColor: Colors.blueGrey.shade100,
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
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
              'Profil › «Not listesi» bölümünden ders notlarını ekleyin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}
