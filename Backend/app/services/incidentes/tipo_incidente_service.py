from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.repositories.incidentes.tipo_incidente_repository import TipoIncidenteRepository
from app.schemas.tipo_incidente_schema import TipoIncidenteCreate, TipoIncidenteUpdate, TipoIncidenteResponse


class TipoIncidenteService:

    def __init__(self, db: AsyncSession):
        self.repo = TipoIncidenteRepository(db)

    async def crear(self, data: TipoIncidenteCreate) -> TipoIncidenteResponse:
        if await self.repo.obtener_por_codigo(data.codigo):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Ya existe un tipo con código '{data.codigo}'",
            )
        tipo = await self.repo.crear(data)
        return TipoIncidenteResponse.model_validate(tipo)

    async def obtener_por_id(self, tipo_id: int) -> TipoIncidenteResponse:
        tipo = await self.repo.obtener_por_id(tipo_id)
        if not tipo:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Tipo de incidente {tipo_id} no encontrado",
            )
        return TipoIncidenteResponse.model_validate(tipo)

    async def listar(self) -> list[TipoIncidenteResponse]:
        tipos = await self.repo.listar()
        return [TipoIncidenteResponse.model_validate(t) for t in tipos]

    async def actualizar(self, tipo_id: int, data: TipoIncidenteUpdate) -> TipoIncidenteResponse:
        await self.obtener_por_id(tipo_id)
        tipo = await self.repo.actualizar(tipo_id, data)
        return TipoIncidenteResponse.model_validate(tipo)

    async def eliminar(self, tipo_id: int) -> dict:
        await self.obtener_por_id(tipo_id)
        await self.repo.eliminar(tipo_id)
        return {"mensaje": f"Tipo de incidente {tipo_id} eliminado"}