import 'package:flutter/material.dart';

import '../data/user_credentials_repository.dart';

const Color _obsAppBar = Color(0xFF1C2F4F);

String _dash(String s) {
  final t = s.trim();
  return t.isEmpty ? '—' : t;
}

Widget _infoRow(BuildContext context, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: TextStyle(fontSize: 14, height: 1.35, color: Colors.grey.shade900),
          ),
        ),
      ],
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
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _infoRow(context, 'Üniversite', _dash(p.universityName)),
              _infoRow(context, 'Eğitim-öğretim yılı', _dash(p.academicYear)),
              _infoRow(context, 'Dönem', _dash(p.academicTerm)),
              _infoRow(context, 'Kayıt tarihi', _dash(p.registrationDate)),
              _infoRow(context, 'Danışman', _dash(p.advisorInfo)),
              _infoRow(context, 'Genel AGNO', _dash(p.overallGpa)),
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
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _infoRow(context, 'Üniversite', _dash(p.universityName)),
              _infoRow(context, 'Fakülte / birim', _dash(p.eduFaculty)),
              _infoRow(context, 'Bölüm / program', _dash(p.eduDepartment)),
              _infoRow(context, 'Sınıf', _dash(p.eduGrade)),
              _infoRow(context, 'Eğitim-öğretim yılı', _dash(p.academicYear)),
              _infoRow(context, 'Dönem', _dash(p.academicTerm)),
              _infoRow(context, 'Danışman', _dash(p.advisorInfo)),
              _infoRow(context, 'Kayıt tarihi', _dash(p.registrationDate)),
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
