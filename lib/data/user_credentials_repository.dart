import 'dart:io' show Directory, File;

import 'package:path/path.dart' as p;
import 'package:sqflite_common/sqflite.dart';

/// Profil satırı (SQLite + isteğe bağlı görseller).
class UserProfile {
  const UserProfile({
    required this.firstName,
    required this.lastName,
    required this.tc,
    required this.password,
    this.profilePhotoPath,
    this.schoolLogoPath,
    this.academicYear = '',
    this.eduFaculty = '',
    this.eduDepartment = '',
    this.eduGrade = '',
    this.universityName = '',
    this.coursesJson = '[]',
    this.attendanceJson = '[]',
    this.semesterGpasJson = '[]',
    this.gradesJson = '[]',
    this.academicTerm = '',
    this.advisorInfo = '',
    this.registrationDate = '',
    this.overallGpa = '',
    this.dashboardWarning = '',
    this.digitalIdInfo = '',
    this.yokAppsInfo = '',
    this.osymInfo = '',
  });

  final String firstName;
  final String lastName;
  final String tc;
  final String password;
  final String? profilePhotoPath;
  final String? schoolLogoPath;

  /// Örn. `2025-2026` — ana sayfa üst çubuğunda gösterilir.
  final String academicYear;

  /// Fakülte / MYO / birim adı.
  final String eduFaculty;

  /// Program / bölüm metni.
  final String eduDepartment;

  /// Örn. `1. Sınıf`.
  final String eduGrade;

  /// Drawer başlığında gösterilir (örn. Akdeniz Üniversitesi).
  final String universityName;

  /// [CourseRecord] listesi için JSON dizisi (`[]`).
  final String coursesJson;

  /// [AttendanceRecord] listesi.
  final String attendanceJson;

  /// [SemesterGpaRecord] listesi.
  final String semesterGpasJson;

  /// [GradeRecord] listesi (not kartı satırları).
  final String gradesJson;

  /// Örn. `Güz`, `Bahar` — üst çubuk ve aktif dönem kartında [academicYear] ile birleştirilir.
  final String academicTerm;

  /// Danışman (ünvan + ad soyad).
  final String advisorInfo;

  /// Ana sayfada kayıt tarihi metni (örn. 28.08.2023).
  final String registrationDate;

  /// Genel AGNO gösterimi (örn. `0` veya `3,45`).
  final String overallGpa;

  /// Boş değilse ana sayfada kırmızı uyarı kartı.
  final String dashboardWarning;

  /// Çekmece › Dijital kimliğim (profilden metin).
  final String digitalIdInfo;

  /// Çekmece › YÖK başvuruları ve sonuçları (profilden).
  final String yokAppsInfo;

  /// Çekmece › ÖSYM bilgisi (profilden).
  final String osymInfo;
}

/// Yerel SQLite: tek satır kullanıcı + `logged_in` oturumu.
///
/// Dizin: [Directory.systemTemp] altı (`path_provider` yok).
class UserCredentialsRepository {
  UserCredentialsRepository._();
  static final UserCredentialsRepository instance = UserCredentialsRepository._();

  Database? _db;

  static const String defaultTc = '11111111111';
  static const String defaultPassword = '123456';

  static const String _table = 'credentials';
  static const int _singletonId = 1;
  static const String _dbFile = 'obs_user.db';
  static const int _dbVersion = 10;

  Future<Directory> get credentialDirectory async {
    final sub = Directory(p.join(Directory.systemTemp.path, 'obs_credentials'));
    if (!await sub.exists()) await sub.create(recursive: true);
    return sub;
  }

  Future<String> get _databasePath async {
    final dir = await credentialDirectory;
    return p.join(dir.path, _dbFile);
  }

  Future<Database> get _database async {
    if (_db != null) return _db!;
    final dbPath = await _databasePath;
    _db = await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: (Database db, int _) async {
        await db.execute('''
CREATE TABLE $_table (
  id INTEGER PRIMARY KEY CHECK (id = $_singletonId),
  tc TEXT NOT NULL,
  password TEXT NOT NULL,
  first_name TEXT NOT NULL DEFAULT '',
  last_name TEXT NOT NULL DEFAULT '',
  profile_photo_path TEXT,
  school_logo_path TEXT,
  academic_year TEXT NOT NULL DEFAULT '',
  edu_faculty TEXT NOT NULL DEFAULT '',
  edu_department TEXT NOT NULL DEFAULT '',
  edu_grade TEXT NOT NULL DEFAULT '',
  university_name TEXT NOT NULL DEFAULT '',
  courses_json TEXT NOT NULL DEFAULT '[]',
  attendance_json TEXT NOT NULL DEFAULT '[]',
  semester_gpas_json TEXT NOT NULL DEFAULT '[]',
  grades_json TEXT NOT NULL DEFAULT '[]',
  academic_term TEXT NOT NULL DEFAULT '',
  advisor_info TEXT NOT NULL DEFAULT '',
  registration_date TEXT NOT NULL DEFAULT '',
  overall_gpa TEXT NOT NULL DEFAULT '',
  dashboard_warning TEXT NOT NULL DEFAULT '',
  digital_id_info TEXT NOT NULL DEFAULT '',
  yok_apps_info TEXT NOT NULL DEFAULT '',
  osym_info TEXT NOT NULL DEFAULT '',
  logged_in INTEGER NOT NULL DEFAULT 0
)
''');
        await db.insert(_table, _insertRowDefaults());
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE $_table ADD COLUMN first_name TEXT DEFAULT ''",
          );
          await db.execute(
            "ALTER TABLE $_table ADD COLUMN last_name TEXT DEFAULT ''",
          );
          await db.execute(
            'ALTER TABLE $_table ADD COLUMN school_logo_path TEXT',
          );
        }
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE $_table ADD COLUMN profile_photo_path TEXT',
          );
        }
        if (oldVersion < 4) {
          await db.execute(
            'ALTER TABLE $_table ADD COLUMN logged_in INTEGER DEFAULT 0',
          );
        }
        if (oldVersion < 5) {
          await db.execute(
            "ALTER TABLE $_table ADD COLUMN academic_year TEXT DEFAULT ''",
          );
        }
        if (oldVersion < 6) {
          await db.execute(
            "ALTER TABLE $_table ADD COLUMN edu_faculty TEXT DEFAULT ''",
          );
          await db.execute(
            "ALTER TABLE $_table ADD COLUMN edu_department TEXT DEFAULT ''",
          );
          await db.execute(
            "ALTER TABLE $_table ADD COLUMN edu_grade TEXT DEFAULT ''",
          );
        }
        if (oldVersion < 7) {
          await db.execute(
            "ALTER TABLE $_table ADD COLUMN university_name TEXT DEFAULT ''",
          );
        }
        if (oldVersion < 8) {
          await db.execute(
            "ALTER TABLE $_table ADD COLUMN courses_json TEXT DEFAULT '[]'",
          );
          await db.execute(
            "ALTER TABLE $_table ADD COLUMN attendance_json TEXT DEFAULT '[]'",
          );
          await db.execute(
            "ALTER TABLE $_table ADD COLUMN semester_gpas_json TEXT DEFAULT '[]'",
          );
          await db.execute(
            "ALTER TABLE $_table ADD COLUMN grades_json TEXT DEFAULT '[]'",
          );
        }
        if (oldVersion < 9) {
          await db.execute(
            "ALTER TABLE $_table ADD COLUMN academic_term TEXT DEFAULT ''",
          );
          await db.execute(
            "ALTER TABLE $_table ADD COLUMN advisor_info TEXT DEFAULT ''",
          );
          await db.execute(
            "ALTER TABLE $_table ADD COLUMN registration_date TEXT DEFAULT ''",
          );
          await db.execute(
            "ALTER TABLE $_table ADD COLUMN overall_gpa TEXT DEFAULT ''",
          );
          await db.execute(
            "ALTER TABLE $_table ADD COLUMN dashboard_warning TEXT DEFAULT ''",
          );
        }
        if (oldVersion < 10) {
          await db.execute(
            "ALTER TABLE $_table ADD COLUMN digital_id_info TEXT DEFAULT ''",
          );
          await db.execute(
            "ALTER TABLE $_table ADD COLUMN yok_apps_info TEXT DEFAULT ''",
          );
          await db.execute(
            "ALTER TABLE $_table ADD COLUMN osym_info TEXT DEFAULT ''",
          );
        }
      },
    );
    await _ensureSingletonRow(_db!);
    return _db!;
  }

  Map<String, Object?> _insertRowDefaults() => {
        'id': _singletonId,
        'tc': defaultTc,
        'password': defaultPassword,
        'first_name': '',
        'last_name': '',
        'profile_photo_path': null,
        'school_logo_path': null,
        'academic_year': '',
        'edu_faculty': '',
        'edu_department': '',
        'edu_grade': '',
        'university_name': '',
        'courses_json': '[]',
        'attendance_json': '[]',
        'semester_gpas_json': '[]',
        'grades_json': '[]',
        'academic_term': '',
        'advisor_info': '',
        'registration_date': '',
        'overall_gpa': '',
        'dashboard_warning': '',
        'digital_id_info': '',
        'yok_apps_info': '',
        'osym_info': '',
        'logged_in': 0,
      };

  Future<void> _ensureSingletonRow(Database db) async {
    final rows = await db.query(
      _table,
      where: 'id = ?',
      whereArgs: [_singletonId],
      limit: 1,
    );
    if (rows.isEmpty) await db.insert(_table, _insertRowDefaults());
  }

  UserProfile _rowToProfile(Map<String, Object?> m) {
    return UserProfile(
      firstName: (m['first_name'] as String?) ?? '',
      lastName: (m['last_name'] as String?) ?? '',
      tc: m['tc'] as String,
      password: m['password'] as String,
      profilePhotoPath: m['profile_photo_path'] as String?,
      schoolLogoPath: m['school_logo_path'] as String?,
      academicYear: (m['academic_year'] as String?)?.trim() ?? '',
      eduFaculty: (m['edu_faculty'] as String?)?.trim() ?? '',
      eduDepartment: (m['edu_department'] as String?)?.trim() ?? '',
      eduGrade: (m['edu_grade'] as String?)?.trim() ?? '',
      universityName: (m['university_name'] as String?)?.trim() ?? '',
      coursesJson: _columnJson(m, 'courses_json'),
      attendanceJson: _columnJson(m, 'attendance_json'),
      semesterGpasJson: _columnJson(m, 'semester_gpas_json'),
      gradesJson: _columnJson(m, 'grades_json'),
      academicTerm: (m['academic_term'] as String?)?.trim() ?? '',
      advisorInfo: (m['advisor_info'] as String?)?.trim() ?? '',
      registrationDate: (m['registration_date'] as String?)?.trim() ?? '',
      overallGpa: (m['overall_gpa'] as String?)?.trim() ?? '',
      dashboardWarning: (m['dashboard_warning'] as String?)?.trim() ?? '',
      digitalIdInfo: (m['digital_id_info'] as String?)?.trim() ?? '',
      yokAppsInfo: (m['yok_apps_info'] as String?)?.trim() ?? '',
      osymInfo: (m['osym_info'] as String?)?.trim() ?? '',
    );
  }

  static String _columnJson(Map<String, Object?> m, String column) {
    final v = m[column];
    if (v is! String) return '[]';
    final t = v.trim();
    return t.isEmpty ? '[]' : t;
  }

  Future<UserProfile> getStored() async {
    final db = await _database;
    await _ensureSingletonRow(db);
    final rows = await db.query(
      _table,
      where: 'id = ?',
      whereArgs: [_singletonId],
      limit: 1,
    );
    return _rowToProfile(rows.first);
  }

  /// Oturum: çıkış yapılana kadar doğrudan ana ekran.
  Future<bool> isLoggedIn() async {
    try {
      final db = await _database;
      final rows = await db.query(
        _table,
        columns: ['logged_in'],
        where: 'id = ?',
        whereArgs: [_singletonId],
        limit: 1,
      );
      if (rows.isEmpty) return false;
      return rows.first['logged_in'] == 1;
    } on Object catch (_) {
      return false;
    }
  }

  Future<void> setLoggedIn(bool value) async {
    final db = await _database;
    await _ensureSingletonRow(db);
    await db.update(
      _table,
      {'logged_in': value ? 1 : 0},
      where: 'id = ?',
      whereArgs: [_singletonId],
    );
  }

  UserProfile get defaultProfile => const UserProfile(
        firstName: '',
        lastName: '',
        tc: defaultTc,
        password: defaultPassword,
        profilePhotoPath: null,
        schoolLogoPath: null,
        academicYear: '',
        eduFaculty: '',
        eduDepartment: '',
        eduGrade: '',
        universityName: '',
        coursesJson: '[]',
        attendanceJson: '[]',
        semesterGpasJson: '[]',
        gradesJson: '[]',
        academicTerm: '',
        advisorInfo: '',
        registrationDate: '',
        overallGpa: '',
        dashboardWarning: '',
        digitalIdInfo: '',
        yokAppsInfo: '',
        osymInfo: '',
      );

  /// [logged_in] sütununa dokunmaz — oturum korunur.
  Future<void> saveProfile(UserProfile profile) async {
    final db = await _database;
    await _ensureSingletonRow(db);
    await db.update(
      _table,
      {
        'tc': profile.tc.trim(),
        'password': profile.password,
        'first_name': profile.firstName.trim(),
        'last_name': profile.lastName.trim(),
        'profile_photo_path': profile.profilePhotoPath,
        'school_logo_path': profile.schoolLogoPath,
        'academic_year': profile.academicYear.trim(),
        'edu_faculty': profile.eduFaculty.trim(),
        'edu_department': profile.eduDepartment.trim(),
        'edu_grade': profile.eduGrade.trim(),
        'university_name': profile.universityName.trim(),
        'courses_json': profile.coursesJson.trim().isEmpty
            ? '[]'
            : profile.coursesJson.trim(),
        'attendance_json': profile.attendanceJson.trim().isEmpty
            ? '[]'
            : profile.attendanceJson.trim(),
        'semester_gpas_json': profile.semesterGpasJson.trim().isEmpty
            ? '[]'
            : profile.semesterGpasJson.trim(),
        'grades_json': profile.gradesJson.trim().isEmpty
            ? '[]'
            : profile.gradesJson.trim(),
        'academic_term': profile.academicTerm.trim(),
        'advisor_info': profile.advisorInfo.trim(),
        'registration_date': profile.registrationDate.trim(),
        'overall_gpa': profile.overallGpa.trim(),
        'dashboard_warning': profile.dashboardWarning.trim(),
        'digital_id_info': profile.digitalIdInfo.trim(),
        'yok_apps_info': profile.yokAppsInfo.trim(),
        'osym_info': profile.osymInfo.trim(),
      },
      where: 'id = ?',
      whereArgs: [_singletonId],
    );
  }

  /// Yalnızca çekmece üniversite logosu yolunu günceller; diğer alanlar korunur.
  Future<void> setSchoolLogoPath(String? logoPath) async {
    final e = await getStored();
    await saveProfile(UserProfile(
      firstName: e.firstName,
      lastName: e.lastName,
      tc: e.tc,
      password: e.password,
      profilePhotoPath: e.profilePhotoPath,
      schoolLogoPath: logoPath,
      academicYear: e.academicYear,
      eduFaculty: e.eduFaculty,
      eduDepartment: e.eduDepartment,
      eduGrade: e.eduGrade,
      universityName: e.universityName,
      coursesJson: e.coursesJson,
      attendanceJson: e.attendanceJson,
      semesterGpasJson: e.semesterGpasJson,
      gradesJson: e.gradesJson,
      academicTerm: e.academicTerm,
      advisorInfo: e.advisorInfo,
      registrationDate: e.registrationDate,
      overallGpa: e.overallGpa,
      dashboardWarning: e.dashboardWarning,
      digitalIdInfo: e.digitalIdInfo,
      yokAppsInfo: e.yokAppsInfo,
      osymInfo: e.osymInfo,
    ));
  }

  Future<bool> verifyLogin(String tcInput, String passwordInput) async {
    final tc = tcInput.trim();
    try {
      final s = await getStored();
      return s.tc == tc && s.password == passwordInput;
    } on Object catch (_) {
      return tc == defaultTc && passwordInput == defaultPassword;
    }
  }

  /// Testler için: bağlantıyı ve `obs_credentials` klasörünü temizler.
  Future<void> resetForTests() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
    final dir = Directory(p.join(Directory.systemTemp.path, 'obs_credentials'));
    if (!dir.existsSync()) return;
    final dbFile = File(p.join(dir.path, _dbFile));
    try {
      if (dbFile.existsSync()) await dbFile.delete();
      final logos = Directory(p.join(dir.path, 'logos'));
      if (logos.existsSync()) await logos.delete(recursive: true);
      final avatars = Directory(p.join(dir.path, 'avatars'));
      if (avatars.existsSync()) await avatars.delete(recursive: true);
    } on Object catch (_) {
      try {
        await dir.delete(recursive: true);
      } on Object catch (_) {}
    }
  }
}
