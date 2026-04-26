from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, func
from typing import Optional
from app.models.asignacion_taller_model import AsignacionTaller
from app.models.taller_model import Taller


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

    # ─── Listar con nombre del taller incluido ────────────────
    async def listar_por_incidente(self, incidente_id: int) -> list[dict]:
        result = await self.db.execute(
            select(
                AsignacionTaller.taller_id,
                AsignacionTaller.estado_respuesta,
                AsignacionTaller.distancia_km,
                AsignacionTaller.puntuacion_asignacion,
                Taller.nombre_negocio,
                Taller.telefono,
                Taller.especialidades,
                Taller.direccion.label("direccion_taller"),
                func.ST_Y(Taller.ubicacion).label("latitud_taller"),
                func.ST_X(Taller.ubicacion).label("longitud_taller"),
            )
            .join(Taller, Taller.id == AsignacionTaller.taller_id)
            .where(AsignacionTaller.incidente_id == incidente_id)
            .order_by(AsignacionTaller.puntuacion_asignacion.desc())
        )
        rows = result.mappings().all()
        return [dict(r) for r in rows]

    async def marcar_aceptado(self, incidente_id: int, taller_id: int) -> None:
        from datetime import datetime, timezone
        await self.db.execute(
            update(AsignacionTaller)
            .where(AsignacionTaller.incidente_id == incidente_id)
            .where(AsignacionTaller.taller_id == taller_id)
            .values(
                estado_respuesta="aceptado",
                respondido_at=datetime.now(timezone.utc),
            )
        )
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