from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import get_db
from app.core.security import get_current_user_from_cookie
from app.schemas.tecnico_schema import TecnicoCreate, TecnicoResponse, TecnicoUpdate
from app.services.gestion_usuario.tecnico_service import TecnicoService

router = APIRouter(prefix="/tecnicos", tags=["Técnicos"])


@router.post("/", response_model=TecnicoResponse, status_code=status.HTTP_201_CREATED)
async def crear_tecnico(
    data: TecnicoCreate,
    db: AsyncSession = Depends(get_db),
):
    return await TecnicoService(db).crear(data)


@router.get("/", response_model=list[TecnicoResponse])
async def listar_tecnicos(
    solo_activos: bool = False,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    return await TecnicoService(db).listar(solo_activos)


@router.get("/{tecnico_id}", response_model=TecnicoResponse)
async def obtener_tecnico(
    tecnico_id: int,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    return await TecnicoService(db).obtener_por_id(tecnico_id)


@router.put("/{tecnico_id}", response_model=TecnicoResponse)
async def actualizar_tecnico(
    tecnico_id: int,
    data: TecnicoUpdate,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    return await TecnicoService(db).actualizar(tecnico_id, data)


@router.patch("/{tecnico_id}/estado", response_model=TecnicoResponse)
async def cambiar_estado_tecnico(
    tecnico_id: int,
    estado: bool,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    return await TecnicoService(db).cambiar_estado(tecnico_id, estado)


@router.delete("/{tecnico_id}")
async def eliminar_tecnico(
    tecnico_id: int,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    return await TecnicoService(db).eliminar(tecnico_id)
