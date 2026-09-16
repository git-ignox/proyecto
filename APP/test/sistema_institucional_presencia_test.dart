import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto/dominio/modelos/politica_dispositivo.dart';
import 'package:proyecto/dominio/modelos/sesion_modo_clase.dart';

void main() {
  group('Regla Fundamental de Presencia (Fase 7)', () {
    test('Alumno presente en el aula SÍ recibe y aplica la política', () {
      final politica = PlantillaPolitica.modoClaseEstandar(
        institucionId: 'INST-SAN-MARTIN',
      );

      final sesion = SesionModoClase(
        id: 'SES-01',
        claseId: 'CLASE-3B',
        cursoNombre: '3° Básico B',
        materia: 'Matemáticas',
        profesorUid: 'prof-1',
        profesorNombre: 'Profesor',
        institucionId: 'INST-SAN-MARTIN',
        horaInicio: DateTime.now(),
        politicaAplicada: politica,
        tokenPresenciaQr: 'token',
        timestampToken: DateTime.now(),
        estudiantesPresentes: {
          'alumno-en-aula': RegistroPresenciaDispositivo(
            alumnoUid: 'alumno-en-aula',
            alumnoNombre: 'Sofía',
            estaPresente: true, // PRESENTE VALIDADO
            momentoRegistro: DateTime.now(),
          ),
        },
      );

      const alumnosInscritos = ['alumno-en-aula', 'alumno-en-casa'];

      // Alumno presente en el aula debe aplicar la política
      final aplicaSofia = sesion.puedeAplicarPoliticaA('alumno-en-aula', alumnosInscritos);
      expect(aplicaSofia, isTrue);
    });

    test('Alumno enfermo en casa (no presente) NUNCA se bloquea aunque esté en horario', () {
      final politica = PlantillaPolitica.modoClaseEstandar(
        institucionId: 'INST-SAN-MARTIN',
      );

      final sesion = SesionModoClase(
        id: 'SES-02',
        claseId: 'CLASE-3B',
        cursoNombre: '3° Básico B',
        materia: 'Matemáticas',
        profesorUid: 'prof-1',
        profesorNombre: 'Profesor',
        institucionId: 'INST-SAN-MARTIN',
        horaInicio: DateTime.now(),
        politicaAplicada: politica,
        tokenPresenciaQr: 'token',
        timestampToken: DateTime.now(),
        estudiantesPresentes: {
          // Joaquín está en su casa enfermo: estaPresente = false
          'alumno-en-casa': RegistroPresenciaDispositivo(
            alumnoUid: 'alumno-en-casa',
            alumnoNombre: 'Joaquín',
            estaPresente: false,
            momentoRegistro: DateTime.now(),
          ),
        },
      );

      const alumnosInscritos = ['alumno-en-casa'];

      // El dispositivo de Joaquín NO debe bloquearse
      final aplicaJoaquin = sesion.puedeAplicarPoliticaA('alumno-en-casa', alumnosInscritos);
      expect(aplicaJoaquin, isFalse);
    });

    test('Alumno liberado individualmente por el docente deja de aplicar la política', () {
      final politica = PlantillaPolitica.modoClaseEstandar(
        institucionId: 'INST-SAN-MARTIN',
      );

      final sesion = SesionModoClase(
        id: 'SES-03',
        claseId: 'CLASE-3B',
        cursoNombre: '3° Básico B',
        materia: 'Matemáticas',
        profesorUid: 'prof-1',
        profesorNombre: 'Profesor',
        institucionId: 'INST-SAN-MARTIN',
        horaInicio: DateTime.now(),
        politicaAplicada: politica,
        tokenPresenciaQr: 'token',
        timestampToken: DateTime.now(),
        estudiantesPresentes: {
          'alumno-liberado': RegistroPresenciaDispositivo(
            alumnoUid: 'alumno-liberado',
            alumnoNombre: 'Mateo',
            estaPresente: true,
            liberadoPorDocente: true, // LIBERADO POR EL PROFESOR
            motivoLiberacion: 'Terminó la actividad anticipadamente',
            momentoRegistro: DateTime.now(),
          ),
        },
      );

      const alumnosInscritos = ['alumno-liberado'];
      final aplicaMateo = sesion.puedeAplicarPoliticaA('alumno-liberado', alumnosInscritos);
      expect(aplicaMateo, isFalse);
    });

    test('Suspensión por Emergencia Institucional anula la aplicación de políticas en todos', () {
      final politica = PlantillaPolitica.modoClaseEstandar(
        institucionId: 'INST-SAN-MARTIN',
      );

      final sesion = SesionModoClase(
        id: 'SES-04',
        claseId: 'CLASE-3B',
        cursoNombre: '3° Básico B',
        materia: 'Matemáticas',
        profesorUid: 'prof-1',
        profesorNombre: 'Profesor',
        institucionId: 'INST-SAN-MARTIN',
        horaInicio: DateTime.now(),
        politicaAplicada: politica,
        tokenPresenciaQr: 'token',
        timestampToken: DateTime.now(),
        restriccionesSuspendidasEmergencia: true, // EMERGENCIA
        estudiantesPresentes: {
          'alumno-presente': RegistroPresenciaDispositivo(
            alumnoUid: 'alumno-presente',
            alumnoNombre: 'Camila',
            estaPresente: true,
            momentoRegistro: DateTime.now(),
          ),
        },
      );

      const alumnosInscritos = ['alumno-presente'];
      final aplicaCamila = sesion.puedeAplicarPoliticaA('alumno-presente', alumnosInscritos);
      expect(aplicaCamila, isFalse);
    });
  });
}
