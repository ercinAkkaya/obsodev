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
  static const int _dbVersion = 6;

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
    );
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
      },
      where: 'id = ?',
      whereArgs: [_singletonId],
    );
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
