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
        final list = AcademicJson.decodeCourses(snap.data!.coursesJson);

        return Scaffold(
          appBar: AppBar(
            backgroundColor: _obsAppBar,
            foregroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            title: const Text('Ders kayıt tarihi'),
          ),
          body: list.isEmpty
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
        );
      },
    );
  }

}
