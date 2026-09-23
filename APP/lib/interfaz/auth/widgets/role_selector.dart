// ============================================================
// role_selector.dart — Selector de rol (Alumno/Profesor/Dirección)
//
// Apariencia:
//   • 3 chips pill con icono + etiqueta
//   • Seleccionado: fondo naranja #DB4406, texto crema
//   • No seleccionado: borde crema 30%, fondo glass tenue, texto crema 70%
//   • Transición animada entre estados (AnimatedContainer 200ms)
//   • En móvil: Wrap (fluye a 2 líneas si es necesario)
//   • En desktop: Row (siempre en una línea)
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../dominio/modelos/usuario_app.dart';
import '../../design/app_colors.dart';

/// Selector de rol para el formulario de registro.
///
/// Emite [onChanged] con el [RolUsuario] seleccionado al tocar un chip.
class RoleSelector extends StatelessWidget {
  const RoleSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final RolUsuario selected;
  final void Function(RolUsuario) onChanged;

  static const _roles = [
    _RoleOption(rol: RolUsuario.alumno, emoji: '🎒', label: 'Alumno'),
    _RoleOption(rol: RolUsuario.profesor, emoji: '👨‍🏫', label: 'Profesor'),
    _RoleOption(rol: RolUsuario.direccion, emoji: '🏛️', label: 'Dirección'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Soy...',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.crema.withAlpha(178),
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        // Wrap: fluye a múltiples líneas en pantallas estrechas
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _roles
              .map((option) => _RoleChip(
                    option: option,
                    isSelected: selected == option.rol,
                    onTap: () => onChanged(option.rol),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final _RoleOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50), // pill
          color: isSelected
              ? AppColors.naranja
              : AppColors.crema.withAlpha(15), // glass tenue
          border: Border.all(
            color: isSelected
                ? AppColors.naranja
                : AppColors.crema.withAlpha(77), // crema 30%
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.glowNaranja.withAlpha(100),
                    blurRadius: 12,
                    offset: Offset.zero,
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(option.emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              option.label,
              style: GoogleFonts.plusJakartaSans(
                color: isSelected
                    ? AppColors.crema
                    : AppColors.crema.withAlpha(178),
                fontSize: 13,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleOption {
  const _RoleOption({
    required this.rol,
    required this.emoji,
    required this.label,
  });

  final RolUsuario rol;
  final String emoji;
  final String label;
}
