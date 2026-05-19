import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/user_credentials_repository.dart';

/// Referans tasarım: ~390 × 844 pt. Tüm telefonlarda aynı görsel oran.
class _UiScale {
  _UiScale._(this._k);
  final double _k;

  /// Geometrik ortalama: çok uzun/dar ekranlarda daha dengeli oran.
  factory _UiScale.of(BuildContext context) {
    final sz = MediaQuery.sizeOf(context);
    final sx = sz.width / _refW;
    final sy = sz.height / _refH;
    if (sx <= 0 || sy <= 0) return _UiScale._(1);
    return _UiScale._(math.sqrt(sx * sy));
  }

  static const double _refW = 390;
  static const double _refH = 844;

  double d(double designDp) => designDp * _k;
}

/// YÖKSİS tarzı giriş ekranı; TC ve şifre yerel SQLite ile doğrulanır.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.onSignedIn});

  /// [ObsApp] oturum kapısı; verilirse girişte [Navigator] ile `/home` kullanılmaz.
  final VoidCallback? onSignedIn;

  @override
  State<LoginPage> createState() => _LoginPageState();

  static const Color _red = Color(0xFFD32F2F);
  static const Color _linkBlue = Color(0xFF1565C0);
  static const Color _iconBoxBg = Color(0xFFE3F2FD);
  static const Color _fieldBorder = Color(0xFFB0BEC5);
}

class _LoginPageState extends State<LoginPage> {
  final _tc = TextEditingController();
  final _pwd = TextEditingController();
  bool _busy = false;

  static final _digits11 = RegExp(r'^\d{11}$');

  @override
  void dispose() {
    _tc.dispose();
    _pwd.dispose();
    super.dispose();
  }

  Future<void> _attemptLogin() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    final tc = _tc.text.trim();
    final pwd = _pwd.text;

    if (!_digits11.hasMatch(tc)) {
      _snack('T.C. kimlik numarası 11 haneli rakam olmalıdır.');
      return;
    }
    if (pwd.isEmpty) {
      _snack('Şifre giriniz.');
      return;
    }

    setState(() => _busy = true);
    final ok = await UserCredentialsRepository.instance.verifyLogin(tc, pwd);
    if (!mounted) return;
    setState(() => _busy = false);

    if (!ok) {
      _snack('T.C. veya şifre hatalı.');
      return;
    }

    try {
      await UserCredentialsRepository.instance.setLoggedIn(true);
    } on Object catch (_) {}

    if (!mounted) return;

    widget.onSignedIn?.call();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final r = _UiScale.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: r.d(36),
                right: r.d(28),
              ),
              child: _YokHeaderBanner(scale: r),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: r.d(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: r.d(40)),
                    _LabeledField(
                      controller: _tc,
                      hint: 'Kimlik Numaranızı Giriniz',
                      obscureText: false,
                      prefix: Icons.person,
                      scale: r,
                      keyboardType: TextInputType.number,
                      maxLength: 11,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                    SizedBox(height: r.d(14)),
                    _LabeledField(
                      controller: _pwd,
                      hint: 'Şifrenizi Giriniz',
                      obscureText: true,
                      prefix: Icons.vpn_key,
                      scale: r,
                    ),
                    SizedBox(height: r.d(18)),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          foregroundColor: LoginPage._linkBlue,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Şifremi unuttum',
                          style: TextStyle(fontSize: r.d(14)),
                        ),
                      ),
                    ),
                    SizedBox(height: r.d(16)),
                    SizedBox(
                      height: r.d(48),
                      child: FilledButton(
                        onPressed: _busy ? null : _attemptLogin,
                        style: FilledButton.styleFrom(
                          backgroundColor: LoginPage._red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(r.d(6)),
                          ),
                        ),
                        child: _busy
                            ? SizedBox(
                                height: r.d(22),
                                width: r.d(22),
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'YÖK OBS ile giriş',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: r.d(15),
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: r.d(22)),
                    SizedBox(
                      height: r.d(58),
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: LoginPage._red,
                          side: BorderSide(color: const Color(0xFF424242), width: r.d(1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(r.d(6)),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: r.d(14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/e_devlet.png',
                              height: r.d(30),
                              errorBuilder: (_, __, ___) =>
                                  Icon(Icons.account_balance, size: r.d(30)),
                            ),
                            SizedBox(width: r.d(12)),
                            Text(
                              'e-DEVLET ile Giriş',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: r.d(17),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: r.d(20)),
                    _PartnerLogoGrid(scale: r),
                    SizedBox(height: r.d(24)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// e-Devlet altında 2×2: bilgi + mavi yazı | study ; atlas | akademik
class _PartnerLogoGrid extends StatelessWidget {
  const _PartnerLogoGrid({required this.scale});

  final _UiScale scale;

  static const Color _captionBlue = LoginPage._linkBlue;

  @override
  Widget build(BuildContext context) {
    final r = scale;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cw = constraints.maxWidth.clamp(1.0, double.infinity);

        /// Referansa yakın büyüklük; taşmayı önlemek için üst sınır + oran.
        /// Atlas / akademik — satır ~cw/2 hücreye sığacak şekilde mümkün olduğunca büyük.
        final maxIconByRow = math.min(cw * 0.476, r.d(196));
        final minIcon = math.min(r.d(98), maxIconByRow * 0.86);
        final iconSide =
            (cw * 0.472).clamp(minIcon, maxIconByRow).toDouble();
        final gapXs = cw * 0.01;
        final bilgiDesired = (cw * 0.29).clamp(r.d(84), r.d(128));
        final bilgiCap =
            (cw * 62 / 100 - gapXs - r.d(28)).clamp(r.d(68), r.d(140));
        final bilgiSide = math.min(bilgiDesired, bilgiCap);
        final captionFs =
            (cw * 0.046).clamp(r.d(14), r.d(20));
        final textMaxWidth =
            ((cw * 62 / 100) - bilgiSide - gapXs).clamp(40.0, cw * 0.62);

        TextStyle captionStyle() => TextStyle(
              color: _captionBlue,
              fontSize: captionFs,
              fontWeight: FontWeight.w700,
              height: 1.04,
            );

        Widget bilgiBoundedIcon() => SizedBox(
              width: bilgiSide,
              height: bilgiSide,
              child: Image.asset(
                'assets/yokbilgi.png',
                fit: BoxFit.contain,
                alignment: Alignment.center,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.info_outline,
                  size: bilgiSide * 0.72,
                  color: _captionBlue,
                ),
              ),
            );

        Widget boundedIcon(String asset, {double factor = 1.0}) {
          final side = math.min(iconSide * factor, cw * 0.47);
          return SizedBox(
            width: side,
            height: side,
            child: Image.asset(
              asset,
              fit: BoxFit.contain,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) => Icon(
                Icons.image_not_supported,
                size: side * 0.5,
                color: _captionBlue,
              ),
            ),
          );
        }

        /// Study geniş logo — hücre genişliğini aşmasın (üst sağ ~%45 sütun).
        final studyW = (cw * 0.348).clamp(r.d(106), r.d(172));
        final studyH =
            (bilgiSide * 1.06).clamp(r.d(72), r.d(108));
        Widget studyTile() => SizedBox(
              width: studyW,
              height: studyH,
              child: Image.asset(
                'assets/study.png',
                fit: BoxFit.contain,
                alignment: Alignment.center,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.school_outlined,
                  size: studyH * 0.55,
                  color: _captionBlue,
                ),
              ),
            );

        final lineGap = r.d(3);

        Widget captionColumn() => SizedBox(
              width: textMaxWidth,
              height: bilgiSide,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'yükseköğretim',
                      textAlign: TextAlign.left,
                      style: captionStyle(),
                    ),
                    SizedBox(height: lineGap),
                    Text(
                      'bilgi yönetim',
                      textAlign: TextAlign.left,
                      style: captionStyle(),
                    ),
                    SizedBox(height: lineGap),
                    Text(
                      'sistemi',
                      textAlign: TextAlign.left,
                      style: captionStyle(),
                    ),
                  ],
                ),
              ),
            );

        final captionTexts = SizedBox(
          height: bilgiSide,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topLeft,
            child: captionColumn(),
          ),
        );

        return Column(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 62,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        bilgiBoundedIcon(),
                        SizedBox(width: gapXs),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: captionTexts,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 38,
                    child: Center(
                      child: studyTile(),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: cw * 0.022),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: boundedIcon('assets/atlas.png'),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: boundedIcon(
                      'assets/akademik.png',
                      factor: 1.24,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Açık mavi zemin + sağda üçgen/low-poly benzeri desen (görsel yoksa yaklaşık).
class _YokHeaderBanner extends StatelessWidget {
  const _YokHeaderBanner({required this.scale});

  final _UiScale scale;

  static const Color _bgLeft = Color(0xFFE8F4FC);
  static const Color _text = Color(0xFF212121);

  @override
  Widget build(BuildContext context) {
    final r = scale;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final patternW = w * 0.56;
        return ClipRRect(
          borderRadius: BorderRadius.circular(r.d(4)),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        _bgLeft,
                        Color(0xFFD6EDF8),
                        Color(0xFFC8E6F5),
                      ],
                      stops: [0.0, 0.42, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: patternW,
                child: CustomPaint(
                  painter: _LowPolySkyPainter(width: patternW, seed: 7),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: const Alignment(0.55, 0.0),
                      colors: [
                        _bgLeft,
                        _bgLeft.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  r.d(18),
                  r.d(14),
                  r.d(18),
                  r.d(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/yoklogo.jpg',
                      height: r.d(74),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/yok.png',
                        height: r.d(74),
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(width: r.d(16)),
                    _FadeVerticalLine(
                      height: r.d(60),
                      width: r.d(2),
                      color: LoginPage._red,
                    ),
                    SizedBox(width: r.d(16)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'YÜKSEKÖĞRETİM',
                            style: TextStyle(
                              fontSize: r.d(18),
                              fontWeight: FontWeight.w400,
                              letterSpacing: r.d(0.45),
                              color: _text,
                              height: 1.2,
                            ),
                          ),
                          Text(
                            'BİLGİ SİSTEMİ',
                            style: TextStyle(
                              fontSize: r.d(18),
                              fontWeight: FontWeight.w400,
                              letterSpacing: r.d(0.45),
                              color: _text,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LowPolySkyPainter extends CustomPainter {
  _LowPolySkyPainter({required this.width, required this.seed});

  final double width;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = _DeterministicRandom(seed);
    const blues = [
      Color(0xFFFFFFFF),
      Color(0xFFE3F2FD),
      Color(0xFFBBDEFB),
      Color(0xFF90CAF9),
      Color(0xFFB3E5FC),
      Color(0xFF81D4FA),
    ];

    void tri(Offset a, Offset b, Offset c, Color color) {
      final p = Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..lineTo(c.dx, c.dy)
        ..close();
      canvas.drawPath(
        p,
        Paint()
          ..color = color.withValues(alpha: 0.35 + rnd.nextDouble() * 0.45)
          ..style = PaintingStyle.fill,
      );
    }

    final h = size.height;
    final w = size.width;

    for (var i = 0; i < 42; i++) {
      final x0 = rnd.nextDouble() * w;
      final y0 = rnd.nextDouble() * h;
      final x1 = x0 + (rnd.nextDouble() - 0.3) * w * 0.22;
      final y1 = y0 + (rnd.nextDouble() - 0.2) * h * 0.35;
      final x2 = x0 + (rnd.nextDouble() - 0.7) * w * 0.25;
      final y2 = y0 + (rnd.nextDouble() - 0.5) * h * 0.4;
      tri(
        Offset(x0, y0),
        Offset(x1, y1),
        Offset(x2, y2),
        blues[(i + seed) % blues.length],
      );
    }

    const grid = 5;
    final cw = w / grid;
    final ch = h / grid;
    for (var gx = 0; gx < grid; gx++) {
      for (var gy = 0; gy < grid; gy++) {
        final ox = gx * cw;
        final oy = gy * ch;
        final skew = (gx + gy + seed) * 0.08;
        tri(
          Offset(ox, oy + ch * 0.35 + skew),
          Offset(ox + cw * 0.6, oy + skew),
          Offset(ox + cw, oy + ch * 0.75),
          blues[(gx + gy) % blues.length],
        );
        tri(
          Offset(ox + cw * 0.15, oy + ch),
          Offset(ox + cw * 0.85, oy + ch * 0.25),
          Offset(ox + cw * 0.45, oy + ch * 0.95),
          blues[(gx * 3 + gy) % blues.length],
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LowPolySkyPainter oldDelegate) {
    return oldDelegate.width != width || oldDelegate.seed != seed;
  }
}

/// Deterministik "rastgele" — her çizimde aynı desen.
class _DeterministicRandom {
  _DeterministicRandom(this._s);
  int _s;

  double nextDouble() {
    _s = (_s * 1103515245 + 12345) & 0x7fffffff;
    return _s / 0x7fffffff;
  }
}

/// Yukarı–aşağı: ortada koyu, uçlara doğru kaybolan dikey çizgi.
class _FadeVerticalLine extends StatelessWidget {
  const _FadeVerticalLine({
    required this.height,
    required this.width,
    required this.color,
  });

  final double height;
  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0),
              color.withValues(alpha: 0.65),
              color.withValues(alpha: 0),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}

class _LabeledField extends StatefulWidget {
  const _LabeledField({
    this.controller,
    required this.hint,
    required this.obscureText,
    required this.prefix,
    required this.scale,
    this.keyboardType,
    this.maxLength,
    this.inputFormatters,
  });

  final TextEditingController? controller;
  final String hint;
  final bool obscureText;
  final IconData prefix;
  final _UiScale scale;
  final TextInputType? keyboardType;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<_LabeledField> createState() => _LabeledFieldState();
}

class _LabeledFieldState extends State<_LabeledField> {
  late final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const borderColor = LoginPage._fieldBorder;
    const focusColor = Color(0xFF64B5F6);
    final r = widget.scale;
    final br = BorderRadius.circular(r.d(6));
    final focusActive = _focusNode.hasFocus;
    final outerBorderWidth = focusActive ? r.d(1.2) : r.d(1);
    final outerBorderColor = focusActive ? focusColor : borderColor;
    /// Sol şeridin genişliği (ikon + görsel olarak örneğe yakın oran).
    final iconStripeW = r.d(48);
    final fieldBarH = r.d(52);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: br,
        border: Border.all(
          color: outerBorderColor,
          width: outerBorderWidth,
        ),
      ),
      child: ClipRRect(
        borderRadius: br,
        child: SizedBox(
          height: fieldBarH,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: iconStripeW,
                decoration: BoxDecoration(
                  color: LoginPage._iconBoxBg,
                  border: Border(
                    right: BorderSide(color: borderColor, width: r.d(1)),
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  widget.prefix,
                  color: Colors.black,
                  size: r.d(22),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  obscureText: widget.obscureText,
                  keyboardType:
                      widget.keyboardType ?? TextInputType.text,
                  maxLength: widget.maxLength,
                  inputFormatters: widget.inputFormatters,
                  style: TextStyle(fontSize: r.d(15)),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle:
                        TextStyle(color: Colors.grey.shade500, fontSize: r.d(15)),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    isDense: true,
                    filled: false,
                    counterText: '',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: r.d(14),
                      vertical: r.d(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
