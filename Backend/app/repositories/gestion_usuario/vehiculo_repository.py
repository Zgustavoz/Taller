from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete
from typing import Optional
from app.models.vehiculo_model import Vehiculo
from app.schemas.vehiculo_schema import VehiculoCreate, VehiculoUpdate


class VehiculoRepository:

    def __init__(self, db: AsyncSession):
        self.db = db

    async def crear(self, data: VehiculoCreate, usuario_id: int) -> Vehiculo:
        vehiculo = Vehiculo(**data.model_dump(), usuario_id=usuario_id)
        self.db.add(vehiculo)
        await self.db.flush()
        await self.db.refresh(vehiculo)
        return vehiculo

    async def obtener_por_id(self, vehiculo_id: int) -> Optional[Vehiculo]:
        result = await self.db.execute(
            select(Vehiculo).where(Vehiculo.id == vehiculo_id)
        )
        return result.scalar_one_or_none()

    async def obtener_por_placa(self, placa: str) -> Optional[Vehiculo]:
        result = await self.db.execute(
            select(Vehiculo).where(Vehiculo.placa == placa.upper())
        )
        return result.scalar_one_or_none()

    async def listar_por_usuario(self, usuario_id: int) -> list[Vehiculo]:
        result = await self.db.execute(
            select(Vehiculo)
            .where(Vehiculo.usuario_id == usuario_id)
            .order_by(Vehiculo.fecha_creacion.desc())
        )
        return result.scalars().all()

    async def actualizar(self, vehiculo_id: int, data: VehiculoUpdate) -> Optional[Vehiculo]:
        valores = {k: v for k, v in data.model_dump().items() if v is not None}
        if not valores:
            return await self.obtener_por_id(vehiculo_id)
        await self.db.execute(
            update(Vehiculo).where(Vehiculo.id == vehiculo_id).values(**valores)
        )
        await self.db.flush()
        return await self.obtener_por_id(vehiculo_id)

    async def cambiar_estado(self, vehiculo_id: int, estado: bool) -> Optional[Vehiculo]:
        await self.db.execute(
            update(Vehiculo).where(Vehiculo.id == vehiculo_id).values(estado=estado)
        )
        await self.db.flush()
        return await self.obtener_por_id(vehiculo_id)

    async def eliminar(self, vehiculo_id: int) -> bool:
        result = await self.db.execute(
            delete(Vehiculo).where(Vehiculo.id == vehiculo_id)
        )
        return result.rowcount > 0