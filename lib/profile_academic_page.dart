import 'dart:io' show Directory, File;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import 'data/academic_records.dart';
import 'data/user_credentials_repository.dart';
import 'widgets/pdf_inline_preview.dart';

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
  bool _loading = true;
  bool _saving = false;
  String? _schoolLogoPath;

  List<CourseRecord> _courses = [];
  List<AttendanceRecord> _attendance = [];
  List<SemesterGpaRecord> _semesterGpas = [];
  List<GradeTermSheet> _gradeSheets = [];
  List<YokDocumentRecord> _yokDocuments = [];
  List<YokDocumentRecord> _osymDocuments = [];
  List<YokDocumentRecord> _digitalDocuments = [];

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
      _schoolLogoPath = r.schoolLogoPath;
      _courses = AcademicJson.decodeCourses(r.coursesJson);
      _attendance = AcademicJson.decodeAttendance(r.attendanceJson);
      _semesterGpas = AcademicJson.decodeSemesterGpas(r.semesterGpasJson);
      _gradeSheets = AcademicJson.decodeGradeSheets(r.gradesJson);
      _yokDocuments = AcademicJson.decodeYokDocuments(r.yokDocumentsJson);
      _osymDocuments = AcademicJson.decodeYokDocuments(r.osymDocumentsJson);
      _digitalDocuments = AcademicJson.decodeYokDocuments(r.digitalIdDocumentsJson);
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
      _schoolLogoPath = d.schoolLogoPath;
      _courses = AcademicJson.decodeCourses(d.coursesJson);
      _attendance = AcademicJson.decodeAttendance(d.attendanceJson);
      _semesterGpas = AcademicJson.decodeSemesterGpas(d.semesterGpasJson);
      _gradeSheets = AcademicJson.decodeGradeSheets(d.gradesJson);
      _yokDocuments = AcademicJson.decodeYokDocuments(d.yokDocumentsJson);
      _osymDocuments = AcademicJson.decodeYokDocuments(d.osymDocumentsJson);
      _digitalDocuments = AcademicJson.decodeYokDocuments(d.digitalIdDocumentsJson);
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
      gradesJson: AcademicJson.encodeGradeSheets(_gradeSheets),
      academicTerm: _academicTerm.text.trim(),
      advisorInfo: _advisorInfo.text.trim(),
      registrationDate: _registrationDate.text.trim(),
      overallGpa: _overallGpa.text.trim(),
      dashboardWarning: _dashboardWarning.text.trim(),
      digitalIdInfo: '',
      yokAppsInfo: '',
      osymInfo: '',
      osymExamsJson: '[]',
      yokDocumentsJson: AcademicJson.encodeYokDocuments(_yokDocuments),
      osymDocumentsJson: AcademicJson.encodeYokDocuments(_osymDocuments),
      digitalIdDocumentsJson: AcademicJson.encodeYokDocuments(_digitalDocuments),
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
    final r = await showDialog<_GradeEntryResult?>(
      context: context,
      builder: (ctx) => _GradeEntryDialog(
        deco: _decoration,
        defaultUniversity: _universityName.text.trim(),
        defaultClassYear: _eduGrade.text.trim(),
        defaultAcademicYear: _academicYear.text.trim(),
        defaultTermSeason: _academicTerm.text.trim(),
      ),
    );
    if (!mounted || r == null) return;
    setState(() => _mergeGradeEntry(r));
  }

  void _mergeGradeEntry(_GradeEntryResult entry) {
    final uni = entry.universityName.trim();
    final cls = entry.classYearLabel.trim();
    final period = entry.academicPeriod.trim();

    var idx = _gradeSheets.indexWhere((s) {
      return s.universityName.trim() == uni &&
          s.classYearLabel.trim() == cls &&
          s.academicPeriod.trim() == period;
    });

    if (idx < 0) {
      if (_gradeSheets.length >= 8) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('En fazla 8 dönem çizelgesi eklenebilir.')),
        );
        return;
      }
      _gradeSheets.add(
        GradeTermSheet(
          universityName: uni,
          classYearLabel: cls,
          academicPeriod: period,
          courses: [entry.course],
        ),
      );
      return;
    }

    final sheet = _gradeSheets[idx];
    _gradeSheets[idx] = GradeTermSheet(
      universityName: sheet.universityName,
      classYearLabel: sheet.classYearLabel,
      semesterLabel: sheet.semesterLabel,
      academicPeriod: sheet.academicPeriod,
      courses: [...sheet.courses, entry.course],
    );
  }

  String _gradeEntryCardTitle(GradeCourseRow c) => '${c.courseCode} · ${c.courseName}';

  String _gradeEntryCardSubtitle(GradeTermSheet sheet, GradeCourseRow c) {
    final bits = <String>[
      if (sheet.universityName.trim().isNotEmpty) sheet.universityName.trim(),
      if (sheet.classYearLabel.trim().isNotEmpty) sheet.classYearLabel.trim(),
      if (sheet.academicPeriod.trim().isNotEmpty) sheet.academicPeriod.trim(),
      ..._gradeCourseSubtitleParts(c),
    ];
    return bits.join(' • ');
  }

  List<String> _gradeCourseSubtitleParts(GradeCourseRow g) {
    return [
      if (g.vizeGrade.trim().isNotEmpty) 'Vize: ${g.vizeGrade.trim()}',
      if (g.finalGrade.trim().isNotEmpty) 'Final: ${g.finalGrade.trim()}',
      if (g.butExam.trim().isNotEmpty) 'Büt: ${g.butExam.trim()}',
      if (g.averageGrade.trim().isNotEmpty) 'Not: ${g.averageGrade.trim()}',
      if (g.letterGrade.trim().isNotEmpty) 'Harf: ${g.letterGrade.trim().toUpperCase()}',
      if (g.passStatus.trim().isNotEmpty) g.passStatus.trim(),
    ];
  }

  void _removeGradeEntry(int sheetIndex, int courseIndex) {
    final sheet = _gradeSheets[sheetIndex];
    final updated = [...sheet.courses]..removeAt(courseIndex);
    if (updated.isEmpty) {
      _gradeSheets.removeAt(sheetIndex);
    } else {
      _gradeSheets[sheetIndex] = GradeTermSheet(
        universityName: sheet.universityName,
        classYearLabel: sheet.classYearLabel,
        semesterLabel: sheet.semesterLabel,
        academicPeriod: sheet.academicPeriod,
        courses: updated,
      );
    }
  }

  Future<void> _pickPdfDocument(
    List<YokDocumentRecord> bucket,
    String folder,
    int maxCount,
  ) async {
    if (bucket.length >= maxCount) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('En fazla $maxCount PDF eklenebilir.')),
      );
      return;
    }
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        withData: true,
      );
      if (!mounted || res == null || res.files.isEmpty) return;
      final plat = res.files.single;
      var name = plat.name.trim();
      if (name.isEmpty) name = 'belge.pdf';
      if (!name.toLowerCase().endsWith('.pdf')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yalnızca PDF dosyası seçilebilir.')),
        );
        return;
      }
      var bytes = plat.bytes;
      if (bytes == null || bytes.isEmpty) {
        final sp = plat.path;
        if (sp == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Dosya okunamadı.')),
            );
          }
          return;
        }
        bytes = await File(sp).readAsBytes();
      }
      final dir = await UserCredentialsRepository.instance.credentialDirectory;
      final sub = Directory(p.join(dir.path, folder));
      if (!await sub.exists()) await sub.create(recursive: true);
      final safe = name.replaceAll(RegExp(r'[/\\:?*"<>|]'), '_');
      final dest = p.join(sub.path, '${DateTime.now().millisecondsSinceEpoch}_$safe');
      await File(dest).writeAsBytes(bytes);
      setState(() {
        bucket.add(YokDocumentRecord(storedPath: dest));
      });
    } on Object catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF eklenemedi.')),
      );
    }
  }

  Future<void> _removeDocumentAt(List<YokDocumentRecord> bucket, int i) async {
    if (i < 0 || i >= bucket.length) return;
    final path = bucket[i].storedPath.trim();
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } on Object catch (_) {}
    setState(() => bucket.removeAt(i));
  }

  Widget _pdfDocumentsBlock({
    required String title,
    required int maxCount,
    required List<YokDocumentRecord> docs,
    required VoidCallback onAdd,
    required void Function(int index) onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: _label,
                ),
              ),
            ),
            if (docs.length < maxCount)
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: const Text('PDF ekle'),
              ),
          ],
        ),
        if (docs.isEmpty) const SizedBox(height: 4)
        else
          ...List.generate(docs.length, (i) {
            final path = docs[i].storedPath.trim();
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ColoredBox(
                      color: Colors.white,
                      child: PdfInlinePreview(
                        key: ValueKey<String>(path),
                        filePath: path,
                        height: 220,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: Colors.black54,
                      shape: const CircleBorder(),
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                        onPressed: () => onRemove(i),
                        tooltip: 'Kaldır',
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _obsListsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _miniBar('Ders kayıt bilgileri', _dialogCourse),
        if (_courses.isEmpty)
          const SizedBox.shrink()
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
          const SizedBox.shrink()
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
          const SizedBox.shrink()
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
        _miniBar('Not durumu', _dialogGrade),
        if (_gradeSheets.isEmpty)
          const SizedBox.shrink()
        else
          ...[
            for (var si = 0; si < _gradeSheets.length; si++)
              for (var ci = 0; ci < _gradeSheets[si].courses.length; ci++)
                _removeCard(
                  title: _gradeEntryCardTitle(_gradeSheets[si].courses[ci]),
                  subtitle: _gradeEntryCardSubtitle(
                    _gradeSheets[si],
                    _gradeSheets[si].courses[ci],
                  ),
                  onRemove: () => setState(() => _removeGradeEntry(si, ci)),
                ),
          ],
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
        bits.isEmpty ? '—' : bits.join(' · ');

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
    return _profileSectionCard(
      title: 'Aktif öğrenim bilgileri',
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
        title: const Text('Veri girişi'),
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
                  _educationPanel(),
                  _profileSectionCard(
                    title: 'Ana sayfa özeti (OBS)',
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
                    title: 'Belgeler (PDF)',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _pdfDocumentsBlock(
                          title: 'YÖK (en fazla 4)',
                          maxCount: 4,
                          docs: _yokDocuments,
                          onAdd: () => _pickPdfDocument(_yokDocuments, 'yok_docs', 4),
                          onRemove: (i) => _removeDocumentAt(_yokDocuments, i),
                        ),
                        const SizedBox(height: 20),
                        _pdfDocumentsBlock(
                          title: 'ÖSYM (en fazla 4)',
                          maxCount: 4,
                          docs: _osymDocuments,
                          onAdd: () => _pickPdfDocument(_osymDocuments, 'osym_docs', 4),
                          onRemove: (i) => _removeDocumentAt(_osymDocuments, i),
                        ),
                        const SizedBox(height: 20),
                        _pdfDocumentsBlock(
                          title: 'Dijital kimlik (en fazla 6)',
                          maxCount: 6,
                          docs: _digitalDocuments,
                          onAdd: () => _pickPdfDocument(_digitalDocuments, 'digital_docs', 6),
                          onRemove: (i) => _removeDocumentAt(_digitalDocuments, i),
                        ),
                      ],
                    ),
                  ),
                  _profileSectionCard(
                    title: 'Okul logosu',
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

class _GradeEntryResult {
  const _GradeEntryResult({
    required this.universityName,
    required this.classYearLabel,
    required this.academicPeriod,
    required this.course,
  });

  final String universityName;
  final String classYearLabel;
  final String academicPeriod;
  final GradeCourseRow course;
}

class _GradeEntryDialog extends StatefulWidget {
  const _GradeEntryDialog({
    required this.deco,
    required this.defaultUniversity,
    required this.defaultClassYear,
    required this.defaultAcademicYear,
    required this.defaultTermSeason,
  });

  final InputDecoration Function(String label) deco;
  final String defaultUniversity;
  final String defaultClassYear;
  final String defaultAcademicYear;
  final String defaultTermSeason;

  @override
  State<_GradeEntryDialog> createState() => _GradeEntryDialogState();
}

class _GradeEntryDialogState extends State<_GradeEntryDialog> {
  late final TextEditingController _university;
  late final TextEditingController _academicYear;
  late final TextEditingController _termSeason;
  late final TextEditingController _classYear;
  late final TextEditingController _code;
  late final TextEditingController _name;
  late final TextEditingController _vize;
  late final TextEditingController _finalNot;
  late final TextEditingController _but;
  late final TextEditingController _average;
  late final TextEditingController _letter;
  late final TextEditingController _passStatus;

  static const _classOptions = [
    'Hazırlık',
    '1. Sınıf',
    '2. Sınıf',
    '3. Sınıf',
    '4. Sınıf',
  ];
  static const _termSeasonOptions = ['Güz', 'Bahar', 'Yaz', 'Yıllık'];
  static const _passOptions = ['Geçti', 'Kaldı', 'Geçti (Büt)'];

  @override
  void initState() {
    super.initState();
    _university = TextEditingController(text: widget.defaultUniversity);
    _academicYear = TextEditingController(text: widget.defaultAcademicYear);
    _termSeason = TextEditingController(text: widget.defaultTermSeason);
    _classYear = TextEditingController(text: widget.defaultClassYear);
    _code = TextEditingController();
    _name = TextEditingController();
    _vize = TextEditingController();
    _finalNot = TextEditingController();
    _but = TextEditingController();
    _average = TextEditingController();
    _letter = TextEditingController();
    _passStatus = TextEditingController();
  }

  @override
  void dispose() {
    _university.dispose();
    _academicYear.dispose();
    _termSeason.dispose();
    _classYear.dispose();
    _code.dispose();
    _name.dispose();
    _vize.dispose();
    _finalNot.dispose();
    _but.dispose();
    _average.dispose();
    _letter.dispose();
    _passStatus.dispose();
    super.dispose();
  }

  Widget _chips(List<String> options, TextEditingController ctrl) {
    final current = ctrl.text.trim();
    const accent = Color(0xFF455A64);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final o in options)
          ChoiceChip(
            label: Text(o),
            selected: current == o,
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            selectedColor: accent.withValues(alpha: 0.22),
            labelStyle: TextStyle(
              fontSize: 12.5,
              color: accent,
              fontWeight: current == o ? FontWeight.w800 : FontWeight.w500,
            ),
            side: BorderSide(
              color: current == o ? accent : accent.withValues(alpha: 0.35),
            ),
            onSelected: (_) => setState(() => ctrl.text = o),
          ),
      ],
    );
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final cc = _code.text.trim();
    final nn = _name.text.trim();
    if (cc.isEmpty || nn.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ders kodu ve ders adı zorunludur.')),
      );
      return;
    }
    final cls = _classYear.text.trim();
    if (cls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sınıf seçin.')),
      );
      return;
    }
    final year = _academicYear.text.trim();
    final season = _termSeason.text.trim();
    if (year.isEmpty && season.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dönem için yıl veya Güz / Bahar / Yaz seçin.')),
      );
      return;
    }
    final period = [year, season].where((s) => s.isNotEmpty).join(' ');

    Navigator.of(context).pop(
      _GradeEntryResult(
        universityName: _university.text.trim(),
        classYearLabel: cls,
        academicPeriod: period,
        course: GradeCourseRow(
          courseCode: cc,
          courseName: nn,
          vizeGrade: _vize.text.trim(),
          finalGrade: _finalNot.text.trim(),
          butExam: _but.text.trim(),
          averageGrade: _average.text.trim(),
          letterGrade: _letter.text.trim(),
          passStatus: _passStatus.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Not ekle'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _university,
              decoration: widget.deco('Üniversite adı'),
            ),
            const SizedBox(height: 16),
            Text('Sınıf', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            const SizedBox(height: 6),
            _chips(_classOptions, _classYear),
            const SizedBox(height: 16),
            Text('Dönem', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            const SizedBox(height: 6),
            TextField(
              controller: _academicYear,
              decoration: widget.deco('Eğitim-öğretim yılı').copyWith(
                hintText: '2025-2026',
              ),
            ),
            const SizedBox(height: 8),
            _chips(_termSeasonOptions, _termSeason),
            const Divider(height: 28),
            TextField(controller: _code, decoration: widget.deco('Ders kodu')),
            const SizedBox(height: 12),
            TextField(controller: _name, decoration: widget.deco('Ders adı')),
            const SizedBox(height: 12),
            TextField(
              controller: _vize,
              decoration: widget.deco('Vize notu'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _finalNot,
              decoration: widget.deco('Final notu'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _but,
              decoration: widget.deco('Büt notu (varsa)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _average,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: widget.deco('Ortalama not'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _letter,
              decoration: widget.deco('Harf notu').copyWith(
                hintText: 'CC, FD, BB…',
              ),
            ),
            const SizedBox(height: 12),
            Text('Geçti / kaldı', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            const SizedBox(height: 6),
            _chips(_passOptions, _passStatus),
            const SizedBox(height: 8),
            TextField(
              controller: _passStatus,
              decoration: widget.deco('Durum'),
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
