from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.repositories.gestion_usuario.taller.taller_repository import TallerRepository
from app.schemas.taller_schema import TallerCreate, TallerResponse, TallerUpdate


class TallerService:

    def __init__(self, db: AsyncSession):
        self.repo = TallerRepository(db)

    async def crear(self, data: TallerCreate) -> TallerResponse:
        if await self.repo.obtener_por_correo(data.correo):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Ya existe un taller con ese correo",
            )

        taller = await self.repo.crear(data)
        return TallerResponse.model_validate(taller)

    async def obtener_por_id(self, taller_id: int) -> TallerResponse:
        taller = await self.repo.obtener_por_id(taller_id)
        if not taller:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Taller con id {taller_id} no encontrado",
            )
        return TallerResponse.model_validate(taller)

    async def listar(self, solo_activos: bool = False) -> list[TallerResponse]:
        talleres = await self.repo.listar(solo_activos)
        return [TallerResponse.model_validate(t) for t in talleres]

    async def actualizar(self, taller_id: int, data: TallerUpdate) -> TallerResponse:
        await self.obtener_por_id(taller_id)

        if data.correo:
            existente = await self.repo.obtener_por_correo(data.correo)
            if existente and existente.id != taller_id:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Ya existe un taller con ese correo",
                )

        taller = await self.repo.actualizar(taller_id, data)
        return TallerResponse.model_validate(taller)

    async def cambiar_estado(self, taller_id: int, estado: bool) -> TallerResponse:
        await self.obtener_por_id(taller_id)
        taller = await self.repo.cambiar_estado(taller_id, estado)
        return TallerResponse.model_validate(taller)

    async def eliminar(self, taller_id: int) -> dict:
        await self.obtener_por_id(taller_id)
        await self.repo.eliminar(taller_id)
        return {"mensaje": f"Taller {taller_id} eliminado correctamente"}
