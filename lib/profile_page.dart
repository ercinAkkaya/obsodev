import 'dart:io' show Directory, File;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import 'data/academic_records.dart';
import 'data/user_credentials_repository.dart';

/// Beyaz arayüz; kişisel bilgiler, öğrenim bilgileri, görseller, çıkış.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.onLogout});

  /// Oturumu kapatıp giriş ekranına döner ([_AuthGate] güncellenir).
  final Future<void> Function()? onLogout;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _tc = TextEditingController();
  final _pwd = TextEditingController();
  final _academicYear = TextEditingController();
  final _eduFaculty = TextEditingController();
  final _eduDepartment = TextEditingController();
  final _eduGrade = TextEditingController();
  final _universityName = TextEditingController();
  final _academicTerm = TextEditingController();
  final _advisorInfo = TextEditingController();
  final _registrationDate = TextEditingController();
  final _overallGpa = TextEditingController();
  final _dashboardWarning = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _profilePhotoPath;
  String? _schoolLogoPath;

  List<CourseRecord> _courses = [];
  List<AttendanceRecord> _attendance = [];
  List<SemesterGpaRecord> _semesterGpas = [];
  List<GradeRecord> _grades = [];

  static final _digits11 = RegExp(r'^\d{11}$');
  /// Boş olabilir; dolu ise `YYYY-YYYY` (örn. 2025-2026).
  static final _yearRange = RegExp(r'^\d{4}-\d{4}$');

  static final Color _label = Colors.black.withValues(alpha: 0.75);
  static const Color _saveBtn = Color(0xFF455A64);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await UserCredentialsRepository.instance.getStored();
      if (!mounted) return;
      _firstName.text = r.firstName;
      _lastName.text = r.lastName;
      _tc.text = r.tc;
      _pwd.text = r.password;
      _academicYear.text = r.academicYear;
      _eduFaculty.text = r.eduFaculty;
      _eduDepartment.text = r.eduDepartment;
      _eduGrade.text = r.eduGrade;
      _universityName.text = r.universityName;
      _academicTerm.text = r.academicTerm;
      _advisorInfo.text = r.advisorInfo;
      _registrationDate.text = r.registrationDate;
      _overallGpa.text = r.overallGpa;
      _dashboardWarning.text = r.dashboardWarning;
      _profilePhotoPath = r.profilePhotoPath;
      _schoolLogoPath = r.schoolLogoPath;
      _courses = AcademicJson.decodeCourses(r.coursesJson);
      _attendance = AcademicJson.decodeAttendance(r.attendanceJson);
      _semesterGpas = AcademicJson.decodeSemesterGpas(r.semesterGpasJson);
      _grades = AcademicJson.decodeGrades(r.gradesJson);
    } on Object catch (_) {
      if (!mounted) return;
      final d = UserCredentialsRepository.instance.defaultProfile;
      _firstName.text = d.firstName;
      _lastName.text = d.lastName;
      _tc.text = d.tc;
      _pwd.text = d.password;
      _academicYear.text = d.academicYear;
      _eduFaculty.text = d.eduFaculty;
      _eduDepartment.text = d.eduDepartment;
      _eduGrade.text = d.eduGrade;
      _universityName.text = d.universityName;
      _academicTerm.text = d.academicTerm;
      _advisorInfo.text = d.advisorInfo;
      _registrationDate.text = d.registrationDate;
      _overallGpa.text = d.overallGpa;
      _dashboardWarning.text = d.dashboardWarning;
      _profilePhotoPath = d.profilePhotoPath;
      _schoolLogoPath = d.schoolLogoPath;
      _courses = AcademicJson.decodeCourses(d.coursesJson);
      _attendance = AcademicJson.decodeAttendance(d.attendanceJson);
      _semesterGpas = AcademicJson.decodeSemesterGpas(d.semesterGpasJson);
      _grades = AcademicJson.decodeGrades(d.gradesJson);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Veritabanı şu an açılamadı — varsayılan bilgiler gösteriliyor.',
          ),
        ),
      );
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  void _snackMissingImagePicker() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Galeri şu an kullanılamıyor (çoğunlukla hot restart sonrası). '
          'Uygulamayı durdurup yeniden çalıştırın veya tam yeniden kurun.',
        ),
        duration: Duration(seconds: 5),
      ),
    );
  }

  /// [image_picker] hot restart’ta kanal kaybolabiliyor; [MissingPluginException] yutulur.
  Future<XFile?> _pickImageFromGallery({
    required double maxWidth,
    required int imageQuality,
  }) async {
    try {
      return await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth,
        imageQuality: imageQuality,
      );
    } on MissingPluginException catch (_) {
      _snackMissingImagePicker();
      return null;
    } on PlatformException catch (_) {
      _snackMissingImagePicker();
      return null;
    }
  }

  Future<void> _pickProfilePhoto() async {
    final x = await _pickImageFromGallery(maxWidth: 900, imageQuality: 88);
    if (x == null || !mounted) return;

    try {
      final dir = await UserCredentialsRepository.instance.credentialDirectory;
      final avatars = Directory(p.join(dir.path, 'avatars'));
      if (!await avatars.exists()) await avatars.create(recursive: true);
      final ext = p.extension(x.path);
      final safeExt = ext.isEmpty ? '.jpg' : ext;
      final dest = p.join(
        avatars.path,
        'profile_${DateTime.now().millisecondsSinceEpoch}$safeExt',
      );
      await File(dest).writeAsBytes(await x.readAsBytes());
      setState(() => _profilePhotoPath = dest);
    } on Object catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil fotoğrafı kaydedilemedi.')),
      );
    }
  }

  void _clearProfilePhoto() {
    setState(() => _profilePhotoPath = null);
  }

  Future<void> _pickSchoolLogo() async {
    final x = await _pickImageFromGallery(maxWidth: 1200, imageQuality: 85);
    if (x == null || !mounted) return;

    try {
      final dir = await UserCredentialsRepository.instance.credentialDirectory;
      final logos = Directory(p.join(dir.path, 'logos'));
      if (!await logos.exists()) await logos.create(recursive: true);
      final ext = p.extension(x.path);
      final safeExt = ext.isEmpty ? '.jpg' : ext;
      final dest = p.join(
        logos.path,
        'school_${DateTime.now().millisecondsSinceEpoch}$safeExt',
      );
      await File(dest).writeAsBytes(await x.readAsBytes());
      setState(() => _schoolLogoPath = dest);
    } on Object catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logo kaydedilemedi.')),
      );
    }
  }

  void _clearSchoolLogo() {
    setState(() => _schoolLogoPath = null);
  }

  Future<void> _logout() async {
    if (!mounted) return;
    final nav = Navigator.of(context);
    if (nav.canPop()) nav.pop();

    try {
      await widget.onLogout?.call();
    } on Object catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Çıkış tamamlanamadı.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _tc.dispose();
    _pwd.dispose();
    _academicYear.dispose();
    _eduFaculty.dispose();
    _eduDepartment.dispose();
    _eduGrade.dispose();
    _universityName.dispose();
    _academicTerm.dispose();
    _advisorInfo.dispose();
    _registrationDate.dispose();
    _overallGpa.dispose();
    _dashboardWarning.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final fn = _firstName.text.trim();
    final ln = _lastName.text.trim();
    final tc = _tc.text.trim();
    final pwd = _pwd.text;

    if (fn.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İsim giriniz.')),
      );
      return;
    }
    if (ln.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Soyisim giriniz.')),
      );
      return;
    }
    if (!_digits11.hasMatch(tc)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('T.C. kimlik numarası 11 haneli rakam olmalıdır.')),
      );
      return;
    }
    if (pwd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şifre boş olamaz.')),
      );
      return;
    }

    final ay = _academicYear.text.trim();
    if (ay.isNotEmpty && !_yearRange.hasMatch(ay)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Eğitim-öğretim yılı boş bırakılabilir veya YYYY-YYYY (örn. 2025-2026) olmalıdır.',
          ),
        ),
      );
      return;
    }

    final profile = UserProfile(
      firstName: fn,
      lastName: ln,
      tc: tc,
      password: pwd,
      profilePhotoPath: _profilePhotoPath,
      schoolLogoPath: _schoolLogoPath,
      academicYear: ay,
      eduFaculty: _eduFaculty.text.trim(),
      eduDepartment: _eduDepartment.text.trim(),
      eduGrade: _eduGrade.text.trim(),
      universityName: _universityName.text.trim(),
      coursesJson: AcademicJson.encodeCourses(_courses),
      attendanceJson: AcademicJson.encodeAttendance(_attendance),
      semesterGpasJson: AcademicJson.encodeSemesterGpas(_semesterGpas),
      gradesJson: AcademicJson.encodeGrades(_grades),
      academicTerm: _academicTerm.text.trim(),
      advisorInfo: _advisorInfo.text.trim(),
      registrationDate: _registrationDate.text.trim(),
      overallGpa: _overallGpa.text.trim(),
      dashboardWarning: _dashboardWarning.text.trim(),
    );

    setState(() => _saving = true);
    try {
      await UserCredentialsRepository.instance.saveProfile(profile);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bilgiler kaydedildi.')),
      );
    } on Object catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kayıt yapılamadı. SQLite açılıyor mu kontrol edin.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: _label, fontWeight: FontWeight.w500),
      filled: true,
      fillColor: Colors.grey.shade50,
      counterText: '',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF546E7A), width: 1.4),
      ),
    );
  }

  Widget _miniBar(String title, VoidCallback onAddRow) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _sectionTitle(title)),
        TextButton.icon(
          onPressed: onAddRow,
          icon: const Icon(Icons.add_circle_outline, size: 22),
          label: const Text('Ekle'),
        ),
      ],
    );
  }

  Widget _mutedLine(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          text,
          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600, height: 1.35),
        ),
      );

  Future<void> _dialogCourse() async {
    final r = await showDialog<CourseRecord?>(
      context: context,
      builder: (ctx) => _CourseFormDialog(deco: _decoration),
    );
    if (!mounted || r == null) return;
    setState(() => _courses.add(r));
  }

  Future<void> _dialogAttendance() async {
    final r = await showDialog<AttendanceRecord?>(
      context: context,
      builder: (ctx) => _AttendanceFormDialog(deco: _decoration),
    );
    if (!mounted || r == null) return;
    setState(() => _attendance.add(r));
  }

  Future<void> _dialogSemesterGpa() async {
    final r = await showDialog<SemesterGpaRecord?>(
      context: context,
      builder: (ctx) => _SemesterGpaFormDialog(deco: _decoration),
    );
    if (!mounted || r == null) return;
    setState(() => _semesterGpas.add(r));
  }

  Future<void> _dialogGrade() async {
    final r = await showDialog<GradeRecord?>(
      context: context,
      builder: (ctx) => _GradeFormDialog(deco: _decoration),
    );
    if (!mounted || r == null) return;
    setState(() => _grades.add(r));
  }

  Widget _academicFromProfileBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 32),
        Text(
          'ÖBS sayfaları',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _label,
          ),
        ),
        const SizedBox(height: 6),
        _mutedLine(
          'Aşağıdaki satırlar menüdeki Ders Kayıt, Devamsızlık, Dönem Ortalamaları ve Not Listesi ekranlarında gösterilir. Kaydet’e basmayı unutmayın.',
        ),
        _miniBar('Ders kayıt bilgileri', _dialogCourse),
        if (_courses.isEmpty)
          _mutedLine('Henüz ders yok.')
        else
          ...List.generate(
            _courses.length,
            (i) => _removeCard(
              title: '${_courses[i].code} — ${_courses[i].name}',
              subtitle: 'AKTS: ${_courses[i].akts}'
                  '${_courses[i].instructor.isEmpty ? '' : ' • ${_courses[i].instructor}'}',
              onRemove: () => setState(() => _courses.removeAt(i)),
            ),
          ),
        const SizedBox(height: 18),
        _miniBar('Devamsızlık kayıtları', _dialogAttendance),
        if (_attendance.isEmpty)
          _mutedLine('Kayıt yok.')
        else
          ...List.generate(
            _attendance.length,
            (i) => _removeCard(
              title: _attendance[i].courseName,
              subtitle:
                  'Devamsız: ${_attendance[i].absentHours} saat / ${_attendance[i].lessonHours} saat',
              onRemove: () => setState(() => _attendance.removeAt(i)),
            ),
          ),
        const SizedBox(height: 18),
        _miniBar('Dönem ortalamaları', _dialogSemesterGpa),
        if (_semesterGpas.isEmpty)
          _mutedLine('Kayıt yok.')
        else
          ...List.generate(
            _semesterGpas.length,
            (i) => _removeCard(
              title: _semesterGpas[i].semesterLabel,
              subtitle: 'AGNO: ${_semesterGpas[i].gpa.toStringAsFixed(3)}',
              onRemove: () => setState(() => _semesterGpas.removeAt(i)),
            ),
          ),
        const SizedBox(height: 18),
        _miniBar('Not listesi', _dialogGrade),
        if (_grades.isEmpty)
          _mutedLine('Kayıt yok.')
        else
          ...List.generate(
            _grades.length,
            (i) => _removeCard(
              title: '${_grades[i].courseCode} · ${_grades[i].courseName}',
              subtitle: 'Not: ${_grades[i].letterGrade}'
                  '${_grades[i].courseAkts != null ? ' • AKTS ${_grades[i].courseAkts}' : ''}',
              onRemove: () => setState(() => _grades.removeAt(i)),
            ),
          ),
      ],
    );
  }

  Widget _removeCard({
    required String title,
    required String subtitle,
    required VoidCallback onRemove,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 0,
        color: Colors.grey.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: ListTile(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(subtitle),
          ),
          trailing: IconButton(
            onPressed: onRemove,
            icon: Icon(Icons.delete_outline_rounded, color: Colors.grey.shade700),
            tooltip: 'Sil',
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(
        t,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: _label,
        ),
      );

  InputDecoration _educationField(String label, {String? helper}) {
    final cyan = Colors.cyan.shade900;
    return _decoration(label).copyWith(
      helperText: helper,
      helperStyle: helper != null
          ? TextStyle(color: cyan.withValues(alpha: 0.72), fontSize: 12)
          : null,
      fillColor: Colors.white,
      counterText: '',
    );
  }

  /// Sonradan yeni satırlar kolay eklensin diye tek yerde toplandı.
  Widget _educationPanel() {
    final cyan = Colors.cyan.shade900;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFB2EBF2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.school_rounded, color: cyan, size: 34),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Öğrenim bilgileri',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: cyan,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _academicYear,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              decoration: _educationField(
                'Eğitim-öğretim yılı',
                helper: 'Boş bırakılabilir • Örn. 2025-2026',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _academicTerm,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: _educationField(
                'Dönem',
                helper: 'Örn. Güz • Bahar • Yaz — üst çubukta gösterilir',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _eduFaculty,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: _educationField('Fakülte / birim'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _eduDepartment,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: _educationField(
                'Bölüm / program',
                helper: 'Örn. MYO — Çocuk Gelişimi',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _eduGrade,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              decoration: _educationField(
                'Sınıf',
                helper: 'Örn. 1. Sınıf',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: Colors.grey.shade600))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.badge_outlined, color: Colors.grey.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Kişisel ve okul bilgileri',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Colors.grey.shade900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Varsayılan giriş: ${UserCredentialsRepository.defaultTc} / ${UserCredentialsRepository.defaultPassword}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle('Profil fotoğrafı'),
                  const SizedBox(height: 10),
                  Center(
                    child: Column(
                      children: [
                        Builder(
                          builder: (context) {
                            final pth = _profilePhotoPath;
                            ImageProvider<Object>? bg;
                            if (pth != null && pth.isNotEmpty && File(pth).existsSync()) {
                              bg = FileImage(File(pth));
                            }
                            return CircleAvatar(
                              radius: 56,
                              backgroundColor: Colors.grey.shade200,
                              child: CircleAvatar(
                                radius: 52,
                                backgroundColor: Colors.grey.shade100,
                                backgroundImage: bg,
                                child: bg != null
                                    ? null
                                    : Icon(
                                        Icons.person_outline_rounded,
                                        size: 64,
                                        color: Colors.grey.shade500,
                                      ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _pickProfilePhoto,
                              icon: const Icon(Icons.add_a_photo_outlined, size: 20),
                              label: const Text('Fotoğraf seç'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black87,
                                side: BorderSide(color: Colors.grey.shade400),
                              ),
                            ),
                            if (_profilePhotoPath != null)
                              IconButton.outlined(
                                onPressed: _clearProfilePhoto,
                                icon: const Icon(Icons.delete_outline),
                                color: Colors.black54,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _sectionTitle('Kişisel bilgiler'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _firstName,
                    textCapitalization: TextCapitalization.words,
                    decoration: _decoration('İsim'),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _lastName,
                    textCapitalization: TextCapitalization.words,
                    decoration: _decoration('Soyisim'),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _tc,
                    keyboardType: TextInputType.number,
                    maxLength: 11,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _decoration('T.C. Kimlik No'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _pwd,
                    obscureText: true,
                    decoration: _decoration('Şifre'),
                  ),
                  const SizedBox(height: 20),
                  _educationPanel(),
                  const SizedBox(height: 22),
                  _sectionTitle('Ana sayfa özeti (OBS)'),
                  const SizedBox(height: 8),
                  Text(
                    'Öğrenim alanları yukarıdadır. Danışman, kayıt tarihi ve AGNO burada; ana ekranda kart olarak gösterilir.',
                    style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600, height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _advisorInfo,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    maxLines: 2,
                    decoration: _decoration('Danışman').copyWith(
                      hintText: 'Örn. Öğr. Gör. Ad Soyad',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _registrationDate,
                    textInputAction: TextInputAction.next,
                    decoration: _decoration('Kayıt tarihi').copyWith(
                      helperText: 'Örn. 28.08.2023',
                      helperStyle: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _overallGpa,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    decoration: _decoration('Genel AGNO').copyWith(
                      helperText: 'Ana sayfadaki «AGNO» satırı',
                      helperStyle: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _dashboardWarning,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 2,
                    decoration: _decoration('Uyarı metni (isteğe bağlı)').copyWith(
                      helperText: 'Doldurursanız ana sayfada kırmızı uyarı kartı çıkar; boşsa gösterilmez.',
                      helperStyle: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ),
                  const SizedBox(height: 22),
                  _sectionTitle('Üniversite'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _universityName,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: _decoration('Üniversite adı').copyWith(
                      helperText:
                          'Menü başlığında gösterilir (örn. Akdeniz Üniversitesi)',
                      helperStyle: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  _sectionTitle('Okul logosu'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: _logoChild(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _pickSchoolLogo,
                                icon: const Icon(Icons.photo_library_outlined),
                                label: const Text('Galeriden seç'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.black87,
                                  side: BorderSide(color: Colors.grey.shade400),
                                ),
                              ),
                            ),
                            if (_schoolLogoPath != null) ...[
                              const SizedBox(width: 8),
                              IconButton.outlined(
                                onPressed: _clearSchoolLogo,
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  _academicFromProfileBlock(),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: _saveBtn,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Kaydet'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, size: 20),
                    label: const Text('Çıkış yap'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFC62828),
                      side: const BorderSide(color: Color(0xFFE57373)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _logoChild() {
    final path = _schoolLogoPath;
    if (path == null || path.isEmpty) {
      return ColoredBox(
        color: Colors.grey.shade200,
        child: Icon(
          Icons.account_balance_outlined,
          size: 56,
          color: Colors.grey.shade400,
        ),
      );
    }
    final f = File(path);
    if (!f.existsSync()) {
      return ColoredBox(
        color: Colors.grey.shade200,
        child: Center(
          child: Text(
            'Logo dosyası bulunamadı',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ),
      );
    }
    return Image.file(
      f,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => ColoredBox(
        color: Colors.grey.shade200,
        child: Center(
          child: Text('Önizleme yüklenemedi', style: TextStyle(color: Colors.grey.shade700)),
        ),
      ),
    );
  }
}

/// Dialog içinde oluşturulan [TextEditingController] öğeleri yalnızca [dispose] sırasında bırakılmalı
/// (diyalog animasyonu sürerken dışarıda erken dispose hatasına yol açmaması için).
class _CourseFormDialog extends StatefulWidget {
  const _CourseFormDialog({required this.deco});

  final InputDecoration Function(String label) deco;

  @override
  State<_CourseFormDialog> createState() => _CourseFormDialogState();
}

class _CourseFormDialogState extends State<_CourseFormDialog> {
  late final TextEditingController _code;
  late final TextEditingController _name;
  late final TextEditingController _akts;
  late final TextEditingController _ins;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController();
    _name = TextEditingController();
    _akts = TextEditingController();
    _ins = TextEditingController();
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _akts.dispose();
    _ins.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final c = _code.text.trim();
    final n = _name.text.trim();
    if (c.isEmpty || n.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ders kodu ve adı zorunludur.')),
      );
      return;
    }
    final a = int.tryParse(_akts.text.trim()) ?? 0;
    Navigator.of(context).pop(
      CourseRecord(
        code: c,
        name: n,
        akts: a,
        instructor: _ins.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ders ekle'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _code, decoration: widget.deco('Ders kodu')),
            const SizedBox(height: 12),
            TextField(controller: _name, decoration: widget.deco('Ders adı')),
            const SizedBox(height: 12),
            TextField(
              controller: _akts,
              keyboardType: TextInputType.number,
              decoration: widget.deco('AKTS'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ins,
              decoration: widget.deco('Öğretim elemanı'),
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('İptal')),
        FilledButton(onPressed: _submit, child: const Text('Tamam')),
      ],
    );
  }
}

class _AttendanceFormDialog extends StatefulWidget {
  const _AttendanceFormDialog({required this.deco});

  final InputDecoration Function(String label) deco;

  @override
  State<_AttendanceFormDialog> createState() => _AttendanceFormDialogState();
}

class _AttendanceFormDialogState extends State<_AttendanceFormDialog> {
  late final TextEditingController _course;
  late final TextEditingController _absent;
  late final TextEditingController _lesson;

  @override
  void initState() {
    super.initState();
    _course = TextEditingController();
    _absent = TextEditingController();
    _lesson = TextEditingController();
  }

  @override
  void dispose() {
    _course.dispose();
    _absent.dispose();
    _lesson.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final cn = _course.text.trim();
    final ab = int.tryParse(_absent.text.trim()) ?? -1;
    final ls = int.tryParse(_lesson.text.trim()) ?? -1;
    if (cn.isEmpty || ab < 0 || ls <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ders adı dolu olmalı; devamsız saat ≥ 0 ve uygun süre > 0 girin.',
          ),
        ),
      );
      return;
    }
    Navigator.of(context).pop(
      AttendanceRecord(courseName: cn, absentHours: ab, lessonHours: ls),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Devamsızlık satırı'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _course,
              decoration: widget.deco('Ders'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _absent,
              keyboardType: TextInputType.number,
              decoration: widget.deco('Devamsız saat'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lesson,
              keyboardType: TextInputType.number,
              decoration: widget.deco('Uygun ders süresi (saat)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('İptal')),
        FilledButton(onPressed: _submit, child: const Text('Tamam')),
      ],
    );
  }
}

class _SemesterGpaFormDialog extends StatefulWidget {
  const _SemesterGpaFormDialog({required this.deco});

  final InputDecoration Function(String label) deco;

  @override
  State<_SemesterGpaFormDialog> createState() => _SemesterGpaFormDialogState();
}

class _SemesterGpaFormDialogState extends State<_SemesterGpaFormDialog> {
  late final TextEditingController _sem;
  late final TextEditingController _gpa;

  @override
  void initState() {
    super.initState();
    _sem = TextEditingController();
    _gpa = TextEditingController();
  }

  @override
  void dispose() {
    _sem.dispose();
    _gpa.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final label = _sem.text.trim();
    if (label.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dönem metni girin.')),
      );
      return;
    }
    final g = double.tryParse(_gpa.text.trim().replaceAll(',', '.'));
    if (g == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AGNO sayı olmalıdır (örn. 3,45).')),
      );
      return;
    }
    Navigator.of(context).pop(SemesterGpaRecord(semesterLabel: label, gpa: g));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Dönem ortalaması'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _sem,
            decoration: widget.deco('Dönem (örn. 2025-2026 Güz)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _gpa,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: widget.deco('AGNO'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('İptal')),
        FilledButton(onPressed: _submit, child: const Text('Tamam')),
      ],
    );
  }
}

class _GradeFormDialog extends StatefulWidget {
  const _GradeFormDialog({required this.deco});

  final InputDecoration Function(String label) deco;

  @override
  State<_GradeFormDialog> createState() => _GradeFormDialogState();
}

class _GradeFormDialogState extends State<_GradeFormDialog> {
  late final TextEditingController _code;
  late final TextEditingController _name;
  late final TextEditingController _letter;
  late final TextEditingController _akts;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController();
    _name = TextEditingController();
    _letter = TextEditingController();
    _akts = TextEditingController();
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _letter.dispose();
    _akts.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final cc = _code.text.trim();
    final nn = _name.text.trim();
    final lg = _letter.text.trim();
    if (cc.isEmpty || nn.isEmpty || lg.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kod, ad ve harf notu zorunlu.')),
      );
      return;
    }
    final ak = _akts.text.trim();
    Navigator.of(context).pop(
      GradeRecord(
        courseCode: cc,
        courseName: nn,
        letterGrade: lg,
        courseAkts: ak.isEmpty ? null : int.tryParse(ak),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Not satırı'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _code, decoration: widget.deco('Ders kodu')),
            const SizedBox(height: 12),
            TextField(controller: _name, decoration: widget.deco('Ders adı')),
            const SizedBox(height: 12),
            TextField(controller: _letter, decoration: widget.deco('Harf notu')),
            const SizedBox(height: 12),
            TextField(
              controller: _akts,
              keyboardType: TextInputType.number,
              decoration: widget.deco('AKTS (isteğe bağlı)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('İptal')),
        FilledButton(onPressed: _submit, child: const Text('Tamam')),
      ],
    );
  }
}
