from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.db import get_db
from app.core.security import get_current_user_from_cookie
from app.services.incidentes.tipo_incidente_service import TipoIncidenteService
from app.schemas.tipo_incidente_schema import TipoIncidenteCreate, TipoIncidenteUpdate, TipoIncidenteResponse

router = APIRouter(prefix="/tipos-incidente", tags=["Tipos de Incidente"])


@router.post("/", response_model=TipoIncidenteResponse, status_code=status.HTTP_201_CREATED)
async def crear(
    data: TipoIncidenteCreate,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    return await TipoIncidenteService(db).crear(data)


@router.get("/", response_model=list[TipoIncidenteResponse])
async def listar(
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    return await TipoIncidenteService(db).listar()


@router.get("/{tipo_id}", response_model=TipoIncidenteResponse)
async def obtener(
    tipo_id: int,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    return await TipoIncidenteService(db).obtener_por_id(tipo_id)


@router.put("/{tipo_id}", response_model=TipoIncidenteResponse)
async def actualizar(
    tipo_id: int,
    data: TipoIncidenteUpdate,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    return await TipoIncidenteService(db).actualizar(tipo_id, data)


@router.delete("/{tipo_id}")
async def eliminar(
    tipo_id: int,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    return await TipoIncidenteService(db).eliminar(tipo_id)