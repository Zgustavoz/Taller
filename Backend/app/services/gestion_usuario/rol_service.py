from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.repositories.gestion_usuario.rol.rol_repository import RolRepository
from app.schemas.rol_schema import RolCreate, RolUpdate, RolResponse


class RolService:

    def __init__(self, db: AsyncSession):
        self.repo = RolRepository(db)

    # ─── Crear ───────────────────────────────────────────────────
    async def crear(self, data: RolCreate) -> RolResponse:
        existente = await self.repo.obtener_por_nombre(data.nombre)
        if existente:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Ya existe un rol con el nombre '{data.nombre}'",
            )
        rol = await self.repo.crear(data)
        return RolResponse.model_validate(rol)

    # ─── Obtener por ID ──────────────────────────────────────────
    async def obtener_por_id(self, rol_id: int) -> RolResponse:
        rol = await self.repo.obtener_por_id(rol_id)
        if not rol:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Rol con id {rol_id} no encontrado",
            )
        return RolResponse.model_validate(rol)

    # ─── Listar ──────────────────────────────────────────────────
    async def listar(self, solo_activos: bool = False) -> list[RolResponse]:
        roles = await self.repo.listar(solo_activos)
        return [RolResponse.model_validate(r) for r in roles]

    # ─── Actualizar ──────────────────────────────────────────────
    async def actualizar(self, rol_id: int, data: RolUpdate) -> RolResponse:
        await self.obtener_por_id(rol_id)  # valida existencia
        if data.nombre:
            existente = await self.repo.obtener_por_nombre(data.nombre)
            if existente and existente.id != rol_id:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Ya existe un rol con el nombre '{data.nombre}'",
                )
        rol = await self.repo.actualizar(rol_id, data)
        return RolResponse.model_validate(rol)

    # ─── Cambiar estado ──────────────────────────────────────────
    async def cambiar_estado(self, rol_id: int, estado: bool) -> RolResponse:
        await self.obtener_por_id(rol_id)  # valida existencia
        rol = await self.repo.cambiar_estado(rol_id, estado)
        return RolResponse.model_validate(rol)

    # ─── Eliminar ────────────────────────────────────────────────
    async def eliminar(self, rol_id: int) -> dict:
        await self.obtener_por_id(rol_id)  # valida existencia
        await self.repo.eliminar(rol_id)
        return {"mensaje": f"Rol {rol_id} eliminado correctamente"}