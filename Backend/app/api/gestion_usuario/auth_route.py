from fastapi import APIRouter, Depends, Request, Response, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.db import get_db
from app.core.security import get_current_user_from_cookie
from app.services.gestion_usuario.auth_service import AuthService
from app.schemas.auth_schema import (
    LoginRequest, RecuperarPasswordRequest, ResetPasswordRequest
)


router = APIRouter(prefix="/auth", tags=["Autenticación"])


# ─── Login ───────────────────────────────────────────────────────
@router.post("/login")
async def login(
    data: LoginRequest,
    response: Response,
    db: AsyncSession = Depends(get_db),
):
    service = AuthService(db)
    return await service.login(data, response)


# ─── Logout ──────────────────────────────────────────────────────
@router.post("/logout")
async def logout(
    response: Response,
    _: dict = Depends(get_current_user_from_cookie),
    db: AsyncSession = Depends(get_db),
):
    service = AuthService(db)
    return await service.logout(response)


# ─── Refresh token ───────────────────────────────────────────────
@router.post("/refresh")
async def refresh_token(
    request: Request,
    response: Response,
    db: AsyncSession = Depends(get_db),
):
    refresh_token = request.cookies.get("refresh_token")
    if not refresh_token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="No hay refresh token",
        )
    service = AuthService(db)
    return await service.refresh_token(refresh_token, response)


# ─── Recuperar contraseña ────────────────────────────────────────
@router.post("/recuperar-password")
async def recuperar_password(
    data: RecuperarPasswordRequest,
    db: AsyncSession = Depends(get_db),
):
    service = AuthService(db)
    return await service.recuperar_password(data)


# ─── Reset contraseña ────────────────────────────────────────────
@router.post("/reset-password")
async def reset_password(
    data: ResetPasswordRequest,
    db: AsyncSession = Depends(get_db),
):
    service = AuthService(db)
    return await service.reset_password(data)


# ─── Google OAuth - Obtener URL ──────────────────────────────────
@router.get("/google")
async def google_auth_url(
    db: AsyncSession = Depends(get_db),
):
    service = AuthService(db)
    return await service.google_auth_url()


# ─── Google OAuth - Callback ─────────────────────────────────────
@router.get("/google/callback")
async def google_callback(
    code: str,
    response: Response,
    db: AsyncSession = Depends(get_db),
):
    service = AuthService(db)
    return await service.google_callback(code, response)


# ─── Me (usuario autenticado) ────────────────────────────────────
@router.get("/me")
async def me(
    current_user: dict = Depends(get_current_user_from_cookie),
    db: AsyncSession = Depends(get_db),
):
    from app.services.gestion_usuario.usuario_service import UsuarioService
    service = UsuarioService(db)
    usuario_id = int(current_user.get("sub"))
    usuario = await service.obtener_por_id(usuario_id)
    return {
        "mensaje": "Usuario autenticado",
        "usuario": usuario,
    }