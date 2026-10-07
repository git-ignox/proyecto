import 'package:flutter/material.dart';
import '../../dominio/modelos/usuario_app.dart';

/// Banner de cabecera motivacional para el estudiante con saludo contextual,
/// nivel de maestría matemática, puntos acumulados y progreso gamificado.
class WidgetHeroAlumno extends StatelessWidget {
  const WidgetHeroAlumno({
    super.key,
    required this.usuario,
    this.precisionGlobal,
    this.onVerDiagnostico,
  });

  final UsuarioApp usuario;
  final double? precisionGlobal;
  final VoidCallback? onVerDiagnostico;

  String _obtenerSaludo() {
    final hora = DateTime.now().hour;
    if (hora < 12) {
      return '¡Buenos días';
    } else if (hora < 19) {
      return '¡Buenas tardes';
    } else {
      return '¡Buenas noches';
    }
  }

  (int nivel, String rango, double progresoNivel, int puntosParaSiguiente) _calcularNivel() {
    final pts = usuario.puntosAcumulados;
    if (pts < 50) {
      return (1, 'Iniciante Numérico 🥉', pts / 50.0, 50 - pts);
    } else if (pts < 150) {
      return (2, 'Explorador Matemático 🥈', (pts - 50) / 100.0, 150 - pts);
    } else if (pts < 300) {
      return (3, 'Estratega del Cálculo 🥇', (pts - 150) / 150.0, 300 - pts);
    } else {
      return (4, 'Maestro Matemático 👑', 1.0, 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final saludo = _obtenerSaludo();
    final nombre = usuario.nombre.isNotEmpty ? usuario.nombre : 'Estudiante';
    final (nivel, rango, progreso, faltantes) = _calcularNivel();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.indigo.shade800,
            Colors.indigo.shade600,
            Colors.deepPurple.shade600,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila superior: Saludo y Puntos
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '$saludo! ',
                          style: TextStyle(
                            color: Colors.indigo.shade100,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Icon(
                          Icons.waving_hand,
                          color: Colors.amberAccent,
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '¡Listo para aprender hoy!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Medalla de Rango o Puntos detallados
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.shade400,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars, color: Colors.indigo, size: 20),
                    const SizedBox(width: 5),
                    Text(
                      '${usuario.puntosAcumulados} EXP',
                      style: const TextStyle(
                        color: Colors.indigo,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Nivel y Rango
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Nivel $nivel',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  rango,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (precisionGlobal != null && onVerDiagnostico != null)
                InkWell(
                  onTap: onVerDiagnostico,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: precisionGlobal! >= 70
                          ? Colors.tealAccent.withValues(alpha: 0.25)
                          : Colors.amberAccent.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.trending_up,
                          size: 14,
                          color: precisionGlobal! >= 70 ? Colors.tealAccent : Colors.amberAccent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${precisionGlobal!.toStringAsFixed(0)}% precisión',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Barra de progreso del nivel
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progreso.clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amberAccent),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                faltantes > 0
                    ? '$faltantes pts para el siguiente nivel'
                    : '¡Nivel máximo alcanzado! 🚀',
                style: TextStyle(
                  color: Colors.indigo.shade100,
                  fontSize: 11,
                ),
              ),
              Text(
                'Institución: ${usuario.institucionId}',
                style: TextStyle(
                  color: Colors.indigo.shade200,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
