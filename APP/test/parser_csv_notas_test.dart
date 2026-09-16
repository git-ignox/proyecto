import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Parser CSV Notas', () {
    // Simulamos la lógica implementada en DialogoCargaNotas
    List<Map<String, dynamic>> parsearCsv(
      String texto, {
      required Map<String, String> alumnosClase,
      double notaMaxima = 7.0,
    }) {
      final lineas = texto.split(RegExp(r'\r?\n')).map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
      final List<Map<String, dynamic>> resultados = [];

      for (int i = 0; i < lineas.length; i++) {
        final linea = lineas[i];
        final partes = linea.contains(';')
            ? linea.split(';')
            : linea.contains('\t')
                ? linea.split('\t')
                : linea.split(',');

        final col1 = partes[0].trim();
        if (i == 0) {
          final ultimaCol = partes.last.trim();
          final esNumero = double.tryParse(ultimaCol.replaceAll(',', '.')) != null;
          if (!esNumero && (col1.toLowerCase().contains('id') || col1.toLowerCase().contains('nombre') || col1.toLowerCase().contains('alumno') || col1.toLowerCase().contains('nota'))) {
            continue;
          }
        }

        if (partes.length < 2) continue;

        String uid = '';
        String nombre = '';
        double? nota;

        if (partes.length >= 3) {
          uid = partes[0].trim();
          nombre = partes[1].trim();
          nota = double.tryParse(partes[2].trim().replaceAll(',', '.'));
        } else {
          final posibleNota = double.tryParse(partes[1].trim().replaceAll(',', '.'));
          nota = posibleNota;
          final identificador = partes[0].trim();

          if (alumnosClase.containsKey(identificador)) {
            uid = identificador;
            nombre = alumnosClase[uid] ?? identificador;
          } else {
            final matchUid = alumnosClase.entries
                .cast<MapEntry<String, String>?>()
                .firstWhere(
                  (e) => e != null && e.value.toLowerCase().contains(identificador.toLowerCase()),
                  orElse: () => null,
                )
                ?.key;
            if (matchUid != null) {
              uid = matchUid;
              nombre = alumnosClase[matchUid] ?? identificador;
            } else {
              uid = 'UID-${identificador.hashCode.abs()}';
              nombre = identificador;
            }
          }
        }

        final bool notaValida = nota != null && nota >= 0 && nota <= notaMaxima;

        resultados.add({
          'uid': uid,
          'nombre': nombre,
          'nota': nota,
          'esValido': notaValida,
        });
      }
      return resultados;
    }

    test('Parsea CSV con comas y cabecera estándar', () {
      const csv = '''
Identificador,Nombre,Nota
alumno-1,Sofía Valenzuela,6.8
alumno-2,Mateo Rivas,5.5
''';
      final resultado = parsearCsv(csv, alumnosClase: {
        'alumno-1': 'Sofía Valenzuela',
        'alumno-2': 'Mateo Rivas',
      });

      expect(resultado.length, equals(2));
      expect(resultado[0]['uid'], equals('alumno-1'));
      expect(resultado[0]['nombre'], equals('Sofía Valenzuela'));
      expect(resultado[0]['nota'], equals(6.8));
      expect(resultado[0]['esValido'], isTrue);

      expect(resultado[1]['uid'], equals('alumno-2'));
      expect(resultado[1]['nota'], equals(5.5));
    });

    test('Parsea CSV con punto y coma y decimales con coma', () {
      const csv = '''
alumno-1;Sofía Valenzuela;6,8
alumno-2;Mateo Rivas;4,2
''';
      final resultado = parsearCsv(csv, alumnosClase: {
        'alumno-1': 'Sofía Valenzuela',
        'alumno-2': 'Mateo Rivas',
      });

      expect(resultado.length, equals(2));
      expect(resultado[0]['nota'], equals(6.8));
      expect(resultado[1]['nota'], equals(4.2));
    });

    test('Identifica alumnos por nombre si no se provee UID', () {
      const csv = '''
Camila Soto,6.1
Joaquín Herrera,4.8
''';
      final resultado = parsearCsv(csv, alumnosClase: {
        'uid-camila': 'Camila Soto',
        'uid-joaquin': 'Joaquín Herrera',
      });

      expect(resultado.length, equals(2));
      expect(resultado[0]['uid'], equals('uid-camila'));
      expect(resultado[0]['nota'], equals(6.1));
      expect(resultado[1]['uid'], equals('uid-joaquin'));
      expect(resultado[1]['nota'], equals(4.8));
    });

    test('Detecta notas fuera de rango como inválidas', () {
      const csv = '''
alumno-1,Sofía,9.5
alumno-2,Mateo,-1.0
''';
      final resultado = parsearCsv(csv, alumnosClase: {'alumno-1': 'Sofía'}, notaMaxima: 7.0);

      expect(resultado.length, equals(2));
      expect(resultado[0]['esValido'], isFalse); // 9.5 > 7.0
      expect(resultado[1]['esValido'], isFalse); // -1.0 < 0
    });
  });
}
