import 'dart:async';
import '../dominio/modelos/curriculo.dart';
import 'repositorio_curriculo.dart';

/// Implementación en memoria con persistencia de sesión y plantillas curriculares predeterminadas.
class FuenteDatosCurriculo implements RepositorioCurriculo {
  FuenteDatosCurriculo() {
    _inicializarCurriculosDemo();
  }

  final Map<String, PlanCurricular> _planes = {};
  final Map<String, String> _asignacionesClase = {}; // claseId -> planId

  void _inicializarCurriculosDemo() {
    // Plan Oficial Sembrado: Matemática 8vo Básico (3 Unidades, 9 Objetivos)
    final planMat8vo = PlanCurricular(
      id: 'plan-mat-8vo',
      nombre: 'Matemática 8vo Básico (Currículo Nacional)',
      area: 'Matemática',
      nivelGrado: '8vo Básico',
      descripcion: 'Bases curriculares y estándares de aprendizaje para 8vo año de educación básica.',
      fechaCreacion: DateTime(2026, 3, 1),
      unidades: [
        const UnidadCurricular(
          id: 'uni-mat-01',
          planCurricularId: 'plan-mat-8vo',
          numero: 1,
          nombre: 'Unidad 1: Números y Operaciones',
          periodoSugerido: 'Trimestre 1',
          descripcion: 'Propiedades numéricas, cálculo aritmético y potencias de base entera.',
          objetivos: [
            ObjetivoAprendizaje(
              id: 'oa-mat-01',
              unidadId: 'uni-mat-01',
              codigo: 'OA-01',
              nombre: 'Operaciones con enteros y racionales',
              descripcion: 'Multiplicar y dividir números enteros y racionales positivos y negativos.',
              orden: 1,
            ),
            ObjetivoAprendizaje(
              id: 'oa-mat-02',
              unidadId: 'uni-mat-01',
              codigo: 'OA-02',
              nombre: 'Potencias de base y exponente entero',
              descripcion: 'Explicar la multiplicación y división de potencias de base entera.',
              orden: 2,
            ),
            ObjetivoAprendizaje(
              id: 'oa-mat-03',
              unidadId: 'uni-mat-01',
              codigo: 'OA-03',
              nombre: 'Raíces cuadradas exactas y estimación',
              descripcion: 'Calcular raíces cuadradas exactas y estimar no exactas de forma pictórica.',
              orden: 3,
            ),
          ],
        ),
        const UnidadCurricular(
          id: 'uni-mat-02',
          planCurricularId: 'plan-mat-8vo',
          numero: 2,
          nombre: 'Unidad 2: Álgebra y Relaciones Lineales',
          periodoSugerido: 'Trimestre 2',
          descripcion: 'Modelamiento algebraico, ecuaciones de primer grado y gráficos de funciones.',
          objetivos: [
            ObjetivoAprendizaje(
              id: 'oa-mat-04',
              unidadId: 'uni-mat-02',
              codigo: 'OA-04',
              nombre: 'Expresiones algebraicas y reducción',
              descripcion: 'Reducir términos semejantes y evaluar expresiones numéricamente.',
              orden: 1,
            ),
            ObjetivoAprendizaje(
              id: 'oa-mat-05',
              unidadId: 'uni-mat-02',
              codigo: 'OA-05',
              nombre: 'Ecuaciones e inecuaciones lineales',
              descripcion: 'Resolver ecuaciones e inecuaciones de la forma ax + b = c.',
              orden: 2,
            ),
            ObjetivoAprendizaje(
              id: 'oa-mat-06',
              unidadId: 'uni-mat-02',
              codigo: 'OA-06',
              nombre: 'Función lineal y afín en el plano',
              descripcion: 'Representar tablas y gráficos de proporcionalidad y variación lineal.',
              orden: 3,
            ),
          ],
        ),
        const UnidadCurricular(
          id: 'uni-mat-03',
          planCurricularId: 'plan-mat-8vo',
          numero: 3,
          nombre: 'Unidad 3: Geometría y Medición',
          periodoSugerido: 'Trimestre 3',
          descripcion: 'Teorema de Pitágoras, cálculo de áreas y volúmenes geométricos.',
          objetivos: [
            ObjetivoAprendizaje(
              id: 'oa-mat-07',
              unidadId: 'uni-mat-03',
              codigo: 'OA-07',
              nombre: 'Teorema de Pitágoras y triángulos',
              descripcion: 'Explicar de manera concreta y pictórica el Teorema de Pitágoras.',
              orden: 1,
            ),
            ObjetivoAprendizaje(
              id: 'oa-mat-08',
              unidadId: 'uni-mat-03',
              codigo: 'OA-08',
              nombre: 'Áreas y volúmenes de prismas y cilindros',
              descripcion: 'Desarrollar y aplicar fórmulas para área basal, total y volumen.',
              orden: 2,
            ),
            ObjetivoAprendizaje(
              id: 'oa-mat-09',
              unidadId: 'uni-mat-03',
              codigo: 'OA-09',
              nombre: 'Estadística descriptiva y medidas de dispersión',
              descripcion: 'Analizar e interpretar diagramas de dispersión, varianza y desviación.',
              orden: 3,
            ),
          ],
        ),
      ],
    );

    _planes[planMat8vo.id] = planMat8vo;

    // Vincular por defecto la clase de demostración a este currículo oficial
    _asignacionesClase['CLASE-DEMO-001'] = planMat8vo.id;
  }

  @override
  Future<List<PlanCurricular>> obtenerPlanesCurriculares({String? profesorUid}) async {
    return _planes.values.toList();
  }

  @override
  Future<PlanCurricular?> obtenerPlanPorId(String id) async {
    return _planes[id];
  }

  @override
  Future<PlanCurricular?> obtenerPlanDeClase(String claseId) async {
    final planId = _asignacionesClase[claseId];
    if (planId == null) return null;
    return _planes[planId];
  }

  @override
  Future<void> asignarPlanAClase(String claseId, String planId) async {
    _asignacionesClase[claseId] = planId;
  }

  @override
  Future<void> guardarPlanCurricular(PlanCurricular plan) async {
    _planes[plan.id] = plan;
  }

  @override
  Future<void> eliminarPlanCurricular(String planId) async {
    _planes.remove(planId);
    _asignacionesClase.removeWhere((k, v) => v == planId);
  }
}
