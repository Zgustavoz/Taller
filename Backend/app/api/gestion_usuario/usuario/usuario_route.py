from fastapi import APIRouter, Depends, UploadFile, File, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.db import get_db
from app.core.security import get_current_user_from_cookie
from app.services.gestion_usuario.usuario_service import UsuarioService
from app.schemas.usuario_schema import (
    UsuarioCreate, UsuarioUpdate, UsuarioResponse, CambiarPassword
)

router = APIRouter(prefix="/usuarios", tags=["Usuarios"])


# ─── Crear usuario ───────────────────────────────────────────────
@router.post("/", response_model=UsuarioResponse, status_code=status.HTTP_201_CREATED)
async def crear_usuario(
    data: UsuarioCreate,
    db: AsyncSession = Depends(get_db),
):
    service = UsuarioService(db)
    return await service.crear(data)


# ─── Listar usuarios ─────────────────────────────────────────────
@router.get("/", response_model=list[UsuarioResponse])
async def listar_usuarios(
    solo_activos: bool = False,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    service = UsuarioService(db)
    return await service.listar(solo_activos)


# ─── Obtener usuario por ID ──────────────────────────────────────
@router.get("/{usuario_id}", response_model=UsuarioResponse)
async def obtener_usuario(
    usuario_id: int,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    service = UsuarioService(db)
    return await service.obtener_por_id(usuario_id)


# ─── Actualizar usuario ──────────────────────────────────────────
@router.put("/{usuario_id}", response_model=UsuarioResponse)
async def actualizar_usuario(
    usuario_id: int,
    data: UsuarioUpdate,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    service = UsuarioService(db)
    return await service.actualizar(usuario_id, data)


@router.patch("/{usuario_id}/foto", response_model=UsuarioResponse)
async def subir_foto_usuario(
    usuario_id: int,
    foto: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user_from_cookie),
):
    service = UsuarioService(db)
    return await service.subir_foto(usuario_id, foto, int(current_user["sub"]))


# ─── Cambiar contraseña ──────────────────────────────────────────
@router.patch("/{usuario_id}/cambiar-password", response_model=dict)
async def cambiar_contraseña(
    usuario_id: int,
    data: CambiarPassword,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    service = UsuarioService(db)
    return await service.cambiar_password(usuario_id, data)


# ─── Cambiar estado ──────────────────────────────────────────────
@router.patch("/{usuario_id}/estado", response_model=UsuarioResponse)
async def cambiar_estado(
    usuario_id: int,
    estado: bool,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    service = UsuarioService(db)
    return await service.cambiar_estado(usuario_id, estado)


# ─── Eliminar usuario ────────────────────────────────────────────
@router.delete("/{usuario_id}", response_model=dict)
async def eliminar_usuario(
    usuario_id: int,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    service = UsuarioService(db)
    return await service.eliminar(usuario_id)