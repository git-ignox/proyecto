import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto/datos/fuente_datos_clases.dart';
import 'package:proyecto/datos/fuente_datos_diagnostico.dart';
import 'package:proyecto/datos/fuente_datos_ejercicios.dart';
import 'package:proyecto/datos/servicio_auth.dart';
import 'package:proyecto/dominio/evaluadores/servicio_evaluacion.dart';
import 'package:proyecto/dominio/modelos/aritmetico.dart';
import 'package:proyecto/dominio/modelos/clase_escolar.dart';
import 'package:proyecto/dominio/modelos/examen_diagnostico.dart';
import 'package:proyecto/dominio/modelos/posicion_curricular.dart';
import 'package:proyecto/dominio/modelos/usuario_app.dart';
import 'package:proyecto/interfaz/pantalla_alumno.dart';

void main() {
  late FuenteDatosEjercicios repoEjercicios;
  late FuenteDatosDiagnostico repoDiagnostico;
  late FuenteDatosClases repoClases;
  late ServicioEvaluacion servicioEvaluacion;
  late ServicioAuth servicioAuth;

  const alumnoTest = UsuarioApp(
    uid: 'alu-dashboard-1',
    nombre: 'Valeria López',
    rol: RolUsuario.alumno,
    puntosAcumulados: 120,
    institucionId: 'COLEGIO-CENTRAL',
  );

  setUp(() async {
    repoEjercicios = FuenteDatosEjercicios([
      const Aritmetico(
        id: 'SUM-1.1.1',
        posicion: PosicionCurricular(tema: 1, subtema: 1, leccion: 1),
        nivel: 1,
        enunciado: 'Calcula la suma en columna: 45 + 32',
        operacion: OperacionAritmetica.suma,
        operando1: 45,
        operando2: 32,
        disposicion: DisposicionAritmetica.vertical,
        incognita: ElementoIncognita.resultado,
        tags: ['aritmetica', 'suma', 'sin_acarreo'],
        puntos: 15,
      ),
    ]);

    repoDiagnostico = FuenteDatosDiagnostico();
    repoClases = FuenteDatosClases();
    await repoClases.unirseAClase(
      codigo: 'MAT-101',
      alumnoUid: alumnoTest.uid,
      alumnoNombre: alumnoTest.nombre,
    );

    servicioEvaluacion = ServicioEvaluacion();
    servicioAuth = ServicioAuth(usuarioInicial: alumnoTest);
  });

  testWidgets('PantallaAlumno renderiza el Dashboard principal con todos sus bloques pedagógicos', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PantallaAlumno(
          usuario: alumnoTest,
          repositorio: repoEjercicios,
          repositorioDiagnostico: repoDiagnostico,
          repositorioClases: repoClases,
          servicioEvaluacion: servicioEvaluacion,
          servicioAuth: servicioAuth,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Cabecera y AppBar
    expect(find.text('Valeria López'), findsOneWidget);
    expect(find.text('120 pts'), findsOneWidget);
    expect(find.text('120 EXP'), findsOneWidget);
    expect(find.text('Nivel 2'), findsOneWidget);

    // 2. Acciones Rápidas
    expect(find.text('⚡ Acciones Rápidas'), findsOneWidget);
    expect(find.text('Mis Clases'), findsAtLeastNWidgets(1));
    expect(find.text('Exámenes'), findsAtLeastNWidgets(1));
    expect(find.text('Mis Notas'), findsOneWidget);
    expect(find.text('Mi Diagnóstico'), findsAtLeastNWidgets(1));
    expect(find.text('Materiales sin Conexión (Offline)'), findsOneWidget);

    // 3. Reto Matemático de Hoy
    expect(find.textContaining('Reto Matemático de Hoy'), findsOneWidget);
    expect(find.text('Calcula la suma en columna: 45 + 32'), findsOneWidget);
    expect(find.text('CALIFICAR RESPUESTA'), findsOneWidget);

    // 4. Módulos Temáticos de Aprendizaje
    expect(find.text('📚 Rutas de Práctica'), findsOneWidget);
    expect(find.text('Suma Vertical'), findsOneWidget);
    expect(find.text('Resta en Columna'), findsOneWidget);
    expect(find.text('Multiplicación'), findsOneWidget);
    expect(find.text('División Galera'), findsOneWidget);

    // 5. Barra de Navegación Inferior
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Práctica'), findsOneWidget);
    expect(find.text('Evaluaciones'), findsOneWidget);
    expect(find.text('Diagnóstico'), findsOneWidget);

    // 6. Navegar a la pestaña 'Mis Clases'
    final tabMisClases = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Mis Clases'),
    );
    await tester.tap(tabMisClases);
    await tester.pumpAndSettle();

    expect(find.text('🏫 Mis Clases Inscritas'), findsOneWidget);
    expect(find.text('Matemáticas 5to Grado A'), findsOneWidget);
    expect(find.text('Profesor: Docente Demo'), findsOneWidget);

    // 7. Navegar a la pestaña 'Evaluaciones'
    final tabEvaluaciones = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Evaluaciones'),
    );
    await tester.tap(tabEvaluaciones);
    await tester.pumpAndSettle();

    expect(find.text('Boletín de Calificaciones'), findsOneWidget);
    expect(find.text('📝 Exámenes Diagnósticos de Nivelación'), findsOneWidget);

    // 8. Navegar a la pestaña 'Diagnóstico'
    final tabDiagnostico = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Diagnóstico'),
    );
    await tester.tap(tabDiagnostico);
    await tester.pumpAndSettle();

    expect(find.text('Mi Diagnóstico Pedagógico'), findsOneWidget);
    expect(find.text('Precisión Global'), findsOneWidget);
    expect(find.text('Intentos Totales'), findsOneWidget);
    expect(find.text('Errores Detectados'), findsOneWidget);
  });
}
