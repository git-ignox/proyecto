/// Ejercicio de refuerzo generado específicamente para remediar una brecha detectada.
class EjercicioRemediacion {
  const EjercicioRemediacion({
    required this.id,
    required this.enunciado,
    required this.pista,
    required this.respuestaEsperada,
    required this.explicacionPasoAPaso,
  });

  final String id;
  final String enunciado;
  final String pista;
  final String respuestaEsperada;
  final String explicacionPasoAPaso;
}

/// Plan de refuerzo generado por el Asistente Pedagógico para remediar un tema prioritario.
class PlanRemediacionTema {
  const PlanRemediacionTema({
    required this.tema,
    required this.titulo,
    required this.diagnosticoBrecha,
    required this.explicacionConcepto,
    required this.ejerciciosPractica,
    required this.tipPedagogico,
  });

  final String tema;
  final String titulo;
  final String diagnosticoBrecha;
  final String explicacionConcepto;
  final List<EjercicioRemediacion> ejerciciosPractica;
  final String tipPedagogico;
}

/// Puerto (interfaz) para el servicio de remediación del Asistente Pedagógico.
///
/// Arquitectura Puerto/Adaptador: desacopla la UI del motor de generación.
/// - Implementación actual: determinista (basada en reglas cognitivas, cero latencia, cero costo, sin alucinaciones).
/// - Implementación futura: llamada a Gemini 1.5 Flash vía Firebase AI Logic reemplazando únicamente este adaptador.
abstract class ServicioAsistenteRemediacion {
  PlanRemediacionTema generarPlanRemediacion({
    required String tema,
    String? alumnoNombre,
    double? porcentajeActual,
  });
}

/// Adaptador determinista del Asistente Pedagógico (Motor de Reglas Cognitivas).
///
/// Genera kits de práctica y explicaciones conceptuales precisas y fiables
/// basadas en el tema detectado como brecha, garantizando cero latencia, sin red ni riesgo de alucinaciones.
class ServicioIaRemediacion implements ServicioAsistenteRemediacion {
  const ServicioIaRemediacion();

  @override
  PlanRemediacionTema generarPlanRemediacion({
    required String tema,
    String? alumnoNombre,
    double? porcentajeActual,
  }) {
    final temaNorm = tema.toLowerCase().trim();

    if (temaNorm.contains('geom') || temaNorm.contains('área') || temaNorm.contains('perímetro')) {
      return _planGeometria(alumnoNombre, porcentajeActual);
    } else if (temaNorm.contains('álgeb') || temaNorm.contains('ecuac')) {
      return _planAlgebra(alumnoNombre, porcentajeActual);
    } else if (temaNorm.contains('fracc') || temaNorm.contains('racion')) {
      return _planFracciones(alumnoNombre, porcentajeActual);
    } else if (temaNorm.contains('aritm') || temaNorm.contains('suma') || temaNorm.contains('resta') || temaNorm.contains('multiplic')) {
      return _planAritmetica(alumnoNombre, porcentajeActual);
    } else if (temaNorm.contains('porcent') || temaNorm.contains('proporc')) {
      return _planPorcentajes(alumnoNombre, porcentajeActual);
    }

    return _planGenerico(tema, alumnoNombre, porcentajeActual);
  }

  PlanRemediacionTema _planGeometria(String? alumnoNombre, double? porcentaje) {
    final sujeto = alumnoNombre != null ? 'para $alumnoNombre' : 'para el grupo';
    return PlanRemediacionTema(
      tema: 'Geometría',
      titulo: 'Kit de Remediación: Áreas, Perímetros y Geometría Plana',
      diagnosticoBrecha:
          'La principal dificultad detectada $sujeto es la confusión entre perímetro (longitud del contorno) y área (superficie bidimensional), además de la aplicación correcta de las unidades correspondientes.',
      explicacionConcepto:
          '💡 Regla mnemotécnica:\n'
          '• Perímetro = "La cerca del terreno" (suma de todos los lados, unidades lineales ej. cm, m).\n'
          '• Área = "El pasto que cubre el terreno" (base × altura o fórmula según la figura, unidades cuadradas ej. cm², m²).\n'
          '• En triángulos: Recuerda SIEMPRE dividir por 2 la base × altura.',
      tipPedagogico:
          'Recomendación didáctica: Haz que dibujen la figura y tracen con color rojo el contorno (perímetro) y pinten con amarillo el interior (área) antes de calcular.',
      ejerciciosPractica: const [
        EjercicioRemediacion(
          id: 'REM-GEO-1',
          enunciado: 'Un jardín rectangular mide 8 metros de largo y 5 metros de ancho. ¿Cuál es su perímetro y cuál su área?',
          pista: 'Perímetro: suma los 4 lados (8 + 5 + 8 + 5). Área: multiplica largo por ancho (8 × 5).',
          respuestaEsperada: 'Perímetro = 26 m, Área = 40 m²',
          explicacionPasoAPaso: '1) Perímetro = 2×(8) + 2×(5) = 16 + 10 = 26 m.\n2) Área = 8 × 5 = 40 m².',
        ),
        EjercicioRemediacion(
          id: 'REM-GEO-2',
          enunciado: 'Calcula el área de un triángulo cuya base mide 12 cm y su altura es de 6 cm.',
          pista: 'La fórmula del área del triángulo es (base × altura) ÷ 2.',
          respuestaEsperada: '36 cm²',
          explicacionPasoAPaso: '1) Multiplicar base por altura: 12 × 6 = 72.\n2) Dividir por 2: 72 ÷ 2 = 36 cm².',
        ),
        EjercicioRemediacion(
          id: 'REM-GEO-3',
          enunciado: 'Un cuadrado tiene un perímetro de 32 cm. ¿Cuánto mide cada lado y cuál es su área?',
          pista: 'Un cuadrado tiene 4 lados iguales. Divide 32 entre 4 para obtener el lado.',
          respuestaEsperada: 'Lado = 8 cm, Área = 64 cm²',
          explicacionPasoAPaso: '1) Lado = 32 ÷ 4 = 8 cm.\n2) Área = lado × lado = 8 × 8 = 64 cm².',
        ),
      ],
    );
  }

  PlanRemediacionTema _planAlgebra(String? alumnoNombre, double? porcentaje) {
    final sujeto = alumnoNombre != null ? 'en $alumnoNombre' : 'en la clase';
    return PlanRemediacionTema(
      tema: 'Álgebra',
      titulo: 'Kit de Remediación: Despeje de Ecuaciones Lineales',
      diagnosticoBrecha:
          'Se detectó una brecha $sujeto en el aislamiento de incógnitas, especialmente al aplicar la operación inversa al cruzar el signo igual (cambio de signo en sumas/restas y división en coeficientes multiplicativos).',
      explicacionConcepto:
          '💡 La balanza algebraica:\n'
          'Una ecuación es una balanza en equilibrio. Lo que haces en un lado, debes hacerlo en el otro:\n'
          '• Si suma (+), pasa restando (-).\n'
          '• Si resta (-), pasa sumando (+).\n'
          '• Si multiplica (×), pasa dividiendo (÷).\n'
          '• Objetivo final: Dejar a la "x" completamente sola de un lado.',
      tipPedagogico:
          'Recomendación didáctica: Utilizar el método visual de "cajas tapadas" o balanzas antes de formalizar la regla de signos.',
      ejerciciosPractica: const [
        EjercicioRemediacion(
          id: 'REM-ALG-1',
          enunciado: 'Resuelve la ecuación: 2x + 7 = 19',
          pista: 'Primero resta 7 a ambos lados, luego divide el resultado entre 2.',
          respuestaEsperada: 'x = 6',
          explicacionPasoAPaso: '1) 2x = 19 - 7\n2) 2x = 12\n3) x = 12 / 2\n4) x = 6.',
        ),
        EjercicioRemediacion(
          id: 'REM-ALG-2',
          enunciado: 'Resuelve la ecuación: 3x - 5 = 16',
          pista: 'Suma 5 a 16 para despejar el término con x.',
          respuestaEsperada: 'x = 7',
          explicacionPasoAPaso: '1) 3x = 16 + 5\n2) 3x = 21\n3) x = 21 / 3\n4) x = 7.',
        ),
        EjercicioRemediacion(
          id: 'REM-ALG-3',
          enunciado: 'Despeja la incógnita: 5x = 2x + 18',
          pista: 'Agrupa todos los términos con x en el lado izquierdo restando 2x.',
          respuestaEsperada: 'x = 6',
          explicacionPasoAPaso: '1) 5x - 2x = 18\n2) 3x = 18\n3) x = 18 / 3\n4) x = 6.',
        ),
      ],
    );
  }

  PlanRemediacionTema _planFracciones(String? alumnoNombre, double? porcentaje) {
    return PlanRemediacionTema(
      tema: 'Fracciones',
      titulo: 'Kit de Remediación: Operaciones con Fracciones y Denominadores',
      diagnosticoBrecha:
          'Error frecuente: Sumar numeradores y denominadores directamente en línea recta (ej. 1/2 + 1/3 ≠ 2/5). Falta consolidar el concepto de común denominador.',
      explicacionConcepto:
          '💡 Solo podemos sumar cosas del mismo tamaño:\n'
          '• Para sumar o restar fracciones de distinto denominador, primero busca el Mínimo Común Múltiplo (mcm) o multiplica cruzado (método mariposa).\n'
          '• En multiplicación: Numerador × Numerador y Denominador × Denominador.\n'
          '• En división: Se multiplica por la fracción invertida.',
      tipPedagogico:
          'Usa tiras fraccionarias o círculos de pizza para evidenciar por qué 1/2 + 1/3 no puede ser 2/5.',
      ejerciciosPractica: const [
        EjercicioRemediacion(
          id: 'REM-FRAC-1',
          enunciado: 'Calcula la suma: 1/4 + 2/4',
          pista: 'Como los denominadores son iguales, solo suma los numeradores y mantén el 4.',
          respuestaEsperada: '3/4',
          explicacionPasoAPaso: '1) Numerador: 1 + 2 = 3.\n2) Denominador: 4.\n3) Resultado: 3/4.',
        ),
        EjercicioRemediacion(
          id: 'REM-FRAC-2',
          enunciado: 'Calcula: 1/2 + 1/3',
          pista: 'Convierte ambas a sextos (denominador común 6). 1/2 = 3/6 y 1/3 = 2/6.',
          respuestaEsperada: '5/6',
          explicacionPasoAPaso: '1) Común denominador entre 2 y 3 es 6.\n2) 1/2 = 3/6, 1/3 = 2/6.\n3) 3/6 + 2/6 = 5/6.',
        ),
        EjercicioRemediacion(
          id: 'REM-FRAC-3',
          enunciado: 'Multiplica: 2/3 × 3/5',
          pista: 'Multiplica numeradores (2×3) y denominadores (3×5). Luego simplifica si es posible.',
          respuestaEsperada: '2/5',
          explicacionPasoAPaso: '1) (2 × 3) / (3 × 5) = 6 / 15.\n2) Simplificar dividiendo por 3: 2/5.',
        ),
      ],
    );
  }

  PlanRemediacionTema _planAritmetica(String? alumnoNombre, double? porcentaje) {
    return PlanRemediacionTema(
      tema: 'Aritmética',
      titulo: 'Kit de Remediación: Aritmética y Valor Posicional',
      diagnosticoBrecha:
          'Se identifican fallas en la conservación del acarreo en sumas y en el préstamo por valor posicional en restas con ceros intermedios.',
      explicacionConcepto:
          '💡 Alineación y valor posicional:\n'
          '• Coloca siempre unidades bajo unidades, decenas bajo decenas y centenas bajo centenas.\n'
          '• Si la suma de una columna es 10 o más, anota la unidad abajo y "lleva" la decena arriba a la siguiente columna.',
      tipPedagogico:
          'Pide al alumno marcar el acarreo con un color llamativo arriba de la columna para evitar olvidarlo al sumar.',
      ejerciciosPractica: const [
        EjercicioRemediacion(
          id: 'REM-ARIT-1',
          enunciado: 'Calcula en columna: 358 + 267',
          pista: '8+7=15 (llevas 1). 1+5+6=12 (llevas 1). 1+3+2=6.',
          respuestaEsperada: '625',
          explicacionPasoAPaso: '1) Unidades: 8 + 7 = 15 -> 5 y llevo 1.\n2) Decenas: 1 + 5 + 6 = 12 -> 2 y llevo 1.\n3) Centenas: 1 + 3 + 2 = 6.\nTotal: 625.',
        ),
        EjercicioRemediacion(
          id: 'REM-ARIT-2',
          enunciado: 'Resuelve la resta: 500 - 238',
          pista: 'Pide prestado desde las centenas a través del cero.',
          respuestaEsperada: '262',
          explicacionPasoAPaso: '1) 500 se descompone en 4 centenas, 9 decenas y 10 unidades.\n2) 10 - 8 = 2.\n3) 9 - 3 = 6.\n4) 4 - 2 = 2.\nTotal: 262.',
        ),
        EjercicioRemediacion(
          id: 'REM-ARIT-3',
          enunciado: 'Calcula: 24 × 6',
          pista: 'Multiplica 6 × 4 = 24 (llevas 2), luego 6 × 2 = 12 más los 2 de acarreo.',
          respuestaEsperada: '144',
          explicacionPasoAPaso: '1) 6 × 4 = 24 -> 4 y llevo 2.\n2) 6 × 2 = 12 + 2 = 14.\nTotal: 144.',
        ),
      ],
    );
  }

  PlanRemediacionTema _planPorcentajes(String? alumnoNombre, double? porcentaje) {
    return PlanRemediacionTema(
      tema: 'Porcentajes',
      titulo: 'Kit de Remediación: Cálculo y Aplicación de Porcentajes',
      diagnosticoBrecha:
          'Dificultad para convertir el concepto de porcentaje en su equivalente decimal o fraccionario para realizar operaciones.',
      explicacionConcepto:
          '💡 "Por ciento" significa "de cada 100":\n'
          '• Para calcular el 20% de una cantidad: multiplica por 0.20 (o divide por 5).\n'
          '• Para el 10%: simplemente corre la coma decimal un lugar a la izquierda.\n'
          '• Para el 50%: calcula la mitad de la cantidad.',
      tipPedagogico:
          'Construye porcentajes basados en el 10% de referencia (ej. el 30% es tres veces el 10%).',
      ejerciciosPractica: const [
        EjercicioRemediacion(
          id: 'REM-PCT-1',
          enunciado: 'Calcula el 25% de 80.',
          pista: 'El 25% equivale a la cuarta parte (dividir por 4).',
          respuestaEsperada: '20',
          explicacionPasoAPaso: '1) 25% = 25/100 = 1/4.\n2) 80 ÷ 4 = 20.',
        ),
        EjercicioRemediacion(
          id: 'REM-PCT-2',
          enunciado: 'Un pantalón cuesta \$20.000 y tiene un 15% de descuento. ¿Cuánto dinero se descuenta?',
          pista: 'Multiplica 20.000 por 0.15.',
          respuestaEsperada: '\$3.000 de descuento',
          explicacionPasoAPaso: '1) 10% de 20.000 = 2.000.\n2) 5% de 20.000 = 1.000.\n3) 15% = 2.000 + 1.000 = 3.000.',
        ),
        EjercicioRemediacion(
          id: 'REM-PCT-3',
          enunciado: '¿Qué porcentaje de 200 representa el número 50?',
          pista: 'Divide 50 entre 200 y multiplica por 100.',
          respuestaEsperada: '25%',
          explicacionPasoAPaso: '1) 50 / 200 = 1/4 = 0.25.\n2) 0.25 × 100 = 25%.',
        ),
      ],
    );
  }

  PlanRemediacionTema _planGenerico(String tema, String? alumnoNombre, double? porcentaje) {
    return PlanRemediacionTema(
      tema: tema,
      titulo: 'Kit de Remediación: $tema',
      diagnosticoBrecha:
          'Se detecta una brecha en los fundamentos de $tema (${porcentaje != null ? "$porcentaje% de dominio" : "rendimiento bajo"}). Se requiere afianzar conceptos clave y resolver ejercicios guiados.',
      explicacionConcepto:
          '💡 Estrategia para dominar $tema:\n'
          '1. Releer la definición y propiedades fundamentales.\n'
          '2. Identificar datos conocidos y qué se nos pide encontrar antes de empezar a calcular.\n'
          '3. Comprobar el resultado final volviendo a leer el enunciado.',
      tipPedagogico:
          'Fomentar la verbalización: pídele al estudiante que explique en voz alta qué paso está ejecutando y por qué.',
      ejerciciosPractica: [
        EjercicioRemediacion(
          id: 'REM-GEN-1',
          enunciado: 'Ejercicio 1 de práctica guiada para afianzar $tema.',
          pista: 'Identifica la regla principal de $tema antes de operar.',
          respuestaEsperada: 'Aplicación correcta de la propiedad principal',
          explicacionPasoAPaso: 'Revisar paso 1 y contrastar con la regla conceptual.',
        ),
        EjercicioRemediacion(
          id: 'REM-GEN-2',
          enunciado: 'Ejercicio 2 de aplicación intermedia en $tema.',
          pista: 'Divide el problema en dos sub-pasos más sencillos.',
          respuestaEsperada: 'Solución del problema intermedio',
          explicacionPasoAPaso: 'Ejecutar sub-paso A y luego sub-paso B.',
        ),
      ],
    );
  }
}
