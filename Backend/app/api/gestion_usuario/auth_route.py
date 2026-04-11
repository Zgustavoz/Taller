from fastapi import APIRouter, Depends, Request, Response, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.db import get_db
from app.core.security import get_current_user_from_cookie, get_current_taller_from_cookie
from app.services.gestion_usuario.auth_service import AuthService
from app.services.gestion_usuario.taller_auth_service import TallerAuthService
from app.schemas.auth_schema import (
    LoginRequest, RecuperarPasswordRequest, ResetPasswordRequest, TallerLoginRequest
)
from app.schemas.taller_schema import TallerCreate


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


# ─── Auth Taller: Register ──────────────────────────────────────
@router.post("/taller/register")
async def register_taller(
    data: TallerCreate,
    response: Response,
    db: AsyncSession = Depends(get_db),
):
    service = TallerAuthService(db)
    return await service.register(data, response)


# ─── Auth Taller: Login ─────────────────────────────────────────
@router.post("/taller/login")
async def login_taller(
    data: TallerLoginRequest,
    response: Response,
    db: AsyncSession = Depends(get_db),
):
    service = TallerAuthService(db)
    return await service.login(data, response)


# ─── Auth Taller: Me ────────────────────────────────────────────
@router.get("/taller/me")
async def me_taller(
    current_taller: dict = Depends(get_current_taller_from_cookie),
    db: AsyncSession = Depends(get_db),
):
    service = TallerAuthService(db)
    taller_id = int(current_taller.get("sub"))
    return await service.me(taller_id)


# ─── Auth Taller: Refresh token ─────────────────────────────────
@router.post("/taller/refresh")
async def refresh_token_taller(
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

    service = TallerAuthService(db)
    return await service.refresh_token(refresh_token, response)


# ─── Auth Taller: Logout ────────────────────────────────────────
@router.post("/taller/logout")
async def logout_taller(
    response: Response,
    _: dict = Depends(get_current_taller_from_cookie),
    db: AsyncSession = Depends(get_db),
):
    service = AuthService(db)
    return await service.logout(response)