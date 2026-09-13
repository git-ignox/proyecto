import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto/datos/fuente_datos_ejercicios.dart';
import 'package:proyecto/dominio/modelos/numerico.dart';
import 'package:proyecto/dominio/modelos/posicion_curricular.dart';
import 'package:proyecto/dominio/modelos/seleccion_multiple.dart';
import 'package:proyecto/dominio/organizacion/organizador_ejercicios.dart';

void main() {
  const e1 = SeleccionMultiple(
    id: '1',
    posicion: PosicionCurricular(tema: 1, subtema: 1, leccion: 1),
    nivel: 1,
    enunciado: 'E1',
    opciones: [],
  );
  const e2 = Numerico(
    id: '2',
    posicion: PosicionCurricular(tema: 2, subtema: 1, leccion: 3),
    nivel: 2,
    enunciado: 'E2',
    valorEsperado: 5.0,
  );
  const e3 = Numerico(
    id: '3',
    posicion: PosicionCurricular(tema: 2, subtema: 2, leccion: 1),
    nivel: 2,
    enunciado: 'E3',
    valorEsperado: 10.0,
  );
  const e4 = Numerico(
    id: '4',
    posicion: PosicionCurricular(tema: 3, subtema: 2, leccion: 1),
    nivel: 3,
    enunciado: 'E4',
    valorEsperado: 20.0,
  );

  group('PosicionCurricular (3 Parámetros Numéricos)', () {
    test('construye y genera código correcto', () {
      const pos = PosicionCurricular(tema: 3, subtema: 2, leccion: 1);
      expect(pos.tema, equals(3));
      expect(pos.subtema, equals(2));
      expect(pos.leccion, equals(1));
      expect(pos.codigo, equals('3.2.1'));
    });

    test('parsea desde formato String "3.2.1"', () {
      final pos = PosicionCurricular.desdeCodigo('3.2.1');
      expect(pos.tema, equals(3));
      expect(pos.subtema, equals(2));
      expect(pos.leccion, equals(1));
    });

    test('compara y ordena por tema -> subtema -> leccion', () {
      const p1 = PosicionCurricular(tema: 1, subtema: 1, leccion: 1);
      const p2 = PosicionCurricular(tema: 1, subtema: 2, leccion: 1);
      const p3 = PosicionCurricular(tema: 2, subtema: 1, leccion: 3);
      const p4 = PosicionCurricular(tema: 3, subtema: 2, leccion: 1);

      final lista = [p4, p2, p1, p3]..sort();

      expect(lista, equals([p1, p2, p3, p4]));
    });

    test('evalúa coincidencias jerárquicas', () {
      const pos = PosicionCurricular(tema: 3, subtema: 2, leccion: 1);
      expect(pos.coincideConTema(3), isTrue);
      expect(pos.coincideConTema(2), isFalse);
      expect(pos.coincideConSubtema(3, 2), isTrue);
      expect(pos.coincideConSubtema(3, 1), isFalse);
      expect(pos.coincideConLeccion(3, 2, 1), isTrue);
    });
  });

  group('OrganizadorEjercicios', () {
    final organizador = OrganizadorEjercicios([e4, e2, e1, e3]);

    test('ordena los ejercicios automáticamente al crearse', () {
      final ordenados = organizador.ejerciciosOrdenados;
      expect(ordenados.map((e) => e.codigoTema).toList(), equals(['1.1.1', '2.1.3', '2.2.1', '3.2.1']));
    });

    test('obtiene la lista de temas únicos', () {
      expect(organizador.obtenerTemas(), equals([1, 2, 3]));
    });

    test('obtiene subtemas de un tema específico', () {
      expect(organizador.obtenerSubtemas(2), equals([1, 2]));
    });

    test('obtiene lecciones de un subtema', () {
      expect(organizador.obtenerLecciones(2, 1), equals([3]));
      expect(organizador.obtenerLecciones(2, 2), equals([1]));
    });

    test('filtra por tema, subtema y lección', () {
      expect(organizador.filtrarPorTema(2).length, equals(2));
      expect(organizador.filtrarPorSubtema(2, 1).length, equals(1));
      expect(organizador.filtrarPorLeccion(3, 2, 1).first.id, equals('4'));
    });

    test('navegación secuencial siguiente y anterior', () {
      expect(organizador.obtenerSiguiente(e1)?.id, equals('2'));
      expect(organizador.obtenerSiguiente(e4), isNull);
      expect(organizador.obtenerAnterior(e2)?.id, equals('1'));
      expect(organizador.obtenerAnterior(e1), isNull);
    });

    test('genera árbol curricular completo', () {
      final arbol = organizador.obtenerArbolCurricular();
      expect(arbol[1]?[1], equals([1]));
      expect(arbol[2]?[1], equals([3]));
      expect(arbol[2]?[2], equals([1]));
      expect(arbol[3]?[2], equals([1]));
    });
  });

  group('FuenteDatosEjercicios (Consultas y Modificaciones Dinámicas)', () {
    final repo = FuenteDatosEjercicios([e1, e2, e3, e4]);

    test('filtra por tema numérico a través del repositorio', () async {
      final tema2 = await repo.obtenerPorTema(2);
      expect(tema2.length, equals(2));
      expect(tema2.every((e) => e.tema == 2), isTrue);
    });

    test('filtra por subtema', () async {
      final subtema = await repo.obtenerPorSubtema(3, 2);
      expect(subtema.length, equals(1));
      expect(subtema.first.posicion.codigo, equals('3.2.1'));
    });

    test('obtiene por lección exacta', () async {
      final leccion = await repo.obtenerPorLeccion(1, 1, 1);
      expect(leccion.length, equals(1));
      expect(leccion.first.id, equals('1'));
    });

    test('agrega y elimina ejercicios dinámicamente', () async {
      const nuevo = Numerico(
        id: '99',
        posicion: PosicionCurricular(tema: 4, subtema: 1, leccion: 1),
        nivel: 1,
        enunciado: 'E99',
        valorEsperado: 99.0,
      );

      await repo.agregarEjercicio(nuevo);
      final todos = await repo.obtenerTodos();
      expect(todos.any((e) => e.id == '99'), isTrue);

      await repo.eliminarEjercicio('99');
      final despues = await repo.obtenerTodos();
      expect(despues.any((e) => e.id == '99'), isFalse);
    });
  });
}
