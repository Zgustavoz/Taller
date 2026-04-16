from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete
from typing import Optional
from app.models.tipo_incidente_model import TipoIncidente
from app.schemas.tipo_incidente_schema import TipoIncidenteCreate, TipoIncidenteUpdate


class TipoIncidenteRepository:

    def __init__(self, db: AsyncSession):
        self.db = db

    async def crear(self, data: TipoIncidenteCreate) -> TipoIncidente:
        tipo = TipoIncidente(**data.model_dump())
        self.db.add(tipo)
        await self.db.flush()
        await self.db.refresh(tipo)
        return tipo

    async def obtener_por_id(self, tipo_id: int) -> Optional[TipoIncidente]:
        result = await self.db.execute(
            select(TipoIncidente).where(TipoIncidente.id == tipo_id)
        )
        return result.scalar_one_or_none()

    async def obtener_por_codigo(self, codigo: str) -> Optional[TipoIncidente]:
        result = await self.db.execute(
            select(TipoIncidente).where(TipoIncidente.codigo == codigo)
        )
        return result.scalar_one_or_none()

    async def listar(self) -> list[TipoIncidente]:
        result = await self.db.execute(select(TipoIncidente))
        return result.scalars().all()

    async def actualizar(self, tipo_id: int, data: TipoIncidenteUpdate) -> Optional[TipoIncidente]:
        valores = {k: v for k, v in data.model_dump().items() if v is not None}
        if not valores:
            return await self.obtener_por_id(tipo_id)
        await self.db.execute(
            update(TipoIncidente).where(TipoIncidente.id == tipo_id).values(**valores)
        )
        await self.db.flush()
        return await self.obtener_por_id(tipo_id)

    async def eliminar(self, tipo_id: int) -> bool:
        result = await self.db.execute(
            delete(TipoIncidente).where(TipoIncidente.id == tipo_id)
        )
        return result.rowcount > 0