import json
from fastapi import HTTPException, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List

from app.repositories.incidentes.incidente_repository import IncidenteRepository
from app.repositories.incidentes.incidente_multimedia_repository import IncidenteMultimediaRepository
from app.repositories.incidentes.asignacion_repository import AsignacionRepository
from app.repositories.incidentes.historial_repository import HistorialRepository
from app.repositories.incidentes.tipo_incidente_repository import TipoIncidenteRepository
from app.services.incidentes.cloudinary_service import subir_archivo_cloudinary
from app.services.ia.gemini_service import (
    analizar_incidente, transcribir_audio, analizar_imagen,
    especialidades_para_tipo,
)
from app.repositories.gestion_usuario.usuario.usuario_repository import UsuarioRepository
from app.schemas.tipo_incidente_schema import TipoIncidenteCreate
from app.services.notificaciones.notificacion_service import NotificacionService
from app.services.incidentes.estado_validator import EstadoIncidenteValidator


class IncidenteService:

    def __init__(self, db: AsyncSession):
        self.db = db
        self.repo = IncidenteRepository(db)
        self.multimedia_repo = IncidenteMultimediaRepository(db)
        self.asignacion_repo = AsignacionRepository(db)
        self.historial_repo = HistorialRepository(db)

    # ─── Serializar incidente ─────────────────────────────────
    async def _serializar(self, incidente, coordenadas: dict | None = None) -> dict:
        coord = coordenadas or await self.repo.obtener_coordenadas(incidente.id)
        return {
            "id": incidente.id,
            "usuario_id": incidente.usuario_id,
            "vehiculo_id": incidente.vehiculo_id,
            "taller_asignado_id": incidente.taller_asignado_id,
            "tecnico_asignado_id": incidente.tecnico_asignado_id,
            "tipo_incidente_id": incidente.tipo_incidente_id,
            "latitud": coord["latitud"] if coord else None,
            "longitud": coord["longitud"] if coord else None,
            "texto_direccion": incidente.texto_direccion,
            "descripcion": incidente.descripcion,
            "estado": incidente.estado,
            "nivel_prioridad": incidente.nivel_prioridad,
            "analisis_ia": json.loads(incidente.analisis_ia) if incidente.analisis_ia else None,
            "ficha_resumen": json.loads(incidente.ficha_resumen) if incidente.ficha_resumen else None,
            "tiempo_estimado_llegada_min": incidente.tiempo_estimado_llegada_min,
            "creado_at": incidente.creado_at,
            "resuelto_at": incidente.resuelto_at,
        }

    # ─── Crear + subir archivos + IA + notificar talleres ─────
    async def crear_con_archivos(
        self,
        usuario_id: int,
        latitud: float,
        longitud: float,
        archivos: List[UploadFile],
        descripcion: str | None = None,
        texto_direccion: str | None = None,
        tipo_incidente_id: int | None = None,
        vehiculo_id: int | None = None,
        nivel_prioridad: int | None = None,
    ) -> dict:

        # 1. Crear incidente (sin tipo, la IA lo asignará)
        incidente = await self.repo.crear(
            usuario_id=usuario_id,
            latitud=latitud,
            longitud=longitud,
            descripcion=descripcion,
            texto_direccion=texto_direccion,
            tipo_incidente_id=None,
            vehiculo_id=vehiculo_id,
            nivel_prioridad=nivel_prioridad,
        )
        await self.historial_repo.registrar(
            incidente_id=incidente.id,
            estado_nuevo="pendiente",
            tipo_actor="usuario",
            actor_id=usuario_id,
            notas="Incidente de emergencia creado",
        )

        # 2. Subir archivos a Cloudinary
        urls_imagenes, urls_audios = [], []
        for archivo in archivos:
            try:
                data_c = await subir_archivo_cloudinary(
                    archivo, carpeta=f"incidentes/{incidente.id}"
                )
                await self.multimedia_repo.crear(
                    incidente_id=incidente.id,
                    url=data_c["url"],
                    public_id=data_c["public_id"],
                    tipo_archivo=data_c["tipo_archivo"],
                    tipo_mime=data_c["tipo_mime"],
                    tamano_bytes=data_c["tamano_bytes"],
                    duracion_seg=data_c.get("duracion_seg"),
                )
                if data_c["tipo_archivo"] == "imagen":
                    urls_imagenes.append(data_c["url"])
                elif data_c["tipo_archivo"] == "audio":
                    urls_audios.append(data_c["url"])
            except Exception:
                continue

        # 3. Transcribir audios ANTES del análisis global para enriquecer el contexto
        multimedia_lista = await self.multimedia_repo.listar_por_incidente(incidente.id)
        transcripciones_audio = []
        for media in multimedia_lista:
            if media.tipo_archivo == "audio":
                try:
                    trans = await transcribir_audio(media.url_almacenamiento, media.tipo_mime)
                    if trans:
                        transcripciones_audio.append(trans)
                        from sqlalchemy import update as sql_up
                        from app.models.incidente_multimedia_model import IncidenteMultimedia
                        await self.db.execute(
                            sql_up(IncidenteMultimedia)
                            .where(IncidenteMultimedia.id == media.id)
                            .values(transcripcion=trans)
                        )
                except Exception as e:
                    print(f"[IncidenteService] Error transcribiendo audio {media.id}: {e}")
        await self.db.flush()

        # 4. Cambiar a "analizando"
        await self.repo.actualizar_estado(incidente.id, "analizando")
        await self.historial_repo.registrar(
            incidente_id=incidente.id,
            estado_nuevo="analizando",
            estado_anterior="pendiente",
            tipo_actor="ia",
            notas="Análisis con Gemini iniciado",
        )

        # 5. Analizar con Gemini — pasa descripción + transcripciones + imágenes
        try:
            resultado_ia = await analizar_incidente(
                descripcion=descripcion,
                urls_imagenes=urls_imagenes,
                urls_audios=urls_audios,
                transcripciones_audio=transcripciones_audio,
                tipo_nombre=None,
            )
        except Exception as e:
            import traceback
            print(f"[IncidenteService] Error en análisis Gemini: {e}")
            print(traceback.format_exc())
            resultado_ia = {
                "tipo_detectado": "other",
                "nivel_prioridad": nivel_prioridad or 3,
                "confianza": 0.0,
                "ficha_resumen": {},
                "resumen": descripcion or "Sin descripción",
                "danos_detectados": [],
                "palabras_clave": [],
            }

        # 6. Análisis individual de imágenes
        for media in multimedia_lista:
            if media.tipo_archivo == "imagen":
                try:
                    analisis_img = await analizar_imagen(media.url_almacenamiento)
                    if analisis_img:
                        from sqlalchemy import update as sql_up
                        from app.models.incidente_multimedia_model import IncidenteMultimedia
                        await self.db.execute(
                            sql_up(IncidenteMultimedia)
                            .where(IncidenteMultimedia.id == media.id)
                            .values(resultado_ia=json.dumps(analisis_img))
                        )
                except Exception as e:
                    print(f"[IncidenteService] Error analizando imagen {media.id}: {e}")
        await self.db.flush()

        # 7. Buscar o crear tipo en catálogo según lo detectado por Gemini
        tipo_id_final = None
        codigo_detectado = resultado_ia.get("tipo_detectado")
        if codigo_detectado:
            tipo_repo = TipoIncidenteRepository(self.db)
            tipo_existente = await tipo_repo.obtener_por_codigo(codigo_detectado)
            if tipo_existente:
                tipo_id_final = tipo_existente.id
            else:
                nuevo_tipo = await tipo_repo.crear(
                    TipoIncidenteCreate(
                        codigo=codigo_detectado,
                        nombre=codigo_detectado.replace("_", " ").title(),
                        prioridad_base=resultado_ia.get("nivel_prioridad", 3),
                    )
                )
                tipo_id_final = nuevo_tipo.id

        # 8. Guardar resultado IA → estado="notificando"
        await self.repo.actualizar_ia(
            incidente_id=incidente.id,
            analisis_ia=json.dumps(resultado_ia),
            ficha_resumen=json.dumps(resultado_ia.get("ficha_resumen", {})),
            nivel_prioridad=resultado_ia.get("nivel_prioridad"),
            tipo_incidente_id=tipo_id_final,
        )
        await self.historial_repo.registrar(
            incidente_id=incidente.id,
            estado_nuevo="notificando",
            estado_anterior="analizando",
            tipo_actor="ia",
            notas=f"IA detectó: {codigo_detectado} "
                  f"(confianza {resultado_ia.get('confianza', 0):.0%})",
        )

        # 9. Buscar talleres cercanos filtrados por especialidad del tipo detectado
        especialidades = especialidades_para_tipo(codigo_detectado or "other")
        print(f"[IncidenteService] Buscando talleres con especialidades: {especialidades}")

        talleres_con_coord = await self.repo.talleres_cercanos_con_coordenadas(
            latitud=latitud,
            longitud=longitud,
            radio_km=15.0,
            limite=5,
            especialidades=especialidades,
        )

        # Si no hay talleres con esa especialidad, buscar sin filtro
        if not talleres_con_coord:
            print(f"[IncidenteService] Sin talleres con especialidad, buscando sin filtro")
            talleres_con_coord = await self.repo.talleres_cercanos_con_coordenadas(
                latitud=latitud,
                longitud=longitud,
                radio_km=15.0,
                limite=5,
                especialidades=[],
            )

        for t in talleres_con_coord:
            puntuacion = float(t["calificacion_promedio"] or 0) * 20
            await self.asignacion_repo.crear(
                incidente_id=incidente.id,
                taller_id=t["id"],
                puntuacion=puntuacion,
            )

        # 10. Enviar FCM a talleres
        notif_service = NotificacionService(self.db)
        await notif_service.enviar_a_talleres(
            talleres=talleres_con_coord,
            titulo="🚨 Nueva emergencia vehicular",
            cuerpo=resultado_ia.get("resumen", "Emergencia vehicular cerca de tu taller"),
            incidente_id=incidente.id,
            datos_extra={
                "incidente_id": str(incidente.id),
                "tipo": codigo_detectado or "other",
                "prioridad": str(resultado_ia.get("nivel_prioridad", 3)),
                "pantalla": "incidente_detalle",
            },
        )

        await self.historial_repo.registrar(
            incidente_id=incidente.id,
            estado_nuevo="notificando",
            tipo_actor="sistema",
            notas=f"{len(talleres_con_coord)} talleres notificados "
                  f"(especialidad: {', '.join(especialidades) or 'general'})",
        )

        coord = await self.repo.obtener_coordenadas(incidente.id)
        return {
            **(await self._serializar(incidente, coord)),
            "talleres_notificados": len(talleres_con_coord),
            "archivos_subidos": len(multimedia_lista),
            "resultado_ia": resultado_ia,
        }

    # ─── Taller acepta incidente ──────────────────────────────
    async def taller_acepta(
        self,
        incidente_id: int,
        taller_id: int,
        tecnico_id: int | None = None,
        tiempo_estimado_min: int | None = None,
    ) -> dict:
        incidente = await self.repo.obtener_por_id(incidente_id)
        if not incidente:
            raise HTTPException(status_code=404, detail="Incidente no encontrado")
        if incidente.estado not in ["notificando", "pendiente"]:
            raise HTTPException(
                status_code=400,
                detail=f"El incidente no puede ser aceptado en estado '{incidente.estado}'",
            )

        await self.asignacion_repo.marcar_aceptado(incidente_id, taller_id)
        incidente = await self.repo.actualizar_estado(
            incidente_id=incidente_id,
            estado="asignado",
            taller_id=taller_id,
            tecnico_id=tecnico_id,
            tiempo_estimado=tiempo_estimado_min,
        )
        await self.historial_repo.registrar(
            incidente_id=incidente_id,
            estado_nuevo="asignado",
            estado_anterior="notificando",
            tipo_actor="taller",
            actor_id=taller_id,
            notas=f"Taller #{taller_id} aceptó. ETA: {tiempo_estimado_min} min",
        )

        usuario = await UsuarioRepository(self.db).obtener_por_id(incidente.usuario_id)
        notif_service = NotificacionService(self.db)
        await notif_service.enviar_a_usuario(
            usuario_id=incidente.usuario_id,
            titulo="✅ ¡Tu emergencia fue aceptada!",
            cuerpo=f"Un técnico está en camino. ETA: {tiempo_estimado_min or '?'} min",
            token_fcm=getattr(usuario, "token_fcm", None),
            incidente_id=incidente_id,
            datos_extra={
                "incidente_id": str(incidente_id),
                "taller_id": str(taller_id),
                "pantalla": "incidente_detalle",
            },
        )

        coord = await self.repo.obtener_coordenadas(incidente_id)
        return await self._serializar(incidente, coord)

    async def taller_rechaza(
        self,
        incidente_id: int,
        taller_id: int,
        notas: str | None = None,
    ) -> dict:
        incidente = await self.repo.obtener_por_id(incidente_id)
        if not incidente:
            raise HTTPException(status_code=404, detail="Incidente no encontrado")

        if incidente.estado not in ["notificando", "pendiente"]:
            raise HTTPException(
                status_code=400,
                detail=f"El incidente no puede ser rechazado en estado '{incidente.estado}'",
            )

        asignacion = await self.asignacion_repo.obtener_por_incidente_y_taller(incidente_id, taller_id)
        if not asignacion:
            raise HTTPException(
                status_code=404,
                detail="No existe asignación para este taller en el incidente",
            )

        if asignacion.estado_respuesta in ["aceptado", "descartado"]:
            raise HTTPException(
                status_code=400,
                detail=f"No se puede rechazar una asignación en estado '{asignacion.estado_respuesta}'",
            )

        await self.asignacion_repo.marcar_rechazado(incidente_id, taller_id)
        await self.historial_repo.registrar(
            incidente_id=incidente_id,
            estado_nuevo=incidente.estado,
            estado_anterior=incidente.estado,
            tipo_actor="taller",
            actor_id=taller_id,
            notas=notas or f"Taller #{taller_id} rechazó la solicitud",
        )

        coord = await self.repo.obtener_coordenadas(incidente_id)
        incidente = await self.repo.obtener_por_id(incidente_id)
        return await self._serializar(incidente, coord)

    # ─── Obtener detalle completo ─────────────────────────────
    async def obtener(self, incidente_id: int) -> dict:
        incidente = await self.repo.obtener_por_id(incidente_id)
        if not incidente:
            raise HTTPException(status_code=404, detail="Incidente no encontrado")
        coord = await self.repo.obtener_coordenadas(incidente_id)
        historial = await self.historial_repo.listar(incidente_id)
        asignaciones = await self.asignacion_repo.listar_por_incidente(incidente_id)

        data = await self._serializar(incidente, coord)
        data["multimedia"] = [
            {
                "id": m.id,
                "incidente_id": m.incidente_id,
                "tipo_archivo": m.tipo_archivo,
                "url_almacenamiento": m.url_almacenamiento,
                "tipo_mime": m.tipo_mime,
                "duracion_seg": m.duracion_seg,
                "tamano_archivo_bytes": m.tamano_archivo_bytes,
                "resultado_ia": json.loads(m.resultado_ia) if m.resultado_ia else None,
                "transcripcion": m.transcripcion,
                "subido_at": m.subido_at.isoformat() if m.subido_at else None,
            }
            for m in incidente.multimedia
        ]
        data["historial"] = [
            {
                "estado_anterior": h.estado_anterior,
                "estado_nuevo": h.estado_nuevo,
                "tipo_actor": h.tipo_actor,
                "notas": h.notas,
                "creado_at": h.creado_at,
            }
            for h in historial
        ]
        data["asignaciones"] = [
            {
                "taller_id": a.taller_id,
                "estado": a.estado_respuesta,
                "distancia_km": float(a.distancia_km) if a.distancia_km else None,
                "puntuacion": float(a.puntuacion_asignacion) if a.puntuacion_asignacion else None,
            }
            for a in asignaciones
        ]
        return data

    # ─── Listar por usuario (con multimedia incluida) ─────────
    async def mis_incidentes(self, usuario_id: int) -> list[dict]:
        incidentes = await self.repo.listar_por_usuario(usuario_id)
        resultado = []
        for inc in incidentes:
            coord = await self.repo.obtener_coordenadas(inc.id)
            data = await self._serializar(inc, coord)
            data["multimedia"] = [
                {
                    "id": m.id,
                    "incidente_id": m.incidente_id,
                    "tipo_archivo": m.tipo_archivo,
                    "url_almacenamiento": m.url_almacenamiento,
                    "tipo_mime": m.tipo_mime,
                    "duracion_seg": m.duracion_seg,
                    "tamano_archivo_bytes": m.tamano_archivo_bytes,
                    "resultado_ia": None,
                    "subido_at": m.subido_at.isoformat() if m.subido_at else None,
                }
                for m in inc.multimedia
            ]
            data["historial"] = []
            data["asignaciones"] = []
            resultado.append(data)
        return resultado

    # ─── Cambiar estado ───────────────────────────────────────
    async def cambiar_estado(
        self,
        incidente_id: int,
        estado: str,
        actor_id: int,
        tipo_actor: str = "sistema",
        notas: str | None = None,
    ) -> dict:
        estado_normalizado = {
            "en_proceso": "en_progreso",
        }.get(estado, estado)

        incidente = await self.repo.obtener_por_id(incidente_id)
        if not incidente:
            raise HTTPException(status_code=404, detail="Incidente no encontrado")

        estado_anterior = incidente.estado
        EstadoIncidenteValidator.validar_transicion(estado_anterior, estado_normalizado)

        valores_extra = {}
        if estado_normalizado == "resuelto":
            from datetime import datetime, timezone
            valores_extra["resuelto_at"] = datetime.now(timezone.utc)

        await self.repo.actualizar_estado(incidente_id, estado_normalizado, **valores_extra)
        await self.historial_repo.registrar(
            incidente_id=incidente_id,
            estado_nuevo=estado_normalizado,
            estado_anterior=estado_anterior,
            tipo_actor=tipo_actor,
            actor_id=actor_id,
            notas=notas,
        )

        incidente = await self.repo.obtener_por_id(incidente_id)
        coord = await self.repo.obtener_coordenadas(incidente_id)
        return await self._serializar(incidente, coord)

    # ─── Talleres cercanos a un incidente filtrados por tipo ──
    async def talleres_cercanos(self, incidente_id: int, radio_km: float = 15.0) -> dict:
        coord = await self.repo.obtener_coordenadas(incidente_id)
        if not coord:
            return {"talleres": []}

        # Obtener tipo del incidente para filtrar especialidades
        incidente = await self.repo.obtener_por_id(incidente_id)
        especialidades = []
        if incidente and incidente.analisis_ia:
            try:
                ia = json.loads(incidente.analisis_ia)
                tipo = ia.get("tipo_detectado", "other")
                especialidades = especialidades_para_tipo(tipo)
            except Exception:
                pass

        talleres = await self.repo.talleres_cercanos_con_coordenadas(
            latitud=coord["latitud"],
            longitud=coord["longitud"],
            radio_km=radio_km,
            especialidades=especialidades,
        )

        # Si no hay con especialidad, buscar todos
        if not talleres:
            talleres = await self.repo.talleres_cercanos_con_coordenadas(
                latitud=coord["latitud"],
                longitud=coord["longitud"],
                radio_km=radio_km,
                especialidades=[],
            )

        return {
            "talleres": [
                {
                    "id": t["id"],
                    "nombre": t["nombre_negocio"],
                    "telefono": t["telefono"],
                    "especialidades": t["especialidades"],
                    "calificacion": float(t["calificacion_promedio"] or 0),
                    "esta_disponible": t["esta_disponible"],
                    "latitud": t["latitud"],
                    "longitud": t["longitud"],
                }
                for t in talleres
            ]
        }