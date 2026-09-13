import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto/datos/fuente_datos_diagnostico.dart';
import 'package:proyecto/datos/fuente_datos_ejercicios.dart';
import 'package:proyecto/datos/servicio_auth.dart';
import 'package:proyecto/dominio/evaluadores/servicio_evaluacion.dart';
import 'package:proyecto/dominio/modelos/aritmetico.dart';
import 'package:proyecto/dominio/modelos/error_aprendizaje.dart';
import 'package:proyecto/dominio/modelos/examen_diagnostico.dart';
import 'package:proyecto/dominio/modelos/posicion_curricular.dart';
import 'package:proyecto/dominio/modelos/progreso_examen_alumno.dart';
import 'package:proyecto/dominio/modelos/usuario_app.dart';
import 'package:proyecto/interfaz/pantalla_alumno.dart';
import 'package:proyecto/interfaz/pantalla_profesor.dart';

void main() {
  group('ExamenDiagnostico - Variable de Avance Determinada por el Docente', () {
    const ej1 = Aritmetico(
      id: 'E1',
      posicion: PosicionCurricular(tema: 1, subtema: 1, leccion: 1),
      nivel: 1,
      enunciado: '10 + 10',
      operacion: OperacionAritmetica.suma,
      operando1: 10,
      operando2: 10,
      puntos: 10,
    );
    const ej2 = Aritmetico(
      id: 'E2',
      posicion: PosicionCurricular(tema: 1, subtema: 1, leccion: 2),
      nivel: 1,
      enunciado: '20 + 20',
      operacion: OperacionAritmetica.suma,
      operando1: 20,
      operando2: 20,
      puntos: 10,
    );
    const ej3 = Aritmetico(
      id: 'E3',
      posicion: PosicionCurricular(tema: 1, subtema: 1, leccion: 3),
      nivel: 1,
      enunciado: '30 + 30',
      operacion: OperacionAritmetica.suma,
      operando1: 30,
      operando2: 30,
      puntos: 10,
    );
    const ej4 = Aritmetico(
      id: 'E4',
      posicion: PosicionCurricular(tema: 1, subtema: 1, leccion: 4),
      nivel: 1,
      enunciado: '40 + 40',
      operacion: OperacionAritmetica.suma,
      operando1: 40,
      operando2: 40,
      puntos: 10,
    );

    final examen75 = ExamenDiagnostico(
      id: 'EXAM-75',
      titulo: 'Diagnóstico Nivel 1',
      descripcion: 'Prueba con umbral del 75%',
      profesorUid: 'profe-1',
      ejercicios: const [ej1, ej2, ej3, ej4],
      criterioAvance: CriterioAvance.porcentajeAciertosMinimo,
      umbralAvance: 0.75, // 75%
      permitirAvanceAutomatico: true,
      temaDestinoAlAvanzar: 'Tema 2: Álgebra',
      fechaCreacion: DateTime.now(),
    );

    test('Verifica avance por porcentaje mínimo: aprueba con 3 de 4 (75%) y reprueba con 2 de 4 (50%)', () {
      // 3 de 4 = 75% -> Cumple
      final resAprobado = examen75.verificarAvance(
        aciertos: 3,
        totalRespondidas: 4,
        puntajeObtenido: 30.0,
      );
      expect(resAprobado.cumple, isTrue);
      expect(resAprobado.puedeAvanzar, isTrue);
      expect(resAprobado.porcentajeLogrado, equals(75.0));
      expect(resAprobado.mensajePedagogico, contains('superando la meta de 75%'));

      // 2 de 4 = 50% -> No cumple
      final resReprobado = examen75.verificarAvance(
        aciertos: 2,
        totalRespondidas: 4,
        puntajeObtenido: 20.0,
      );
      expect(resReprobado.cumple, isFalse);
      expect(resReprobado.puedeAvanzar, isFalse);
      expect(resReprobado.porcentajeLogrado, equals(50.0));
      expect(resReprobado.mensajePedagogico, contains('Necesitas al menos 75%'));
    });

    test('Verifica avance con criterio sinErroresCriticos', () {
      final examenCritico = ExamenDiagnostico(
        id: 'EXAM-CRIT',
        titulo: 'Diagnóstico Riguroso',
        descripcion: 'Requiere 0 errores críticos',
        profesorUid: 'profe-1',
        ejercicios: const [ej1, ej2, ej3, ej4],
        criterioAvance: CriterioAvance.sinErroresCriticos,
        umbralAvance: 0.50,
        fechaCreacion: DateTime.now(),
      );

      // Con 3 aciertos pero 1 error crítico
      final conErrorCritico = examenCritico.verificarAvance(
        aciertos: 3,
        totalRespondidas: 4,
        puntajeObtenido: 30.0,
        errores: const [
          ErrorAprendizaje(
            id: 'ERR-1',
            categoria: CategoriaError.acarreoReagrupacion,
            subtipo: 'grave',
            descripcion: 'Error crítico',
            sugerenciaPedagogica: 'Reforzar',
            severidad: SeveridadError.critica,
          ),
        ],
      );
      expect(conErrorCritico.cumple, isFalse);
      expect(conErrorCritico.puedeAvanzar, isFalse);
      expect(conErrorCritico.erroresCriticosDetectados, equals(1));

      // Con 3 aciertos y errores leves
      final conErrorLeve = examenCritico.verificarAvance(
        aciertos: 3,
        totalRespondidas: 4,
        puntajeObtenido: 30.0,
        errores: const [
          ErrorAprendizaje(
            id: 'ERR-2',
            categoria: CategoriaError.precisionRedondeo,
            subtipo: 'leve',
            descripcion: 'Error menor',
            sugerenciaPedagogica: 'Revisar',
            severidad: SeveridadError.leve,
          ),
        ],
      );
      expect(conErrorLeve.cumple, isTrue);
      expect(conErrorLeve.puedeAvanzar, isTrue);
    });

    test('Verifica criterio de puntaje mínimo fijado por el docente', () {
      final examenPuntaje = ExamenDiagnostico(
        id: 'EXAM-PTS',
        titulo: 'Diagnóstico por Puntos',
        descripcion: 'Requiere 35 puntos',
        profesorUid: 'profe-1',
        ejercicios: const [ej1, ej2, ej3, ej4],
        criterioAvance: CriterioAvance.puntajeTotalMinimo,
        umbralAvance: 35.0,
        fechaCreacion: DateTime.now(),
      );

      final res30 = examenPuntaje.verificarAvance(
        aciertos: 3,
        totalRespondidas: 4,
        puntajeObtenido: 30.0,
      );
      expect(res30.cumple, isFalse);

      final res40 = examenPuntaje.verificarAvance(
        aciertos: 4,
        totalRespondidas: 4,
        puntajeObtenido: 40.0,
      );
      expect(res40.cumple, isTrue);
      expect(res40.puedeAvanzar, isTrue);
    });

    test('Serialización toMap y fromMap de ExamenDiagnostico y ProgresoExamenAlumno', () {
      final mapaExamen = examen75.toMap();
      expect(mapaExamen['criterioAvance'], equals('porcentajeAciertosMinimo'));
      expect(mapaExamen['umbralAvance'], equals(0.75));

      final examenRestaurado = ExamenDiagnostico.fromMap(mapaExamen, ejercicios: [ej1, ej2]);
      expect(examenRestaurado.criterioAvance, equals(CriterioAvance.porcentajeAciertosMinimo));
      expect(examenRestaurado.umbralAvance, equals(0.75));
      expect(examenRestaurado.permitirAvanceAutomatico, isTrue);

      final progreso = ProgresoExamenAlumno(
        id: 'PROG-1',
        examenId: examen75.id,
        alumnoUid: 'alumno-1',
        alumnoNombre: 'Ana',
        respuestasPorEjercicio: {'E1': '20', 'E2': '40'},
        aciertos: 2,
        totalEjercicios: 4,
        puntajeTotal: 20.0,
        estado: EstadoExamenAlumno.enProgreso,
        fechaInicio: DateTime.now(),
      );

      expect(progreso.porcentajeAvance, equals(50.0));
      expect(progreso.porcentajePrecision, equals(50.0));

      final mapaProgreso = progreso.toMap();
      final progresoRestaurado = ProgresoExamenAlumno.fromMap(mapaProgreso);
      expect(progresoRestaurado.alumnoUid, equals('alumno-1'));
      expect(progresoRestaurado.aciertos, equals(2));
      expect(progresoRestaurado.estado, equals(EstadoExamenAlumno.enProgreso));
    });
  });

  group('ExamenDiagnostico - Repositorio e Interfaz', () {
    late FuenteDatosEjercicios repoEjercicios;
    late FuenteDatosDiagnostico repoDiagnostico;
    late ServicioEvaluacion servicioEvaluacion;
    late ServicioAuth servicioAuth;

    setUp(() {
      repoEjercicios = FuenteDatosEjercicios();
      repoDiagnostico = FuenteDatosDiagnostico();
      servicioEvaluacion = ServicioEvaluacion();
      servicioAuth = ServicioAuth(
        usuarioInicial: const UsuarioApp(
          uid: 'alumno-test',
          nombre: 'Alumno Prueba',
          rol: RolUsuario.alumno,
        ),
      );
    });

    testWidgets('Profesor puede abrir el Gestor de Exámenes y ver las variables de avance configuradas', (tester) async {
      const usuarioProfesor = UsuarioApp(
        uid: 'profe-1',
        nombre: 'Prof. Carlos',
        rol: RolUsuario.profesor,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PantallaProfesor(
            usuario: usuarioProfesor,
            repositorio: repoEjercicios,
            repositorioDiagnostico: repoDiagnostico,
            servicioEvaluacion: servicioEvaluacion,
            servicioAuth: servicioAuth,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Abrir gestor de exámenes
      final botonGestor = find.byIcon(Icons.fact_check_outlined);
      expect(botonGestor, findsOneWidget);
      await tester.tap(botonGestor);
      await tester.pumpAndSettle();

      expect(find.textContaining('Gestor de Exámenes Diagnósticos'), findsOneWidget);
      expect(find.textContaining('Variable de Avance Docente:'), findsOneWidget);
      expect(find.textContaining('75% para avanzar'), findsOneWidget);
    });

    testWidgets('Alumno puede ver la meta del profesor y presentar el Examen Diagnóstico', (tester) async {
      const usuarioAlumno = UsuarioApp(
        uid: 'alumno-test',
        nombre: 'Alumno Prueba',
        rol: RolUsuario.alumno,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PantallaAlumno(
            usuario: usuarioAlumno,
            repositorio: repoEjercicios,
            repositorioDiagnostico: repoDiagnostico,
            servicioEvaluacion: servicioEvaluacion,
            servicioAuth: servicioAuth,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Abrir lista de exámenes diagnósticos
      final botonExamen = find.byIcon(Icons.assignment_outlined);
      expect(botonExamen, findsOneWidget);
      await tester.tap(botonExamen);
      await tester.pumpAndSettle();

      expect(find.textContaining('Exámenes Diagnósticos de Nivelación'), findsOneWidget);
      expect(find.textContaining('Meta de Avance fijada por tu profesor:'), findsOneWidget);
      expect(find.textContaining('75% de aciertos mínimos'), findsOneWidget);
    });
  });
}
