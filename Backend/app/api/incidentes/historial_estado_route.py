from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional

from app.core.db import get_db
from app.core.security import get_current_user_from_cookie
from app.services.incidentes.historial_estado_service import HistorialEstadoService
from app.schemas.historial_estado_schema import HistorialEstadoResponse

router = APIRouter(prefix="/historial-estados", tags=["Historial Estados"])


@router.get("/", response_model=list[HistorialEstadoResponse])
async def listar_historiales(
    incidente_id: Optional[int] = None,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    return await HistorialEstadoService(db).listar(incidente_id)


@router.get("/{historial_id}", response_model=HistorialEstadoResponse)
async def obtener_historial(
    historial_id: int,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    return await HistorialEstadoService(db).obtener_por_id(historial_id)
