import 'dart:math' as math;
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

import 'tema.dart';

/// Dibujo del diagrama de clases (solo lectura) a partir de los nodos y aristas del tablero, con el
/// aspecto del estudio web: hoja de papel con puntos, clases con cabecera salvia y miembros en letra
/// monoespaciada. Las clases que acaban de cambiar se resaltan en durazno unos segundos.

String _comoTexto(dynamic item, {bool metodo = false}) {
  if (item == null) return '';
  if (item is String) return item.trim();
  if (item is Map) {
    if (metodo && item['name'] != null) return '${item['name']}()${item['returnType'] != null ? ': ${item['returnType']}' : ''}';
    if (item['name'] != null && item['type'] != null) return '${item['name']}: ${item['type']}';
    if (item['name'] != null) return '${item['name']}';
  }
  return item.toString();
}

class CajaClase {
  CajaClase({required this.id, required this.rect, required this.nombre, required this.atributos, required this.metodos, required this.estereotipo, required this.esNota});
  final String id;
  final Rect rect;
  final String nombre;
  final List<String> atributos;
  final List<String> metodos;
  final String? estereotipo;
  final bool esNota;
}

const _estiloNombre = TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: Marca.carbon);
const _estiloMiembro = TextStyle(fontSize: 11, fontFamily: fuenteMono, fontFamilyFallback: respaldoMono, color: Marca.carbon);
const _estiloNota = TextStyle(fontSize: 11, height: 1.35, color: Marca.carbon);
const double _linea = 15;

/// Lugar del "{ }" que va antes del nombre de cada clase, como en el estudio web.
const double _anchoMarca = 24;

double _ancho(String texto, TextStyle estilo) {
  final tp = TextPainter(text: TextSpan(text: texto, style: estilo), textDirection: TextDirection.ltr, maxLines: 1)..layout();
  return tp.width;
}

/// Calcula el rectángulo de cada clase (posición del tablero, tamaño según su contenido).
List<CajaClase> calcularCajas(List<Map<String, dynamic>> nodos) {
  final cajas = <CajaClase>[];
  for (final n in nodos) {
    final datos = (n['data'] as Map?)?.cast<String, dynamic>() ?? {};
    final pos = (n['position'] as Map?) ?? {};
    final x = (pos['x'] as num?)?.toDouble() ?? 0;
    final y = (pos['y'] as num?)?.toDouble() ?? 0;
    if (n['type'] == 'noteNode') {
      final texto = '${datos['text'] ?? ''}';
      final lineas = texto.split('\n');
      final ancho = math.min(260.0, math.max(140.0, lineas.map((l) => _ancho(l, _estiloNota)).fold<double>(0, math.max) + 24));
      final alto = 20 + lineas.fold<int>(0, (s, l) => s + 1 + (_ancho(l, _estiloNota) / (ancho - 24)).floor()) * _linea;
      cajas.add(CajaClase(id: '${n['id']}', rect: Rect.fromLTWH(x, y, ancho, alto), nombre: texto, atributos: const [], metodos: const [], estereotipo: datos['deIA'] == true ? 'ia' : null, esNota: true));
      continue;
    }
    if (n['type'] != 'classNode' || datos['isConnectionPoint'] == true) continue;
    final nombre = '${datos['className'] ?? 'Clase'}';
    final atributos = ((datos['attributes'] as List?) ?? []).map((a) => _comoTexto(a)).where((a) => a.isNotEmpty).toList();
    final metodos = ((datos['methods'] as List?) ?? []).map((m) => _comoTexto(m, metodo: true)).where((m) => m.isNotEmpty).toList();
    final estereotipo = datos['stereotype'] as String?;
    final anchos = [
      _ancho(nombre, _estiloNombre) + _anchoMarca,
      ...atributos.map((a) => _ancho(a, _estiloMiembro)),
      ...metodos.map((m) => _ancho(m, _estiloMiembro)),
    ];
    final ancho = math.max(140.0, anchos.fold<double>(0, math.max) + 20);
    final alto = 30 + (estereotipo != null ? 13 : 0) + math.max(1, atributos.length) * _linea + 8 + (metodos.isEmpty ? 0 : metodos.length * _linea + 8);
    cajas.add(CajaClase(id: '${n['id']}', rect: Rect.fromLTWH(x, y, ancho, alto), nombre: nombre, atributos: atributos, metodos: metodos, estereotipo: estereotipo, esNota: false));
  }
  return cajas;
}

/// Límites de todo el diagrama, para encuadrarlo al abrir.
Rect limitesDe(List<CajaClase> cajas) {
  if (cajas.isEmpty) return const Rect.fromLTWH(0, 0, 400, 400);
  return cajas.map((c) => c.rect).reduce((a, b) => a.expandToInclude(b)).inflate(60);
}

/// Límites del zoom: con diagramas grandes hace falta alejarse mucho para verlo entero y acercarse
/// bastante para leer una clase.
const double escalaMinima = 0.05;
const double escalaMaxima = 6;

/// Por debajo de esta escala el texto de los miembros sería ilegible: se dibuja solo el nombre.
const double escalaCompacta = 0.5;

/// Escala que muestra todo el diagrama en la pantalla (por ancho y por alto, con un pequeño margen).
double escalaParaVer(Rect limites, Size pantalla) {
  if (limites.isEmpty || pantalla.isEmpty) return 1;
  final escala = math.min(pantalla.width / limites.width, pantalla.height / limites.height) * 0.95;
  return escala.clamp(escalaMinima, 1.5).toDouble();
}

/// La clase o nota que está en ese punto (coordenadas del tablero), la de arriba si se superponen.
CajaClase? cajaEn(List<CajaClase> cajas, Offset punto) {
  for (final c in cajas.reversed) {
    if (c.rect.contains(punto)) return c;
  }
  return null;
}

const _nombresRelacion = {
  'association': 'Asociación',
  'composition': 'Composición',
  'aggregation': 'Agregación',
  'generalization': 'Herencia',
  'inheritance': 'Herencia',
  'dependency': 'Dependencia',
  'realization': 'Realización',
  'implementation': 'Realización',
};

/// Relaciones de una clase en palabras, para la hoja de detalle ("Asociación con Producto (1 — *)").
List<String> relacionesDe(String id, List<CajaClase> cajas, List<Map<String, dynamic>> aristas) {
  final nombres = {for (final c in cajas) c.id: c.esNota ? 'nota' : c.nombre};
  final salida = <String>[];
  for (final e in aristas) {
    final datos = (e['data'] as Map?) ?? {};
    if (datos['isAssociationConnection'] == true) continue;
    final origen = '${e['source']}';
    final destino = '${e['target']}';
    if (origen != id && destino != id) continue;
    final otro = nombres[origen == id ? destino : origen];
    if (otro == null) continue;
    final tipo = '${datos['type'] ?? 'Association'}'.toLowerCase();
    final nombre = _nombresRelacion[tipo] ?? tipo;
    final esHerencia = nombre == 'Herencia' || nombre == 'Realización';
    final texto = esHerencia ? (origen == id ? '$nombre de $otro' : '$nombre: $otro la extiende') : '$nombre con $otro';
    final inicio = '${datos['startLabel'] ?? ''}'.trim();
    final fin = '${datos['endLabel'] ?? ''}'.trim();
    final mult = inicio.isEmpty && fin.isEmpty ? '' : ' (${origen == id ? inicio : fin} — ${origen == id ? fin : inicio})';
    final etiqueta = '${datos['label'] ?? ''}'.trim();
    salida.add('$texto$mult${etiqueta.isEmpty ? '' : ' «$etiqueta»'}');
  }
  return salida;
}

/// Colores del lienzo según el tema: los mismos tokens que el estudio web.
class PaletaLienzo {
  const PaletaLienzo({
    required this.hoja,
    required this.borde,
    required this.punto,
    required this.texto,
    required this.texto2,
    required this.cabecera,
    required this.tinta,
    required this.duraznoTinta,
    required this.resaltado,
    required this.anillo,
    required this.sombra,
  });

  final Color hoja;
  final Color borde;
  final Color punto;
  final Color texto;
  final Color texto2;
  final Color cabecera;
  final Color tinta;
  final Color duraznoTinta;
  final Color resaltado;
  final Color anillo;
  final Color sombra;

  factory PaletaLienzo.de(ColoresApp c) => PaletaLienzo(
        hoja: c.superficie,
        borde: c.borde,
        punto: c.puntoLienzo,
        texto: c.texto,
        texto2: c.texto2,
        cabecera: c.salviaSuave,
        tinta: c.salviaTinta,
        duraznoTinta: c.duraznoTinta,
        resaltado: c.duraznoSuave,
        anillo: c.salviaSuave,
        sombra: c.sombraAlta,
      );

  static final claro = PaletaLienzo.de(ColoresApp.claro);

  /// Color de cada tipo de relación (como en la web): agregación salvia, composición durazno,
  /// dependencia gris y el resto en tinta.
  Color deRelacion(String tipo, {bool deNota = false}) {
    if (deNota) return duraznoTinta;
    return switch (tipo) {
      'aggregation' => tinta,
      'composition' => duraznoTinta,
      'dependency' => texto2,
      _ => texto,
    };
  }
}

/// Notas: durazno las del equipo y salvia las ideas de la IA, como pósits; no cambian con el tema.
const _notaEquipo = (fondo: Marca.durazno, borde: Color(0xFFDCB898), esquina: Color(0xFFE8B695));
const _notaIA = (fondo: Color(0xFFE5EDDF), borde: Color(0xFFB1C8AB), esquina: Color(0xFFB1C8AB));

class PintorDiagrama extends CustomPainter {
  PintorDiagrama({required this.cajas, required this.aristas, required this.origen, required this.resaltadas, this.escala = 1, this.seleccionada, PaletaLienzo? paleta})
      : paleta = paleta ?? PaletaLienzo.claro;
  final List<CajaClase> cajas;
  final List<Map<String, dynamic>> aristas;
  final Offset origen;
  final Set<String> resaltadas;

  /// Escala actual del visor: alejado, cada clase muestra solo su nombre en letra legible.
  final double escala;

  /// Clase elegida en la búsqueda o tocada: borde salvia con anillo, como la seleccionada en la web.
  final String? seleccionada;

  final PaletaLienzo paleta;

  bool get _compacto => escala < escalaCompacta;

  /// Punto del borde de la caja en la dirección del otro extremo.
  Offset _borde(Rect r, Offset hacia) {
    final c = r.center;
    final d = hacia - c;
    if (d.dx == 0 && d.dy == 0) return c;
    final tx = d.dx == 0 ? double.infinity : (r.width / 2) / d.dx.abs();
    final ty = d.dy == 0 ? double.infinity : (r.height / 2) / d.dy.abs();
    final t = math.min(tx, ty);
    return c + d * t;
  }

  void _punteada(Canvas canvas, Offset p1, Offset p2, Paint linea, {double trazo = 5, double hueco = 5}) {
    final d = p2 - p1;
    final largo = d.distance;
    if (largo == 0) return;
    for (double t = 0; t < largo; t += trazo + hueco) {
      canvas.drawLine(p1 + d * (t / largo), p1 + d * (math.min(t + trazo, largo) / largo), linea);
    }
  }

  void _texto(Canvas canvas, String texto, Offset en, TextStyle estilo, {double? ancho, bool centrado = false}) {
    final tp = TextPainter(text: TextSpan(text: texto, style: estilo), textDirection: TextDirection.ltr, maxLines: ancho == null ? 1 : 12, ellipsis: '…')
      ..layout(maxWidth: ancho ?? double.infinity);
    tp.paint(canvas, centrado ? en - Offset(tp.width / 2, 0) : en);
  }

  /// Etiqueta en pastilla (cardinalidades y nombres de relación), centrada en ese punto.
  void _pastilla(Canvas canvas, String texto, Offset centro, TextStyle estilo, {required Color borde, double grosor = 1}) {
    final tp = TextPainter(text: TextSpan(text: texto, style: estilo), textDirection: TextDirection.ltr, maxLines: 1)..layout();
    final caja = Rect.fromCenter(center: centro, width: tp.width + 10, height: tp.height + 4);
    final r = RRect.fromRectAndRadius(caja, const Radius.circular(5));
    canvas.drawRRect(r, Paint()..color = paleta.hoja);
    canvas.drawRRect(r, Paint()
      ..color = borde
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosor);
    tp.paint(canvas, centro - Offset(tp.width / 2, tp.height / 2));
  }

  void _marcador(Canvas canvas, Offset punta, Offset desde, String tipo, Color color) {
    final dir = (punta - desde);
    final largo = dir.distance;
    if (largo == 0) return;
    final u = dir / largo;
    final n = Offset(-u.dy, u.dx);
    final trazo = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final relleno = Paint()..color = color;
    final hueco = Paint()..color = paleta.hoja;
    switch (tipo) {
      case 'generalization':
      case 'inheritance':
      case 'implementation':
      case 'realization':
        final base = punta - u * 14;
        final tri = Path()
          ..moveTo(punta.dx, punta.dy)
          ..lineTo((base + n * 8).dx, (base + n * 8).dy)
          ..lineTo((base - n * 8).dx, (base - n * 8).dy)
          ..close();
        canvas.drawPath(tri, hueco);
        canvas.drawPath(tri, trazo);
      case 'composition':
      case 'aggregation':
        final medio = punta - u * 10;
        final fondo = punta - u * 20;
        final rombo = Path()
          ..moveTo(punta.dx, punta.dy)
          ..lineTo((medio + n * 6).dx, (medio + n * 6).dy)
          ..lineTo(fondo.dx, fondo.dy)
          ..lineTo((medio - n * 6).dx, (medio - n * 6).dy)
          ..close();
        canvas.drawPath(rombo, tipo == 'composition' ? relleno : hueco);
        canvas.drawPath(rombo, trazo);
      case 'dependency':
        final base = punta - u * 11;
        canvas.drawLine(punta, base + n * 6, trazo);
        canvas.drawLine(punta, base - n * 6, trazo);
    }
  }

  /// La hoja del lienzo: papel con borde y la cuadrícula de puntos del estudio web.
  void _hoja(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(14));
    canvas.drawRRect(r, Paint()..color = paleta.hoja);
    canvas.drawRRect(r, Paint()
      ..color = paleta.borde
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1 / escala);
    // Alejado, los puntos se juntan y solo ensucian la vista
    if (_compacto) return;
    const paso = 24.0;
    final puntos = <Offset>[
      for (double x = paso / 2; x < size.width; x += paso)
        for (double y = paso / 2; y < size.height; y += paso) Offset(x, y),
    ];
    canvas.drawPoints(
      PointMode.points,
      puntos,
      Paint()
        ..color = paleta.punto
        ..strokeWidth = 1.7
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    _hoja(canvas, size);
    canvas.translate(-origen.dx, -origen.dy);
    final porId = {for (final c in cajas) c.id: c};

    // Relaciones primero, para que queden debajo de las clases
    final aristasPorId = {for (final e in aristas) '${e['id']}': e};
    for (final e in aristas) {
      final a = porId['${e['source']}'];
      final b = porId['${e['target']}'];
      if (a == null || b == null) continue;
      final datos = (e['data'] as Map?) ?? {};
      final tipo = '${datos['type'] ?? 'Association'}'.toLowerCase();
      final deNota = a.esNota || b.esNota;
      final color = paleta.deRelacion(tipo, deNota: deNota);
      final linea = Paint()
        ..color = color
        ..strokeWidth = deNota ? 1.3 : 1.6;
      // Clase de asociación: línea punteada de la clase al punto medio de su relación
      if (datos['isAssociationConnection'] == true) {
        final relacion = aristasPorId['${datos['parentRelationId']}'];
        final ra = porId['${relacion?['source']}'];
        final rb = porId['${relacion?['target']}'];
        if (ra != null && rb != null) {
          final medio = (_borde(ra.rect, rb.rect.center) + _borde(rb.rect, ra.rect.center)) / 2;
          _punteada(canvas, _borde(a.rect, medio), medio, Paint()
            ..color = paleta.tinta
            ..strokeWidth = 1.8, trazo: 8, hueco: 4);
        }
        continue;
      }
      final p1 = _borde(a.rect, b.rect.center);
      final p2 = _borde(b.rect, a.rect.center);
      if (deNota) {
        _punteada(canvas, p1, p2, linea, trazo: 4, hueco: 4);
      } else if (tipo == 'implementation' || tipo == 'realization' || tipo == 'dependency') {
        _punteada(canvas, p1, p2, linea);
      } else {
        canvas.drawLine(p1, p2, linea);
      }
      _marcador(canvas, p2, p1, tipo, color);
      // Alejado, las multiplicidades y los nombres de las relaciones no se alcanzan a leer
      if (_compacto) continue;
      final u = (p2 - p1).distance == 0 ? Offset.zero : (p2 - p1) / (p2 - p1).distance;
      final n = Offset(-u.dy, u.dx);
      final inicio = '${datos['startLabel'] ?? ''}';
      final fin = '${datos['endLabel'] ?? ''}';
      final estilo = TextStyle(fontSize: 10, fontFamily: fuenteMono, fontFamilyFallback: respaldoMono, fontWeight: FontWeight.w700, color: paleta.tinta);
      if (inicio.isNotEmpty) _pastilla(canvas, inicio, p1 + u * 18 + n * 11, estilo, borde: paleta.tinta, grosor: 1.4);
      if (fin.isNotEmpty) _pastilla(canvas, fin, p2 - u * 26 + n * 11, estilo, borde: paleta.tinta, grosor: 1.4);
      final etiqueta = '${datos['label'] ?? ''}';
      if (etiqueta.isNotEmpty) _pastilla(canvas, etiqueta, (p1 + p2) / 2 - n * 12, TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: paleta.texto), borde: paleta.borde);
    }

    for (final c in cajas) {
      final resaltada = resaltadas.contains(c.id);
      final elegida = c.id == seleccionada;
      if (c.esNota) {
        final nota = c.estereotipo == 'ia' ? _notaIA : _notaEquipo;
        final r = RRect.fromRectAndRadius(c.rect, const Radius.circular(4));
        canvas.drawRRect(r.shift(const Offset(0, 3)), Paint()..color = paleta.sombra);
        canvas.drawRRect(r, Paint()..color = nota.fondo);
        // Esquina doblada de la nota UML
        const pliegue = 13.0;
        final esquina = Path()
          ..moveTo(c.rect.right - pliegue, c.rect.top)
          ..lineTo(c.rect.right, c.rect.top + pliegue)
          ..lineTo(c.rect.right - pliegue, c.rect.top + pliegue)
          ..close();
        canvas.drawPath(esquina, Paint()..color = nota.esquina);
        canvas.drawRRect(r, Paint()
          ..color = resaltada ? Marca.salmon : (elegida ? paleta.tinta : nota.borde)
          ..style = PaintingStyle.stroke
          ..strokeWidth = resaltada ? 2.5 : 1);
        if (!_compacto) _texto(canvas, c.nombre, c.rect.topLeft + const Offset(10, 8), _estiloNota, ancho: c.rect.width - 20 - pliegue / 2);
        continue;
      }
      final r = RRect.fromRectAndRadius(c.rect, const Radius.circular(10));
      if (elegida) {
        canvas.drawRRect(r.inflate(3 / escala), Paint()
          ..color = paleta.anillo
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5 / escala);
      }
      canvas.drawRRect(r.shift(const Offset(0, 4)), Paint()..color = paleta.sombra);
      canvas.drawRRect(r, Paint()..color = resaltada ? paleta.resaltado : paleta.hoja);
      // Cabecera salvia con el nombre (y el estereotipo, si lo tiene)
      final altoCabecera = 26.0 + (c.estereotipo != null ? 13 : 0);
      canvas.save();
      canvas.clipRRect(r);
      canvas.drawRect(Rect.fromLTWH(c.rect.left, c.rect.top, c.rect.width, altoCabecera), Paint()..color = resaltada ? paleta.resaltado : paleta.cabecera);
      canvas.restore();
      canvas.drawLine(Offset(c.rect.left, c.rect.top + altoCabecera), Offset(c.rect.right, c.rect.top + altoCabecera), Paint()
        ..color = paleta.borde
        ..strokeWidth = 1);
      canvas.drawRRect(r, Paint()
        ..color = resaltada ? Marca.salmon : (elegida ? paleta.tinta : paleta.borde)
        ..style = PaintingStyle.stroke
        ..strokeWidth = resaltada ? 2.5 : (elegida ? 1.8 : 1));
      if (_compacto) {
        _nombreCompacto(canvas, c);
        continue;
      }
      double y = c.rect.top + 7;
      final izquierda = c.rect.left + 10;
      if (c.estereotipo != null) {
        _texto(canvas, '«${c.estereotipo}»', Offset(izquierda + _anchoMarca, y), TextStyle(fontSize: 9, color: paleta.texto2));
        y += 13;
      }
      _texto(canvas, '{ }', Offset(izquierda, y + 1), TextStyle(fontSize: 11, fontFamily: fuenteMono, fontFamilyFallback: respaldoMono, fontWeight: FontWeight.w700, color: paleta.tinta));
      final estiloNombre = _estiloNombre.copyWith(color: paleta.texto, fontStyle: c.estereotipo == 'abstract' ? FontStyle.italic : null);
      _texto(canvas, c.nombre, Offset(izquierda + _anchoMarca, y), estiloNombre);
      y += 21;
      final separador = Paint()
        ..color = paleta.borde
        ..strokeWidth = 1;
      final estiloMiembro = _estiloMiembro.copyWith(color: paleta.texto);
      for (final a in c.atributos) {
        _texto(canvas, a, Offset(izquierda, y), estiloMiembro);
        y += _linea;
      }
      if (c.atributos.isEmpty) y += _linea;
      if (c.metodos.isNotEmpty) {
        y += 4;
        canvas.drawLine(Offset(c.rect.left, y - 2), Offset(c.rect.right, y - 2), separador);
        for (final m in c.metodos) {
          _texto(canvas, m, Offset(izquierda, y), estiloMiembro);
          y += _linea;
        }
      }
    }
  }

  /// Vista alejada: solo el nombre, con una letra que en pantalla se ve de unos 12 px; si no entra,
  /// se achica hasta poco menos del doble del ancho de la caja, sin bajar de unos 8 px en pantalla.
  void _nombreCompacto(Canvas canvas, CajaClase c) {
    double tam = 12 / escala;
    TextPainter medir(double t) => TextPainter(
          text: TextSpan(text: c.nombre, style: _estiloNombre.copyWith(fontSize: t, color: paleta.texto)),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout();
    var tp = medir(tam);
    final maximo = c.rect.width * 1.8;
    if (tp.width > maximo) {
      tam = math.max(8 / escala, tam * maximo / tp.width);
      tp = medir(tam);
    }
    tp.paint(canvas, c.rect.center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant PintorDiagrama old) => true;
}
