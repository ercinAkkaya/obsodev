import 'dart:io' show File;

import 'package:flutter/material.dart';

/// OBS web kenar çubuğuna benzeyen koyu tema menü (üstte logo + üniversite adı).
class ObsNavigationDrawer extends StatelessWidget {
  const ObsNavigationDrawer({
    super.key,
    required this.universityName,
    this.schoolLogoPath,
  });

  final String universityName;
  final String? schoolLogoPath;

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
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white.withValues(alpha: 0.16),
                      backgroundImage: logoImage,
                      child: logoImage != null
                          ? null
                          : Icon(Icons.account_balance_rounded, size: 38, color: Colors.white.withValues(alpha: 0.75)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      uni.isEmpty ? 'Üniversite adı (Profil)' : uni,
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
                      leading: const Icon(Icons.grid_view_rounded),
                      title: const Text('Genel İşlemler'),
                      initiallyExpanded: false,
                      children: [
                        _sub(context, 'Duyurular'),
                        _sub(context, 'Özet'),
                      ],
                    ),
                    ExpansionTile(
                      leading: const Icon(Icons.menu_book_rounded),
                      title: const Text('Ders ve Dönem İşlemleri'),
                      initiallyExpanded: true,
                      children: [
                        _sub(context, 'Ders Kayıt'),
                        _sub(context, 'Bütünleme Kayıt'),
                        _sub(context, 'Ders Ekle/Bırak'),
                        _sub(context, 'Dönem Ortalamaları'),
                        _sub(context, 'Not Listesi'),
                        _sub(context, 'Transkript'),
                        _sub(context, 'Transkript Senaryosu'),
                        _sub(context, 'Diğer Belgeler'),
                        _sub(context, 'Müfredat Durum'),
                        _sub(context, 'Staj Başvurusu'),
                        _sub(context, 'Akademik Faaliyetler'),
                        _sub(context, 'Devamsızlık Durumu'),
                      ],
                    ),
                    ExpansionTile(
                      leading: const Icon(Icons.description_outlined),
                      title: const Text('Form İşlemleri'),
                      initiallyExpanded: false,
                      children: [
                        _sub(context, 'Form talepleri'),
                        _sub(context, 'Onay bekleyen formlar'),
                      ],
                    ),
                    ExpansionTile(
                      leading: const Icon(Icons.account_tree_outlined),
                      title: const Text('YÖKSİS İşlemleri'),
                      initiallyExpanded: false,
                      children: [
                        _sub(context, 'YÖKSİS aktarımları'),
                        _sub(context, 'Başvurular'),
                      ],
                    ),
                    ExpansionTile(
                      leading: const Icon(Icons.badge_outlined),
                      title: const Text('Hazırlık İşlemleri'),
                      initiallyExpanded: false,
                      children: [
                        _sub(context, 'Hazırlık programı durumu'),
                        _sub(context, 'Sınavlar'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _sub(BuildContext context, String title) {
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
      onTap: () => Navigator.of(context).pop(),
    );
  }
}
