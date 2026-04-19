from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.repositories.incidentes.historial_repository import HistorialRepository
from app.schemas.historial_estado_schema import HistorialEstadoResponse


class HistorialEstadoService:

    def __init__(self, db: AsyncSession):
        self.repo = HistorialRepository(db)

    async def obtener_por_id(self, historial_id: int) -> HistorialEstadoResponse:
        historial = await self.repo.obtener_por_id(historial_id)
        if not historial:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Historial de estado {historial_id} no encontrado",
            )
        return HistorialEstadoResponse.model_validate(historial)

    async def listar(self, incidente_id: int | None = None) -> list[HistorialEstadoResponse]:
        historiales = await self.repo.listar(incidente_id)
        return [HistorialEstadoResponse.model_validate(h) for h in historiales]
