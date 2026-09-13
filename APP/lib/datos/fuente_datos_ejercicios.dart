import '../dominio/modelos/aritmetico.dart';
import '../dominio/modelos/ejercicio.dart';
import '../dominio/modelos/posicion_curricular.dart';
import '../dominio/organizacion/organizador_ejercicios.dart';
import 'repositorio_ejercicios.dart';

/// Fuente de datos en memoria para gestionar ejercicios creados en la app.
/// Contiene un banco inicial con preguntas de aritmética básica en distintos formatos y tags.
class FuenteDatosEjercicios implements RepositorioEjercicios {
  FuenteDatosEjercicios([List<Ejercicio>? iniciales]) {
    if (iniciales != null) {
      _ejercicios.addAll(iniciales);
    } else {
      _ejercicios.addAll(_ejerciciosInicialesPredeterminados());
    }
    _actualizarOrganizador();
  }

  static List<Ejercicio> _ejerciciosInicialesPredeterminados() {
    return [
      const Aritmetico(
        id: 'ARIT-1.1.1',
        posicion: PosicionCurricular(tema: 1, subtema: 1, leccion: 1),
        nivel: 1,
        enunciado: 'Calcula la suma en columna alineando unidades y decenas:',
        operacion: OperacionAritmetica.suma,
        operando1: 125,
        operando2: 78,
        disposicion: DisposicionAritmetica.vertical,
        incognita: ElementoIncognita.resultado,
        tags: ['aritmetica', 'suma', 'acarreo', 'reagrupacion', 'vertical'],
        puntos: 10,
        explicacion: '125 + 78 = 203. Sumamos 5+8=13 (llevamos 1), 2+7+1=10 (llevamos 1), 1+1=2 -> 203.',
      ),
      const Aritmetico(
        id: 'ARIT-1.2.1',
        posicion: PosicionCurricular(tema: 1, subtema: 2, leccion: 1),
        nivel: 2,
        enunciado: 'Resuelve la multiplicación tradicional:',
        operacion: OperacionAritmetica.multiplicacion,
        operando1: 46,
        operando2: 7,
        disposicion: DisposicionAritmetica.vertical,
        incognita: ElementoIncognita.resultado,
        tags: ['aritmetica', 'multiplicacion', 'tablas-multiplicar', 'acarreo', 'vertical'],
        puntos: 10,
        explicacion: '46 × 7 = 322. Multiplicamos 7×6=42 (llevamos 4), 7×4=28 + 4 = 32 -> 322.',
      ),
      const Aritmetico(
        id: 'ARIT-1.3.1',
        posicion: PosicionCurricular(tema: 1, subtema: 3, leccion: 1),
        nivel: 2,
        enunciado: 'Encuentra el número inicial faltante (minuendo):',
        operacion: OperacionAritmetica.resta,
        operando1: 77,
        operando2: 35,
        disposicion: DisposicionAritmetica.vertical,
        incognita: ElementoIncognita.operando1,
        tags: ['aritmetica', 'resta', 'despeje', 'ecuaciones-casilla', 'minuendo'],
        puntos: 15,
        explicacion: 'Para despejar el minuendo a: a = 42 + 35 = 77.',
      ),
      const Aritmetico(
        id: 'ARIT-1.4.1',
        posicion: PosicionCurricular(tema: 1, subtema: 4, leccion: 1),
        nivel: 2,
        enunciado: 'Realiza la división en galera e ingresa el cociente y el resto:',
        operacion: OperacionAritmetica.division,
        operando1: 125,
        operando2: 5,
        disposicion: DisposicionAritmetica.vertical,
        incognita: ElementoIncognita.cociente,
        tags: ['aritmetica', 'division', 'division-galera', 'cociente', 'resto'],
        puntos: 15,
        explicacion: '125 ÷ 5 = 25 con resto 0 (división exacta).',
      ),
      const Aritmetico(
        id: 'ARIT-1.5.1',
        posicion: PosicionCurricular(tema: 1, subtema: 5, leccion: 1),
        nivel: 1,
        enunciado: 'Completa la tabla de multiplicar (encuentra el factor faltante):',
        operacion: OperacionAritmetica.multiplicacion,
        operando1: 7,
        operando2: 8,
        disposicion: DisposicionAritmetica.horizontal,
        incognita: ElementoIncognita.operando2,
        tags: ['aritmetica', 'multiplicacion', 'tablas-multiplicar', 'despeje'],
        puntos: 10,
        explicacion: '7 × 8 = 56. El número faltante es 8 (56 ÷ 7 = 8).',
      ),
      const Aritmetico(
        id: 'ARIT-1.6.1',
        posicion: PosicionCurricular(tema: 1, subtema: 6, leccion: 1),
        nivel: 1,
        enunciado: 'Simplifica la fracción y calcula su valor entero:',
        operacion: OperacionAritmetica.division,
        operando1: 18,
        operando2: 6,
        disposicion: DisposicionAritmetica.fraccion,
        incognita: ElementoIncognita.resultado,
        tags: ['aritmetica', 'division', 'fraccion', 'simplificacion'],
        puntos: 10,
        explicacion: '18 / 6 = 3.',
      ),
    ];
  }

  final List<Ejercicio> _ejercicios = [];
  late OrganizadorEjercicios _organizador;

  OrganizadorEjercicios get organizador => _organizador;

  void _actualizarOrganizador() {
    _organizador = OrganizadorEjercicios(_ejercicios);
  }

  @override
  Future<List<Ejercicio>> obtenerTodos() async {
    return _organizador.ejerciciosOrdenados;
  }

  @override
  Future<Ejercicio?> obtenerPorId(String id) async {
    try {
      return _ejercicios.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Ejercicio?> obtenerPorPosicion(PosicionCurricular posicion) async {
    return _organizador.buscarPorPosicion(posicion);
  }

  @override
  Future<List<Ejercicio>> obtenerPorTema(int tema) async {
    return _organizador.filtrarPorTema(tema);
  }

  @override
  Future<List<Ejercicio>> obtenerPorSubtema(int tema, int subtema) async {
    return _organizador.filtrarPorSubtema(tema, subtema);
  }

  @override
  Future<List<Ejercicio>> obtenerPorLeccion(int tema, int subtema, int leccion) async {
    return _organizador.filtrarPorLeccion(tema, subtema, leccion);
  }

  @override
  Future<void> agregarEjercicio(Ejercicio ejercicio) async {
    // Si ya existe uno con el mismo ID o misma posición, lo actualiza o añade
    _ejercicios.removeWhere((e) => e.id == ejercicio.id);
    _ejercicios.add(ejercicio);
    _actualizarOrganizador();
  }

  @override
  Future<void> eliminarEjercicio(String id) async {
    _ejercicios.removeWhere((e) => e.id == id);
    _actualizarOrganizador();
  }

  @override
  Future<void> limpiar() async {
    _ejercicios.clear();
    _actualizarOrganizador();
  }
}
