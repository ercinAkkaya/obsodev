import 'dart:io' show File;

import 'package:flutter/material.dart';

/// OBS web kenar çubuğuna benzeyen koyu tema menü (üstte logo + üniversite adı).
class ObsNavigationDrawer extends StatelessWidget {
  const ObsNavigationDrawer({
    super.key,
    required this.universityName,
    this.schoolLogoPath,
    required this.onDersKayitTarihi,
    required this.onDonemOrtalamalari,
    required this.onNotListesi,
    required this.onDevamsizlik,
    required this.onYokBasvurular,
    required this.onDijitalKimlik,
    required this.onOsym,
    required this.onAktifDonem,
    required this.onAktifOgrenim,
    required this.onSchoolLogoTap,
  });

  final String universityName;
  final String? schoolLogoPath;

  final VoidCallback onDersKayitTarihi;
  final VoidCallback onDonemOrtalamalari;
  final VoidCallback onNotListesi;
  final VoidCallback onDevamsizlik;
  final VoidCallback onYokBasvurular;
  final VoidCallback onDijitalKimlik;
  final VoidCallback onOsym;
  final VoidCallback onAktifDonem;
  final VoidCallback onAktifOgrenim;

  /// Üstteki üniversite logosuna dokunulunca — galeriden yeni logo.
  final VoidCallback onSchoolLogoTap;

  static const Color _bg = Color(0xFF152844);
  static const Color _muted = Colors.white70;

  @override
  Widget build(BuildContext context) {
    final uni = universityName.trim();
    final theme = Theme.of(context);

    ImageProvider<Object>? logoImage;
    final logoPath = schoolLogoPath?.trim();
    if (logoPath != null && logoPath.isNotEmpty && File(logoPath).existsSync()) {
      logoImage = FileImage(File(logoPath));
    }

    return Drawer(
      backgroundColor: _bg,
      child: Theme(
        data: theme.copyWith(
          dividerTheme: DividerThemeData(color: Colors.white.withValues(alpha: 0.12)),
          splashColor: Colors.white24,
          hoverColor: Colors.white12,
          listTileTheme: const ListTileThemeData(
            iconColor: Colors.white,
            textColor: Colors.white,
          ),
          expansionTileTheme: ExpansionTileThemeData(
            backgroundColor: Colors.transparent,
            collapsedBackgroundColor: Colors.transparent,
            iconColor: _muted,
            collapsedIconColor: _muted,
            textColor: Colors.white,
            collapsedTextColor: Colors.white,
            shape: Border.all(color: Colors.transparent),
            collapsedShape: Border.all(color: Colors.transparent),
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  children: [
                    Tooltip(
                      message: 'Üniversite logosu — galeriden değiştir',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onSchoolLogoTap,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.white.withValues(alpha: 0.16),
                              backgroundImage: logoImage,
                              child: logoImage != null
                                  ? null
                                  : Icon(Icons.add_photo_alternate_outlined,
                                      size: 34, color: Colors.white.withValues(alpha: 0.85)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      uni.isEmpty ? 'Üniversite adı' : uni,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Divider(height: 1, color: Colors.white.withValues(alpha: 0.22)),
                    const SizedBox(height: 10),
                    Text(
                      'Öğrenci Bilgi Sistemi',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ExpansionTile(
                      leading: const Icon(Icons.menu_book_rounded),
                      title: const Text('Ders ve genel işlemler'),
                      initiallyExpanded: true,
                      children: [
                        _navTile(context, 'Ders kayıt tarihi', onDersKayitTarihi),
                        _navTile(context, 'Dönem ortalamaları', onDonemOrtalamalari),
                        _navTile(context, 'Not durumu', onNotListesi),
                        _navTile(context, 'Devamsızlık', onDevamsizlik),
                      ],
                    ),
                    ExpansionTile(
                      leading: const Icon(Icons.account_tree_outlined),
                      title: const Text('YÖK işlemleri'),
                      initiallyExpanded: false,
                      children: [
                        _navTile(context, 'Başvurular ve sonuçları', onYokBasvurular),
                      ],
                    ),
                    _topLevelTile(context, Icons.fingerprint_rounded, 'Dijital kimliğim', onDijitalKimlik),
                    _topLevelTile(context, Icons.assignment_turned_in_outlined, 'ÖSYM sonuçları başvuruları', onOsym),
                    _topLevelTile(context, Icons.calendar_today_rounded, 'Aktif akademik dönem bilgileri', onAktifDonem),
                    _topLevelTile(context, Icons.school_outlined, 'Aktif öğrenim bilgileri', onAktifOgrenim),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _navTile(
    BuildContext context,
    String title,
    VoidCallback onOpen,
  ) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.only(left: 36, right: 16),
      leading: Icon(
        Icons.square_rounded,
        size: 8,
        color: Colors.white.withValues(alpha: 0.45),
      ),
      horizontalTitleGap: 8,
      title: Text(
        title,
        style: TextStyle(fontSize: 13.5, color: Colors.white.withValues(alpha: 0.95)),
      ),
      onTap: onOpen,
    );
  }

  static Widget _topLevelTile(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onOpen,
  ) {
    return ListTile(
      dense: false,
      leading: Icon(icon, color: Colors.white.withValues(alpha: 0.95)),
      title: Text(
        title,
        style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.98)),
      ),
      onTap: onOpen,
    );
  }
}
