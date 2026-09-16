import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto/datos/fuente_datos_politicas.dart';
import 'package:proyecto/dominio/modelos/permiso_institucional.dart';
import 'package:proyecto/dominio/modelos/politica_dispositivo.dart';
import 'package:proyecto/dominio/modelos/usuario_app.dart';

void main() {
  group('Motor de Resolución de Políticas Jerárquicas (Fase 4)', () {
    late FuenteDatosPoliticas repoPoliticas;

    setUp(() {
      repoPoliticas = FuenteDatosPoliticas();
    });

    test('Institución establece política base por defecto (bloqueo de redes y juegos)', () {
      final efectiva = repoPoliticas.resolverPoliticaEfectiva(
        institucionId: 'INST-SAN-MARTIN',
      );

      expect(efectiva.esAppPermitida(PlantillaPolitica.appCalculadora.id), isTrue);
      expect(efectiva.esAppPermitida(PlantillaPolitica.appDiccionario.id), isTrue);
      expect(efectiva.esAppPermitida(PlantillaPolitica.appTikTok.id), isFalse);
      expect(efectiva.esBloqueoCritico(PlantillaPolitica.appTikTok.id), isTrue);
      expect(efectiva.esAppPermitida(PlantillaPolitica.appInstagram.id), isFalse);
      expect(efectiva.esBloqueoCritico(PlantillaPolitica.appInstagram.id), isTrue);
    });

    test('Capa de Materia agrega permisos curriculares esenciales', () {
      // En Matemáticas -> GeoGebra y Calculadora garantizadas
      final efectivaMatematicas = repoPoliticas.resolverPoliticaEfectiva(
        institucionId: 'INST-SAN-MARTIN',
        materia: 'Matemáticas y Álgebra',
      );

      expect(efectivaMatematicas.esAppPermitida(PlantillaPolitica.appCalculadora.id), isTrue);
      expect(efectivaMatematicas.esAppPermitida(PlantillaPolitica.appGeoGebra.id), isTrue);

      // En Lenguaje -> Diccionario garantizado
      final efectivaLengua = repoPoliticas.resolverPoliticaEfectiva(
        institucionId: 'INST-SAN-MARTIN',
        materia: 'Lenguaje y Comunicación',
      );

      expect(efectivaLengua.esAppPermitida(PlantillaPolitica.appDiccionario.id), isTrue);
    });

    test('Profesor común NO puede anular bloqueos críticos institucionales', () async {
      const direccion = UsuarioApp(
        uid: 'dir-admin',
        nombre: 'Directora',
        rol: RolUsuario.direccion,
      );

      const profesorComun = UsuarioApp(
        uid: 'prof-comun',
        nombre: 'Profesor Común',
        rol: RolUsuario.profesor,
        permisosEspecificos: [], // NO tiene omitirPoliticaInstitucional
      );

      // El curso intenta permitir TikTok (lo cual es bloqueo crítico institucional)
      final politicaCurso = PoliticaDispositivo(
        id: 'POL-INTENTO-BYPASS',
        nombre: 'Curso con TikTok',
        descripcion: 'Intento de permitir TikTok',
        institucionId: 'INST-SAN-MARTIN',
        cursoId: 'CURSO-BYPASS',
        jerarquia: NivelJerarquiaPolitica.curso,
        apps: [
          PlantillaPolitica.appTikTok.copyWith(estado: EstadoReglaApp.permitido),
        ],
      );

      // Guardamos la política de curso
      await repoPoliticas.guardarPolitica(politicaCurso, usuario: direccion);

      final efectiva = repoPoliticas.resolverPoliticaEfectiva(
        institucionId: 'INST-SAN-MARTIN',
        cursoId: 'CURSO-BYPASS',
        docente: profesorComun,
      );

      // TikTok DEBE seguir bloqueado porque es bloqueo crítico institucional
      expect(efectiva.esAppPermitida(PlantillaPolitica.appTikTok.id), isFalse);
    });

    test('Profesor con permiso omitirPoliticaInstitucional SÍ puede anular bloqueo crítico si Dirección lo autorizó', () async {
      const direccion = UsuarioApp(
        uid: 'dir-admin',
        nombre: 'Directora',
        rol: RolUsuario.direccion,
      );

      final politicaCurso = PoliticaDispositivo(
        id: 'POL-INTENTO-BYPASS-2',
        nombre: 'Curso con TikTok Autorizado',
        descripcion: 'Taller de Medios Audiovisuales',
        institucionId: 'INST-SAN-MARTIN',
        cursoId: 'CURSO-BYPASS',
        jerarquia: NivelJerarquiaPolitica.curso,
        apps: [
          PlantillaPolitica.appTikTok.copyWith(estado: EstadoReglaApp.permitido),
        ],
      );

      await repoPoliticas.guardarPolitica(politicaCurso, usuario: direccion);

      const profesorSupervisado = UsuarioApp(
        uid: 'prof-autorizado-critico',
        nombre: 'Profesor de Medios Audiovisuales',
        rol: RolUsuario.profesor,
        permisosEspecificos: [PermisoInstitucional.omitirPoliticaInstitucional],
      );

      // Si existe una política de curso específica que lo habilite y el docente tiene el permiso
      final efectiva = repoPoliticas.resolverPoliticaEfectiva(
        institucionId: 'INST-SAN-MARTIN',
        cursoId: 'CURSO-BYPASS',
        docente: profesorSupervisado,
      );

      expect(profesorSupervisado.tienePermiso(PermisoInstitucional.omitirPoliticaInstitucional), isTrue);
      expect(efectiva.esAppPermitida(PlantillaPolitica.appTikTok.id), isTrue);
    });
  });
}
