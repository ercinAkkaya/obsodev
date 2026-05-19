import 'package:flutter/material.dart';

import '../data/academic_records.dart';
import '../data/user_credentials_repository.dart';

const Color _obsAppBar = Color(0xFF1C2F4F);

/// Drawer › Ders kayıt tarihi; kayıtlı ders listesi Profil’de girilir.
class CourseRegistrationPage extends StatelessWidget {
  const CourseRegistrationPage({super.key});

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
              title: const Text('Ders kayıt tarihi'),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final p = snap.data!;
        final list = AcademicJson.decodeCourses(p.coursesJson);
        final reg = p.registrationDate.trim();

        return Scaffold(
          appBar: AppBar(
            backgroundColor: _obsAppBar,
            foregroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            title: const Text('Ders kayıt tarihi'),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Material(
                color: reg.isEmpty ? Colors.orange.shade50 : Colors.blueGrey.shade50,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.event_note_rounded,
                        color: reg.isEmpty ? Colors.orange.shade800 : Colors.blueGrey.shade800,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          reg.isEmpty
                              ? 'Ders kayıt tarihi: —'
                              : 'Ders kayıt tarihi: $reg',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                            color:
                                reg.isEmpty ? Colors.orange.shade900 : Colors.blueGrey.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? const SizedBox.shrink()
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final c = list[i];
                          return Card(
                            elevation: 0,
                            color: Colors.grey.shade50,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            child: ListTile(
                              title: Text(
                                '${c.code} — ${c.name}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('AKTS: ${c.akts}'),
                                    if (c.instructor.trim().isNotEmpty)
                                      Text('Öğr. Elem.: ${c.instructor}'),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

}
