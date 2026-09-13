import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto/dominio/diagnostico/analizador_diagnostico.dart';
import 'package:proyecto/dominio/generadores/generador_aritmetica.dart';
import 'package:proyecto/dominio/modelos/aritmetico.dart';
import 'package:proyecto/dominio/modelos/diagnostico_alumno.dart';
import 'package:proyecto/dominio/modelos/error_aprendizaje.dart';
import 'package:proyecto/dominio/modelos/intento_evaluacion.dart';
import 'package:proyecto/dominio/modelos/tipo_ejercicio.dart';

void main() {
  group('AnalizadorDiagnostico - Cálculo de Perfil y Errores Prominentes', () {
    const analizador = AnalizadorDiagnostico();

    test('Calcula estadísticas básicas con precisión y conteo correcto', () {
      final intentos = [
        IntentoEvaluacion(
          id: '1',
          usuarioUid: 'alumno-1',
          ejercicioId: 'E1',
          codigoTema: '1.1.1',
          tags: const ['suma', 'acarreo'],
          tipo: TipoEjercicio.aritmetico,
          esCorrecto: true,
          puntaje: 1.0,
          fecha: DateTime.now(),
        ),
        IntentoEvaluacion(
          id: '2',
          usuarioUid: 'alumno-1',
          ejercicioId: 'E2',
          codigoTema: '1.1.1',
          tags: const ['suma', 'acarreo'],
          tipo: TipoEjercicio.aritmetico,
          esCorrecto: false,
          puntaje: 0.0,
          error: const ErrorAprendizaje(
            id: 'ERR-1',
            categoria: CategoriaError.acarreoReagrupacion,
            subtipo: 'olvido_acarreo_llevada',
            descripcion: 'Olvidó acarreo',
            sugerenciaPedagogica: 'Suma el 1 arriba',
            tagsAsociados: ['acarreo', 'suma'],
            severidad: SeveridadError.moderada,
          ),
          fecha: DateTime.now(),
        ),
      ];

      final diag = analizador.analizar(usuarioUid: 'alumno-1', intentos: intentos);

      expect(diag.totalIntentos, equals(2));
      expect(diag.aciertos, equals(1));
      expect(diag.errores, equals(1));
      expect(diag.porcentajePrecision, equals(50.0));
      expect(diag.distribucionPorCategoria[CategoriaError.acarreoReagrupacion], equals(1));
      expect(diag.distribucionPorTag['acarreo'], equals(1));
    });

    test('Identifica errores prominentes y tags críticos ante fallos recurrentes', () {
      // 3 fallos en acarreo y 1 fallo en signos
      final intentos = [
        for (int i = 0; i < 3; i++)
          IntentoEvaluacion(
            id: 'int-acarreo-$i',
            usuarioUid: 'alumno-1',
            ejercicioId: 'E-SUM-$i',
            codigoTema: '1.1.1',
            tags: const ['aritmetica', 'suma', 'acarreo'],
            tipo: TipoEjercicio.aritmetico,
            esCorrecto: false,
            puntaje: 0.0,
            error: const ErrorAprendizaje(
              id: 'ERR-ACARREO',
              categoria: CategoriaError.acarreoReagrupacion,
              subtipo: 'olvido_acarreo_llevada',
              descripcion: 'Olvido constante de acarreo',
              sugerenciaPedagogica: 'Marcar el número llevado',
              tagsAsociados: ['acarreo'],
              severidad: SeveridadError.moderada,
            ),
            fecha: DateTime.now(),
          ),
        IntentoEvaluacion(
          id: 'int-signo-1',
          usuarioUid: 'alumno-1',
          ejercicioId: 'E-SIG-1',
          codigoTema: '1.2.1',
          tags: const ['aritmetica', 'signos'],
          tipo: TipoEjercicio.aritmetico,
          esCorrecto: false,
          puntaje: 0.0,
          error: const ErrorAprendizaje(
            id: 'ERR-SIGNO',
            categoria: CategoriaError.signoOperacion,
            subtipo: 'resto_en_lugar_de_sumar',
            descripcion: 'Confusión de signos',
            sugerenciaPedagogica: 'Revisar el operador',
            tagsAsociados: ['signos'],
            severidad: SeveridadError.moderada,
          ),
          fecha: DateTime.now(),
        ),
      ];

      final diag = analizador.analizar(usuarioUid: 'alumno-1', intentos: intentos);

      expect(diag.erroresProminentes.isNotEmpty, isTrue);
      // El error más prominente debe ser el de acarreo (3 fallos)
      final primerError = diag.erroresProminentes.first;
      expect(primerError.categoria, equals(CategoriaError.acarreoReagrupacion));
      expect(primerError.conteo, equals(3));

      // Tags críticos (deben incluir 'acarreo' ya que tiene >= 2 fallos)
      expect(diag.tagsCriticos, contains('acarreo'));

      // Recomendaciones pedagógicas ("¿En qué se debe ayudar?")
      expect(diag.recomendacionesRefuerzo.isNotEmpty, isTrue);
      final recAcarreo = diag.recomendacionesRefuerzo.firstWhere(
        (r) => r.id.contains('acarreoReagrupacion'),
      );
      expect(recAcarreo.prioridad, equals(PrioridadAyuda.alta));
      expect(recAcarreo.tagsParaReforzar, contains('acarreo'));
    });

    test('GeneradorAritmetica genera ejercicios de refuerzo específicos para tags críticos', () {
      final generador = GeneradorAritmetica();

      // Refuerzo para acarreo
      final ejAcarreo = generador.generarRefuerzoParaTags(['acarreo', 'suma']);
      expect(ejAcarreo.tags, contains('acarreo'));
      expect(ejAcarreo.operacion, equals(OperacionAritmetica.suma));

      // Refuerzo para tablas de multiplicar
      final ejTablas = generador.generarRefuerzoParaTags(['tablas-multiplicar']);
      expect(ejTablas.tags, contains('tablas-multiplicar'));
      expect(ejTablas.operacion, equals(OperacionAritmetica.multiplicacion));

      // Refuerzo para división galera
      final ejDiv = generador.generarRefuerzoParaTags(['division-galera', 'resto']);
      expect(ejDiv.tags, contains('division-galera'));
      expect(ejDiv.operacion, equals(OperacionAritmetica.division));
    });
  });
}
