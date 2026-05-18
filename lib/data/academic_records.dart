import 'dart:convert';

/// Kayıtlı ders bilgisi (Profil ⇄ JSON).
class CourseRecord {
  const CourseRecord({
    required this.code,
    required this.name,
    required this.akts,
    this.instructor = '',
  });

  final String code;
  final String name;
  final int akts;
  final String instructor;

  Map<String, Object?> toJson() => {
        'code': code,
        'name': name,
        'akts': akts,
        'instructor': instructor,
      };

  factory CourseRecord.fromJson(Map<String, dynamic> map) {
    final akRaw = map['akts'];
    int akts = akRaw is int ? akRaw : int.tryParse('$akRaw') ?? 0;
    return CourseRecord(
      code: '${map['code'] ?? ''}'.trim(),
      name: '${map['name'] ?? ''}'.trim(),
      akts: akts,
      instructor: '${map['instructor'] ?? ''}'.trim(),
    );
  }
}

/// Ders bazlı devamsızlık özeti (Profilde girilir).
class AttendanceRecord {
  const AttendanceRecord({
    required this.courseName,
    required this.absentHours,
    required this.lessonHours,
  });

  /// Ders görünür adı / kod ile birlikte yazılabilir.
  final String courseName;

  /// Devamsız kalınan saat/adet.
  final int absentHours;

  /// Öğretim uygun süre (payda — örn. toplam ders saati).
  final int lessonHours;

  double get absentRatioPercent =>
      lessonHours <= 0 ? 0 : (absentHours / lessonHours * 100).clamp(0, 999);

  Map<String, Object?> toJson() => {
        'courseName': courseName,
        'absentHours': absentHours,
        'lessonHours': lessonHours,
      };

  factory AttendanceRecord.fromJson(Map<String, dynamic> map) {
    int ih(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;
    final legacyQuota = ih(map['attendedHours']); // geriye uyum
    final lh = ih(map['lessonHours']);
    return AttendanceRecord(
      courseName: '${map['courseName'] ?? ''}'.trim(),
      absentHours: ih(map['absentHours']),
      lessonHours: lh > 0 ? lh : legacyQuota,
    );
  }
}

/// Bir dönem için AGNO.
class SemesterGpaRecord {
  const SemesterGpaRecord({
    required this.semesterLabel,
    required this.gpa,
  });

  final String semesterLabel;
  final double gpa;

  Map<String, Object?> toJson() => {'semester': semesterLabel, 'gpa': gpa};

  factory SemesterGpaRecord.fromJson(Map<String, dynamic> map) {
    final gRaw = map['gpa'];
    double g;
    if (gRaw is num) {
      g = gRaw.toDouble();
    } else {
      g = double.tryParse('${map['gpa']}'.replaceAll(',', '.')) ?? 0;
    }
    return SemesterGpaRecord(
      semesterLabel: '${map['semester'] ?? map['semesterLabel'] ?? ''}'.trim(),
      gpa: g,
    );
  }
}

/// Not kartı satırı (vize / final / büt + harf; eski düz liste — geriye uyum).
class GradeRecord {
  const GradeRecord({
    required this.courseCode,
    required this.courseName,
    this.letterGrade = '',
    this.courseAkts,
    this.vizeGrade = '',
    this.finalGrade = '',
    this.butExam = '',
  });

  final String courseCode;
  final String courseName;
  final String letterGrade;
  final int? courseAkts;
  final String vizeGrade;
  final String finalGrade;
  final String butExam;

  Map<String, Object?> toJson() {
    return {
      'code': courseCode,
      'name': courseName,
      'letter': letterGrade,
      'vize': vizeGrade,
      'finalNot': finalGrade,
      'but': butExam,
      if (courseAkts != null) 'akts': courseAkts,
    };
  }

  factory GradeRecord.fromJson(Map<String, dynamic> map) {
    final a = map['akts'];
    return GradeRecord(
      courseCode: '${map['code'] ?? ''}'.trim(),
      courseName: '${map['name'] ?? ''}'.trim(),
      letterGrade: '${map['letter'] ?? map['letterGrade'] ?? ''}'.trim(),
      courseAkts: a != null ? (a is int ? a : int.tryParse('$a')) : null,
      vizeGrade: '${map['vize'] ?? ''}'.trim(),
      finalGrade: '${map['finalNot'] ?? map['final'] ?? map['final_grade'] ?? ''}'.trim(),
      butExam: '${map['but'] ?? map['butExam'] ?? ''}'.trim(),
    );
  }
}

/// Dönem çizelgesindeki tek ders satırı (OBS «Not Durumu» tablosu).
class GradeCourseRow {
  const GradeCourseRow({
    required this.courseCode,
    required this.courseName,
    this.resultStatus = 'Sonuçlandırıldı',
    this.vizeGrade = '',
    this.finalGrade = '',
    this.butExam = '',
    this.averageGrade = '',
    this.letterGrade = '',
    this.passStatus = '',
  });

  final String courseCode;
  final String courseName;

  /// Örn. «Sonuçlandırıldı».
  final String resultStatus;
  final String vizeGrade;
  final String finalGrade;
  final String butExam;

  /// Sayısal ort — örn. `54.8`.
  final String averageGrade;

  /// Harf — örn. `CC`, `FD`.
  final String letterGrade;

  /// Örn. `Geçti`, `Kaldı`, `Geçti (Büt)`.
  final String passStatus;

  Map<String, Object?> toJson() => {
        'code': courseCode,
        'name': courseName,
        'resultStatus': resultStatus,
        'vize': vizeGrade,
        'finalNot': finalGrade,
        'but': butExam,
        'average': averageGrade,
        'letter': letterGrade,
        'passStatus': passStatus,
      };

  factory GradeCourseRow.fromJson(Map<String, dynamic> map) {
    return GradeCourseRow(
      courseCode: '${map['code'] ?? ''}'.trim(),
      courseName: '${map['name'] ?? ''}'.trim(),
      resultStatus:
          '${map['resultStatus'] ?? map['result_status'] ?? 'Sonuçlandırıldı'}'.trim(),
      vizeGrade: '${map['vize'] ?? ''}'.trim(),
      finalGrade: '${map['finalNot'] ?? map['final'] ?? ''}'.trim(),
      butExam: '${map['but'] ?? map['butExam'] ?? ''}'.trim(),
      averageGrade: '${map['average'] ?? map['averageGrade'] ?? ''}'.trim(),
      letterGrade: '${map['letter'] ?? map['letterGrade'] ?? ''}'.trim(),
      passStatus: '${map['passStatus'] ?? map['pass_status'] ?? ''}'.trim(),
    );
  }

  factory GradeCourseRow.fromLegacy(GradeRecord g) => GradeCourseRow(
        courseCode: g.courseCode,
        courseName: g.courseName,
        vizeGrade: g.vizeGrade,
        finalGrade: g.finalGrade,
        butExam: g.butExam,
        letterGrade: g.letterGrade,
      );
}

/// Bir dönem / yarıyıl not çizelgesi (6–8 adet tanımlanabilir).
class GradeTermSheet {
  const GradeTermSheet({
    this.universityName = '',
    this.classYearLabel = '',
    this.semesterLabel = '',
    this.academicPeriod = '',
    this.courses = const [],
  });

  /// Sınıf bloğu başında gösterilir (boşsa profil üniversite adı).
  final String universityName;

  /// Örn. `1. Sınıf`.
  final String classYearLabel;

  /// Örn. `1. Dönem`.
  final String semesterLabel;

  /// Üst sağ açılır liste — örn. `2025-2026 Güz`.
  final String academicPeriod;
  final List<GradeCourseRow> courses;

  String get headerTitle {
    final c = classYearLabel.trim();
    final s = semesterLabel.trim();
    if (c.isEmpty && s.isEmpty) return 'Not çizelgesi';
    if (c.isEmpty) return s;
    if (s.isEmpty) return c;
    return '$c - $s';
  }

  /// Not durumu sayfasındaki dönem sekmesi — örn. «1. Sınıf Güz».
  String get selectorLabel {
    final cls = classYearLabel.trim();
    final period = academicPeriod.trim();
    if (cls.isEmpty && period.isEmpty) {
      return semesterLabel.trim().isEmpty ? 'Dönem' : semesterLabel.trim();
    }

    for (final season in const ['Güz', 'Bahar', 'Yaz', 'Yıllık']) {
      if (period.contains(season)) {
        return cls.isEmpty ? season : '$cls $season';
      }
    }

    if (cls.isNotEmpty && period.isNotEmpty) return '$cls · $period';
    return cls.isNotEmpty ? cls : period;
  }

  Map<String, Object?> toJson() => {
        if (universityName.trim().isNotEmpty) 'universityName': universityName.trim(),
        if (classYearLabel.trim().isNotEmpty) 'classYear': classYearLabel.trim(),
        if (semesterLabel.trim().isNotEmpty) 'semester': semesterLabel.trim(),
        if (academicPeriod.trim().isNotEmpty) 'academicPeriod': academicPeriod.trim(),
        'courses': courses.map((e) => e.toJson()).toList(),
      };

  factory GradeTermSheet.fromJson(Map<String, dynamic> map) {
    final rawCourses = map['courses'];
    final rows = <GradeCourseRow>[];
    if (rawCourses is List) {
      for (final dynamic e in rawCourses) {
        if (e is Map) {
          rows.add(GradeCourseRow.fromJson(
            Map<String, dynamic>.from(Map<Object?, Object?>.from(e)),
          ));
        }
      }
    }
    return GradeTermSheet(
      universityName:
          '${map['universityName'] ?? map['university'] ?? ''}'.trim(),
      classYearLabel: '${map['classYear'] ?? map['class_year'] ?? ''}'.trim(),
      semesterLabel: '${map['semester'] ?? map['semesterLabel'] ?? ''}'.trim(),
      academicPeriod:
          '${map['academicPeriod'] ?? map['academic_period'] ?? ''}'.trim(),
      courses: rows,
    );
  }
}

/// ÖSYM / TYT-AYT vb. sınav satırı (profil JSON dizisi).
class OsymExamRecord {
  const OsymExamRecord({
    required this.examName,
    this.examDate = '',
    this.score = '',
    this.note = '',
  });

  final String examName;

  /// Tarih serbest metin (örn. 13.06.2025).
  final String examDate;

  /// Puan / ham puan / net — serbest metin.
  final String score;

  final String note;

  Map<String, Object?> toJson() => {
        'name': examName,
        'date': examDate,
        'score': score,
        if (note.isNotEmpty) 'note': note,
      };

  factory OsymExamRecord.fromJson(Map<String, dynamic> map) {
    return OsymExamRecord(
      examName: '${map['name'] ?? map['examName'] ?? map['title'] ?? ''}'.trim(),
      examDate: '${map['date'] ?? map['examDate'] ?? ''}'.trim(),
      score: '${map['score'] ?? map['not'] ?? map['puan'] ?? ''}'.trim(),
      note: '${map['note'] ?? ''}'.trim(),
    );
  }
}

/// YÖK başvuruları için yerel kopyalanmış belge (PDF, görüntü vb.).
class YokDocumentRecord {
  const YokDocumentRecord({
    required this.storedPath,
    this.displayName = '',
  });

  /// [UserCredentialsRepository.credentialDirectory] altında kopya yolu.
  final String storedPath;

  /// Listede gösterilen kısa başlık; boşsa dosya adı kullanılır.
  final String displayName;

  Map<String, Object?> toJson() => {
        'path': storedPath,
        if (displayName.trim().isNotEmpty) 'label': displayName.trim(),
      };

  factory YokDocumentRecord.fromJson(Map<String, dynamic> map) {
    return YokDocumentRecord(
      storedPath: '${map['path'] ?? map['storedPath'] ?? ''}'.trim(),
      displayName: '${map['label'] ?? map['displayName'] ?? ''}'.trim(),
    );
  }
}

/// JSON güvenli ayrıştırma yardımcıları.
abstract final class AcademicJson {
  AcademicJson._();

  static List<CourseRecord> decodeCourses(String raw) =>
      _decodeList(raw, (m) => CourseRecord.fromJson(m));

  static String encodeCourses(List<CourseRecord> xs) =>
      jsonEncode(xs.map((e) => e.toJson()).toList());

  static List<AttendanceRecord> decodeAttendance(String raw) =>
      _decodeList(raw, (m) => AttendanceRecord.fromJson(m));

  static String encodeAttendance(List<AttendanceRecord> xs) =>
      jsonEncode(xs.map((e) => e.toJson()).toList());

  static List<SemesterGpaRecord> decodeSemesterGpas(String raw) =>
      _decodeList(raw, (m) => SemesterGpaRecord.fromJson(m));

  static String encodeSemesterGpas(List<SemesterGpaRecord> xs) =>
      jsonEncode(xs.map((e) => e.toJson()).toList());

  static List<GradeRecord> decodeGrades(String raw) =>
      _decodeList(raw, (m) => GradeRecord.fromJson(m));

  static String encodeGrades(List<GradeRecord> xs) =>
      jsonEncode(xs.map((e) => e.toJson()).toList());

  /// Dönem not çizelgeleri; eski düz [GradeRecord] listesini tek çizelgeye sarar.
  static List<GradeTermSheet> decodeGradeSheets(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return [];
    try {
      final d = jsonDecode(t);
      if (d is! List || d.isEmpty) return [];
      final first = d.first;
      if (first is Map &&
          (first.containsKey('courses') ||
              first.containsKey('classYear') ||
              first.containsKey('class_year'))) {
        return [
          for (final dynamic e in d)
            if (e is Map)
              GradeTermSheet.fromJson(
                Map<String, dynamic>.from(Map<Object?, Object?>.from(e)),
              ),
        ];
      }
      final legacy = decodeGrades(raw);
      if (legacy.isEmpty) return [];
      return [
        GradeTermSheet(
          courses: [for (final g in legacy) GradeCourseRow.fromLegacy(g)],
        ),
      ];
    } on Object catch (_) {
      return [];
    }
  }

  static String encodeGradeSheets(List<GradeTermSheet> xs) =>
      jsonEncode(xs.map((e) => e.toJson()).toList());

  static List<OsymExamRecord> decodeOsymExams(String raw) =>
      _decodeList(raw, (m) => OsymExamRecord.fromJson(m));

  static String encodeOsymExams(List<OsymExamRecord> xs) =>
      jsonEncode(xs.map((e) => e.toJson()).toList());

  static List<YokDocumentRecord> decodeYokDocuments(String raw) =>
      _decodeList(raw, (m) => YokDocumentRecord.fromJson(m));

  static String encodeYokDocuments(List<YokDocumentRecord> xs) =>
      jsonEncode(xs.map((e) => e.toJson()).toList());

  static List<T> _decodeList<T>(
    String raw,
    T Function(Map<String, dynamic> m) f,
  ) {
    final t = raw.trim();
    if (t.isEmpty) return [];
    try {
      final d = jsonDecode(t);
      if (d is! List) return [];
      return [
        for (final dynamic e in d)
          if (e is Map) f(Map<String, dynamic>.from(Map<Object?, Object?>.from(e)))
      ];
    } on Object catch (_) {
      return [];
    }
  }
}
