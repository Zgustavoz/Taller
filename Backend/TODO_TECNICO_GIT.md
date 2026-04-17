# TODO Tecnico y Colaboracion Git (2 personas)

## 1) Estrategia de ramas

- main: solo codigo estable y liberable.
- develop: integracion semanal del equipo.
- feat/<modulo>-<descripcion>: funcionalidades nuevas.
- fix/<modulo>-<descripcion>: correcciones puntuales.

Regla:
- Nadie trabaja directo en main.

---

## 2) Reglas para evitar conflictos

- Pull Request obligatorio para merge.
- Rebase diario contra develop.
- Commits pequenos y con un solo objetivo.
- No mezclar backend + frontend + BD en el mismo commit.
- Actualizar este documento o el funcional cuando cambien contratos.

Checklist antes de abrir PR:
- Tests y arranque local en verde.
- Sin archivos no relacionados.
- Sin cambios de formato masivo innecesario.
- Endpoints/documentacion sincronizados.

---

## 3) Reparto sugerido de ownership

Persona A (backend operacional):
- app/services/incidentes/*
- app/repositories/incidentes/*
- app/api/incidentes/*
- asignacion y notificaciones

Persona B (IA, estados y cierre):
- app/services/ia/* (nuevo)
- app/services/incidentes/* (estado/historial)
- pagos/calificaciones
- mejoras de contratos de respuesta

Nota:
- Si ambos tocan el mismo archivo de servicio, dividir por metodos y coordinar PR en orden.

---

## 4) Plan semanal para ejecutar en paralelo

Semana 1
- Persona A: candidatos + endpoint asignar.
- Persona B: pipeline IA base (audio -> texto, clasificacion inicial).

Semana 2
- Persona A: aceptar/rechazar + timeout + reasignacion.
- Persona B: envio push (FCM) + persistencia en notificaciones.

Semana 3
- Persona A: panel taller (solicitudes, filtros, respuesta).
- Persona B: pagos/comision/calificacion + cierre de incidente.

Semana 4
- Ambos: pruebas E2E, optimizacion, hardening, documentacion final.

---

## 5) Convencion de commits sugerida

Formato:
- feat: agrega funcionalidad.
- fix: corrige error.
- refactor: cambia estructura sin cambiar comportamiento.
- docs: documentacion.
- test: pruebas.

Ejemplos:
- feat(incidentes): agregar endpoint de asignacion automatica
- fix(asignacion): evitar tecnico duplicado en incidentes activos
- docs(api): actualizar contrato de respuesta de incidente

---

## 6) Politica de migraciones y BD

- Una sola persona crea migraciones por sprint para evitar choques.
- Nombre de migration con prefijo de fecha y modulo.
- Nunca editar migraciones ya mergeadas en develop/main.
- Si hay conflicto, crear migracion correctiva nueva.

Orden recomendado:
1. Crear migracion.
2. Revisar en PR.
3. Aplicar en entorno local de ambos.
4. Integrar frontend contra el nuevo contrato.

---

## 7) Politica de endpoints y contratos

- Si cambia request/response, actualizar en el mismo PR:
- schema Pydantic
- endpoint
- documento funcional

- Evitar cambios rompientes:
- preferir agregar campos antes que renombrar/eliminar.
- si es rompiente, versionar endpoint.

---

## 8) Comandos base de coordinacion (flujo diario)

Inicio del dia:
1. git checkout develop
2. git pull
3. git checkout -b feat/<modulo>-<descripcion>

Antes de subir:
1. git fetch origin
2. git rebase origin/develop
3. resolver conflictos
4. ejecutar pruebas
5. git push -u origin feat/<...>

Antes de merge:
1. aprobacion del companero
2. checks en verde
3. squash o rebase merge segun acuerdo

---

## 9) Riesgos comunes y prevencion

Riesgo: ambos editan incidente_service.py.
Prevencion: dividir por metodos y PR pequenos en secuencia.

Riesgo: drift entre BD y backend.
Prevencion: migraciones controladas y PR con prueba de arranque.

Riesgo: frontend rompe por cambio de contrato.
Prevencion: versionar o hacer cambios backward-compatible.

Riesgo: conflicto en router principal.
Prevencion: unificar alta de rutas en una sola rama de integracion por semana.
