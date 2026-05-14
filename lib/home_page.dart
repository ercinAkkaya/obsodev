import 'dart:io' show File;

import 'package:flutter/material.dart';

import 'data/user_credentials_repository.dart';
import 'obs_drawer.dart';
import 'profile_page.dart';

/// Ana sayfa: üst çubukta dönem/yıl, ev + duyuru ikonları ve profil fotoğrafı.
class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.onLogout});

  final Future<void> Function() onLogout;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _loading = true;
  String _academicYear = '';
  String _universityName = '';
  String? _profilePhotoPath;
  String? _schoolLogoPath;

  static const Color _obsAppBarBg = Color(0xFF1C2F4F);

  @override
  void initState() {
    super.initState();
    _refreshHeader();
  }

  Future<void> _refreshHeader() async {
    try {
      final p = await UserCredentialsRepository.instance.getStored();
      if (!mounted) return;
      setState(() {
        _academicYear = p.academicYear.trim();
        _universityName = p.universityName.trim();
        _profilePhotoPath = p.profilePhotoPath;
        _schoolLogoPath = p.schoolLogoPath;
        _loading = false;
      });
    } on Object catch (_) {
      if (!mounted) return;
      setState(() {
        _academicYear = '';
        _universityName = '';
        _profilePhotoPath = null;
        _schoolLogoPath = null;
        _loading = false;
      });
    }
  }

  Future<void> _openProfile() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ProfilePage(onLogout: widget.onLogout),
      ),
    );
    if (!mounted) return;
    await _refreshHeader();
  }

  Widget _leadingTitle() {
    if (_loading) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final y = _academicYear.trim();
    return Text(
      y.isEmpty ? 'Eğitim yılı (Profilden)' : y,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  ImageProvider<Object>? _avatarImage() {
    final path = _profilePhotoPath?.trim();
    if (path == null || path.isEmpty) return null;
    final f = File(path);
    if (!f.existsSync()) return null;
    return FileImage(f);
  }

  @override
  Widget build(BuildContext context) {
    final avatar = _avatarImage();

    return Scaffold(
      key: _scaffoldKey,
      drawer: ObsNavigationDrawer(
        universityName: _universityName,
        schoolLogoPath: _schoolLogoPath,
      ),
      appBar: AppBar(
        backgroundColor: _obsAppBarBg,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          tooltip: 'Menü',
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          icon: const Icon(Icons.menu_rounded),
        ),
        title: _leadingTitle(),
        actions: [
          // Görünüm için (OBS üst çubuğu); tıklanmak zorunda değil.
          ExcludeSemantics(
            child: SizedBox(
              width: 40,
              height: 48,
              child: Center(
                child: Icon(
                  Icons.home_outlined,
                  color: Colors.white.withValues(alpha: 0.95),
                  size: 22,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: ExcludeSemantics(
              child: Badge(
                backgroundColor: const Color(0xFFE53935),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                label: Text(
                  '0',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.98),
                    height: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  child: Icon(
                    Icons.campaign_outlined,
                    color: Colors.white.withValues(alpha: 0.95),
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 2, right: 10),
            child: GestureDetector(
              onTap: _openProfile,
              child: Tooltip(
                message: 'Profil',
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.85),
                      width: 1.5,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 19,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    backgroundImage: avatar,
                    child: avatar == null
                        ? Icon(
                            Icons.person_rounded,
                            color: Colors.white.withValues(alpha: 0.92),
                            size: 22,
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school_rounded, size: 72, color: Color(0xFFD32F2F)),
              const SizedBox(height: 24),
              const Text(
                'Giriş başarılı',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                'Sol menüden ÖBS modüllerine bakın; üniversite adı için Profil › Üniversite.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black54,
                    ),
              ),
              const SizedBox(height: 36),
              FilledButton.icon(
                onPressed: _openProfile,
                icon: const Icon(Icons.person_outline),
                label: const Text('Profil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
