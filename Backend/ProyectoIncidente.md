1. DESCRIPCIÓN DEL PROBLEMA
En entornos urbanos y carreteras, los conductores frecuentemente enfrentan situaciones
imprevistas como fallas mecánicas, pinchazos de llantas, problemas de batería,
sobrecalentamiento del motor o accidentes leves, perder la llave del vehículo, dejar llave
dentro el vehículo y otros.
En muchos casos, el proceso de conseguir ayuda es ineficiente, lento y poco confiable.
Actualmente, las alternativas existentes presentan limitaciones como:
* dependencia de llamadas telefónicas
* falta de información clara sobre el problema
* tiempos de respuesta impredecibles
* dificultad para identificar el proveedor adecuado
* ausencia de trazabilidad del servicio
Por otro lado, los talleres mecánicos no cuentan con una plataforma estructurada que les
permita:
* recibir solicitudes de manera organizada
* evaluar rápidamente la naturaleza del problema
* priorizar casos
* optimizar la asignación de recursos
La plataforma debe integrar múltiples fuentes de información (imágenes, audio,
ubicación) para asistir en la clasificación automática del incidente y facilitar la toma de
decisiones.
2. OBJETIVO GENERAL
Desarrollar una plataforma inteligente de atención de emergencias vehiculares que
permita conectar usuarios con talleres mecánicos mediante el análisis automatizado de
incidentes utilizando datos multimodales (imagen, audio, texto y geolocalización),
optimizando el proceso de diagnóstico preliminar, priorización y asignación del servicio.
Examen 1 Sistemas 2 - S1-26 MSc. Ing. Angélica Garzón Cuéllar
2
3. OBJETIVOS ESPECÍFICOS
* Diseñar una arquitectura basada en servicios que soporte procesamiento en
tiempo real.
* Implementar una aplicación móvil para usuarios que permita reportar
emergencias vehiculares.
* Diseñar una aplicación web para talleres que gestione solicitudes y operaciones.
* Integrar mecanismos de geolocalización para ubicar incidentes y proveedores.
* Incorporar módulos de inteligencia artificial para:
o transcripción de audio
o clasificación de incidentes
o análisis básico de imágenes
* Diseñar un sistema de priorización de emergencias.
* Implementar un mecanismo de asignación inteligente de talleres.
* Gestionar notificaciones en tiempo real (push).
* Mantener trazabilidad completa de cada incidente.
4. ALCANCE Y FUNCIONALIDADES DEL SISTEMA
4.1 Aplicación móvil (Cliente)
El usuario deberá poder:
Los clientes se deben registrar en la aplicación, como también registrar sus vehículos
Registro de emergencia
* enviar ubicación en tiempo real
* adjuntar fotos del vehículo
* enviar audio describiendo el problema
* ingresar texto adicional opcional
Gestión de solicitudes
* visualizar estado de su solicitud:
o pendiente
o en proceso
o atendido
* ver taller asignado
* ver tiempo estimado de llegada
Examen 1 Sistemas 2 - S1-26 MSc. Ing. Angélica Garzón Cuéllar
3

Interacción
* recibir notificaciones push
* comunicarse con el taller (opcional)
El cliente debe realizar los pagos correspondientes desde la aplicación

4.2 Aplicación web (Talleres)
Los Talleres se deben registrar para que sean los que provean el servicio de asistencia a
los clientes que lo soliciten, para esto un taller puede tener uno o más técnicos quienes
serán los asignados para asistir a un cliente
Cuando un taller recibe una alerta de asistencia revisa el lugar donde se encuentran sus
técnicos y disponibilidad para asignarle la orden correspondiente según el tipo de
percance y ubicación del cliente que solicita asistencia
El taller debe pagar un porcentaje (10%) del precio cobrado a la plataforma como
comisión
Los talleres deberán poder:
Gestión de solicitudes
* visualizar solicitudes disponibles
* ver información estructurada del incidente
* aceptar o rechazar solicitudes
Operación
* actualizar estado del servicio
* gestionar disponibilidad
* visualizar historial de atenciones
Información enriquecida (IA)
* ver resumen automático del incidente
* ver clasificación del problema
* ver nivel de prioridad
Examen 1 Sistemas 2 - S1-26 MSc. Ing. Angélica Garzón Cuéllar
4
4.3 Backend (FastAPI)
El sistema backend deberá gestionar:
* autenticación y autorización
* gestión de usuarios y talleres
* gestión de incidentes
* procesamiento de datos
* integración con módulos de IA
* motor de asignación
* sistema de notificaciones
* APIs REST
4.4 Base de datos (PostgreSQL)
El modelo de datos deberá contemplar:
* usuarios
* talleres
* vehículos
* incidentes
* evidencias (imagen, audio, texto)
* estados del servicio
* historial
* métricas
Debe considerar:
* integridad de datos
* relaciones complejas
* trazabilidad
4.5 Módulos de Inteligencia Artificial
1. Procesamiento de audio
* conversión de audio a texto
* extracción de información relevante


Examen 1 Sistemas 2 - S1-26 MSc. Ing. Angélica Garzón Cuéllar
5
2. Clasificación de incidentes (Imágenes a través de fotos lo clasifica, visión artificial)
* categorización automática del problema:
o batería
o llanta
o choque
o motor
o otros
3. Análisis de imágenes (básico)
* identificación de daños visibles
* apoyo en la clasificación del incidente
4. Generación de resumen
* creación automática de una ficha estructurada del incidente
4.6 Sistema de asignación inteligente
Debe considerar:
* ubicación del incidente
* tipo de problema
* disponibilidad del taller
* capacidad del taller
* distancia
* prioridad del caso
El sistema debe generar:
* lista de talleres candidatos
* selección del más adecuado
4.7 Notificaciones
* notificaciones push al cliente
* notificaciones a talleres
* actualizaciones en tiempo real


Examen 1 Sistemas 2 - S1-26 MSc. Ing. Angélica Garzón Cuéllar
6
5. CARACTERÍSTICAS DEL SISTEMA
* integración de múltiples fuentes de datos
* uso de inteligencia artificial aplicada al flujo del sistema
* diseño de interfaces centrado en experiencia de usuario
6. STACK TECNOLOGICO
* frontend web: Angular
* backend: FastAPI (framework) - phyton
* base de datos: PostgreSQL
* aplicación móvil: Flutter

7. EJEMPLOS DE SITUACIONES DE USO

Caso 1: Problema de batería
Un usuario se encuentra en un estacionamiento y su vehículo no enciende.
Envía:
* ubicación
* audio indicando que el auto no responde
* foto del tablero
El sistema:
* transcribe el audio
* clasifica como “problema de batería”
* asigna prioridad media
* sugiere talleres con servicio de auxilio eléctrico
Examen 1 Sistemas 2 - S1-26 MSc. Ing. Angélica Garzón Cuéllar
7
Caso 2: Pinchazo de llanta
El usuario reporta:
* foto de llanta dañada
* ubicación en carretera
El sistema:
* detecta posible pinchazo
* clasifica como incidente leve
* asigna prioridad media
* sugiere talleres cercanos con servicio móvil
Caso 3: Accidente leve
El usuario envía:
* múltiples fotos
* audio indicando choque
El sistema:
* detecta daño visible
* clasifica como choque
* asigna prioridad alta
* sugiere talleres con capacidad de remolque
Caso 4: Situación ambigua
El usuario envía información poco clara.
El sistema:
* clasifica como “incierto”
* solicita más información
* permite intervención manual
8. CONSIDERACIONES IMPORTANTES
* La IA no debe considerarse un módulo aislado, sino parte del flujo principal.
* El sistema debe manejar incertidumbre (no todos los casos serán claros).
* Se espera que los estudiantes tomen decisiones de diseño justificadas. 
