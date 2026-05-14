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

/// Not kartı satırı.
class GradeRecord {
  const GradeRecord({
    required this.courseCode,
    required this.courseName,
    required this.letterGrade,
    this.courseAkts,
  });

  final String courseCode;
  final String courseName;

  /// Harf notu — örn. BA, DD.
  final String letterGrade;

  /// Nullable — isteğe bağlı gösterilir.
  final int? courseAkts;

  Map<String, Object?> toJson() {
    return {
      'code': courseCode,
      'name': courseName,
      'letter': letterGrade,
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
