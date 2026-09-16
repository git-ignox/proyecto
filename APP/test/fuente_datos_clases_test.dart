import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto/datos/fuente_datos_clases.dart';

void main() {
  group('FuenteDatosClases (Gestión de Alumnos y Clases)', () {
    late FuenteDatosClases repo;

    setUp(() {
      repo = FuenteDatosClases();
    });

    test('Inscribir alumno directo genera UID manual y lo agrega al curso', () async {
      final claseActualizada = await repo.inscribirAlumnoDirecto(
        claseId: 'CLASE-DEMO-001',
        alumnoNombre: 'Benjamín Morales',
      );

      expect(claseActualizada, isNotNull);
      expect(claseActualizada!.nombresAlumnos.values, contains('Benjamín Morales'));

      // Verificar que el UID generado tiene el formato manual
      final uid = claseActualizada.nombresAlumnos.entries
          .firstWhere((e) => e.value == 'Benjamín Morales')
          .key;
      expect(uid.startsWith('manual-'), isTrue);
      expect(claseActualizada.alumnosUids, contains(uid));
      expect(claseActualizada.alumnoEstaInscrito(uid), isTrue);
    });

    test('Inscribir alumno con UID explícito preserva dicho UID', () async {
      final claseActualizada = await repo.inscribirAlumnoDirecto(
        claseId: 'CLASE-DEMO-001',
        alumnoNombre: 'Lucía Fernández',
        alumnoUid: 'alumno-uid-lucia',
      );

      expect(claseActualizada, isNotNull);
      expect(claseActualizada!.alumnosUids, contains('alumno-uid-lucia'));
      expect(claseActualizada.nombresAlumnos['alumno-uid-lucia'], equals('Lucía Fernández'));
    });

    test('Inscribir alumno ya existente no duplica su registro', () async {
      // Inscribir por primera vez
      await repo.inscribirAlumnoDirecto(
        claseId: 'CLASE-DEMO-001',
        alumnoNombre: 'Estudiante Prueba',
        alumnoUid: 'uid-prueba-1',
      );

      // Inscribir de nuevo con el mismo UID
      final claseReintentada = await repo.inscribirAlumnoDirecto(
        claseId: 'CLASE-DEMO-001',
        alumnoNombre: 'Estudiante Prueba',
        alumnoUid: 'uid-prueba-1',
      );

      final totalOcurrencias = claseReintentada!.alumnosUids.where((u) => u == 'uid-prueba-1').length;
      expect(totalOcurrencias, equals(1));
    });

    test('Actualizar nombre de alumno modifica nombresAlumnos en la clase', () async {
      // En la demo existe 'alumno-demo-1': 'Sofía Valenzuela'
      final claseModificada = await repo.actualizarNombreAlumno(
        claseId: 'CLASE-DEMO-001',
        alumnoUid: 'alumno-demo-1',
        nuevoNombre: 'Sofía Valenzuela Silva',
      );

      expect(claseModificada, isNotNull);
      expect(claseModificada!.nombresAlumnos['alumno-demo-1'], equals('Sofía Valenzuela Silva'));

      // Verificar persistencia en memoria
      final recuperada = await repo.obtenerClasePorId('CLASE-DEMO-001');
      expect(recuperada?.nombresAlumnos['alumno-demo-1'], equals('Sofía Valenzuela Silva'));
    });

    test('Actualizar nombre de un alumno no registrado no altera la clase', () async {
      final clase = await repo.actualizarNombreAlumno(
        claseId: 'CLASE-DEMO-001',
        alumnoUid: 'uid-inexistente',
        nuevoNombre: 'Fantasma',
      );

      expect(clase, isNotNull);
      expect(clase!.nombresAlumnos.containsKey('uid-inexistente'), isFalse);
    });

    test('Desinscribir alumno elimina su UID y su nombre de la clase', () async {
      // Desinscribir a Mateo Rivas ('alumno-demo-2')
      await repo.salirDeClase(claseId: 'CLASE-DEMO-001', alumnoUid: 'alumno-demo-2');

      final recuperada = await repo.obtenerClasePorId('CLASE-DEMO-001');
      expect(recuperada, isNotNull);
      expect(recuperada!.alumnosUids, isNot(contains('alumno-demo-2')));
      expect(recuperada.nombresAlumnos.containsKey('alumno-demo-2'), isFalse);
      expect(recuperada.alumnoEstaInscrito('alumno-demo-2'), isFalse);
    });
  });
}
