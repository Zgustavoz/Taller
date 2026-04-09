from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete, or_
from typing import Optional
from app.models.usuario_model import Usuario
from app.schemas.usuario_schema import UsuarioCreate, UsuarioUpdate
from app.core.security import hash_password


class UsuarioRepository:

    def __init__(self, db: AsyncSession):
        self.db = db

    # ─── Crear ───────────────────────────────────────────────────
    async def crear(self, data: UsuarioCreate) -> Usuario:
        datos = data.model_dump()
        datos["password"] = hash_password(datos["password"])
        usuario = Usuario(**datos)
        self.db.add(usuario)
        await self.db.flush()
        await self.db.refresh(usuario)
        return usuario

    # ─── Crear desde Google OAuth ────────────────────────────────
    async def crear_desde_google(
        self,
        nombre: str,
        apellido: str,
        correo: str,
        usuario: str,
        url: Optional[str] = None,
    ) -> Usuario:
        nuevo = Usuario(
            nombre=nombre,
            apellido=apellido,
            correo=correo,
            usuario=usuario,
            password=hash_password("GOOGLE_OAUTH_NO_PASSWORD"),
            url=url,
            estado=True,
        )
        self.db.add(nuevo)
        await self.db.flush()
        await self.db.refresh(nuevo)
        return nuevo

    # ─── Obtener por ID ──────────────────────────────────────────
    async def obtener_por_id(self, usuario_id: int) -> Optional[Usuario]:
        result = await self.db.execute(
            select(Usuario).where(Usuario.id == usuario_id)
        )
        return result.scalar_one_or_none()

    # ─── Obtener por correo ──────────────────────────────────────
    async def obtener_por_correo(self, correo: str) -> Optional[Usuario]:
        result = await self.db.execute(
            select(Usuario).where(Usuario.correo == correo)
        )
        return result.scalar_one_or_none()

    # ─── Obtener por username ────────────────────────────────────
    async def obtener_por_usuario(self, usuario: str) -> Optional[Usuario]:
        result = await self.db.execute(
            select(Usuario).where(Usuario.usuario == usuario)
        )
        return result.scalar_one_or_none()

    # ─── Buscar por usuario O correo (para login) ────────────────
    async def obtener_por_usuario_o_correo(self, identificador: str) -> Optional[Usuario]:
        result = await self.db.execute(
            select(Usuario).where(
                or_(
                    Usuario.usuario == identificador,
                    Usuario.correo == identificador,
                )
            )
        )
        return result.scalar_one_or_none()

    # ─── Listar todos ────────────────────────────────────────────
    async def listar(self, solo_activos: bool = False) -> list[Usuario]:
        query = select(Usuario)
        if solo_activos:
            query = query.where(Usuario.estado == True)
        result = await self.db.execute(query)
        return result.scalars().all()

    # ─── Actualizar ──────────────────────────────────────────────
    async def actualizar(self, usuario_id: int, data: UsuarioUpdate) -> Optional[Usuario]:
        valores = {k: v for k, v in data.model_dump().items() if v is not None}
        if not valores:
            return await self.obtener_por_id(usuario_id)
        await self.db.execute(
            update(Usuario).where(Usuario.id == usuario_id).values(**valores)
        )
        await self.db.flush()
        return await self.obtener_por_id(usuario_id)

    # ─── Actualizar contraseña ───────────────────────────────────
    async def actualizar_password(self, usuario_id: int, nueva_password: str) -> bool:
        hashed = hash_password(nueva_password)
        result = await self.db.execute(
            update(Usuario)
            .where(Usuario.id == usuario_id)
            .values(password=hashed)
        )
        await self.db.flush()
        return result.rowcount > 0

    # ─── Cambiar estado ──────────────────────────────────────────
    async def cambiar_estado(self, usuario_id: int, estado: bool) -> Optional[Usuario]:
        await self.db.execute(
            update(Usuario).where(Usuario.id == usuario_id).values(estado=estado)
        )
        await self.db.flush()
        return await self.obtener_por_id(usuario_id)

    # ─── Eliminar ────────────────────────────────────────────────
    async def eliminar(self, usuario_id: int) -> bool:
        result = await self.db.execute(
            delete(Usuario).where(Usuario.id == usuario_id)
        )
        return result.rowcount > 0