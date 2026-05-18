import 'dart:io' show Directory, File;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;

import 'data/academic_records.dart';
import 'data/user_credentials_repository.dart';

/// Eğitim, menü metinleri, okul logosu ve ÖBS listeleri (ders / devamsızlık / not).
class ProfileAcademicPage extends StatefulWidget {
  const ProfileAcademicPage({super.key});

  @override
  State<ProfileAcademicPage> createState() => _ProfileAcademicPageState();
}

class _ProfileAcademicPageState extends State<ProfileAcademicPage> {
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
  final _digitalIdInfo = TextEditingController();
  final _yokAppsInfo = TextEditingController();
  final _osymInfo = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _schoolLogoPath;

  List<CourseRecord> _courses = [];
  List<AttendanceRecord> _attendance = [];
  List<SemesterGpaRecord> _semesterGpas = [];
  List<GradeRecord> _grades = [];
  List<OsymExamRecord> _osymExams = [];
  List<YokDocumentRecord> _yokDocuments = [];

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
      _digitalIdInfo.text = r.digitalIdInfo;
      _yokAppsInfo.text = r.yokAppsInfo;
      _osymInfo.text = r.osymInfo;
      _schoolLogoPath = r.schoolLogoPath;
      _courses = AcademicJson.decodeCourses(r.coursesJson);
      _attendance = AcademicJson.decodeAttendance(r.attendanceJson);
      _semesterGpas = AcademicJson.decodeSemesterGpas(r.semesterGpasJson);
      _grades = AcademicJson.decodeGrades(r.gradesJson);
      _osymExams = AcademicJson.decodeOsymExams(r.osymExamsJson);
      _yokDocuments = AcademicJson.decodeYokDocuments(r.yokDocumentsJson);
    } on Object catch (_) {
      if (!mounted) return;
      final d = UserCredentialsRepository.instance.defaultProfile;
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
      _digitalIdInfo.text = d.digitalIdInfo;
      _yokAppsInfo.text = d.yokAppsInfo;
      _osymInfo.text = d.osymInfo;
      _schoolLogoPath = d.schoolLogoPath;
      _courses = AcademicJson.decodeCourses(d.coursesJson);
      _attendance = AcademicJson.decodeAttendance(d.attendanceJson);
      _semesterGpas = AcademicJson.decodeSemesterGpas(d.semesterGpasJson);
      _grades = AcademicJson.decodeGrades(d.gradesJson);
      _osymExams = AcademicJson.decodeOsymExams(d.osymExamsJson);
      _yokDocuments = AcademicJson.decodeYokDocuments(d.yokDocumentsJson);
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

  @override
  void dispose() {
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
    _digitalIdInfo.dispose();
    _yokAppsInfo.dispose();
    _osymInfo.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
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

    UserProfile identity;
    try {
      identity = await UserCredentialsRepository.instance.getStored();
    } on Object catch (_) {
      identity = UserCredentialsRepository.instance.defaultProfile;
    }

    final profile = UserProfile(
      firstName: identity.firstName,
      lastName: identity.lastName,
      tc: identity.tc,
      password: identity.password,
      profilePhotoPath: identity.profilePhotoPath,
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
      digitalIdInfo: _digitalIdInfo.text.trim(),
      yokAppsInfo: _yokAppsInfo.text.trim(),
      osymInfo: _osymInfo.text.trim(),
      osymExamsJson: AcademicJson.encodeOsymExams(_osymExams),
      yokDocumentsJson: AcademicJson.encodeYokDocuments(_yokDocuments),
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

  String _gradeCardSubtitle(GradeRecord g) {
    final bits = <String>[
      if (g.vizeGrade.trim().isNotEmpty) 'Vize: ${g.vizeGrade.trim()}',
      if (g.finalGrade.trim().isNotEmpty) 'Final: ${g.finalGrade.trim()}',
      if (g.butExam.trim().isNotEmpty) 'Büt: ${g.butExam.trim()}',
      if (g.letterGrade.trim().isNotEmpty) 'Harf: ${g.letterGrade.trim().toUpperCase()}',
      if (g.courseAkts != null) 'AKTS: ${g.courseAkts}',
    ];
    return bits.isEmpty ? 'Not satırı (vize / final / büt henüz girilmemiş).' : bits.join(' • ');
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

  String _osymExamSubtitle(OsymExamRecord e) {
    final bits = <String>[
      if (e.examDate.trim().isNotEmpty) 'Tarih: ${e.examDate.trim()}',
      if (e.score.trim().isNotEmpty) 'Puan / not: ${e.score.trim()}',
      if (e.note.trim().isNotEmpty) e.note.trim(),
    ];
    return bits.isEmpty ? 'Tarih ve puan ekleyebilirsiniz.' : bits.join(' • ');
  }

  Future<void> _dialogOsymExam() async {
    final r = await showDialog<OsymExamRecord?>(
      context: context,
      builder: (ctx) => _OsymExamFormDialog(deco: _decoration),
    );
    if (!mounted || r == null) return;
    setState(() => _osymExams.add(r));
  }

  String _yokDocTitle(YokDocumentRecord r) {
    final n = r.displayName.trim();
    if (n.isNotEmpty) return n;
    final path = r.storedPath.trim();
    if (path.isEmpty) return 'Belge';
    return p.basename(path);
  }

  String _yokDocSubtitle(YokDocumentRecord r) {
    final path = r.storedPath.trim();
    if (path.isEmpty) return 'Geçersiz kayıt';
    final ext = p.extension(path);
    final shortExt = ext.isEmpty ? 'dosya' : ext.replaceFirst('.', '').toUpperCase();
    if (!File(path).existsSync()) {
      return '$shortExt • dosya bulunamadı (silip yeniden ekleyin)';
    }
    return '$shortExt • ${p.basename(path)}';
  }

  Future<void> _pickYokDocument() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: true,
      );
      if (!mounted || res == null || res.files.isEmpty) return;
      final plat = res.files.single;
      var bytes = plat.bytes;
      if (bytes == null || bytes.isEmpty) {
        final sp = plat.path;
        if (sp == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Dosya okunamadı — tekrar deneyin.')),
            );
          }
          return;
        }
        bytes = await File(sp).readAsBytes();
      }
      final dir = await UserCredentialsRepository.instance.credentialDirectory;
      final sub = Directory(p.join(dir.path, 'yok_docs'));
      if (!await sub.exists()) await sub.create(recursive: true);
      var orig = plat.name.trim();
      if (orig.isEmpty) orig = 'belge';
      final safe = orig.replaceAll(RegExp(r'[/\\:?*"<>|]'), '_');
      final dest = p.join(sub.path, 'yok_${DateTime.now().millisecondsSinceEpoch}_$safe');
      await File(dest).writeAsBytes(bytes);
      final label = p.basenameWithoutExtension(safe);
      setState(() {
        _yokDocuments.add(
          YokDocumentRecord(storedPath: dest, displayName: label),
        );
      });
    } on Object catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belge eklenemedi.')),
      );
    }
  }

  Future<void> _openYokDocument(YokDocumentRecord r) async {
    final fp = r.storedPath.trim();
    if (fp.isEmpty || !mounted) return;
    if (!File(fp).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dosya bulunamadı.')),
      );
      return;
    }
    final res = await OpenFilex.open(fp);
    if (!mounted || res.type == ResultType.done) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res.message)),
    );
  }

  Future<void> _removeYokDocumentAt(int i) async {
    if (i < 0 || i >= _yokDocuments.length) return;
    final path = _yokDocuments[i].storedPath.trim();
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } on Object catch (_) {}
    setState(() => _yokDocuments.removeAt(i));
  }

  Widget _obsListsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _formHint(
          'Çekmedeki «Ders ve genel işlemler» ve OBS sayfaları bu kayıtlarla dolar. ÖSYM ayrı bölümde. Kaydetmeyi unutmayın.',
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
              subtitle: _gradeCardSubtitle(_grades[i]),
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
    VoidCallback? onOpen,
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
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onOpen != null)
                IconButton(
                  onPressed: onOpen,
                  icon: Icon(Icons.open_in_new_rounded, color: Colors.grey.shade700),
                  tooltip: 'Aç',
                ),
              IconButton(
                onPressed: onRemove,
                icon: Icon(Icons.delete_outline_rounded, color: Colors.grey.shade700),
                tooltip: 'Sil',
              ),
            ],
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

  Widget _profileSectionCard({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Colors.grey.shade900,
              ),
            ),
            if (subtitle != null && subtitle.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                subtitle.trim(),
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.38,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Widget _panelSubheading(String t) => Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 8),
        child: Text(
          t,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: Colors.grey.shade800,
          ),
        ),
      );

  Widget _formHint(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12.5,
            height: 1.4,
            color: Colors.grey.shade700,
          ),
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

  static const List<String> _gradeQuickOptions = [
    '1. Sınıf',
    '2. Sınıf',
    '3. Sınıf',
    '4. Sınıf',
    '5. Sınıf',
    'Hazırlık',
  ];

  static const List<String> _termQuickOptions = [
    'Güz',
    'Bahar',
    'Yaz',
    'Yıllık',
  ];

  Widget _activePeriodPreview() {
    final cyan = Colors.cyan.shade900;
    final y = _academicYear.text.trim();
    final g = _eduGrade.text.trim();
    final t = _academicTerm.text.trim();
    final bits = <String>[
      if (y.isNotEmpty) y,
      if (g.isNotEmpty) g,
      if (t.isNotEmpty) t,
    ];
    final line =
        bits.isEmpty ? 'Henüz doldurulmadı — alanları kaydettiğinizde burada özetlenir.' : bits.join(' · ');

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cyan.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aktif dönem özeti (ana sayfa ve kartlar)',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
                color: cyan.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              line,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                height: 1.35,
                color: bits.isEmpty ? cyan.withValues(alpha: 0.55) : cyan,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Örnek: «2025-2026 · 1. Sınıf · Güz» veya «2024-2025 · 2. Sınıf · Yaz»',
              style: TextStyle(
                fontSize: 11.5,
                height: 1.35,
                color: cyan.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickChips({
    required List<String> options,
    required String current,
    required ValueChanged<String> onSelect,
  }) {
    final cyan = Colors.cyan.shade900;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options
          .map(
            (opt) => ChoiceChip(
              label: Text(opt),
              selected: current == opt,
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
              selectedColor: cyan.withValues(alpha: 0.22),
              labelStyle: TextStyle(
                fontSize: 12.5,
                color: cyan,
                fontWeight: current == opt ? FontWeight.w800 : FontWeight.w500,
              ),
              side: BorderSide(color: cyan.withValues(alpha: 0.4)),
              onSelected: (_) => onSelect(opt),
            ),
          )
          .toList(),
    );
  }

  /// Aktif yıl, sınıf, yarıyıl, üniversite ve birim.
  Widget _educationPanel() {
    const cardSub =
        'Buradaki «aktif» değerler, ana sayfa üst çubuğu ve «Aktif akademik dönem / öğrenim bilgileri» '
        'kartlarında kullanılır. Sınıf ile yarıyılı birlikte düşünün (örn. 2. sınıf + Güz). '
        'Üniversite adı sol menü başlığında görünür.';
    return _profileSectionCard(
      title: 'Aktif öğrenim bilgileri',
      subtitle: cardSub,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _panelSubheading('Aktif dönem'),
          TextField(
            controller: _academicYear,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
            decoration: _educationField(
              'Aktif eğitim — öğretim yılı',
              helper:
                  'Şu an kayıtlı olduğunuz akademik yıl. Boş bırakılabilir. Biçim: 2025-2026',
            ),
          ),
          const SizedBox(height: 16),
          _panelSubheading('Sınıf düzeyi (lisans / önlisans)'),
          _formHint(
            'Önce hazır seçeneklerden dokunabilir, gerekirse kutuyu kendiniz düzenlersiniz '
            '(örn. «1. Sınıf (İÖ)», «3. Sınıf»).',
          ),
          _quickChips(
            options: _gradeQuickOptions,
            current: _eduGrade.text.trim(),
            onSelect: (v) => setState(() => _eduGrade.text = v),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _eduGrade,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
            decoration: _educationField(
              'Sınıf metni (kaydedilen değer)',
              helper:
                  'Üst çubuk ve kartlarda «sınıf» olarak geçer. Örn. 1. Sınıf, 2. Sınıf',
            ),
          ),
          const SizedBox(height: 16),
          _panelSubheading('Yarıyıl / alt dönem'),
          _formHint(
            'Güz, bahar veya yaz dönemi; sınıf alanıyla birlikte «1. sınıf güz» gibi düşünebilirsiniz.',
          ),
          _quickChips(
            options: _termQuickOptions,
            current: _academicTerm.text.trim(),
            onSelect: (v) => setState(() => _academicTerm.text = v),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _academicTerm,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
            decoration: _educationField(
              'Yarıyıl metni (kaydedilen değer)',
              helper:
                  'Örn. Güz, Bahar, Yaz, Yıllık — veya akademinizin kullandığı tam ifade',
            ),
          ),
          const SizedBox(height: 14),
          _activePeriodPreview(),
          const SizedBox(height: 20),
          Divider(height: 1, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          _panelSubheading('Üniversite ve birim'),
          _formHint(
            'Üniversite adı sol menünün üst başlığında gösterilir. Fakülte ve bölüm öğrenim kartlarında yer alır.',
          ),
          TextField(
            controller: _universityName,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: _educationField('Üniversite adı').copyWith(
              helperText: 'Örn. Akdeniz Üniversitesi',
              helperStyle: TextStyle(color: Colors.cyan.shade900.withValues(alpha: 0.72), fontSize: 12),
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Eğitim ve akademik bilgiler'),
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
                  _profileSectionCard(
                    title: 'Bu sayfa hakkında',
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey.shade700),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Öğrenim bilgileri, menü metinleri, okul logosu ve ÖBS listeleri burada. '
                            'İsim, T.C., şifre ve fotoğraf için Profil (sağ üst avatar). '
                            'Bu ekrana ana sayfadaki zil ile de gelirsiniz.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.grey.shade700,
                              height: 1.38,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _educationPanel(),
                  _profileSectionCard(
                    title: 'Ana sayfa özeti (OBS)',
                    subtitle:
                        'Danışman, kayıt tarihi ve AGNO ana ekrandaki kartlarda kullanılır; öğrenim alanları yukarıdaki aktif bilgiler kartındadır.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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
                            helperText:
                                'Doldurursanız ana sayfada kırmızı uyarı kartı çıkar; boşsa gösterilmez.',
                            helperStyle: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _profileSectionCard(
                    title: 'Menü, YÖK ve ÖSYM',
                    subtitle:
                        'Dijital kimlik ile YÖK metni çekmede görünür. İsterseniz YÖK için belge ekleyin; sınavlar ayrı «ÖSYM» listesidir.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _digitalIdInfo,
                          textCapitalization: TextCapitalization.sentences,
                          minLines: 3,
                          maxLines: 6,
                          decoration: _decoration('Dijital kimlik bilgisi'),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _yokAppsInfo,
                          textCapitalization: TextCapitalization.sentences,
                          minLines: 3,
                          maxLines: 6,
                          decoration: _decoration('YÖK başvuru ve sonuç metni'),
                        ),
                        const SizedBox(height: 16),
                        _panelSubheading('YÖK ek belgeleri'),
                        _formHint(
                          'PDF, Word veya görsel seçilir; dosya uygulama klasörüne kopyalanır. '
                          'Çekmedeki YÖK sayfasından «Aç» ile görüntüleyebilirsiniz.',
                        ),
                        _miniBar('Belge ekle', _pickYokDocument),
                        if (_yokDocuments.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              'Henüz belge yok.',
                              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                            ),
                          )
                        else
                          ...List.generate(
                            _yokDocuments.length,
                            (i) => _removeCard(
                              title: _yokDocTitle(_yokDocuments[i]),
                              subtitle: _yokDocSubtitle(_yokDocuments[i]),
                              onOpen: () => _openYokDocument(_yokDocuments[i]),
                              onRemove: () => _removeYokDocumentAt(i),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Divider(height: 1, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        _panelSubheading('ÖSYM sınavları'),
                        _formHint(
                          'Sınav adı, tarih ve puan/not. Çekmede sınav kartları olarak görünür.',
                        ),
                        _miniBar('Sınav satırları', _dialogOsymExam),
                        if (_osymExams.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Henüz sınav yok — «Ekle» ile satır ekleyin.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.grey.shade600,
                                height: 1.35,
                              ),
                            ),
                          )
                        else
                          ...List.generate(
                            _osymExams.length,
                            (i) => _removeCard(
                              title: _osymExams[i].examName.isEmpty
                                  ? 'İsimsiz sınav'
                                  : _osymExams[i].examName,
                              subtitle: _osymExamSubtitle(_osymExams[i]),
                              onRemove: () => setState(() => _osymExams.removeAt(i)),
                            ),
                          ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _osymInfo,
                          textCapitalization: TextCapitalization.sentences,
                          minLines: 2,
                          maxLines: 4,
                          decoration: _decoration('ÖSYM ek notlar (isteğe bağlı)').copyWith(
                            helperText:
                                'Liste dışında kısa açıklama; çekmede listenin altında gösterilir.',
                            helperStyle: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _profileSectionCard(
                    title: 'Okul logosu',
                    subtitle: 'Sol menü üstündeki üniversite görseli.',
                    child: Column(
                      children: [
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: ColoredBox(
                              color: Colors.white,
                              child: _logoChild(),
                            ),
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
                  _profileSectionCard(
                    title: 'ÖBS listeleri',
                    child: _obsListsContent(),
                  ),
                  const SizedBox(height: 8),
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

class _OsymExamFormDialog extends StatefulWidget {
  const _OsymExamFormDialog({required this.deco});

  final InputDecoration Function(String label) deco;

  @override
  State<_OsymExamFormDialog> createState() => _OsymExamFormDialogState();
}

class _OsymExamFormDialogState extends State<_OsymExamFormDialog> {
  late final TextEditingController _name;
  late final TextEditingController _date;
  late final TextEditingController _score;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _date = TextEditingController();
    _score = TextEditingController();
    _note = TextEditingController();
  }

  @override
  void dispose() {
    _name.dispose();
    _date.dispose();
    _score.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final n = _name.text.trim();
    if (n.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sınav adını girin.')),
      );
      return;
    }
    Navigator.of(context).pop(
      OsymExamRecord(
        examName: n,
        examDate: _date.text.trim(),
        score: _score.text.trim(),
        note: _note.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('ÖSYM sınavı'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: widget.deco('Sınav adı').copyWith(
                hintText: 'Örn. 2025-TYT, 2025-AYT',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _date,
              decoration: widget.deco('Sınav tarihi').copyWith(
                hintText: 'Örn. 18.06.2025',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _score,
              decoration: widget.deco('Puan / not').copyWith(
                hintText: 'Ham puan, net, yerleştirme puanı…',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              decoration: widget.deco('Kısa not (isteğe bağlı)'),
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

class _GradeFormDialog extends StatefulWidget {
  const _GradeFormDialog({required this.deco});

  final InputDecoration Function(String label) deco;

  @override
  State<_GradeFormDialog> createState() => _GradeFormDialogState();
}

class _GradeFormDialogState extends State<_GradeFormDialog> {
  late final TextEditingController _code;
  late final TextEditingController _name;
  late final TextEditingController _vize;
  late final TextEditingController _finalNot;
  late final TextEditingController _but;
  late final TextEditingController _letter;
  late final TextEditingController _akts;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController();
    _name = TextEditingController();
    _vize = TextEditingController();
    _finalNot = TextEditingController();
    _but = TextEditingController();
    _letter = TextEditingController();
    _akts = TextEditingController();
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _vize.dispose();
    _finalNot.dispose();
    _but.dispose();
    _letter.dispose();
    _akts.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final cc = _code.text.trim();
    final nn = _name.text.trim();
    if (cc.isEmpty || nn.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ders kodu ve adı zorunludur.')),
      );
      return;
    }
    final ak = _akts.text.trim();
    Navigator.of(context).pop(
      GradeRecord(
        courseCode: cc,
        courseName: nn,
        letterGrade: _letter.text.trim(),
        courseAkts: ak.isEmpty ? null : int.tryParse(ak),
        vizeGrade: _vize.text.trim(),
        finalGrade: _finalNot.text.trim(),
        butExam: _but.text.trim(),
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
            TextField(
              controller: _vize,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: widget.deco('Vize notu'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _finalNot,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: widget.deco('Final notu'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _but,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: widget.deco('Büt notu'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _letter,
              decoration:
                  widget.deco('Harf notu').copyWith(hintText: 'İsteğe bağlı (örn. BA)'),
            ),
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
