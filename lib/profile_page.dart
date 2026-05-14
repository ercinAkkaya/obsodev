import 'dart:io' show Directory, File;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

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
  bool _loading = true;
  bool _saving = false;
  String? _profilePhotoPath;
  String? _schoolLogoPath;

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
      _profilePhotoPath = r.profilePhotoPath;
      _schoolLogoPath = r.schoolLogoPath;
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
      _profilePhotoPath = d.profilePhotoPath;
      _schoolLogoPath = d.schoolLogoPath;
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
