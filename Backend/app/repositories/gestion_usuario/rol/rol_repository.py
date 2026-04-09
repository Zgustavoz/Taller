from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete
from typing import Optional
from app.models.rol_model import Rol
from app.schemas.rol_schema import RolCreate, RolUpdate


class RolRepository:

    def __init__(self, db: AsyncSession):
        self.db = db

    # ─── Crear ───────────────────────────────────────────────────
    async def crear(self, data: RolCreate) -> Rol:
        rol = Rol(**data.model_dump())
        self.db.add(rol)
        await self.db.flush()
        await self.db.refresh(rol)
        return rol

    # ─── Obtener por ID ──────────────────────────────────────────
    async def obtener_por_id(self, rol_id: int) -> Optional[Rol]:
        result = await self.db.execute(
            select(Rol).where(Rol.id == rol_id)
        )
        return result.scalar_one_or_none()

    # ─── Obtener por nombre ──────────────────────────────────────
    async def obtener_por_nombre(self, nombre: str) -> Optional[Rol]:
        result = await self.db.execute(
            select(Rol).where(Rol.nombre == nombre)
        )
        return result.scalar_one_or_none()

    # ─── Listar todos ────────────────────────────────────────────
    async def listar(self, solo_activos: bool = False) -> list[Rol]:
        query = select(Rol)
        if solo_activos:
            query = query.where(Rol.estado == True)
        result = await self.db.execute(query)
        return result.scalars().all()

    # ─── Actualizar ──────────────────────────────────────────────
    async def actualizar(self, rol_id: int, data: RolUpdate) -> Optional[Rol]:
        valores = {k: v for k, v in data.model_dump().items() if v is not None}
        if not valores:
            return await self.obtener_por_id(rol_id)
        await self.db.execute(
            update(Rol).where(Rol.id == rol_id).values(**valores)
        )
        await self.db.flush()
        return await self.obtener_por_id(rol_id)

    # ─── Cambiar estado ──────────────────────────────────────────
    async def cambiar_estado(self, rol_id: int, estado: bool) -> Optional[Rol]:
        await self.db.execute(
            update(Rol).where(Rol.id == rol_id).values(estado=estado)
        )
        await self.db.flush()
        return await self.obtener_por_id(rol_id)

    # ─── Eliminar ────────────────────────────────────────────────
    async def eliminar(self, rol_id: int) -> bool:
        result = await self.db.execute(
            delete(Rol).where(Rol.id == rol_id)
        )
        return result.rowcount > 0