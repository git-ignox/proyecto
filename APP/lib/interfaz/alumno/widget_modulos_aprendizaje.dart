import 'package:flutter/material.dart';
import '../../dominio/modelos/aritmetico.dart';

/// Selector interactivo de módulos matemáticos para que el estudiante
/// elija qué destreza aritmética o tema practicar hoy.
class WidgetModulosAprendizajeAlumno extends StatelessWidget {
  const WidgetModulosAprendizajeAlumno({
    super.key,
    required this.onIniciarModulo,
  });

  final void Function(OperacionAritmetica op, int nivel) onIniciarModulo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '📚 Rutas de Práctica',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.1,
                ),
              ),
              Text(
                'Elige tu reto',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 140,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _ModuloCard(
                  titulo: 'Suma Vertical',
                  descripcion: 'En columna con acarreo',
                  icono: Icons.add,
                  colorPrimario: Colors.blue.shade700,
                  colorFondo: Colors.blue.shade50,
                  colorBorde: Colors.blue.shade200,
                  nivelTexto: 'Niveles 1-3',
                  onTap: () => onIniciarModulo(OperacionAritmetica.suma, 1),
                ),
                const SizedBox(width: 12),
                _ModuloCard(
                  titulo: 'Resta en Columna',
                  descripcion: 'Reagrupación y llevadas',
                  icono: Icons.remove,
                  colorPrimario: Colors.deepOrange.shade700,
                  colorFondo: Colors.deepOrange.shade50,
                  colorBorde: Colors.deepOrange.shade200,
                  nivelTexto: 'Niveles 1-3',
                  onTap: () => onIniciarModulo(OperacionAritmetica.resta, 1),
                ),
                const SizedBox(width: 12),
                _ModuloCard(
                  titulo: 'Multiplicación',
                  descripcion: 'Tablas y productos parciales',
                  icono: Icons.close,
                  colorPrimario: Colors.purple.shade700,
                  colorFondo: Colors.purple.shade50,
                  colorBorde: Colors.purple.shade200,
                  nivelTexto: 'Niveles 1-3',
                  onTap: () => onIniciarModulo(OperacionAritmetica.multiplicacion, 1),
                ),
                const SizedBox(width: 12),
                _ModuloCard(
                  titulo: 'División Galera',
                  descripcion: 'Cociente y resto paso a paso',
                  icono: Icons.call_split,
                  colorPrimario: Colors.teal.shade700,
                  colorFondo: Colors.teal.shade50,
                  colorBorde: Colors.teal.shade200,
                  nivelTexto: 'Galera tradicional',
                  onTap: () => onIniciarModulo(OperacionAritmetica.division, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuloCard extends StatelessWidget {
  const _ModuloCard({
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.colorPrimario,
    required this.colorFondo,
    required this.colorBorde,
    required this.nivelTexto,
    required this.onTap,
  });

  final String titulo;
  final String descripcion;
  final IconData icono;
  final Color colorPrimario;
  final Color colorFondo;
  final Color colorBorde;
  final String nivelTexto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorBorde, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: colorPrimario.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(icono, color: colorPrimario, size: 20),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          nivelTexto,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: colorPrimario,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: colorPrimario,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      descripcion,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
