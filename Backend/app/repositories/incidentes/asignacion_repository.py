from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update
from typing import Optional
from app.models.asignacion_taller_model import AsignacionTaller


class AsignacionRepository:

    def __init__(self, db: AsyncSession):
        self.db = db

    async def crear(
        self,
        incidente_id: int,
        taller_id: int,
        distancia_km: float | None = None,
        puntuacion: float | None = None,
        tipo: str = "automatica",
    ) -> AsignacionTaller:
        asignacion = AsignacionTaller(
            incidente_id=incidente_id,
            taller_id=taller_id,
            distancia_km=distancia_km,
            puntuacion_asignacion=puntuacion,
            tipo_asignacion=tipo,
            estado_respuesta="pendiente",
        )
        self.db.add(asignacion)
        await self.db.flush()
        await self.db.refresh(asignacion)
        return asignacion

    async def obtener_por_incidente_y_taller(
        self, incidente_id: int, taller_id: int
    ) -> Optional[AsignacionTaller]:
        result = await self.db.execute(
            select(AsignacionTaller)
            .where(AsignacionTaller.incidente_id == incidente_id)
            .where(AsignacionTaller.taller_id == taller_id)
        )
        return result.scalar_one_or_none()

    async def listar_por_incidente(self, incidente_id: int) -> list[AsignacionTaller]:
        result = await self.db.execute(
            select(AsignacionTaller)
            .where(AsignacionTaller.incidente_id == incidente_id)
            .order_by(AsignacionTaller.puntuacion_asignacion.desc())
        )
        return result.scalars().all()

    async def marcar_aceptado(self, incidente_id: int, taller_id: int) -> None:
        from datetime import datetime, timezone
        # Aceptar el taller que respondió
        await self.db.execute(
            update(AsignacionTaller)
            .where(AsignacionTaller.incidente_id == incidente_id)
            .where(AsignacionTaller.taller_id == taller_id)
            .values(
                estado_respuesta="aceptado",
                respondido_at=datetime.now(timezone.utc),
            )
        )
        # Descartar los demás
        await self.db.execute(
            update(AsignacionTaller)
            .where(AsignacionTaller.incidente_id == incidente_id)
            .where(AsignacionTaller.taller_id != taller_id)
            .values(estado_respuesta="descartado")
        )
        await self.db.flush()

    async def marcar_rechazado(self, incidente_id: int, taller_id: int) -> None:
        from datetime import datetime, timezone
        await self.db.execute(
            update(AsignacionTaller)
            .where(AsignacionTaller.incidente_id == incidente_id)
            .where(AsignacionTaller.taller_id == taller_id)
            .values(
                estado_respuesta="rechazado",
                respondido_at=datetime.now(timezone.utc),
            )
        )
        await self.db.flush()