from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional
from app.core.db import get_db
from app.core.security import get_current_user_from_cookie
from app.services.incidentes.incidente_service import IncidenteService
from app.schemas.incidente_schema import IncidenteCreate, IncidenteUpdate

router = APIRouter(prefix="/incidentes", tags=["Incidentes"])


@router.post("/", status_code=status.HTTP_201_CREATED)
async def crear_incidente(
    data: IncidenteCreate,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user_from_cookie),
):
    usuario_id = int(current_user.get("sub"))
    return await IncidenteService(db).crear(data, usuario_id)


@router.get("/mis-incidentes")
async def mis_incidentes(
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user_from_cookie),
):
    usuario_id = int(current_user.get("sub"))
    return await IncidenteService(db).listar_por_usuario(usuario_id)


@router.get("/")
async def listar_todos(
    estado: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    return await IncidenteService(db).listar_todos(estado)


@router.get("/{incidente_id}")
async def obtener_incidente(
    incidente_id: int,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    return await IncidenteService(db).obtener_por_id(incidente_id)


@router.put("/{incidente_id}")
async def actualizar_incidente(
    incidente_id: int,
    data: IncidenteUpdate,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    return await IncidenteService(db).actualizar(incidente_id, data)


@router.patch("/{incidente_id}/estado")
async def cambiar_estado(
    incidente_id: int,
    estado: str,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    return await IncidenteService(db).cambiar_estado(incidente_id, estado)


@router.delete("/{incidente_id}")
async def eliminar_incidente(
    incidente_id: int,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    return await IncidenteService(db).eliminar(incidente_id)