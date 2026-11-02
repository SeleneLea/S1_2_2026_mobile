import 'package:flutter/material.dart';

import 'api.dart';
import 'notificaciones.dart';
import 'pantalla_sala.dart';
import 'push.dart';
import 'tema.dart';

/// Navegador de la app: lo usan los avisos para abrir la sala al tocarlos.
final navegador = GlobalKey<NavigatorState>();

Future<void> _abrirSala(int salaId, String titulo) async {
  final sesion = await Sesion.leer();
  if (sesion == null) return;
  navegador.currentState?.push(MaterialPageRoute(builder: (_) => PantallaSala(sesion: sesion, salaId: salaId, titulo: titulo)));
}

/// Diagramador móvil: versión informativa para quien está de viaje. Muestra el diagrama de la
/// sala actualizándose en vivo, el chat del equipo con la IA y quién hizo cada cambio, y avisa
/// con notificaciones cuando hay novedades.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Notificaciones.instancia.alTocar = _abrirSala;
  Push.instancia.alTocar = _abrirSala;
  await Notificaciones.instancia.iniciar();
  await Push.instancia.iniciar();
  final sesion = await Sesion.leer();
  if (sesion != null) Push.instancia.registrar(sesion);
  runApp(AppDiagramador(sesion: sesion));
}

class AppDiagramador extends StatelessWidget {
  const AppDiagramador({super.key, this.sesion});
  final Sesion? sesion;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diagramador UML',
      navigatorKey: navegador,
      debugShowCheckedModeBanner: false,
      // La paleta de la web: crema y carbón, con su versión oscura según el teléfono
      theme: temaClaro(),
      darkTheme: temaOscuro(),
      themeMode: ThemeMode.system,
      home: sesion == null ? const PantallaInicio() : PantallaSalas(sesion: sesion!),
    );
  }
}

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});
  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  final _servidor = TextEditingController();
  final _email = TextEditingController();
  final _clave = TextEditingController();
  bool _cargando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    Sesion.ultimoServidor().then((s) => _servidor.text = s);
  }

  Future<void> _entrar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final sesion = await Api.iniciarSesion(_servidor.text, _email.text, _clave.text);
      Push.instancia.registrar(sesion);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => PantallaSalas(sesion: sesion)));
    } on ErrorApi catch (e) {
      setState(() => _error = e.estado == 400 || e.estado == 401 ? 'Correo o contraseña incorrectos.' : e.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Widget _campo(String etiqueta, TextEditingController controlador, IconData icono, {String? ayuda, String? pista, TextInputType? teclado, bool oculto = false, ValueChanged<String>? alEnviar}) {
    final c = context.colores;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(etiqueta, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.texto)),
      const SizedBox(height: 9),
      TextField(
        controller: controlador,
        keyboardType: teclado,
        obscureText: oculto,
        onSubmitted: alEnviar,
        decoration: InputDecoration(
          hintText: pista,
          helperText: ayuda,
          prefixIcon: Icon(icono, size: 18),
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
        ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final tema = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            const Align(alignment: Alignment.centerLeft, child: LogotipoApp(tam: 19)),
            const SizedBox(height: 24),
            // La historia de la página de acceso de la web, en versión de bolsillo
            Container(
              padding: const EdgeInsets.fromLTRB(23, 22, 23, 24),
              decoration: BoxDecoration(color: c.salviaSuave, borderRadius: BorderRadius.circular(18)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  IconoFlujo(tam: 16, color: c.texto),
                  const SizedBox(width: 9),
                  Text('IDEAS QUE TOMAN FORMA', style: estiloEyebrow(c.texto, tam: 9)),
                ]),
                const SizedBox(height: 16),
                Text.rich(
                  TextSpan(children: [
                    const TextSpan(text: 'Todo gran proyecto empieza con '),
                    TextSpan(text: 'una conexión.', style: const TextStyle(fontFamily: fuenteSerif, fontFamilyFallback: respaldoSerif, fontStyle: FontStyle.italic, fontWeight: FontWeight.w400, letterSpacing: -0.6)),
                  ]),
                  style: TextStyle(fontSize: 30, height: 1.14, fontWeight: FontWeight.w500, letterSpacing: -1.4, color: c.texto),
                ),
              ]),
            ),
            const SizedBox(height: 30),
            Text('QUÉ BUENO VERTE DE NUEVO', style: estiloEyebrow(c.salviaTinta, tam: 9)),
            const SizedBox(height: 12),
            Text('Vuelve a tus ideas.', style: tema.headlineSmall),
            const SizedBox(height: 8),
            Text('Sigue el diagrama de tu equipo y a la IA desde donde estés.', style: TextStyle(fontSize: 13, height: 1.8, color: c.texto2)),
            const SizedBox(height: 26),
            _campo('Servidor', _servidor, Icons.dns_outlined, teclado: TextInputType.url, ayuda: 'Ej.: https://diagramador-uml.onrender.com'),
            const SizedBox(height: 18),
            _campo('Correo electrónico', _email, Icons.mail_outline_rounded, teclado: TextInputType.emailAddress, pista: 'tu@correo.com'),
            const SizedBox(height: 18),
            _campo('Contraseña', _clave, Icons.lock_outline_rounded, oculto: true, pista: 'Tu contraseña', alEnviar: (_) => _entrar()),
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: c.salmonSuave, borderRadius: BorderRadius.circular(8)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.error_outline_rounded, size: 18, color: c.error),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: TextStyle(fontSize: 12, height: 1.6, color: c.error))),
                ]),
              ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: _cargando ? null : _entrar,
              style: const ButtonStyle(minimumSize: WidgetStatePropertyAll(Size.fromHeight(50))),
              child: Row(children: [
                Expanded(child: Text(_cargando ? 'Entrando…' : 'Entrar')),
                const Icon(Icons.north_east_rounded, size: 18),
              ]),
            ),
            const SizedBox(height: 32),
            Divider(color: c.borde),
            const SizedBox(height: 18),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const PuntoEstado(),
              const SizedBox(width: 7),
              Text('Un espacio para crear a tu manera.', style: TextStyle(fontSize: 11, color: c.texto2)),
            ]),
          ],
        ),
      ),
    );
  }
}

class PantallaSalas extends StatefulWidget {
  const PantallaSalas({super.key, required this.sesion});
  final Sesion sesion;
  @override
  State<PantallaSalas> createState() => _PantallaSalasState();
}

class _PantallaSalasState extends State<PantallaSalas> {
  late Future<List<Map<String, dynamic>>> _salas;

  @override
  void initState() {
    super.initState();
    _salas = Api(widget.sesion).salas();
  }

  Future<void> _recargar() async {
    setState(() => _salas = Api(widget.sesion).salas());
    await _salas;
  }

  String _hace(String? iso) {
    if (iso == null) return '';
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return '';
    final m = DateTime.now().difference(d).inMinutes;
    if (m < 1) return 'ahora';
    if (m < 60) return 'hace $m min';
    if (m < 60 * 24) return 'hace ${m ~/ 60} h';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
  }

  Future<void> _salir() async {
    await Push.instancia.olvidar(widget.sesion);
    await Sesion.cerrar();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const PantallaInicio()));
  }

  /// Encabezado de la lista, como el de "Mis diagramas" de la web.
  List<Widget> _encabezado(int? cantidad) {
    final c = context.colores;
    final nombre = widget.sesion.nombre.trim().split(' ').first;
    return [
      const Antetitulo('Mi espacio de trabajo'),
      const SizedBox(height: 10),
      Text('Mis salas.', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 6),
      Text('Hola, ${nombre.isEmpty ? 'de nuevo' : nombre}. Tus ideas tienen un lugar aquí.', style: TextStyle(fontSize: 13, height: 1.6, color: c.texto2)),
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.borde))),
        child: Row(children: [
          Icon(Icons.grid_view_rounded, size: 17, color: c.texto),
          const SizedBox(width: 10),
          Text('Todas las salas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.texto)),
          if (cantidad != null) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: c.salviaSuave, borderRadius: BorderRadius.circular(5)),
              child: Text('$cantidad', style: TextStyle(fontSize: 10, color: c.salviaTinta, fontWeight: FontWeight.w600)),
            ),
          ],
        ]),
      ),
      const SizedBox(height: 16),
    ];
  }

  Widget _tarjeta(Map<String, dynamic> sala, int i) {
    final c = context.colores;
    final pendientes = (sala['propuestasPendientes'] as num?)?.toInt() ?? 0;
    // Tintes alternos de la web: salvia, durazno y papel
    final tintes = [(c.salviaSuave, c.salviaTinta), (c.duraznoSuave, c.duraznoTinta), (c.fondo2, c.texto2)];
    final (fondo, tinta) = tintes[i % 3];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: InkWell(
          onTap: () async {
            await Navigator.of(context).push(MaterialPageRoute(builder: (_) => PantallaSala(sesion: widget.sesion, salaId: (sala['id'] as num).toInt(), titulo: '${sala['titulo']}')));
            _recargar();
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: IconoFlujo(tam: 26, color: tinta, grosor: 1.6),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${sala['titulo']}', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, height: 1.35, fontWeight: FontWeight.w600, letterSpacing: -0.3, color: c.texto)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.person_outline_rounded, size: 13, color: c.texto2),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        '${sala['propia'] == true ? 'Tuya' : 'De ${sala['dueno']}'} · ${_hace(sala['ultimaActividad'] as String?)}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: c.texto2),
                      ),
                    ),
                  ]),
                ]),
              ),
              const SizedBox(width: 10),
              pendientes > 0
                  ? Tooltip(
                      message: '$pendientes propuesta${pendientes == 1 ? '' : 's'} de la IA por decidir',
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(color: c.salviaSuave, borderRadius: BorderRadius.circular(6)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.auto_awesome_outlined, size: 13, color: c.salviaTinta),
                          const SizedBox(width: 4),
                          Text('$pendientes', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.salviaTinta)),
                        ]),
                      ),
                    )
                  : Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(color: c.fondo2, shape: BoxShape.circle),
                      child: Icon(Icons.north_east_rounded, size: 15, color: c.texto),
                    ),
            ]),
          ),
        ),
      ),
    );
  }

  /// Estado vacío o de error: borde discontinuo y baldosa de ícono, como en la web.
  Widget _aviso({required IconData icono, required String titulo, required String texto, Widget? accion}) {
    final c = context.colores;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 28),
      decoration: BoxDecoration(color: c.superficie, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.borde)),
      child: Column(children: [
        BaldosaIcono(icono: Icon(icono)),
        const SizedBox(height: 16),
        Text(titulo, textAlign: TextAlign.center, style: TextStyle(fontSize: 20, height: 1.25, fontWeight: FontWeight.w500, letterSpacing: -0.5, color: c.texto)),
        const SizedBox(height: 8),
        Text(texto, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, height: 1.8, color: c.texto2)),
        if (accion != null) ...[const SizedBox(height: 18), accion],
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Scaffold(
      appBar: AppBar(
        title: const LogotipoApp(tam: 18),
        actions: [IconButton(onPressed: _salir, tooltip: 'Cerrar sesión', icon: const Icon(Icons.logout_rounded)), const SizedBox(width: 8)],
      ),
      body: RefreshIndicator(
        color: c.salviaTinta,
        backgroundColor: c.superficie,
        onRefresh: _recargar,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _salas,
          builder: (context, s) {
            const relleno = EdgeInsets.fromLTRB(20, 26, 20, 32);
            if (s.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (s.hasError) {
              final expirada = s.error is ErrorApi && ((s.error as ErrorApi).estado == 401 || (s.error as ErrorApi).estado == 403);
              return ListView(padding: relleno, children: [
                ..._encabezado(null),
                _aviso(
                  icono: Icons.cloud_off_outlined,
                  titulo: expirada ? 'Tu sesión terminó.' : 'No pudimos traer tus salas.',
                  texto: s.error is ErrorApi ? (s.error as ErrorApi).mensaje : 'No se pudieron cargar tus salas. Revisa la conexión.',
                  accion: FilledButton(onPressed: expirada ? _salir : _recargar, child: Text(expirada ? 'Iniciar sesión de nuevo' : 'Reintentar')),
                ),
              ]);
            }
            final salas = s.data ?? [];
            if (salas.isEmpty) {
              return ListView(padding: relleno, children: [
                ..._encabezado(0),
                _aviso(icono: Icons.schema_outlined, titulo: 'Un lienzo lleno de posibilidades.', texto: 'Todavía no tienes salas. Créalas desde la web y aparecerán aquí.'),
              ]);
            }
            return ListView(
              padding: relleno,
              children: [
                ..._encabezado(salas.length),
                for (var i = 0; i < salas.length; i++) _tarjeta(salas[i], i),
              ],
            );
          },
        ),
      ),
    );
  }
}
