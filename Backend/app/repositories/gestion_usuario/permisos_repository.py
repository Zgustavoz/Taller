from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete
from typing import Optional
from app.models.permisos_model import Permiso
from app.schemas.permisos_schema import PermisosCreate, PermisosUpdate


class PermisosRepository:

    def __init__(self, db: AsyncSession):
        self.db = db

    # ─── Crear ───────────────────────────────────────────────────
    async def crear(self, data: PermisosCreate) -> Permiso:
        permiso = Permiso(**data.model_dump())
        self.db.add(permiso)
        await self.db.flush()
        await self.db.refresh(permiso)
        return permiso

    # ─── Obtener por ID ──────────────────────────────────────────
    async def obtener_por_id(self, permiso_id: int) -> Optional[Permiso]:
        result = await self.db.execute(
            select(Permiso).where(Permiso.id == permiso_id)
        )
        return result.scalar_one_or_none()

    # ─── Obtener por usuario y rol ───────────────────────────────
    async def obtener_por_usuario_y_rol(
        self, usuario_id: int, rol_id: int
    ) -> Optional[Permiso]:
        result = await self.db.execute(
            select(Permiso).where(
                Permiso.usuario_id == usuario_id,
                Permiso.rol_id == rol_id,
            )
        )
        return result.scalar_one_or_none()

    # ─── Listar permisos de un usuario ───────────────────────────
    async def listar_por_usuario(self, usuario_id: int) -> list[Permiso]:
        result = await self.db.execute(
            select(Permiso).where(Permiso.usuario_id == usuario_id)
        )
        return result.scalars().all()

    # ─── Listar permisos de un rol ───────────────────────────────
    async def listar_por_rol(self, rol_id: int) -> list[Permiso]:
        result = await self.db.execute(
            select(Permiso).where(Permiso.rol_id == rol_id)
        )
        return result.scalars().all()

    # ─── Actualizar ──────────────────────────────────────────────
    async def actualizar(self, permiso_id: int, data: PermisosUpdate) -> Optional[Permiso]:
        valores = {k: v for k, v in data.model_dump().items() if v is not None}
        if not valores:
            return await self.obtener_por_id(permiso_id)
        await self.db.execute(
            update(Permiso).where(Permiso.id == permiso_id).values(**valores)
        )
        await self.db.flush()
        return await self.obtener_por_id(permiso_id)

    # ─── Cambiar estado ──────────────────────────────────────────
    async def cambiar_estado(self, permiso_id: int, estado: bool) -> Optional[Permiso]:
        await self.db.execute(
            update(Permiso).where(Permiso.id == permiso_id).values(estado=estado)
        )
        await self.db.flush()
        return await self.obtener_por_id(permiso_id)

    # ─── Eliminar ────────────────────────────────────────────────
    async def eliminar(self, permiso_id: int) -> bool:
        result = await self.db.execute(
            delete(Permiso).where(Permiso.id == permiso_id)
        )
        return result.rowcount > 0