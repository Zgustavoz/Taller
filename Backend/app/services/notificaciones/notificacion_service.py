import json
import logging
from datetime import datetime, timezone
from fastapi import HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from app.repositories.notificaciones.notificacion_repository import NotificacionRepository
from app.repositories.gestion_usuario.usuario.usuario_repository import UsuarioRepository
from app.services.notificaciones.firebase_service import enviar_a_token, enviar_a_multiples

logger = logging.getLogger(__name__)


class NotificacionService:

    def __init__(self, db: AsyncSession):
        self.db = db
        self.repo = NotificacionRepository(db)

    # ─── Enviar a un usuario ──────────────────────────────────
    async def enviar_a_usuario(
        self,
        usuario_id: int,
        titulo: str,
        cuerpo: str,
        token_fcm: str | None,
        incidente_id: int | None = None,
        datos_extra: dict | None = None,
    ) -> bool:
        # 1. Registrar en BD
        notif = await self.repo.crear(
            tipo_destinatario="usuario",
            id_destinatario=usuario_id,
            titulo=titulo,
            cuerpo=cuerpo,
            incidente_id=incidente_id,
            datos_extra=datos_extra,
        )

        if not token_fcm:
            await self.repo.marcar_fallida(notif.id)
            logger.warning(f"Usuario {usuario_id} sin token FCM")
            return False

        # 2. Enviar por FCM
        exito = await enviar_a_token(
            token=token_fcm,
            titulo=titulo,
            cuerpo=cuerpo,
            datos=datos_extra,
        )

        # 3. Actualizar estado en BD
        if exito:
            await self.repo.marcar_enviada(notif.id)
        else:
            await self.repo.marcar_fallida(notif.id)

        return exito

    # ─── Enviar a múltiples talleres ──────────────────────────
    async def enviar_a_talleres(
        self,
        talleres: list[dict],
        titulo: str,
        cuerpo: str,
        incidente_id: int | None = None,
        datos_extra: dict | None = None,
    ) -> dict:
        tokens = []
        notif_ids = []

        for t in talleres:
            notif = await self.repo.crear(
                tipo_destinatario="taller",
                id_destinatario=t["id"],
                titulo=titulo,
                cuerpo=cuerpo,
                incidente_id=incidente_id,
                datos_extra=datos_extra,
            )
            notif_ids.append(notif.id)
            if t.get("token_fcm"):
                tokens.append(t["token_fcm"])

        if not tokens:
            for nid in notif_ids:
                await self.repo.marcar_fallida(nid)
            return {"exitosos": 0, "fallidos": len(talleres)}

        resultado = await enviar_a_multiples(
            tokens=tokens,
            titulo=titulo,
            cuerpo=cuerpo,
            datos=datos_extra,
        )

        for nid in notif_ids:
            if resultado["exitosos"] > 0:
                await self.repo.marcar_enviada(nid)
            else:
                await self.repo.marcar_fallida(nid)

        return resultado

    # ─── Listar notificaciones del usuario ────────────────────
    async def mis_notificaciones(
        self,
        usuario_id: int,
        solo_no_leidas: bool = False,
    ) -> list[dict]:
        notifs = await self.repo.listar_por_destinatario(
            tipo="usuario",
            id_destinatario=usuario_id,
            solo_no_leidas=solo_no_leidas,
        )
        return [self._serializar(n) for n in notifs]

    # ─── Marcar como leída ────────────────────────────────────
    async def marcar_leida(self, notif_id: int) -> dict:
        await self.repo.marcar_leida(notif_id)
        return {"mensaje": "Notificación marcada como leída"}

    # ─── Marcar todas como leídas ─────────────────────────────
    async def marcar_todas_leidas(self, usuario_id: int) -> dict:
        notifs = await self.repo.listar_por_destinatario(
            tipo="usuario",
            id_destinatario=usuario_id,
            solo_no_leidas=True,
        )
        for n in notifs:
            await self.repo.marcar_leida(n.id)
        return {"mensaje": f"{len(notifs)} notificaciones marcadas como leídas"}

    # ─── Contar no leídas ─────────────────────────────────────
    async def contar_no_leidas(self, usuario_id: int) -> dict:
        total = await self.repo.contar_no_leidas("usuario", usuario_id)
        return {"total": total}

    # ─── Enviar notificación de prueba al usuario autenticado ─────
    async def enviar_prueba_usuario(
        self,
        usuario_id: int,
        titulo: str,
        cuerpo: str,
    ) -> dict:
        usuario = await UsuarioRepository(self.db).obtener_por_id(usuario_id)
        if not usuario:
            raise HTTPException(status_code=404, detail="Usuario no encontrado")

        token = getattr(usuario, "token_fcm", None)
        exito = await self.enviar_a_usuario(
            usuario_id=usuario_id,
            titulo=titulo,
            cuerpo=cuerpo,
            token_fcm=token,
            datos_extra={
                "tipo": "test_push",
                "pantalla": "notificaciones",
            },
        )

        if not token:
            return {
                "enviado": False,
                "mensaje": "Usuario sin token FCM registrado",
            }

        return {
            "enviado": exito,
            "mensaje": "Push de prueba enviado" if exito else "No se pudo enviar el push de prueba",
        }

    def _serializar(self, n) -> dict:
        return {
            "id": n.id,
            "tipo_destinatario": n.tipo_destinatario,
            "incidente_id": n.incidente_id,
            "titulo": n.titulo,
            "cuerpo": n.cuerpo,
            "datos_extra": json.loads(n.datos_extra) if n.datos_extra else None,
            "estado": n.estado,
            "enviado_en": n.enviado_en,
            "leido_en": n.leido_en,
            "creado_en": n.creado_en,
        }