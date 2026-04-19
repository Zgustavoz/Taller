from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.repositories.gestion_usuario.tecnico.tecnico_repository import TecnicoRepository
from app.schemas.tecnico_schema import TecnicoCreate, TecnicoResponse, TecnicoUpdate


class TecnicoService:

    def __init__(self, db: AsyncSession):
        self.repo = TecnicoRepository(db)

    async def crear(self, data: TecnicoCreate) -> TecnicoResponse:
        tecnico = await self.repo.crear(data)
        return TecnicoResponse.model_validate(tecnico)

    async def obtener_por_id(self, tecnico_id: int) -> TecnicoResponse:
        tecnico = await self.repo.obtener_por_id(tecnico_id)
        if not tecnico:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Técnico {tecnico_id} no encontrado",
            )
        return TecnicoResponse.model_validate(tecnico)

    async def listar(self, solo_activos: bool = False) -> list[TecnicoResponse]:
        tecnicos = await self.repo.listar(solo_activos)
        return [TecnicoResponse.model_validate(t) for t in tecnicos]

    async def listar_por_taller(self, taller_id: int, solo_activos: bool = False) -> list[TecnicoResponse]:
        tecnicos = await self.repo.listar_por_taller(taller_id, solo_activos)
        return [TecnicoResponse.model_validate(t) for t in tecnicos]

    async def actualizar(self, tecnico_id: int, data: TecnicoUpdate) -> TecnicoResponse:
        await self.obtener_por_id(tecnico_id)
        tecnico = await self.repo.actualizar(tecnico_id, data)
        return TecnicoResponse.model_validate(tecnico)

    async def cambiar_estado(self, tecnico_id: int, estado: bool) -> TecnicoResponse:
        await self.obtener_por_id(tecnico_id)
        tecnico = await self.repo.cambiar_estado(tecnico_id, estado)
        return TecnicoResponse.model_validate(tecnico)

    async def eliminar(self, tecnico_id: int) -> dict:
        await self.obtener_por_id(tecnico_id)
        await self.repo.eliminar(tecnico_id)
        return {"mensaje": f"Técnico {tecnico_id} eliminado correctamente"}
