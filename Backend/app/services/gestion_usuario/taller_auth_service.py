from fastapi import HTTPException, Response, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    set_auth_cookies,
    verify_password,
)
from app.repositories.gestion_usuario.taller.taller_repository import TallerRepository
from app.schemas.auth_schema import TallerLoginRequest
from app.schemas.taller_schema import TallerCreate, TallerResponse


class TallerAuthService:

    def __init__(self, db: AsyncSession):
        self.repo = TallerRepository(db)

    async def register(self, data: TallerCreate, response: Response) -> dict:
        if await self.repo.obtener_por_correo(data.correo):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Ya existe un taller con ese correo",
            )

        taller = await self.repo.crear(data)
        payload = {
            "sub": str(taller["id"]),
            "correo": taller["correo"],
            "actor_type": "taller",
        }

        access_token = create_access_token(payload)
        refresh_token = create_refresh_token(payload)
        set_auth_cookies(response, access_token, refresh_token)

        return {
            "mensaje": "Registro de taller exitoso",
            "taller": TallerResponse.model_validate(taller),
        }

    async def login(self, data: TallerLoginRequest, response: Response) -> dict:
        taller = await self.repo.obtener_por_correo(data.correo)
        if not taller:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Credenciales incorrectas",
            )

        if not taller.esta_activo:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Taller inactivo, contacte al administrador",
            )

        if not verify_password(data.password, taller.contrasena_hash):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Credenciales incorrectas",
            )

        taller_payload = await self.repo.obtener_por_id(taller.id)
        payload = {
            "sub": str(taller.id),
            "correo": taller.correo,
            "actor_type": "taller",
        }

        access_token = create_access_token(payload)
        refresh_token = create_refresh_token(payload)
        set_auth_cookies(response, access_token, refresh_token)

        return {
            "mensaje": "Inicio de sesión de taller exitoso",
            "taller": TallerResponse.model_validate(taller_payload),
        }

    async def me(self, taller_id: int) -> dict:
        taller = await self.repo.obtener_por_id(taller_id)
        if not taller:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Taller con id {taller_id} no encontrado",
            )

        return {
            "mensaje": "Taller autenticado",
            "taller": TallerResponse.model_validate(taller),
        }

    async def refresh_token(self, refresh_token: str, response: Response) -> dict:
        payload = decode_token(refresh_token)

        if payload.get("type") != "refresh" or payload.get("actor_type") != "taller":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token inválido",
            )

        taller_id = int(payload.get("sub"))
        taller = await self.repo.obtener_por_id(taller_id)

        if not taller or not taller.get("esta_activo", False):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Taller no encontrado o inactivo",
            )

        nuevo_payload = {
            "sub": str(taller_id),
            "correo": taller["correo"],
            "actor_type": "taller",
        }
        nuevo_access = create_access_token(nuevo_payload)
        nuevo_refresh = create_refresh_token(nuevo_payload)
        set_auth_cookies(response, nuevo_access, nuevo_refresh)

        return {"mensaje": "Token de taller renovado correctamente"}
