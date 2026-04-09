from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.db import get_db
from app.core.security import get_current_user_from_cookie
from app.services.gestion_usuario.rol_service import RolService
from app.schemas.rol_schema import RolCreate, RolUpdate, RolResponse

router = APIRouter(prefix="/roles", tags=["Roles"])


# ─── Crear rol ───────────────────────────────────────────────────
@router.post("/", response_model=RolResponse, status_code=status.HTTP_201_CREATED)
async def crear_rol(
    data: RolCreate,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    service = RolService(db)
    return await service.crear(data)


# ─── Listar roles ────────────────────────────────────────────────
@router.get("/", response_model=list[RolResponse])
async def listar_roles(
    solo_activos: bool = False,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    service = RolService(db)
    return await service.listar(solo_activos)


# ─── Obtener rol por ID ──────────────────────────────────────────
@router.get("/{rol_id}", response_model=RolResponse)
async def obtener_rol(
    rol_id: int,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    service = RolService(db)
    return await service.obtener_por_id(rol_id)


# ─── Actualizar rol ──────────────────────────────────────────────
@router.put("/{rol_id}", response_model=RolResponse)
async def actualizar_rol(
    rol_id: int,
    data: RolUpdate,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    service = RolService(db)
    return await service.actualizar(rol_id, data)


# ─── Cambiar estado ──────────────────────────────────────────────
@router.patch("/{rol_id}/estado", response_model=RolResponse)
async def cambiar_estado(
    rol_id: int,
    estado: bool,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    service = RolService(db)
    return await service.cambiar_estado(rol_id, estado)


# ─── Eliminar rol ────────────────────────────────────────────────
@router.delete("/{rol_id}", response_model=dict)
async def eliminar_rol(
    rol_id: int,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    service = RolService(db)
    return await service.eliminar(rol_id)