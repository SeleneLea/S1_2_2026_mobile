import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Tema de la app: la misma paleta, tipografía y formas que el frontend web (guia-estilo).
/// Papel crema, tinta carbón, acentos salvia y durazno, y un solo color vivo (frambuesa) para la
/// acción principal. Los tokens cambian con el tema oscuro; los colores de marca, no.

/// Colores de marca: no cambian entre el tema claro y el oscuro.
class Marca {
  static const carbon = Color(0xFF2A363B);
  static const durazno = Color(0xFFFECEA8);
  static const salvia = Color(0xFF99B898);
  static const frambuesa = Color(0xFFE84A5F);
  static const salmon = Color(0xFFFF847C);
  static const frambuesaActiva = Color(0xFFCB3449);
  static const papel = Color(0xFFF8F7F2);
}

/// Tokens semánticos (los mismos nombres que las variables CSS de la web).
@immutable
class ColoresApp extends ThemeExtension<ColoresApp> {
  const ColoresApp({
    required this.fondo,
    required this.fondo2,
    required this.fondo3,
    required this.superficie,
    required this.superficieAlta,
    required this.borde,
    required this.bordeSuave,
    required this.texto,
    required this.texto2,
    required this.error,
    required this.salviaSuave,
    required this.duraznoSuave,
    required this.salmonSuave,
    required this.salviaTinta,
    required this.duraznoTinta,
    required this.solido,
    required this.sobreSolido,
    required this.puntoLienzo,
    required this.sombra,
    required this.sombraAlta,
  });

  final Color fondo;
  final Color fondo2;
  final Color fondo3;
  final Color superficie;
  final Color superficieAlta;
  final Color borde;
  final Color bordeSuave;
  final Color texto;
  final Color texto2;
  final Color error;
  final Color salviaSuave;
  final Color duraznoSuave;
  final Color salmonSuave;
  final Color salviaTinta;
  final Color duraznoTinta;
  final Color solido;
  final Color sobreSolido;
  final Color puntoLienzo;
  final Color sombra;
  final Color sombraAlta;

  static const claro = ColoresApp(
    fondo: Color(0xFFF8F7F2),
    fondo2: Color(0xFFF0F1E9),
    fondo3: Color(0xFFE6E9DF),
    superficie: Color(0xFFFFFEFB),
    superficieAlta: Color(0xFFFFFFFF),
    borde: Color(0xFFDFE2D7),
    bordeSuave: Color(0xFFEAEBE3),
    texto: Color(0xFF2A363B),
    texto2: Color(0xFF69716D),
    error: Color(0xFFC33248),
    salviaSuave: Color(0xFFE5EDDF),
    duraznoSuave: Color(0xFFFBE9D8),
    salmonSuave: Color(0xFFFCE6E1),
    salviaTinta: Color(0xFF46604A),
    duraznoTinta: Color(0xFF835533),
    solido: Color(0xFF2A363B),
    sobreSolido: Color(0xFFFFFEFB),
    puntoLienzo: Color(0xFFD2D9CD),
    sombra: Color(0x0F2A363B),
    sombraAlta: Color(0x1F2A363B),
  );

  static const oscuro = ColoresApp(
    fondo: Color(0xFF2A363B),
    fondo2: Color(0xFF303F42),
    fondo3: Color(0xFF3E5050),
    superficie: Color(0xFF324247),
    superficieAlta: Color(0xFF3A4B50),
    borde: Color(0xFF4B5C5D),
    bordeSuave: Color(0xFF3E5154),
    texto: Color(0xFFF1F1E9),
    texto2: Color(0xFFB7C2B8),
    error: Color(0xFFFF9D99),
    salviaSuave: Color(0xFF3B5149),
    duraznoSuave: Color(0xFF574A41),
    salmonSuave: Color(0xFF574347),
    salviaTinta: Color(0xFFB5D0AE),
    duraznoTinta: Color(0xFFFECEA8),
    solido: Color(0xFF465F55),
    sobreSolido: Color(0xFFFFFEFB),
    puntoLienzo: Color(0xFF495C5E),
    sombra: Color(0x1F000000),
    sombraAlta: Color(0x3D000000),
  );

  @override
  ColoresApp copyWith() => this;

  @override
  ColoresApp lerp(ThemeExtension<ColoresApp>? other, double t) {
    if (other is! ColoresApp) return this;
    Color m(Color a, Color b) => Color.lerp(a, b, t)!;
    return ColoresApp(
      fondo: m(fondo, other.fondo),
      fondo2: m(fondo2, other.fondo2),
      fondo3: m(fondo3, other.fondo3),
      superficie: m(superficie, other.superficie),
      superficieAlta: m(superficieAlta, other.superficieAlta),
      borde: m(borde, other.borde),
      bordeSuave: m(bordeSuave, other.bordeSuave),
      texto: m(texto, other.texto),
      texto2: m(texto2, other.texto2),
      error: m(error, other.error),
      salviaSuave: m(salviaSuave, other.salviaSuave),
      duraznoSuave: m(duraznoSuave, other.duraznoSuave),
      salmonSuave: m(salmonSuave, other.salmonSuave),
      salviaTinta: m(salviaTinta, other.salviaTinta),
      duraznoTinta: m(duraznoTinta, other.duraznoTinta),
      solido: m(solido, other.solido),
      sobreSolido: m(sobreSolido, other.sobreSolido),
      puntoLienzo: m(puntoLienzo, other.puntoLienzo),
      sombra: m(sombra, other.sombra),
      sombraAlta: m(sombraAlta, other.sombraAlta),
    );
  }
}

extension ColoresDelTema on BuildContext {
  /// Tokens del tema actual; sin el tema de la app (p. ej. en una prueba) se usan los de su brillo.
  ColoresApp get colores {
    final tema = Theme.of(this);
    return tema.extension<ColoresApp>() ?? (tema.brightness == Brightness.dark ? ColoresApp.oscuro : ColoresApp.claro);
  }
}

/// Familias: la del sistema para la interfaz, serif itálica para la palabra destacada de un
/// titular y monoespaciada para atributos y métodos.
const fuenteSerif = 'serif';
const respaldoSerif = ['Georgia', 'Times New Roman'];
const fuenteMono = 'monospace';
const respaldoMono = ['Menlo', 'Consolas', 'Courier New'];

/// Antetítulo ("eyebrow"): MAYÚSCULAS diminutas con interletrado, sobre cada titular.
TextStyle estiloEyebrow(Color color, {double tam = 10}) =>
    TextStyle(fontSize: tam, letterSpacing: tam * 0.17, fontWeight: FontWeight.w600, color: color, height: 1.4);

ThemeData temaClaro() => _tema(ColoresApp.claro, Brightness.light);
ThemeData temaOscuro() => _tema(ColoresApp.oscuro, Brightness.dark);

ThemeData _tema(ColoresApp c, Brightness brillo) {
  final esquema = ColorScheme(
    brightness: brillo,
    primary: Marca.frambuesa,
    onPrimary: Colors.white,
    primaryContainer: c.salmonSuave,
    onPrimaryContainer: c.error,
    secondary: c.salviaTinta,
    onSecondary: c.superficie,
    secondaryContainer: c.salviaSuave,
    onSecondaryContainer: c.salviaTinta,
    tertiary: c.duraznoTinta,
    onTertiary: c.superficie,
    tertiaryContainer: c.duraznoSuave,
    onTertiaryContainer: c.duraznoTinta,
    error: c.error,
    onError: Colors.white,
    errorContainer: c.salmonSuave,
    onErrorContainer: c.error,
    surface: c.superficie,
    onSurface: c.texto,
    onSurfaceVariant: c.texto2,
    surfaceContainerLowest: c.superficieAlta,
    surfaceContainerLow: c.superficie,
    surfaceContainer: c.fondo2,
    surfaceContainerHigh: c.fondo2,
    surfaceContainerHighest: c.fondo3,
    outline: c.borde,
    outlineVariant: c.bordeSuave,
    shadow: c.sombraAlta,
    scrim: brillo == Brightness.dark ? const Color(0xB80F191D) : const Color(0x6B2A363B),
    inverseSurface: Marca.carbon,
    onInverseSurface: Marca.papel,
    inversePrimary: Marca.salmon,
    surfaceTint: Colors.transparent,
  );

  final base = brillo == Brightness.dark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);
  final texto = base.textTheme.apply(bodyColor: c.texto, displayColor: c.texto).copyWith(
        headlineMedium: TextStyle(fontSize: 34, height: 1.12, fontWeight: FontWeight.w600, letterSpacing: -1.2, color: c.texto),
        headlineSmall: TextStyle(fontSize: 29, height: 1.15, fontWeight: FontWeight.w600, letterSpacing: -1.1, color: c.texto),
        titleLarge: TextStyle(fontSize: 22, height: 1.25, fontWeight: FontWeight.w600, letterSpacing: -0.5, color: c.texto),
        titleMedium: TextStyle(fontSize: 16, height: 1.35, fontWeight: FontWeight.w600, letterSpacing: -0.3, color: c.texto),
        titleSmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.texto),
        bodyLarge: TextStyle(fontSize: 14, height: 1.6, color: c.texto),
        bodyMedium: TextStyle(fontSize: 13, height: 1.6, color: c.texto),
        bodySmall: TextStyle(fontSize: 11, height: 1.6, color: c.texto2),
        labelLarge: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.4),
        labelMedium: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.texto2),
        labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: c.texto2),
      );
  final redondeo9 = RoundedRectangleBorder(borderRadius: BorderRadius.circular(9));

  OutlineInputBorder bordeCampo(Color color, [double ancho = 1]) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: color, width: ancho));

  return base.copyWith(
    colorScheme: esquema,
    scaffoldBackgroundColor: c.fondo,
    canvasColor: c.fondo,
    dividerColor: c.borde,
    textTheme: texto,
    extensions: [c],
    splashColor: c.salviaSuave.withValues(alpha: 0.6),
    highlightColor: c.salviaSuave.withValues(alpha: 0.4),
    appBarTheme: AppBarTheme(
      backgroundColor: c.fondo,
      foregroundColor: c.texto,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleSpacing: 20,
      titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.45, color: c.texto),
      iconTheme: IconThemeData(color: c.texto2, size: 22),
      actionsIconTheme: IconThemeData(color: c.texto2, size: 22),
      shape: Border(bottom: BorderSide(color: c.borde)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.disabled)) return Marca.frambuesa.withValues(alpha: 0.45);
          if (s.contains(WidgetState.pressed)) return Marca.salmon;
          return Marca.frambuesa;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.disabled)) return Colors.white.withValues(alpha: 0.85);
          if (s.contains(WidgetState.pressed)) return Marca.carbon;
          return Colors.white;
        }),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        minimumSize: const WidgetStatePropertyAll(Size(64, 46)),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 17, vertical: 10)),
        shape: WidgetStatePropertyAll(redondeo9),
        textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        elevation: const WidgetStatePropertyAll(0),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.pressed) ? c.duraznoSuave : c.superficie),
        foregroundColor: WidgetStatePropertyAll(c.texto),
        side: WidgetStateProperty.resolveWith((s) => BorderSide(color: s.contains(WidgetState.pressed) ? Marca.salmon : c.borde)),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        minimumSize: const WidgetStatePropertyAll(Size(64, 42)),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 15, vertical: 9)),
        shape: WidgetStatePropertyAll(redondeo9),
        textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.salviaTinta,
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: c.texto2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.superficie,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
      border: bordeCampo(c.borde),
      enabledBorder: bordeCampo(c.borde),
      disabledBorder: bordeCampo(c.bordeSuave),
      focusedBorder: bordeCampo(c.salviaTinta, 1.5),
      errorBorder: bordeCampo(c.error),
      focusedErrorBorder: bordeCampo(c.error, 1.5),
      hintStyle: TextStyle(fontSize: 13, color: c.texto2.withValues(alpha: 0.8)),
      labelStyle: TextStyle(fontSize: 13, color: c.texto2),
      floatingLabelStyle: TextStyle(fontSize: 13, color: c.salviaTinta, fontWeight: FontWeight.w600),
      helperStyle: TextStyle(fontSize: 11, color: c.texto2),
      prefixIconColor: c.texto2,
      suffixIconColor: c.texto2,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.salviaTinta,
      selectionColor: Marca.durazno.withValues(alpha: 0.7),
      selectionHandleColor: c.salviaTinta,
    ),
    cardTheme: CardThemeData(
      color: c.superficie,
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: c.borde)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: c.superficie,
      side: BorderSide(color: c.borde),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      labelStyle: TextStyle(fontSize: 11, color: c.texto2, fontFeatures: const [FontFeature.tabularFigures()]),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: c.superficie,
        foregroundColor: c.texto2,
        selectedBackgroundColor: c.salviaSuave,
        selectedForegroundColor: c.salviaTinta,
        side: BorderSide(color: c.borde),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: c.texto,
      unselectedLabelColor: c.texto2,
      dividerColor: Colors.transparent,
      indicatorSize: TabBarIndicatorSize.tab,
      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
      labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      indicator: BoxDecoration(
        color: c.superficie,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [BoxShadow(color: c.sombraAlta, blurRadius: 4, offset: const Offset(0, 1))],
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: c.superficie,
      foregroundColor: c.texto,
      elevation: 1,
      highlightElevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: c.borde)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.superficie,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: c.superficie,
      dragHandleColor: c.borde,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.superficie,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: c.borde)),
      titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.5, color: c.texto),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: brillo == Brightness.dark ? c.superficieAlta : Marca.carbon,
      contentTextStyle: TextStyle(fontSize: 13, color: brillo == Brightness.dark ? c.texto : Marca.papel),
      actionTextColor: Marca.durazno,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
    ),
    bannerTheme: MaterialBannerThemeData(
      backgroundColor: c.salviaSuave,
      contentTextStyle: TextStyle(fontSize: 12, height: 1.6, color: c.salviaTinta),
      dividerColor: c.borde,
    ),
    dividerTheme: DividerThemeData(color: c.borde, thickness: 1, space: 1),
    listTileTheme: ListTileThemeData(
      iconColor: c.salviaTinta,
      textColor: c.texto,
      titleTextStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.texto),
      subtitleTextStyle: TextStyle(fontSize: 11, color: c.texto2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: c.salviaTinta, linearTrackColor: c.salviaSuave, circularTrackColor: Colors.transparent),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: Marca.carbon, borderRadius: BorderRadius.circular(6)),
      textStyle: const TextStyle(fontSize: 11, color: Marca.papel),
    ),
  );
}

/// Símbolo de la marca: el ícono "workflow" (dos cajas unidas por un codo) en una baldosa salvia.
class SimboloMarca extends StatelessWidget {
  const SimboloMarca({super.key, this.tam = 36});
  final double tam;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tam,
      height: tam,
      decoration: BoxDecoration(color: Marca.salvia, borderRadius: BorderRadius.circular(tam * 0.3)),
      alignment: Alignment.center,
      child: IconoFlujo(tam: tam * 0.64, color: Marca.carbon),
    );
  }
}

/// Logotipo: símbolo + "diagramador" en minúsculas con el sufijo UML volado.
class LogotipoApp extends StatelessWidget {
  const LogotipoApp({super.key, this.tam = 21});
  final double tam;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      SimboloMarca(tam: tam * 1.7),
      const SizedBox(width: 10),
      Text('diagramador', style: TextStyle(fontSize: tam, fontWeight: FontWeight.w800, letterSpacing: -0.9, color: c.texto)),
      Padding(
        padding: EdgeInsets.only(left: 5, bottom: tam * 0.55),
        child: Text('UML', style: TextStyle(fontSize: 9, letterSpacing: 1, color: c.texto2)),
      ),
    ]);
  }
}

/// Ícono "workflow" de lucide (el de la web), dibujado a trazo para no depender de otra fuente.
class IconoFlujo extends StatelessWidget {
  const IconoFlujo({super.key, this.tam = 24, this.color, this.grosor = 1.8});
  final double tam;
  final Color? color;
  final double grosor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(tam), painter: _PintorFlujo(color ?? IconTheme.of(context).color ?? context.colores.texto, grosor));
  }
}

class _PintorFlujo extends CustomPainter {
  _PintorFlujo(this.color, this.grosor);
  final Color color;
  final double grosor;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    final trazo = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosor * k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(3 * k, 3 * k, 8 * k, 8 * k), Radius.circular(2 * k)), trazo);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(13 * k, 13 * k, 8 * k, 8 * k), Radius.circular(2 * k)), trazo);
    final codo = Path()
      ..moveTo(7 * k, 11 * k)
      ..lineTo(7 * k, 15 * k)
      ..arcToPoint(Offset(9 * k, 17 * k), radius: Radius.circular(2 * k), clockwise: false)
      ..lineTo(13 * k, 17 * k);
    canvas.drawPath(codo, trazo);
  }

  @override
  bool shouldRepaint(covariant _PintorFlujo old) => old.color != color || old.grosor != grosor;
}

/// Baldosa de ícono levemente girada (estados vacíos, como en la web).
class BaldosaIcono extends StatelessWidget {
  const BaldosaIcono({super.key, required this.icono, this.fondo, this.color, this.tam = 52, this.giro = -8});
  final Widget icono;
  final Color? fondo;
  final Color? color;
  final double tam;
  final double giro;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Transform.rotate(
      angle: giro * math.pi / 180,
      child: Container(
        width: tam,
        height: tam,
        decoration: BoxDecoration(color: fondo ?? c.salviaSuave, borderRadius: BorderRadius.circular(tam * 0.3)),
        alignment: Alignment.center,
        child: IconTheme(data: IconThemeData(color: color ?? c.salviaTinta, size: tam * 0.46), child: icono),
      ),
    );
  }
}

/// Punto de estado (7 px, salvia), el que acompaña a los antetítulos.
class PuntoEstado extends StatelessWidget {
  const PuntoEstado({super.key, this.color, this.tam = 7});
  final Color? color;
  final double tam;

  @override
  Widget build(BuildContext context) {
    return Container(width: tam, height: tam, decoration: BoxDecoration(color: color ?? context.colores.salviaTinta, shape: BoxShape.circle));
  }
}

/// Antetítulo con su punto: "· MI ESPACIO DE TRABAJO".
class Antetitulo extends StatelessWidget {
  const Antetitulo(this.texto, {super.key, this.color, this.conPunto = true, this.tam = 10});
  final String texto;
  final Color? color;
  final bool conPunto;
  final double tam;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      if (conPunto) ...[PuntoEstado(color: color ?? c.salviaTinta), const SizedBox(width: 9)],
      Flexible(child: Text(texto.toUpperCase(), style: estiloEyebrow(color ?? c.texto2, tam: tam))),
    ]);
  }
}
