import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../dominio/modelos/usuario_app.dart';
import '../design/app_colors.dart';

/// Banner de cabecera motivacional para el estudiante con estética de Claude.
/// Paleta cálida terracota (#D97757), tipografía editorial y gamificación positiva.
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
    final (nivel, rango, progreso, faltantes) = _calcularNivel();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFC15F3C), // Terracota profundo Claude
            AppColors.claudeTerracota, // Crail Orange #D97757
            Color(0xFFE28B6E), // Terracota luminoso
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x33FFFFFF), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22D97757),
            blurRadius: 16,
            offset: Offset(0, 6),
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
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFFBECE7),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Icon(
                          Icons.waving_hand,
                          color: AppColors.claudeAmbar,
                          size: 15,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '¡Listo para aprender hoy!',
                      style: GoogleFonts.lora(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Medalla de Puntos EXP estilo pill de Claude
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.claudeFondo,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0x33FFFFFF)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars, color: AppColors.claudeAmbar, size: 18),
                    const SizedBox(width: 5),
                    Text(
                      '${usuario.puntosAcumulados} EXP',
                      style: GoogleFonts.poppins(
                        color: AppColors.claudeTextoPrincipal,
                        fontWeight: FontWeight.w700,
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
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Nivel $nivel',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  rango,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
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
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.trending_up,
                          size: 14,
                          color: AppColors.claudeFondo,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${precisionGlobal!.toStringAsFixed(0)}% precisión',
                          style: GoogleFonts.poppins(
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
          const SizedBox(height: 10),

          // Barra de progreso del nivel
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progreso.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.claudeFondo),
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
                style: GoogleFonts.poppins(
                  color: const Color(0xFFFBECE7),
                  fontSize: 11,
                ),
              ),
              Text(
                'Institución: ${usuario.institucionId}',
                style: GoogleFonts.poppins(
                  color: const Color(0xFFFBECE7),
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
