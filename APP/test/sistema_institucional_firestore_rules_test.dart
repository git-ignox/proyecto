import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Auditoría y Validación de Reglas de Seguridad de Firestore', () {
    late String rulesContent;

    setUpAll(() {
      final file = File('firestore.rules');
      expect(file.existsSync(), isTrue, reason: 'El archivo firestore.rules debe existir en la raíz de APP');
      rulesContent = file.readAsStringSync();
    });

    test('Reglas especifican rules_version = 2 y bloque de servicio cloud.firestore', () {
      expect(rulesContent, contains("rules_version = '2';"));
      expect(rulesContent, contains("service cloud.firestore"));
      expect(rulesContent, contains("match /databases/{database}/documents"));
    });

    test('Define funciones de autenticación y verificación de roles institucionales', () {
      expect(rulesContent, contains('function estaAutenticado()'));
      expect(rulesContent, contains('function esDireccion()'));
      expect(rulesContent, contains('function esProfesor()'));
      expect(rulesContent, contains('function esAlumno()'));
      expect(rulesContent, contains('function tienePermiso('));
      expect(rulesContent, contains('function mismaInstitucion('));
    });

    test('Colección usuarios previene auto-asignación y escalamiento de rol no autorizado', () {
      expect(rulesContent, contains('match /usuarios/{userId}'));
      // No permite auto-asignarse rol dirección en creación
      expect(rulesContent, contains("request.resource.data.rol != 'direccion' || esDireccion()"));
      // Protege claves sensibles de edición por usuarios comunes
      expect(rulesContent, contains("hasAny(['rol', 'permisosEspecificos', 'institucionId'])"));
      expect(rulesContent, contains('allow delete: if esDireccion();'));
    });

    test('Colección politicas_dispositivos restringe escritura exclusivamente a Dirección o administradores', () {
      expect(rulesContent, contains('match /politicas_dispositivos/{politicaId}'));
      expect(rulesContent, contains("esDireccion() || tienePermiso('administrar_institucion')"));
    });

    test('Colección sesiones_modo_clase protege activación y permite a alumnos actualizar solo su presencia', () {
      expect(rulesContent, contains('match /sesiones_modo_clase/{sesionId}'));
      // Iniciar sesión requiere permiso de examen o modo clase
      expect(rulesContent, contains("tienePermiso('activar_modo_examen')"));
      expect(rulesContent, contains("tienePermiso('activar_modo_clase')"));
      // Alumno solo puede tocar estudiantesPresentes[request.auth.uid]
      expect(rulesContent, contains("affectedKeys().hasOnly(['estudiantesPresentes'])"));
      expect(rulesContent, contains("affectedKeys().hasOnly([request.auth.uid])"));
    });

    test('Colección auditoria_institucional es ESTRICTAMENTE INMUTABLE (append-only)', () {
      expect(rulesContent, contains('match /auditoria_institucional/{eventoId}'));
      // Modificación y borrado denegados
      expect(rulesContent, contains('allow update: if false;'));
      expect(rulesContent, contains('allow delete: if false;'));
      // Solo dirección puede leer la bitácora
      expect(rulesContent, contains('allow read: if esDireccion();'));
    });
  });
}
