from typing import Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.historial_estado_model import HistorialEstado


class HistorialEstadoRepository:

    def __init__(self, db: AsyncSession):
        self.db = db

    async def obtener_por_id(self, historial_id: int) -> Optional[HistorialEstado]:
        result = await self.db.execute(
            select(HistorialEstado).where(HistorialEstado.id == historial_id)
        )
        return result.scalar_one_or_none()

    async def listar(self, incidente_id: Optional[int] = None) -> list[HistorialEstado]:
        query = select(HistorialEstado).order_by(HistorialEstado.creado_en.desc())
        if incidente_id is not None:
            query = query.where(HistorialEstado.incidente_id == incidente_id)

        result = await self.db.execute(query)
        return result.scalars().all()
