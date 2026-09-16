import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto/dominio/analisis/servicio_ia_remediacion.dart';

void main() {
  group('ServicioIaRemediacion', () {
    const servicio = ServicioIaRemediacion();

    test('Genera plan pedagógico de remediación para Geometría con ejercicios guiados', () {
      final plan = servicio.generarPlanRemediacion(
        tema: 'Geometría',
        alumnoNombre: 'Sofía',
        porcentajeActual: 45.7,
      );

      expect(plan.tema, equals('Geometría'));
      expect(plan.diagnosticoBrecha, contains('perímetro'));
      expect(plan.diagnosticoBrecha, contains('área'));
      expect(plan.explicacionConcepto, contains('Regla mnemotécnica'));
      expect(plan.ejerciciosPractica.length, greaterThanOrEqualTo(3));

      // Comprobar que los ejercicios tengan enunciado, pista y paso a paso
      for (final ej in plan.ejerciciosPractica) {
        expect(ej.enunciado.isNotEmpty, isTrue);
        expect(ej.pista.isNotEmpty, isTrue);
        expect(ej.respuestaEsperada.isNotEmpty, isTrue);
        expect(ej.explicacionPasoAPaso.isNotEmpty, isTrue);
      }
    });

    test('Genera plan pedagógico de remediación para Álgebra', () {
      final plan = servicio.generarPlanRemediacion(
        tema: 'Álgebra y Ecuaciones',
        porcentajeActual: 52.0,
      );

      expect(plan.tema, equals('Álgebra'));
      expect(plan.explicacionConcepto, contains('balanza'));
      expect(plan.ejerciciosPractica.length, equals(3));
    });

    test('Genera plan pedagógico de remediación para Fracciones', () {
      final plan = servicio.generarPlanRemediacion(
        tema: 'Fracciones',
        porcentajeActual: 40.0,
      );

      expect(plan.tema, equals('Fracciones'));
      expect(plan.diagnosticoBrecha, contains('denominador'));
      expect(plan.ejerciciosPractica.length, equals(3));
    });
  });
}
