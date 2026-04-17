# Tablero Operativo Semanal - Proyecto Incidentes (Documento Principal)

Este es el archivo principal de seguimiento del proyecto.

## Roles
- Mobile: tu amigo.
- Web: tu.
- Backend compartido: ambos (con propietario semanal para evitar conflictos).

## Estado rapido
- Pendiente
- En progreso
- Bloqueado
- Hecho

## Regla de coordinacion backend
- Cada semana se define un propietario backend.
- El otro miembro puede revisar o testear, pero no tocar los mismos archivos core sin aviso.
- Si cambia un contrato API, se actualiza tambien TODO_FUNCIONAL.md.

---

## Semana 0 - Fase 0: Contratos base

Propietario backend semanal: [ ] Web [ ] Mobile

### Tareas
- Mobile
	- [ ] Definir payload de creacion de incidente.
	- [ ] Definir campos minimos para detalle de incidente.
- Web
	- [ ] Definir campos minimos del panel de solicitudes.
	- [ ] Definir campos minimos del detalle para taller.
- Backend compartido
	- [X] Unificar respuesta base `{ok, mensaje, data}`.
	- [X] Definir transiciones de estado validas.

### Tablas BD involucradas
- `incidentes`
- `tipos_incidente`
- `historial_estados`

### Atributos clave
- `incidentes.id`, `incidentes.estado`, `incidentes.id_tipo_incidente`, `incidentes.nivel_prioridad`
- `historial_estados.estado_anterior`, `historial_estados.estado_nuevo`, `historial_estados.tipo_actor`

### Endpoints minimos
- `POST /api/incidentes`
- `GET /api/incidentes/{id}`
- `PATCH /api/incidentes/{id}/estado`

### Respuesta esperada
```json
{
	"ok": true,
	"mensaje": "Operacion exitosa",
	"data": {
		"id": "id_simple",
		"estado": "pendiente"
	}
}
```

---

## Semana 1 - Fase 1: Asignacion inteligente

Propietario backend semanal: [ ] Web [ ] Mobile

### Tareas
- Mobile
	- [ ] Enviar ubicacion, audio, imagen, descripcion.
- Web
	- [ ] Mostrar candidatos y seleccionado en UI de taller.
- Backend compartido
	- [ ] Generar lista de talleres candidatos por distancia y cobertura.
	- [ ] Filtrar por disponibilidad y especialidades.
	- [ ] Seleccionar mejor candidato y persistir.

### Tablas BD involucradas
- `incidentes`
- `talleres`
- `tecnicos`
- `asignaciones_talleres`
- `tipos_incidente`

### Atributos clave
- `incidentes.ubicacion`, `incidentes.id_tipo_incidente`, `incidentes.nivel_prioridad`
- `talleres.ubicacion`, `talleres.radio_cobertura_km`, `talleres.especialidades`, `talleres.esta_disponible`
- `tecnicos.ubicacion_actual`, `tecnicos.especialidades`, `tecnicos.esta_disponible`
- `asignaciones_talleres.distancia_km`, `asignaciones_talleres.puntuacion_asignacion`

### Endpoints minimos
- `POST /api/incidentes/{id}/asignar`
- `GET /api/incidentes/{id}`

### Respuesta esperada
```json
{
	"ok": true,
	"mensaje": "Asignacion generada",
	"data": {
		"estado": "asignado",
		"candidatos": [
			{
				"id_taller": "id",
				"id_tecnico": "id",
				"distancia_km": 2.35,
				"score": 91.2
			}
		],
		"seleccion": {
			"id_taller": "id",
			"id_tecnico": "id",
			"eta_min": 12
		}
	}
}
```

---

## Semana 2 - Fase 2: Respuesta del taller

Propietario backend semanal: [ ] Web [ ] Mobile

### Tareas
- Mobile
	- [ ] Mostrar actualizacion de estado y ETA al usuario.
- Web
	- [ ] Implementar aceptar/rechazar solicitud.
	- [ ] Mostrar resumen automatico para decidir.
- Backend compartido
	- [ ] Registrar respuesta (`aceptado`/`rechazado`/`timeout`).
	- [ ] Reasignar automaticamente si corresponde.
	- [ ] Persistir historial de cambios.

### Tablas BD involucradas
- `asignaciones_talleres`
- `incidentes`
- `historial_estados`

### Atributos clave
- `asignaciones_talleres.estado_respuesta`, `asignaciones_talleres.respondido_en`
- `incidentes.id_taller_asignado`, `incidentes.id_tecnico_asignado`, `incidentes.estado`
- `historial_estados.id_incidente`, `historial_estados.notas`

### Endpoints minimos
- `POST /api/incidentes/{id}/respuesta-taller`
- `GET /api/talleres/me/solicitudes?estado=pendiente`

### Respuesta esperada
```json
{
	"ok": true,
	"mensaje": "Respuesta registrada",
	"data": {
		"incidente_id": "id_simple",
		"estado_respuesta": "aceptado",
		"estado_incidente": "en_proceso",
		"id_taller": "id_simple",
		"id_tecnico": "id_simple"
	}
}
```

---

## Semana 3 - Fase 3: Notificaciones

Propietario backend semanal: [ ] Web [ ] Mobile

### Tareas
- Mobile
	- [ ] Recibir notificaciones y refrescar estado de incidente.
- Web
	- [ ] Mostrar alertas de nuevas solicitudes para taller.
- Backend compartido
	- [ ] Integrar envio FCM.
	- [ ] Persistir resultado de envio/lectura.

### Tablas BD involucradas
- `notificaciones`
- `talleres`
- `tecnicos`
- `usuarios`
- `incidentes`

### Atributos clave
- `notificaciones.tipo_destinatario`, `notificaciones.id_destinatario`, `notificaciones.estado`
- `notificaciones.enviado_en`, `notificaciones.leido_en`, `notificaciones.datos_extra`
- `usuarios.token_fcm`, `talleres.token_fcm`, `tecnicos.token_fcm`

### Endpoints minimos
- `POST /api/notificaciones/enviar` (interno/backend)
- `GET /api/notificaciones/mis-notificaciones`
- `PATCH /api/notificaciones/{id}/leida`

### Respuesta esperada
```json
{
	"ok": true,
	"mensaje": "Notificacion enviada",
	"data": {
		"id_notificacion": "id_simple",
		"estado": "enviado"
	}
}
```

---

## Semana 4 - Fase 4: IA en flujo principal

Propietario backend semanal: [ ] Web [ ] Mobile

### Tareas
- Mobile
	- [ ] Enviar audio e imagen desde el reporte.
- Web
	- [ ] Mostrar clasificacion, confianza y resumen IA.
- Backend compartido
	- [ ] Pipeline audio -> transcripcion.
	- [ ] Pipeline imagen -> clasificacion.
	- [ ] Calcular prioridad sugerida.
	- [ ] Guardar analisis_ia y ficha_resumen.

### Tablas BD involucradas
- `archivos_multimedia`
- `incidentes`
- `tipos_incidente`

### Atributos clave
- `archivos_multimedia.tipo_media`, `archivos_multimedia.url_almacenamiento`, `archivos_multimedia.transcripcion`, `archivos_multimedia.resultado_ia`
- `incidentes.analisis_ia`, `incidentes.ficha_resumen`, `incidentes.id_tipo_incidente`, `incidentes.nivel_prioridad`

### Endpoints minimos
- `POST /api/incidentes/{id}/multimedia`
- `POST /api/incidentes/{id}/analizar`
- `POST /api/incidentes/{id}/reprocesar-ia`

### Respuesta esperada
```json
{
	"ok": true,
	"mensaje": "Analisis IA completado",
	"data": {
		"incidente_id": "id_simple",
		"clasificacion": "battery_dead",
		"confianza": 0.88,
		"prioridad_sugerida": 3,
		"resumen": "Texto breve para taller"
	}
}
```

---

## Semana 5 - Fase 5: Pagos, cierre y calificacion

Propietario backend semanal: [ ] Web [ ] Mobile

### Tareas
- Mobile
	- [ ] Pagar y calificar servicio.
- Web
	- [ ] Ver comision, cierre e historial final.
- Backend compartido
	- [ ] Registrar pago y estado.
	- [ ] Aplicar comision 10%.
	- [ ] Habilitar calificacion y cierre.

### Tablas BD involucradas
- `pagos`
- `calificaciones`
- `incidentes`
- `historial_estados`

### Atributos clave
- `pagos.monto_total`, `pagos.monto_comision`, `pagos.monto_taller`, `pagos.estado_pago`, `pagos.metodo_pago`
- `calificaciones.puntuacion`, `calificaciones.comentario`
- `incidentes.estado`, `incidentes.resuelto_en`

### Endpoints minimos
- `POST /api/pagos`
- `PATCH /api/pagos/{id}/confirmar`
- `POST /api/incidentes/{id}/calificar`
- `PATCH /api/incidentes/{id}/cerrar`

### Respuesta esperada
```json
{
	"ok": true,
	"mensaje": "Incidente cerrado",
	"data": {
		"incidente_id": "id_simple",
		"estado": "resuelto",
		"estado_pago": "completado",
		"calificacion": 5
	}
}
```
