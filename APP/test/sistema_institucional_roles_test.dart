import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto/datos/fuente_datos_ejercicios.dart';
import 'package:proyecto/datos/servicio_auth.dart';
import 'package:proyecto/dominio/evaluadores/servicio_evaluacion.dart';
import 'package:proyecto/dominio/modelos/permiso_institucional.dart';
import 'package:proyecto/dominio/modelos/usuario_app.dart';
import 'package:proyecto/interfaz/direccion/pantalla_direccion.dart';
import 'package:proyecto/interfaz/pantalla_alumno.dart';
import 'package:proyecto/interfaz/pantalla_profesor.dart';
import 'package:proyecto/main.dart';

void main() {
  group('Roles y Enrutamiento Institucional', () {
    test('Modelo UsuarioApp soporta RolUsuario.direccion y atributos institucionales', () {
      const direccion = UsuarioApp(
        uid: 'dir-100',
        email: 'directora@sanmartin.edu',
        nombre: 'Dra. Alicia Moreau',
        rol: RolUsuario.direccion,
        institucionId: 'INST-SAN-MARTIN',
        permisosEspecificos: [PermisoInstitucional.administrarInstitucion],
      );

      expect(direccion.esDireccion, isTrue);
      expect(direccion.esProfesor, isFalse);
      expect(direccion.esAlumno, isFalse);
      expect(direccion.institucionId, equals('INST-SAN-MARTIN'));
      expect(direccion.tienePermiso(PermisoInstitucional.administrarInstitucion), isTrue);
      expect(direccion.tienePermiso(PermisoInstitucional.activarModoExamen), isTrue); // Dirección tiene todos
    });

    test('Serialización toMap y fromMap preserva RolUsuario.direccion e institucionId', () {
      const original = UsuarioApp(
        uid: 'dir-101',
        email: 'admin@colegio.edu',
        nombre: 'Director General',
        rol: RolUsuario.direccion,
        institucionId: 'INST-MODELO-01',
        permisosEspecificos: ['activar_modo_examen', 'suspender_emergencia'],
      );

      final map = original.toMap();
      final restaurado = UsuarioApp.fromMap(map, 'dir-101');

      expect(restaurado.uid, equals('dir-101'));
      expect(restaurado.rol, equals(RolUsuario.direccion));
      expect(restaurado.esDireccion, isTrue);
      expect(restaurado.institucionId, equals('INST-MODELO-01'));
      expect(restaurado.permisosEspecificos, contains('suspender_emergencia'));
    });

    testWidgets('AppMatematicas enruta a PantallaDireccion cuando el usuario tiene rol direccion',
        (WidgetTester tester) async {
      const usuarioDireccion = UsuarioApp(
        uid: 'dir-demo',
        nombre: 'Directora Demo',
        rol: RolUsuario.direccion,
        institucionId: 'INST-SAN-MARTIN',
      );

      final auth = ServicioAuth(usuarioInicial: usuarioDireccion);
      final repositorio = FuenteDatosEjercicios();
      final servicioEvaluacion = ServicioEvaluacion();

      await tester.pumpWidget(AppMatematicas(
        repositorio: repositorio,
        servicioEvaluacion: servicioEvaluacion,
        servicioAuth: auth,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(PantallaDireccion), findsOneWidget);
      expect(find.text('Panel de Dirección — Directora Demo'), findsOneWidget);
    });

    testWidgets('AppMatematicas enruta a PantallaProfesor cuando el usuario es profesor',
        (WidgetTester tester) async {
      const usuarioProfesor = UsuarioApp(
        uid: 'prof-demo',
        nombre: 'Prof. Mario',
        rol: RolUsuario.profesor,
        institucionId: 'INST-SAN-MARTIN',
      );

      final auth = ServicioAuth(usuarioInicial: usuarioProfesor);
      final repositorio = FuenteDatosEjercicios();
      final servicioEvaluacion = ServicioEvaluacion();

      await tester.pumpWidget(AppMatematicas(
        repositorio: repositorio,
        servicioEvaluacion: servicioEvaluacion,
        servicioAuth: auth,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(PantallaProfesor), findsOneWidget);
      expect(find.text('Docente: Prof. Mario'), findsOneWidget);
    });

    testWidgets('AppMatematicas enruta a PantallaAlumno cuando el usuario es alumno',
        (WidgetTester tester) async {
      const usuarioAlumno = UsuarioApp(
        uid: 'alu-demo',
        nombre: 'Alumno Lucas',
        rol: RolUsuario.alumno,
        institucionId: 'INST-SAN-MARTIN',
      );

      final auth = ServicioAuth(usuarioInicial: usuarioAlumno);
      final repositorio = FuenteDatosEjercicios();
      final servicioEvaluacion = ServicioEvaluacion();

      await tester.pumpWidget(AppMatematicas(
        repositorio: repositorio,
        servicioEvaluacion: servicioEvaluacion,
        servicioAuth: auth,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(PantallaAlumno), findsOneWidget);
      expect(find.text('Alumno Lucas'), findsOneWidget);
    });
  });
}
