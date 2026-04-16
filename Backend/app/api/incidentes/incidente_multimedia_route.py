from fastapi import APIRouter, Depends, UploadFile, File, status
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List
from app.core.db import get_db
from app.core.security import get_current_user_from_cookie
from app.services.incidentes.incidente_multimedia_service import IncidenteMultimediaService
from app.schemas.incidente_multimedia_schema import MultimediaResponse

router = APIRouter(prefix="/incidentes", tags=["Multimedia de Incidentes"])


# Subir uno o múltiples archivos al incidente
@router.post(
    "/{incidente_id}/multimedia",
    response_model=list[MultimediaResponse],
    status_code=status.HTTP_201_CREATED,
)
async def subir_archivos(
    incidente_id: int,
    archivos: List[UploadFile] = File(...),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    return await IncidenteMultimediaService(db).subir_archivos(incidente_id, archivos)


# Listar multimedia de un incidente
@router.get(
    "/{incidente_id}/multimedia",
    response_model=list[MultimediaResponse],
)
async def listar_multimedia(
    incidente_id: int,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    return await IncidenteMultimediaService(db).listar_por_incidente(incidente_id)


# Eliminar un archivo multimedia
@router.delete("/multimedia/{multimedia_id}")
async def eliminar_multimedia(
    multimedia_id: int,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    return await IncidenteMultimediaService(db).eliminar(multimedia_id)