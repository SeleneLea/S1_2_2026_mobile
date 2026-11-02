import 'dart:async';

import 'package:flutter/material.dart';

import 'api.dart';
import 'diagrama.dart';
import 'notificaciones.dart';
import 'fusion.dart';
import 'tema.dart';
import 'tiempo_real.dart';

/// Una sala en el móvil: el diagrama en vivo, el chat del equipo con la IA y el historial.
class PantallaSala extends StatefulWidget {
  const PantallaSala({super.key, required this.sesion, required this.salaId, required this.titulo});
  final Sesion sesion;
  final int salaId;
  final String titulo;
  @override
  State<PantallaSala> createState() => _PantallaSalaState();
}

class _PantallaSalaState extends State<PantallaSala> {
  late final SalaEnVivo sala;
  StreamSubscription? _avisos;
  Timer? _reloj;

  @override
  void initState() {
    super.initState();
    sala = SalaEnVivo(widget.sesion, widget.salaId)..conectar();
    _avisos = sala.avisos.listen(
      (a) => Notificaciones.instancia.avisar('${widget.titulo}: ${a.titulo}', a.texto, esCambio: a.titulo == 'Cambio en el diagrama', salaId: widget.salaId, sala: widget.titulo),
    );
    // Repinta cada segundo para apagar el resaltado de las clases que cambiaron
    _reloj = Timer.periodic(const Duration(seconds: 1), (_) {
      if (sala.resaltadas.isNotEmpty) {
        sala.resaltadas.removeWhere((_, cuando) => DateTime.now().difference(cuando).inSeconds > 6);
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _reloj?.cancel();
    _avisos?.cancel();
    sala.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return DefaultTabController(
      length: 3,
      child: ListenableBuilder(
        listenable: sala,
        builder: (context, _) {
          final iaOcupada = sala.estadoIA['ocupada'] == true;
          final estado = sala.conectado ? (iaOcupada ? 'La IA está atendiendo a ${sala.estadoIA['atendiendoA']}…' : 'En vivo') : (sala.error ?? 'Conectando…');
          return Scaffold(
            // El fondo del estudio de la web: el lienzo queda como una hoja sobre la mesa
            backgroundColor: c.fondo2,
            appBar: AppBar(
              backgroundColor: c.superficie,
              titleSpacing: 4,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.titulo, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      PuntoEstado(tam: 6, color: sala.conectado ? (iaOcupada ? c.salviaTinta : Marca.salvia) : Marca.salmon),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          estado,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: c.texto2),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(62),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: c.fondo2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: c.bordeSuave),
                  ),
                  child: const TabBar(
                    tabs: [
                      Tab(
                        height: 36,
                        iconMargin: EdgeInsets.zero,
                        child: _Pestana(icono: Icons.schema_outlined, texto: 'Diagrama'),
                      ),
                      Tab(
                        height: 36,
                        iconMargin: EdgeInsets.zero,
                        child: _Pestana(icono: Icons.forum_outlined, texto: 'Chat'),
                      ),
                      Tab(
                        height: 36,
                        iconMargin: EdgeInsets.zero,
                        child: _Pestana(icono: Icons.history_rounded, texto: 'Quién hizo qué'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            body: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                VistaDiagrama(sala: sala),
                VistaChat(sala: sala),
                VistaHistorial(sala: sala),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Pestaña de la barra segmentada: ícono y texto en una línea.
class _Pestana extends StatelessWidget {
  const _Pestana({required this.icono, required this.texto});
  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icono, size: 15),
        const SizedBox(width: 6),
        Flexible(child: Text(texto, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

class VistaDiagrama extends StatefulWidget {
  const VistaDiagrama({super.key, required this.sala});
  final SalaEnVivo sala;
  @override
  State<VistaDiagrama> createState() => _VistaDiagramaState();
}

class _VistaDiagramaState extends State<VistaDiagrama> with SingleTickerProviderStateMixin {
  final _transformacion = TransformationController();
  late final AnimationController _animacion = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
  Animation<Matrix4>? _destino;
  bool _encuadrado = false;
  Size _pantalla = Size.zero;
  Offset? _dobleToque;
  String? _seleccionada;

  @override
  void initState() {
    super.initState();
    _animacion.addListener(() {
      if (_destino != null) _transformacion.value = _destino!.value;
    });
  }

  @override
  void dispose() {
    _animacion.dispose();
    _transformacion.dispose();
    super.dispose();
  }

  double get _escala => _transformacion.value.getMaxScaleOnAxis();

  /// Transformación que deja ese punto del lienzo en el centro de la pantalla con esa escala.
  /// La escala va también en Z: InteractiveViewer mide la escala con el mayor de los tres ejes, y con
  /// Z en 1 creía estar al 100 % aunque se viera al 20 %, así que el pellizco no dejaba acercar.
  Matrix4 _centradoEn(Offset punto, double escala) {
    final dx = _pantalla.width / 2 - punto.dx * escala;
    final dy = _pantalla.height / 2 - punto.dy * escala;
    return Matrix4(escala, 0, 0, 0, 0, escala, 0, 0, 0, 0, escala, 0, dx, dy, 0, 1);
  }

  void _animarA(Matrix4 destino) {
    _destino = Matrix4Tween(begin: _transformacion.value, end: destino).animate(CurvedAnimation(parent: _animacion, curve: Curves.easeOutCubic));
    _animacion.forward(from: 0);
  }

  void _encuadrar(Rect limites, {bool animado = true}) {
    final destino = _centradoEn(limites.size.center(Offset.zero), escalaParaVer(limites, _pantalla));
    if (animado) {
      _animarA(destino);
    } else {
      _transformacion.value = destino;
    }
  }

  /// Acerca o aleja manteniendo fijo el centro de la pantalla.
  void _zoom(double factor) {
    final centro = _transformacion.toScene(_pantalla.center(Offset.zero));
    _animarA(_centradoEn(centro, (_escala * factor).clamp(escalaMinima, escalaMaxima).toDouble()));
  }

  /// Doble toque: acerca donde se tocó; si ya está cerca, vuelve a ver todo.
  void _alDobleToque(Rect limites) {
    final punto = _dobleToque;
    if (punto == null) return;
    if (_escala >= 1.2) {
      _encuadrar(limites);
    } else {
      _animarA(_centradoEn(punto, 1.6));
    }
  }

  void _irAClase(CajaClase caja, Rect limites) {
    setState(() => _seleccionada = caja.id);
    _animarA(_centradoEn(caja.rect.center - limites.topLeft, 1.3));
  }

  void _verDetalle(CajaClase caja, List<CajaClase> cajas) {
    setState(() => _seleccionada = caja.id);
    final relaciones = relacionesDe(caja.id, cajas, widget.sala.aristas);
    final c = context.colores;
    final tema = Theme.of(context).textTheme;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.45,
        maxChildSize: 0.9,
        builder: (context, desplazamiento) => ListView(
          controller: desplazamiento,
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
          children: [
            Row(
              children: [
                BaldosaIcono(
                  icono: caja.esNota
                      ? const Icon(Icons.sticky_note_2_outlined)
                      : Text(
                          '{ }',
                          style: TextStyle(fontFamily: fuenteMono, fontFamilyFallback: respaldoMono, fontSize: 13, fontWeight: FontWeight.w700, color: c.salviaTinta),
                        ),
                  fondo: caja.esNota ? c.duraznoSuave : c.salviaSuave,
                  color: caja.esNota ? c.duraznoTinta : c.salviaTinta,
                  tam: 38,
                  giro: 0,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (caja.estereotipo != null && !caja.esNota) Text('«${caja.estereotipo}»', style: tema.bodySmall),
                      Text(caja.esNota ? 'Nota' : caja.nombre, style: tema.titleLarge),
                    ],
                  ),
                ),
              ],
            ),
            if (caja.esNota)
              Container(
                margin: const EdgeInsets.only(top: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: caja.estereotipo == 'ia' ? const Color(0xFFE5EDDF) : Marca.durazno, borderRadius: BorderRadius.circular(6)),
                child: Text(caja.nombre, style: const TextStyle(fontSize: 14, height: 1.6, color: Marca.carbon)),
              ),
            if (!caja.esNota) ...[
              _seccion('Atributos', caja.atributos, vacio: 'Sin atributos', codigo: true),
              if (caja.metodos.isNotEmpty) _seccion('Métodos', caja.metodos, codigo: true),
              _seccion('Relaciones', relaciones, vacio: 'No está relacionada con otras clases'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _seccion(String titulo, List<String> items, {String? vacio, bool codigo = false}) {
    final c = context.colores;
    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.borde)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo.toUpperCase(), style: estiloEyebrow(c.texto2, tam: 9)),
          const SizedBox(height: 8),
          if (items.isEmpty && vacio != null) Text(vacio, style: TextStyle(fontSize: 13, color: c.texto2)),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '• $item',
                style: codigo ? TextStyle(fontFamily: fuenteMono, fontFamilyFallback: respaldoMono, fontSize: 13, height: 1.8, color: c.texto) : TextStyle(fontSize: 14, height: 1.7, color: c.texto),
              ),
            ),
        ],
      ),
    );
  }

  /// Lista de clases con filtro: elegir una lleva el visor hasta ella.
  Future<void> _buscarClase(List<CajaClase> cajas, Rect limites) async {
    final clases = cajas.where((c) => !c.esNota).toList()..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    final elegida = await showModalBottomSheet<CajaClase>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        var filtro = '';
        final c = context.colores;
        return StatefulBuilder(
          builder: (context, actualizar) {
            final visibles = clases.where((c) => c.nombre.toLowerCase().contains(filtro.toLowerCase())).toList();
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: TextField(
                      autofocus: true,
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded, size: 19), hintText: 'Buscar clase'),
                      onChanged: (v) => actualizar(() => filtro = v),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemCount: visibles.length,
                      itemBuilder: (context, i) => ListTile(
                        leading: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(color: c.salviaSuave, borderRadius: BorderRadius.circular(8)),
                          alignment: Alignment.center,
                          child: Text(
                            '{ }',
                            style: TextStyle(fontFamily: fuenteMono, fontFamilyFallback: respaldoMono, fontSize: 11, fontWeight: FontWeight.w700, color: c.salviaTinta),
                          ),
                        ),
                        title: Text(visibles[i].nombre),
                        subtitle: Text('${visibles[i].atributos.length} atributos'),
                        trailing: Icon(Icons.chevron_right_rounded, size: 18, color: c.texto2),
                        onTap: () => Navigator.pop(context, visibles[i]),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (elegida != null) _irAClase(elegida, limites);
  }

  /// Botón de la barra de controles del lienzo (la de React Flow en la web).
  Widget _control({required String ayuda, required IconData icono, required VoidCallback alTocar}) {
    return IconButton(
      tooltip: ayuda,
      onPressed: alTocar,
      icon: Icon(icono, size: 20),
      constraints: const BoxConstraints.tightFor(width: 42, height: 42),
      style: IconButton.styleFrom(foregroundColor: context.colores.texto, shape: const RoundedRectangleBorder()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final cajas = calcularCajas(widget.sala.nodos);
    final limites = limitesDe(cajas);
    if (cajas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: widget.sala.conectado
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        BaldosaIcono(
                          icono: Text(
                            '{ }',
                            style: TextStyle(fontFamily: fuenteMono, fontFamilyFallback: respaldoMono, fontSize: 16, fontWeight: FontWeight.w700, color: c.salviaTinta),
                          ),
                        ),
                        Container(width: 30, height: 1, color: Marca.salvia),
                        BaldosaIcono(icono: const IconoFlujo(), fondo: c.duraznoSuave, color: c.duraznoTinta, giro: 8, tam: 46),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text('EL COMIENZO DE ALGO GRANDE', style: estiloEyebrow(c.texto2, tam: 8)),
                    const SizedBox(height: 10),
                    Text(
                      'El diagrama está vacío.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 26, height: 1.2, fontWeight: FontWeight.w500, letterSpacing: -0.8, color: c.texto),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cuando tu equipo cree clases en la web, aparecerán aquí en vivo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, height: 1.8, color: c.texto2),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.5)),
                    const SizedBox(height: 14),
                    Text('Cargando el diagrama…', style: TextStyle(fontSize: 12, color: c.texto2)),
                  ],
                ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, medidas) {
        // Con el teclado abierto (buscar clase) la pantalla se achica: se mide sin él para que, al
        // cerrarlo, el centrado no quede corrido hacia arriba
        _pantalla = Size(medidas.maxWidth, medidas.maxHeight + MediaQuery.viewInsetsOf(context).bottom);
        if (!_encuadrado) {
          _encuadrado = true;
          WidgetsBinding.instance.addPostFrameCallback((_) => _encuadrar(limites, animado: false));
        }
        return Stack(
          children: [
            InteractiveViewer(
              transformationController: _transformacion,
              constrained: false,
              minScale: escalaMinima,
              maxScale: escalaMaxima,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              child: GestureDetector(
                onTapUp: (d) {
                  final caja = cajaEn(cajas, d.localPosition + limites.topLeft);
                  if (caja != null) _verDetalle(caja, cajas);
                },
                onDoubleTapDown: (d) => _dobleToque = d.localPosition,
                onDoubleTap: () => _alDobleToque(limites),
                // La escala cambia con los gestos: alejado se dibuja solo el nombre de cada clase
                child: ListenableBuilder(
                  listenable: _transformacion,
                  builder: (context, _) => CustomPaint(
                    size: limites.size,
                    painter: PintorDiagrama(
                      cajas: cajas,
                      aristas: widget.sala.aristas,
                      origen: limites.topLeft,
                      resaltadas: widget.sala.resaltadas.keys.toSet(),
                      escala: _escala,
                      seleccionada: _seleccionada,
                      paleta: PaletaLienzo.de(c),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                decoration: BoxDecoration(
                  color: c.superficie,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: c.borde),
                  boxShadow: [BoxShadow(color: c.sombraAlta, blurRadius: 12, offset: const Offset(0, 3))],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _control(ayuda: 'Buscar una clase', icono: Icons.search_rounded, alTocar: () => _buscarClase(cajas, limites)),
                    Divider(height: 1, color: c.borde),
                    _control(ayuda: 'Acercar', icono: Icons.add_rounded, alTocar: () => _zoom(1.5)),
                    Divider(height: 1, color: c.borde),
                    _control(ayuda: 'Alejar', icono: Icons.remove_rounded, alTocar: () => _zoom(1 / 1.5)),
                    Divider(height: 1, color: c.borde),
                    _control(ayuda: 'Ver todo el diagrama', icono: Icons.fit_screen_outlined, alTocar: () => _encuadrar(limites)),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              // Deja libre la barra de controles de la derecha
              right: 70,
              child: Align(
                alignment: Alignment.bottomLeft,
                child: ListenableBuilder(
                  listenable: _transformacion,
                  builder: (context, _) => Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: Icon(Icons.data_object_rounded, size: 14, color: c.salviaTinta),
                    label: Text('${cajas.where((c) => !c.esNota).length} clases · ${widget.sala.aristas.length} relaciones · ${(_escala * 100).round()} %'),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              top: 10,
              right: 12,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(color: c.superficie.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(5)),
                    child: Text(
                      'Pellizca o usa + y − para acercar · toca una clase para ver sus detalles',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10, color: c.texto2),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class VistaChat extends StatefulWidget {
  const VistaChat({super.key, required this.sala});
  final SalaEnVivo sala;
  @override
  State<VistaChat> createState() => _VistaChatState();
}

class _VistaChatState extends State<VistaChat> {
  final _texto = TextEditingController();
  final _desplazamiento = ScrollController();
  bool _enviando = false;
  int _vistos = 0;
  // Chat que se ve: 'equipo' (entre personas) o 'ia' (la IA compartida de la sala)
  String _canal = 'equipo';

  Future<void> _mandar() async {
    final t = _texto.text.trim();
    if (t.isEmpty || _enviando) return;
    // En el chat del equipo, mencionar a @IA también le pide algo (va al chat de la IA)
    final paraIA = _canal == 'ia' || mencionaALaIA(t);
    setState(() => _enviando = true);
    final error = await widget.sala.enviar(t, paraIA: paraIA);
    if (!mounted) return;
    setState(() {
      _enviando = false;
      if (error == null && paraIA) _canal = 'ia';
    });
    if (error == null) {
      _texto.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _decidir(int id, String decision) async {
    final error = await widget.sala.decidir(id, decision);
    if (!mounted) return;
    if (error != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  String _hora(String? iso) {
    final d = iso == null ? null : DateTime.tryParse(iso)?.toLocal();
    return d == null ? '' : '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  /// Fondo y tinta de una observación de la IA según su gravedad.
  (Color, Color) _colorGravedad(String? gravedad, ColoresApp c) => switch (gravedad) {
    'error' => (c.salmonSuave, c.error),
    'sugerencia' => (c.superficie, c.salviaTinta),
    _ => (c.duraznoSuave, c.duraznoTinta),
  };

  Widget _propuesta(Map<String, dynamic> p) {
    final c = context.colores;
    final estado = '${p['estado']}';
    final resumen = List<String>.from((p['resumen'] as List? ?? []).map((x) => '$x'));
    final (fondoEstado, tintaEstado) = switch (estado) {
      'pendiente' => (c.duraznoSuave, c.duraznoTinta),
      'aceptada' || 'aplicando' => (c.salviaSuave, c.salviaTinta),
      'desactualizada' => (c.salmonSuave, c.error),
      _ => (c.fondo2, c.texto2),
    };
    return Container(
      margin: const EdgeInsets.only(top: 9),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: c.superficie,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: c.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Propuesta: ${resumen.length} cambios',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: c.texto),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: fondoEstado, borderRadius: BorderRadius.circular(4)),
                child: Text(
                  estado,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: tintaEstado),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final r in resumen) Text('• $r', style: TextStyle(fontSize: 12, height: 1.6, color: c.texto)),
          if (estado == 'pendiente')
            Padding(
              padding: const EdgeInsets.only(top: 9),
              child: Row(
                children: [
                  // Aceptar va en salvia (el botón de éxito de la web): el frambuesa queda para enviar
                  FilledButton(
                    onPressed: () => _decidir((p['id'] as num).toInt(), 'aceptar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: c.salviaSuave,
                      foregroundColor: c.salviaTinta,
                      side: BorderSide(color: c.borde),
                    ),
                    child: const Text('Aceptar'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(onPressed: () => _decidir((p['id'] as num).toInt(), 'rechazar'), child: const Text('Rechazar')),
                ],
              ),
            )
          else if (p['decididoPorNombre'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Por ${p['decididoPorNombre']}', style: TextStyle(fontSize: 11, color: c.texto2)),
            ),
        ],
      ),
    );
  }

  Widget _mensaje(Map<String, dynamic> m) {
    final c = context.colores;
    final tipo = m['tipo'];
    if (tipo == 'sistema') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 24),
        child: Text(
          '${m['texto']}',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, height: 1.6, color: c.texto2),
        ),
      );
    }
    final esIA = tipo == 'ia';
    final propio = !esIA && (m['autorId'] as num?)?.toInt() == widget.sala.sesion.id;
    final datos = (m['datos'] as Map?)?.cast<String, dynamic>() ?? {};
    final propuestaId = (datos['propuesta'] as Map?)?['id'];
    final propuesta = propuestaId is num ? widget.sala.propuestas[propuestaId.toInt()] : null;
    final observaciones = (datos['observaciones'] as List?) ?? [];
    final ideas = (datos['ideas'] as List?) ?? [];
    final iaLocal = esIA && datos['proveedor'] == 'IA local';
    // Burbujas: las propias en tinta sólida, las de la IA en salvia, las demás en papel
    final fondo = propio
        ? c.solido
        : esIA
        ? c.salviaSuave
        : c.superficie;
    final tinta = propio ? c.sobreSolido : c.texto;
    final meta = propio
        ? c.sobreSolido.withValues(alpha: 0.75)
        : esIA
        ? c.salviaTinta
        : c.texto2;
    return Align(
      alignment: propio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.86),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(propio ? 12 : 4),
            bottomRight: Radius.circular(propio ? 4 : 12),
          ),
          border: Border.all(color: propio ? c.solido : c.borde),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (esIA) ...[Icon(iaLocal ? Icons.laptop_mac_outlined : Icons.auto_awesome_outlined, size: 12, color: meta), const SizedBox(width: 4)],
                Flexible(
                  child: Text(
                    '${esIA
                        ? (iaLocal ? 'IA local' : 'IA')
                        : propio
                        ? 'Tú'
                        : m['autorNombre']} · ${_hora((datos['escritoEn'] ?? m['creadoEn']) as String?)}${esIA && datos['proveedor'] != null && datos['proveedor'] != 'IA local' ? ' · ${datos['proveedor']}' : ''}${datos['sinConexion'] == true ? ' · sin conexión' : ''}',
                    style: TextStyle(fontSize: 10, color: meta, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text('${m['texto']}'.replaceAll('**', '').replaceAll('`', ''), style: TextStyle(fontSize: 13, height: 1.6, color: tinta)),
            for (final o in observaciones)
              if (o is Map)
                Builder(
                  builder: (context) {
                    final (fondoObs, tintaObs) = _colorGravedad(o['gravedad'] as String?, c);
                    return Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                      decoration: BoxDecoration(
                        color: fondoObs,
                        borderRadius: BorderRadius.circular(6),
                        border: o['gravedad'] == 'sugerencia' ? Border.all(color: c.borde) : null,
                      ),
                      child: Text('${o['clase']}: ${o['texto']}', style: TextStyle(fontSize: 12, height: 1.5, color: tintaObs)),
                    );
                  },
                ),
            for (final i in ideas)
              if (i is Map)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(color: c.duraznoSuave, borderRadius: BorderRadius.circular(6)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(Icons.lightbulb_outline_rounded, size: 13, color: c.duraznoTinta),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('${i['titulo']}: ${i['texto']}', style: TextStyle(fontSize: 12, height: 1.5, color: c.duraznoTinta)),
                      ),
                    ],
                  ),
                ),
            if (propuesta != null) _propuesta(propuesta),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final deIA = _canal == 'ia';
    final mensajes = widget.sala.mensajes.where((m) => canalDe(m) == _canal).toList();
    final hayAnteriores = widget.sala.anteriores[_canal] == true;
    final ultimoId = mensajes.isEmpty ? 0 : (mensajes.last['id'] as num?)?.toInt() ?? 0;
    if (ultimoId != _vistos) {
      _vistos = ultimoId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_desplazamiento.hasClients) _desplazamiento.jumpTo(_desplazamiento.position.maxScrollExtent);
      });
    }
    return Column(
      children: [
        if (widget.sala.bienvenida != null)
          MaterialBanner(
            content: Text(widget.sala.bienvenida!),
            leading: Icon(Icons.auto_awesome_outlined, size: 18, color: c.salviaTinta),
            actions: [TextButton(onPressed: () => setState(() => widget.sala.bienvenida = null), child: const Text('Entendido'))],
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              segments: [
                const ButtonSegment(value: 'equipo', icon: Icon(Icons.group_outlined, size: 16), label: Text('Equipo')),
                ButtonSegment(value: 'ia', icon: const Icon(Icons.auto_awesome_outlined, size: 16), label: Text(widget.sala.estadoIA['ocupada'] == true ? 'IA…' : 'IA del equipo')),
              ],
              selected: {_canal},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _canal = s.first),
            ),
          ),
        ),
        Expanded(
          child: mensajes.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        BaldosaIcono(icono: Icon(deIA ? Icons.auto_awesome_outlined : Icons.group_outlined), tam: 46),
                        const SizedBox(height: 16),
                        Text(
                          deIA
                              ? 'La IA es un integrante más del equipo: todos ven lo que le piden y lo que responde. Sus cambios llegan como propuesta.'
                              : 'Chat entre los integrantes de la sala. La IA no interviene aquí; para pedirle algo usa "IA del equipo" o escribe @IA.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, height: 1.8, color: c.texto2),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _desplazamiento,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  itemCount: mensajes.length + (hayAnteriores ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (hayAnteriores) {
                      if (i == 0) {
                        return Center(
                          child: TextButton(onPressed: () => widget.sala.cargarAnteriores(_canal), child: const Text('Cargar mensajes anteriores')),
                        );
                      }
                      return _mensaje(mensajes[i - 1]);
                    }
                    return _mensaje(mensajes[i]);
                  },
                ),
        ),
        Container(
          decoration: BoxDecoration(
            color: c.fondo2,
            border: Border(top: BorderSide(color: c.borde)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _texto,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _mandar(),
                      decoration: InputDecoration(hintText: deIA ? 'Pídele algo a la IA (todo el equipo lo ve)' : 'Escribe al equipo'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _enviando ? null : _mandar,
                    tooltip: deIA ? 'Pedir a la IA' : 'Enviar al equipo',
                    icon: Icon(deIA ? Icons.auto_awesome : Icons.send_rounded, size: 19),
                    style: IconButton.styleFrom(
                      backgroundColor: Marca.frambuesa,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Marca.frambuesa.withValues(alpha: 0.45),
                      minimumSize: const Size(46, 46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class VistaHistorial extends StatelessWidget {
  const VistaHistorial({super.key, required this.sala});
  final SalaEnVivo sala;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final cambios = sala.cambios.reversed.toList();
    if (cambios.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BaldosaIcono(icono: Icon(Icons.history_rounded), tam: 46),
            const SizedBox(height: 16),
            Text('Todavía no hay cambios registrados.', style: TextStyle(fontSize: 13, color: c.texto2)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      itemCount: cambios.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final ch = cambios[i];
        final esIA = ch['esIA'] == true;
        final d = DateTime.tryParse('${ch['creadoEn']}')?.toLocal();
        final cuando = d == null ? '' : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
        // Como en la web: la línea de la izquierda es salvia para la IA y durazno para las personas
        return Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: c.superficie,
            borderRadius: BorderRadius.circular(9),
            border: Border(left: BorderSide(color: esIA ? Marca.salvia : Marca.durazno, width: 3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: esIA ? c.salviaSuave : Marca.durazno, shape: BoxShape.circle),
                child: esIA
                    ? Icon(Icons.auto_awesome_outlined, size: 14, color: c.salviaTinta)
                    : Text(
                        '${ch['autorNombre'] ?? '?'}'.characters.first.toUpperCase(),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Marca.carbon),
                      ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${esIA ? 'IA' : ch['autorNombre']} ${ch['resumen']}', style: TextStyle(fontSize: 13, height: 1.5, color: c.texto)),
                    const SizedBox(height: 3),
                    Text(
                      esIA ? '$cuando · pedido por ${ch['pedidoPor']}${ch['aprobadoPor'] != null ? ', aprobado por ${ch['aprobadoPor']}' : ''}' : cuando,
                      style: TextStyle(fontSize: 11, color: c.texto2),
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
