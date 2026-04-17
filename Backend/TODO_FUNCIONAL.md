# TODO Funcional - Proyecto Incidentes

## 1) Estado actual vs requisitos

### Cumple en BD
- Usuarios, talleres, tecnicos, vehiculos, incidentes.
- Evidencias multimedia (imagen/audio/video).
- Historial de estados y trazabilidad.
- Geolocalizacion con PostGIS (ubicacion en incidentes/talleres/tecnicos).
- Notificaciones, pagos y calificaciones modelados.

### Parcial (falta backend real)
- Motor de asignacion inteligente (candidatos + mejor opcion).
- Notificaciones push en tiempo real (FCM realmente enviado).
- Flujo IA integrado al ciclo principal (audio/image -> clasificacion/prioridad).
- Flujo de aceptacion/rechazo de taller sobre la asignacion.

### No implementado o incompleto
- Contratos API estables y versionados para frontend mobile/web.
- Reglas de consistencia de estado de incidente en backend.

---

## 2) TODO por fases (paso a paso)

## Fase 0 - Congelar contratos y base tecnica
- [ ] Crear app/schemas/common_response.py con formato unico de respuesta.
- [ ] Definir enumeraciones compartidas de estados de incidente.
- [ ] Agregar validaciones de transicion de estado (backend).
- [ ] Documentar endpoints minimos de mobile y web.

Contexto IA:
- La IA no debe decidir todavia; en esta fase solo necesita consumir contratos estables para producir clasificaciones, resúmenes y prioridad de forma predecible.
- El objetivo es que los datos de audio, imagen y texto tengan un formato uniforme para poder ser interpretados por el pipeline luego.

Entregable:
- OpenAPI consistente y estable para ambos frontends.

## Fase 1 - Motor de asignacion inteligente
- [ ] Crear tabla/uso real de asignaciones_talleres en backend.
- [ ] Endpoint para generar candidatos de taller por incidente.
- [ ] Filtro por:
- estado del taller (esta_disponible, esta_activo).
- cobertura (radio_cobertura_km).
- especialidades compatibles con tipo_incidente.
- [ ] Calculo de distancia (PostGIS) y ranking.
- [ ] Seleccion del mejor candidato (automatica) y persistencia.
- [ ] Asignacion opcional de tecnico por cercania y disponibilidad.

Contexto IA:
- La salida de IA aqui debe ayudar a priorizar, no reemplazar la decision completa.
- El motor puede usar la clasificacion IA del incidente para ponderar especialidades y urgencia.
- Si la IA marca incertidumbre, el ranking debe bajar confianza y dejar trazabilidad para revision manual.

Entregable:
- Un incidente en estado analizando pasa a asignado con trazabilidad.

## Fase 2 - Gestion de respuesta del taller
- [ ] Endpoint POST /incidentes/{id}/responder-asignacion (aceptar/rechazar).
- [ ] Si rechaza, elegir siguiente candidato.
- [ ] Si timeout, mover a siguiente candidato automatico.
- [ ] Actualizar historial con actor taller o sistema.

Contexto IA:
- La IA no responde aqui, pero su resumen debe ayudar al taller a decidir rapido.
- El sistema deberia mostrar al taller un resumen generado del incidente, tipo probable y nivel de prioridad.
- Si el taller rechaza, ese feedback puede alimentar reglas futuras de asignacion.

Entregable:
- Flujo completo de aceptacion/rechazo.

## Fase 3 - Notificaciones push en tiempo real
- [ ] Crear servicio FCM real (app/services/notificaciones/fcm_service.py).
- [ ] Notificar a taller al crear candidato.
- [ ] Notificar a usuario cuando se asigna taller/tecnico.
- [ ] Guardar resultado de envio en tabla notificaciones.

Contexto IA:
- La IA puede ayudar a definir el texto de la notificacion: resumen corto, gravedad y accion esperada.
- Debe generarse un mensaje claro y breve, no tecnico, para que el taller entienda el caso en segundos.

Entregable:
- Entrega y tracking de notificaciones (pendiente/enviado/fallido/leido).

## Fase 4 - Integracion IA al flujo principal
- [ ] Pipeline audio -> transcripcion.
- [ ] Pipeline imagen -> clasificacion de percance.
- [ ] Motor de prioridad (reglas + score IA).
- [ ] Guardar salida en analisis_ia y ficha_resumen.
- [ ] Endpoint de reproceso IA manual para casos ambiguos.

Contexto IA:
- Aqui la IA si es protagonista: recibe audio, imagen y texto para producir una clasificacion probable del incidente.
- Debe devolver como minimo: tipo probable, confianza, resumen estructurado y una sugerencia de prioridad.
- Si la confianza es baja, el sistema debe marcar el caso como incierto y pedir mas informacion.

Entregable:
- El incidente queda enriquecido antes de asignacion final.

## Fase 5 - Pagos y cierre del servicio
- [ ] Endpoint de cobro usuario y estado de pago.
- [ ] Calculo y marcacion de comision 10%.
- [ ] Habilitar calificacion post-servicio.
- [ ] Cerrar incidente al completar pago/estado.

Contexto IA:
- La IA puede generar el resumen final del servicio y sugerir etiquetas para analitica, pero no debe alterar el monto.
- El cierre debe conservar trazabilidad para auditoria y aprendizaje futuro.

Entregable:
- Flujo completo desde reporte hasta cierre y rating.

---

## 3) Data que deben retornar los endpoints (contratos minimos)

## 3.1 Crear incidente
Endpoint sugerido:
- POST /api/incidentes

Debe retornar:
```json
{
  "ok": true,
  "mensaje": "Incidente creado",
  "data": {
    "incidente_id": "id_simple",
    "estado": "pendiente",
    "tipo_incidente": {
      "id": 1,
      "codigo": "battery_dead",
      "nombre": "Bateria descargada"
    },
    "prioridad": 3,
    "ubicacion": {"latitud": -17.78, "longitud": -63.18},
    "creado_en": "2026-04-16T12:00:00Z"
  }
}
```

## 3.2 Resultado de asignacion inteligente
Endpoint sugerido:
- POST /api/incidentes/{id}/asignar

Debe retornar:
```json
{
  "ok": true,
  "mensaje": "Asignacion generada",
  "data": {
    "incidente_id": "id_simple",
    "estado": "asignado",
    "candidatos": [
      {
        "id_taller": "id_simple",
        "id_tecnico": "id_simple",
        "distancia_km": 2.35,
        "score": 91.2,
        "especialidad_match": true
      }
    ],
    "seleccion": {
      "id_taller": "id_simple",
      "id_tecnico": "id_simple",
      "eta_min": 12
    }
  }
}
```

## 3.3 Respuesta de taller (aceptar/rechazar)
Endpoint sugerido:
- POST /api/incidentes/{id}/respuesta-taller

Debe retornar:
```json
{
  "ok": true,
  "mensaje": "Respuesta registrada",
  "data": {
    "incidente_id": "id_simple",
    "estado_respuesta": "aceptado",
    "estado_incidente": "en_proceso",
    "id_taller": "id_simple",
    "id_tecnico": "id_simple",
    "respondido_en": "2026-04-16T12:10:00Z"
  }
}
```

## 3.4 Obtener detalle de incidente (mobile/web)
Endpoint sugerido:
- GET /api/incidentes/{id}

Debe retornar:
```json
{
  "ok": true,
  "data": {
    "id": "id_simple",
    "estado": "en_proceso",
    "prioridad": 4,
    "usuario": {"id": "id_simple", "nombre": "..."},
    "vehiculo": {"id": "id_simple", "placa": "..."},
    "taller": {"id": "id_simple", "nombre_negocio": "..."},
    "tecnico": {"id": "id_simple", "nombre_completo": "..."},
    "ubicacion": {"latitud": -17.78, "longitud": -63.18},
    "analisis_ia": {
      "clasificacion": "battery_dead",
      "confianza": 0.88,
      "transcripcion": "..."
    },
    "ficha_resumen": {
      "resumen": "...",
      "recomendacion": "..."
    },
    "historial": [
      {
        "estado_anterior": "pendiente",
        "estado_nuevo": "asignado",
        "tipo_actor": "sistema",
        "creado_en": "2026-04-16T12:03:00Z"
      }
    ]
  }
}
```

## 3.5 Listado para panel de taller
Endpoint sugerido:
- GET /api/talleres/me/solicitudes?estado=pendiente

Debe retornar:
```json
{
  "ok": true,
  "data": [
    {
      "incidente_id": "id_simple",
      "estado": "pendiente",
      "tipo_incidente": "flat_tire",
      "prioridad": 3,
      "distancia_km": 4.1,
      "eta_min": 15,
      "direccion_texto": "...",
      "creado_en": "2026-04-16T12:00:00Z"
    }
  ]
}
```

---

## 4) Reglas de negocio minimas pendientes
- [ ] Un tecnico no puede estar en 2 incidentes activos al mismo tiempo.
- [ ] Si estado incidente = resuelto, debe tener resuelto_en.
- [ ] Si estado incidente = asignado/en_proceso, debe existir taller asignado.
- [ ] Si el taller no responde en N minutos, marcar timeout y pasar al siguiente candidato.
- [ ] Si no hay candidato valido, dejar incidente en pendiente y notificar admin/sistema.

---

## 5) Definicion de terminado (DoD)
- [ ] Caso bateria completo (crear -> asignar -> atender -> pagar -> calificar).
- [ ] Caso pinchazo completo.
- [ ] Caso ambiguo con reproceso IA.
- [ ] Trazabilidad visible de cada cambio de estado.
- [ ] Notificaciones enviadas y registradas.
- [ ] Documentacion de endpoints actualizada.
