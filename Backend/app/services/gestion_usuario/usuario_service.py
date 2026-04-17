from fastapi import HTTPException, status, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession
from app.repositories.gestion_usuario.usuario.usuario_repository import UsuarioRepository
from app.schemas.usuario_schema import (
    UsuarioCreate, UsuarioUpdate, UsuarioResponse, CambiarPassword
)
from app.core.security import verify_password
from app.services.incidentes.cloudinary_service import subir_archivo_cloudinary


class UsuarioService:

    def __init__(self, db: AsyncSession):
        self.repo = UsuarioRepository(db)

    # ─── Crear ───────────────────────────────────────────────────
    async def crear(self, data: UsuarioCreate) -> UsuarioResponse:
        if await self.repo.obtener_por_correo(data.correo):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Ya existe un usuario con ese correo",
            )
        if await self.repo.obtener_por_usuario(data.usuario):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Ya existe un usuario con ese nombre de usuario",
            )
        usuario = await self.repo.crear(data)
        return UsuarioResponse.model_validate(usuario)

    # ─── Obtener por ID ──────────────────────────────────────────
    async def obtener_por_id(self, usuario_id: int) -> UsuarioResponse:
        usuario = await self.repo.obtener_por_id(usuario_id)
        if not usuario:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Usuario con id {usuario_id} no encontrado",
            )
        return UsuarioResponse.model_validate(usuario)

    # ─── Listar ──────────────────────────────────────────────────
    async def listar(self, solo_activos: bool = False) -> list[UsuarioResponse]:
        usuarios = await self.repo.listar(solo_activos)
        return [UsuarioResponse.model_validate(u) for u in usuarios]

    # ─── Actualizar ──────────────────────────────────────────────
    async def actualizar(self, usuario_id: int, data: UsuarioUpdate) -> UsuarioResponse:
        await self.obtener_por_id(usuario_id)  # valida existencia
        if data.usuario:
            existente = await self.repo.obtener_por_usuario(data.usuario)
            if existente and existente.id != usuario_id:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Ya existe un usuario con ese nombre de usuario",
                )
        usuario = await self.repo.actualizar(usuario_id, data)
        return UsuarioResponse.model_validate(usuario)

    # ─── Cambiar contraseña ──────────────────────────────────────
    async def cambiar_password(self, usuario_id: int, data: CambiarPassword) -> dict:
        usuario = await self.repo.obtener_por_id(usuario_id)
        if not usuario:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Usuario no encontrado",
            )
        if not verify_password(data.password_actual, usuario.password):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="La contraseña actual es incorrecta",
            )
        if data.password_actual == data.password_nueva:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="La nueva contraseña no puede ser igual a la actual",
            )
        await self.repo.actualizar_password(usuario_id, data.password_nueva)
        return {"mensaje": "Contraseña actualizada correctamente"}

    async def subir_foto(self, usuario_id: int, foto: UploadFile, current_user_id: int) -> UsuarioResponse:
        usuario = await self.repo.obtener_por_id(usuario_id)
        if not usuario:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Usuario no encontrado",
            )
        if usuario.id != current_user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="No tienes permiso",
            )
        resultado = await subir_archivo_cloudinary(foto, carpeta="usuarios")
        usuario = await self.repo.actualizar(
            usuario_id,
            UsuarioUpdate.model_validate({"url": resultado["url"]}),
        )
        return UsuarioResponse.model_validate(usuario)

    # ─── Cambiar estado ──────────────────────────────────────────
    async def cambiar_estado(self, usuario_id: int, estado: bool) -> UsuarioResponse:
        await self.obtener_por_id(usuario_id)  # valida existencia
        usuario = await self.repo.cambiar_estado(usuario_id, estado)
        return UsuarioResponse.model_validate(usuario)

    # ─── Eliminar ────────────────────────────────────────────────
    async def eliminar(self, usuario_id: int) -> dict:
        await self.obtener_por_id(usuario_id)  # valida existencia
        await self.repo.eliminar(usuario_id)
        return {"mensaje": f"Usuario {usuario_id} eliminado correctamente"}