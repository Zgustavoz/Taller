from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import get_db
from app.core.security import get_current_taller_from_cookie, get_current_user_from_cookie
from app.schemas.taller_schema import (
    SolicitudPanelMinimaResponse,
    TallerCreate,
    TallerResponse,
    TallerUpdate,
)
from app.services.gestion_usuario.taller_service import TallerService

router = APIRouter(prefix="/talleres", tags=["Talleres"])


@router.post("/", response_model=TallerResponse, status_code=status.HTTP_201_CREATED)
async def crear_taller(
    data: TallerCreate,
    db: AsyncSession = Depends(get_db),
):
    service = TallerService(db)
    return await service.crear(data)


@router.get("/", response_model=list[TallerResponse])
async def listar_talleres(
    solo_activos: bool = False,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    service = TallerService(db)
    return await service.listar(solo_activos)


@router.get("/me/solicitudes", response_model=list[SolicitudPanelMinimaResponse])
async def listar_mis_solicitudes(
    estado: str | None = None,
    db: AsyncSession = Depends(get_db),
    current_taller: dict = Depends(get_current_taller_from_cookie),
):
    service = TallerService(db)
    taller_id = int(current_taller.get("sub"))
    return await service.listar_solicitudes_minimas(taller_id=taller_id, estado=estado)


@router.get("/{taller_id}", response_model=TallerResponse)
async def obtener_taller(
    taller_id: int,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    service = TallerService(db)
    return await service.obtener_por_id(taller_id)


@router.put("/{taller_id}", response_model=TallerResponse)
async def actualizar_taller(
    taller_id: int,
    data: TallerUpdate,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    service = TallerService(db)
    return await service.actualizar(taller_id, data)


@router.patch("/{taller_id}/estado", response_model=TallerResponse)
async def cambiar_estado(
    taller_id: int,
    estado: bool,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    service = TallerService(db)
    return await service.cambiar_estado(taller_id, estado)


@router.delete("/{taller_id}", response_model=dict)
async def eliminar_taller(
    taller_id: int,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    service = TallerService(db)
    return await service.eliminar(taller_id)
