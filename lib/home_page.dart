import 'dart:io' show File;

import 'package:flutter/material.dart';

import 'data/user_credentials_repository.dart';
import 'obs_drawer.dart';
import 'pages/attendance_status_page.dart';
import 'pages/course_registration_page.dart';
import 'pages/grade_list_page.dart';
import 'pages/semester_gpa_page.dart';
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

  /// Profilde uyarı yazılmışsa kart kapatılınca gizlenir (sayfa yenilenince sıfırlanır).
  bool _warningDismissed = false;

  String _academicYear = '';
  String _academicTerm = '';
  String _eduFaculty = '';
  String _eduDepartment = '';
  String _eduGrade = '';
  String _advisorInfo = '';
  String _registrationDate = '';
  String _overallGpa = '';
  String _dashboardWarning = '';
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
        _academicTerm = p.academicTerm.trim();
        _eduFaculty = p.eduFaculty.trim();
        _eduDepartment = p.eduDepartment.trim();
        _eduGrade = p.eduGrade.trim();
        _advisorInfo = p.advisorInfo.trim();
        _registrationDate = p.registrationDate.trim();
        _overallGpa = p.overallGpa.trim();
        _dashboardWarning = p.dashboardWarning.trim();
        _universityName = p.universityName.trim();
        _profilePhotoPath = p.profilePhotoPath;
        _schoolLogoPath = p.schoolLogoPath;
        _warningDismissed = false;
        _loading = false;
      });
    } on Object catch (_) {
      if (!mounted) return;
      setState(() {
        _academicYear = '';
        _academicTerm = '';
        _eduFaculty = '';
        _eduDepartment = '';
        _eduGrade = '';
        _advisorInfo = '';
        _registrationDate = '';
        _overallGpa = '';
        _dashboardWarning = '';
        _universityName = '';
        _profilePhotoPath = null;
        _schoolLogoPath = null;
        _warningDismissed = false;
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

  /// Çekmece animasyonundan sonra ilgili ekranı aç.
  void _openAfterDrawer(Widget page) {
    _scaffoldKey.currentState?.closeDrawer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => page),
      );
    });
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
    final t = _academicTerm.trim();
    if (y.isEmpty && t.isEmpty) {
      return const Text(
        'Profilden dönem',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      );
    }
    if (y.isEmpty) {
      return Text(
        t,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      );
    }
    if (t.isEmpty) {
      return Text(
        y,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      );
    }
    return Text(
      '$y $t',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }

  ImageProvider<Object>? _avatarImage() {
    final path = _profilePhotoPath?.trim();
    if (path == null || path.isEmpty) return null;
    final f = File(path);
    if (!f.existsSync()) return null;
    return FileImage(f);
  }

  static const Color _cardActive = Color(0xFF1C2F4F);
  static const Color _cardAdvisor = Color(0xFF2E7D32);
  static const Color _cardEdu = Color(0xFF00ACC1);
  static const Color _cardReg = Color(0xFF546E7A);
  static const Color _cardWarn = Color(0xFFC62828);

  String _lineOrPlaceholder(String s, String placeholder) {
    final t = s.trim();
    return t.isEmpty ? placeholder : t;
  }

  Widget _summaryCard({
    required Color backgroundColor,
    required IconData icon,
    required String title,
    required List<String> lines,
    VoidCallback? onDetail,
  }) {
    return Material(
      color: backgroundColor,
      elevation: 0,
      borderRadius: BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  for (final line in lines)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        line,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          height: 1.35,
                        ),
                      ),
                    ),
                  if (onDetail != null) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: onDetail,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Detay', style: TextStyle(fontWeight: FontWeight.w600)),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _warningCard(String message) {
    return Material(
      color: _cardWarn,
      elevation: 0,
      borderRadius: BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _warningDismissed = true),
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              tooltip: 'Kapat',
            ),
          ],
        ),
      ),
    );
  }

  Widget _dashboardBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final periodSubtitle = _lineOrPlaceholder(
      '${_academicYear.trim()} ${_academicTerm.trim()}'.trim(),
      'Profil › Öğrenim bilgileri',
    );

    final advisorBody = _lineOrPlaceholder(
      _advisorInfo,
      'Profil › Danışman',
    );

    final dept = _lineOrPlaceholder(_eduDepartment, 'Bölüm / program (Profil)');
    final grd = _lineOrPlaceholder(_eduGrade, 'Sınıf (Profil)');

    final regDate = _registrationDate.trim().isEmpty
        ? '—'
        : _registrationDate.trim();
    final agno = _overallGpa.trim().isEmpty ? '—' : _overallGpa.trim();

    final showWarning =
        !_warningDismissed && _dashboardWarning.trim().isNotEmpty;

    final fac = _eduFaculty.trim();
    final eduLines = <String>[
      if (fac.isNotEmpty) fac,
      dept,
      grd,
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
      children: [
        if (showWarning) ...[
          _warningCard(_dashboardWarning.trim()),
          const SizedBox(height: 10),
        ],
        _summaryCard(
          backgroundColor: _cardActive,
          icon: Icons.account_balance_rounded,
          title: 'Aktif Akademik Dönem Bilgileri',
          lines: [periodSubtitle],
        ),
        const SizedBox(height: 10),
        _summaryCard(
          backgroundColor: _cardAdvisor,
          icon: Icons.person_pin_rounded,
          title: 'Danışman Bilgileri',
          lines: [advisorBody],
        ),
        const SizedBox(height: 10),
        _summaryCard(
          backgroundColor: _cardEdu,
          icon: Icons.workspace_premium_rounded,
          title: 'Öğrenim Bilgileri',
          lines: eduLines,
        ),
        const SizedBox(height: 10),
        _summaryCard(
          backgroundColor: _cardReg,
          icon: Icons.storage_rounded,
          title: 'Kayıt ve not ortalaması',
          lines: [
            'Kayıt Tarihi: $regDate',
            'AGNO: $agno',
          ],
          onDetail: () => _openAfterDrawer(const SemesterGpaPage()),
        ),
      ],
    );
  }

  /// Çekmeden çıkıp profil rotasına gider (AppBar’daki foto ile aynı).
  void _openProfileAfterDrawer() {
    _scaffoldKey.currentState?.closeDrawer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final avatar = _avatarImage();

    return Scaffold(
      key: _scaffoldKey,
      drawer: ObsNavigationDrawer(
        universityName: _universityName,
        schoolLogoPath: _schoolLogoPath,
        onDersKayit: () => _openAfterDrawer(const CourseRegistrationPage()),
        onDevamsizlik: () => _openAfterDrawer(const AttendanceStatusPage()),
        onDonemOrtalamalari: () => _openAfterDrawer(const SemesterGpaPage()),
        onNotListesi: () => _openAfterDrawer(const GradeListPage()),
        onProfile: _openProfileAfterDrawer,
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
      body: _dashboardBody(),
    );
  }
}
