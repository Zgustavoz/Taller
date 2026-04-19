from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update
from datetime import datetime, timezone
from typing import Optional
from app.models.notificacion_model import Notificacion


class NotificacionRepository:

    def __init__(self, db: AsyncSession):
        self.db = db

    async def crear(
        self,
        tipo_destinatario: str,
        id_destinatario: int,
        titulo: str,
        cuerpo: str,
        incidente_id: int | None = None,
        datos_extra: dict | None = None,
    ) -> Notificacion:
        import json
        notif = Notificacion(
            tipo_destinatario=tipo_destinatario,
            id_destinatario=id_destinatario,
            incidente_id=incidente_id,
            titulo=titulo,
            cuerpo=cuerpo,
            datos_extra=json.dumps(datos_extra) if datos_extra else None,
            estado="pendiente",
        )
        self.db.add(notif)
        await self.db.flush()
        await self.db.refresh(notif)
        return notif

    async def marcar_enviada(self, notif_id: int) -> None:
        await self.db.execute(
            update(Notificacion)
            .where(Notificacion.id == notif_id)
            .values(estado="enviado", enviado_en=datetime.now(timezone.utc))
        )
        await self.db.flush()

    async def marcar_fallida(self, notif_id: int) -> None:
        await self.db.execute(
            update(Notificacion)
            .where(Notificacion.id == notif_id)
            .values(estado="fallido")
        )
        await self.db.flush()

    async def marcar_leida(self, notif_id: int) -> None:
        await self.db.execute(
            update(Notificacion)
            .where(Notificacion.id == notif_id)
            .values(estado="leido", leido_en=datetime.now(timezone.utc))
        )
        await self.db.flush()

    async def listar_por_destinatario(
        self,
        tipo: str,
        id_destinatario: int,
        solo_no_leidas: bool = False,
    ) -> list[Notificacion]:
        query = (
            select(Notificacion)
            .where(Notificacion.tipo_destinatario == tipo)
            .where(Notificacion.id_destinatario == id_destinatario)
            .order_by(Notificacion.creado_en.desc())
        )
        if solo_no_leidas:
            query = query.where(Notificacion.leido_en == None)
        result = await self.db.execute(query)
        return result.scalars().all()

    async def contar_no_leidas(self, tipo: str, id_destinatario: int) -> int:
        from sqlalchemy import func, select
        result = await self.db.execute(
            select(func.count())
            .where(Notificacion.tipo_destinatario == tipo)
            .where(Notificacion.id_destinatario == id_destinatario)
            .where(Notificacion.leido_en == None)
        )
        return result.scalar() or 0