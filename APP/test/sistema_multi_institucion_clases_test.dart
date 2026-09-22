import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto/datos/fuente_datos_clases.dart';
import 'package:proyecto/datos/servicio_auth.dart';
import 'package:proyecto/dominio/modelos/clase_escolar.dart';
import 'package:proyecto/dominio/modelos/usuario_app.dart';

void main() {
  group('Soporte Multi-Institución y Multi-Clase para Profesores', () {
    test('UsuarioApp permite pertenecer a múltiples instituciones y alternar la activa', () {
      final profesor = UsuarioApp(
        uid: 'prof-multi-1',
        nombre: 'Prof. Carlos Fuentes',
        rol: RolUsuario.profesor,
        institucionId: 'INST-SAN-MARTIN',
        institucionesIds: const ['INST-SAN-MARTIN', 'INST-BELGRANO'],
      );

      expect(profesor.esProfesor, isTrue);
      expect(profesor.institucionId, equals('INST-SAN-MARTIN'));
      expect(profesor.institucionesIds, containsAll(['INST-SAN-MARTIN', 'INST-BELGRANO']));
      expect(profesor.todasLasInstituciones, containsAll(['INST-SAN-MARTIN', 'INST-BELGRANO']));
      expect(profesor.perteneceAInstitucion('INST-SAN-MARTIN'), isTrue);
      expect(profesor.perteneceAInstitucion('INST-BELGRANO'), isTrue);
      expect(profesor.perteneceAInstitucion('INST-OTRA'), isFalse);

      // Alternar institución activa mediante copyWith
      final profesorActivoBelgrano = profesor.copyWith(institucionId: 'INST-BELGRANO');
      expect(profesorActivoBelgrano.institucionId, equals('INST-BELGRANO'));
      expect(profesorActivoBelgrano.todasLasInstituciones, containsAll(['INST-SAN-MARTIN', 'INST-BELGRANO']));
    });

    test('Serialización de UsuarioApp (toMap y fromMap) preserva múltiples instituciones', () {
      final profesor = UsuarioApp(
        uid: 'prof-multi-2',
        nombre: 'Prof. Laura Méndez',
        rol: RolUsuario.profesor,
        institucionId: 'INST-SAN-MARTIN',
        institucionesIds: const ['INST-SAN-MARTIN', 'INST-BELGRANO', 'INST-SARMIENTO'],
      );

      final map = profesor.toMap();
      expect(map['institucionId'], equals('INST-SAN-MARTIN'));
      expect(map['institucionesIds'], containsAll(['INST-SAN-MARTIN', 'INST-BELGRANO', 'INST-SARMIENTO']));

      final restaurado = UsuarioApp.fromMap(map, 'prof-multi-2');
      expect(restaurado.institucionId, equals('INST-SAN-MARTIN'));
      expect(restaurado.institucionesIds, containsAll(['INST-SAN-MARTIN', 'INST-BELGRANO', 'INST-SARMIENTO']));
      expect(restaurado.perteneceAInstitucion('INST-SARMIENTO'), isTrue);
    });

    test('ClaseEscolar soporta atributo institucionId y serialización completa', () {
      final clase = ClaseEscolar(
        id: 'CLASE-TEST-01',
        codigoAcceso: 'MAT-9999',
        nombre: 'Física y Matemática 4to A',
        gradoGrupo: '4to Medio',
        descripcion: 'Curso experimental',
        profesorUid: 'prof-01',
        profesorNombre: 'Profesor Uno',
        institucionId: 'INST-BELGRANO',
        fechaCreacion: DateTime(2026, 9, 20),
      );

      expect(clase.institucionId, equals('INST-BELGRANO'));

      final map = clase.toMap();
      expect(map['institucionId'], equals('INST-BELGRANO'));

      final restaurada = ClaseEscolar.fromMap(map);
      expect(restaurada.id, equals('CLASE-TEST-01'));
      expect(restaurada.institucionId, equals('INST-BELGRANO'));
    });

    test('FuenteDatosClases gestiona múltiples clases en diferentes instituciones para un mismo profesor', () async {
      final repo = FuenteDatosClases();

      // El profesor demo ya cuenta con clases de muestra en dos instituciones
      final clasesIniciales = await repo.obtenerClasesPorProfesor('profesor-demo');
      expect(clasesIniciales.length, greaterThanOrEqualTo(2));

      final institucionesPresentes = clasesIniciales.map((c) => c.institucionId).toSet();
      expect(institucionesPresentes, contains('INST-SAN-MARTIN'));
      expect(institucionesPresentes, contains('INST-BELGRANO'));

      // El profesor crea una nueva clase en INST-BELGRANO
      final nuevaClaseBelgrano = await repo.crearClase(
        nombre: 'Geometría 2do',
        gradoGrupo: '2° Secundaria',
        descripcion: 'Geometría euclidiana y analítica',
        profesorUid: 'profesor-demo',
        profesorNombre: 'Docente Demo',
        institucionId: 'INST-BELGRANO',
      );
      expect(nuevaClaseBelgrano.institucionId, equals('INST-BELGRANO'));

      // El profesor crea una nueva clase en una tercera institución INST-SARMIENTO
      final nuevaClaseSarmiento = await repo.crearClase(
        nombre: 'Cálculo Avanzado',
        gradoGrupo: '6° Año Técnico',
        descripcion: 'Límites y derivadas',
        profesorUid: 'profesor-demo',
        profesorNombre: 'Docente Demo',
        institucionId: 'INST-SARMIENTO',
      );
      expect(nuevaClaseSarmiento.institucionId, equals('INST-SARMIENTO'));

      // Obtener todas las clases del profesor sin importar institución
      final todasClasesProfesor = await repo.obtenerClasesPorProfesor('profesor-demo');
      expect(todasClasesProfesor.length, greaterThanOrEqualTo(4));
      expect(todasClasesProfesor.map((c) => c.id), contains(nuevaClaseBelgrano.id));
      expect(todasClasesProfesor.map((c) => c.id), contains(nuevaClaseSarmiento.id));

      // Filtrar clases por institución específica
      final clasesBelgrano = await repo.obtenerClasesPorInstitucion('INST-BELGRANO');
      expect(clasesBelgrano.every((c) => c.institucionId == 'INST-BELGRANO'), isTrue);
      expect(clasesBelgrano.map((c) => c.id), contains(nuevaClaseBelgrano.id));

      final clasesSarmiento = await repo.obtenerClasesPorInstitucion('INST-SARMIENTO');
      expect(clasesSarmiento.length, equals(1));
      expect(clasesSarmiento.first.nombre, equals('Cálculo Avanzado'));

      // Filtrar clases por profesor e institución
      final clasesProfesorBelgrano = await repo.obtenerClasesPorProfesorEInstitucion(
        profesorUid: 'profesor-demo',
        institucionId: 'INST-BELGRANO',
      );
      expect(clasesProfesorBelgrano.every((c) => c.profesorUid == 'profesor-demo' && c.institucionId == 'INST-BELGRANO'), isTrue);
    });

    test('ServicioAuth permite alternar institución activa y asociar nuevas instituciones', () async {
      final auth = ServicioAuth();
      final profesor = await auth.loginDemo(RolUsuario.profesor);

      expect(profesor.institucionesIds, containsAll(['INST-SAN-MARTIN', 'INST-BELGRANO']));
      expect(profesor.institucionId, equals('INST-SAN-MARTIN'));

      // Cambiar institución activa a INST-BELGRANO
      await auth.cambiarInstitucionActiva('INST-BELGRANO');
      expect(auth.usuarioActual?.institucionId, equals('INST-BELGRANO'));

      // Agregar una nueva institución
      await auth.agregarInstitucion('INST-SARMIENTO');
      expect(auth.usuarioActual?.institucionesIds, contains('INST-SARMIENTO'));
      expect(auth.usuarioActual?.perteneceAInstitucion('INST-SARMIENTO'), isTrue);

      auth.dispose();
    });

    test('Reglas de Firestore contemplan institucionesIds en función mismaInstitucion', () {
      final file = File('firestore.rules');
      final content = file.readAsStringSync();

      expect(content, contains('function mismaInstitucion('));
      expect(content, contains('datosUsuario().institucionesIds != null && institucionId in datosUsuario().institucionesIds'));
      expect(content, contains('hasAny([\'institucionesIds\'])'));
    });
  });
}
