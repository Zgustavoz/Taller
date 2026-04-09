import httpx
import resend
from fastapi import HTTPException, status, Response
from sqlalchemy.ext.asyncio import AsyncSession
from itsdangerous import URLSafeTimedSerializer, SignatureExpired, BadSignature

from app.repositories.gestion_usuario.usuario.usuario_repository import UsuarioRepository
from app.core.security import (
    verify_password, create_access_token,
    create_refresh_token, set_auth_cookies, decode_token
)
from app.core.config import settings
from app.schemas.auth_schema import LoginRequest, RecuperarPasswordRequest, ResetPasswordRequest


# Serializador para tokens de recuperación de contraseña
serializer = URLSafeTimedSerializer(settings.SECRET_KEY)


class AuthService:

    def __init__(self, db: AsyncSession):
        self.repo = UsuarioRepository(db)

    # ─── Login ───────────────────────────────────────────────────
    async def login(self, data: LoginRequest, response: Response) -> dict:
        usuario = await self.repo.obtener_por_usuario_o_correo(data.usuario)

        if not usuario:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Credenciales incorrectas",
            )
        if not usuario.estado:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Usuario inactivo, contacte al administrador",
            )
        if not verify_password(data.password, usuario.password):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Credenciales incorrectas",
            )

        payload = {"sub": str(usuario.id), "usuario": usuario.usuario}
        access_token = create_access_token(payload)
        refresh_token = create_refresh_token(payload)

        set_auth_cookies(response, access_token, refresh_token)

        return {
            "mensaje": "Inicio de sesión exitoso",
            "usuario": {
                "id": usuario.id,
                "nombre": usuario.nombre,
                "apellido": usuario.apellido,
                "usuario": usuario.usuario,
                "correo": usuario.correo,
                "url": usuario.url,
            },
        }

    # ─── Logout ──────────────────────────────────────────────────
    async def logout(self, response: Response) -> dict:
        from app.core.security import clear_auth_cookies
        clear_auth_cookies(response)
        return {"mensaje": "Sesión cerrada correctamente"}

    # ─── Refresh token ───────────────────────────────────────────
    async def refresh_token(self, refresh_token: str, response: Response) -> dict:
        payload = decode_token(refresh_token)

        if payload.get("type") != "refresh":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token inválido",
            )

        usuario_id = int(payload.get("sub"))
        usuario = await self.repo.obtener_por_id(usuario_id)

        if not usuario or not usuario.estado:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Usuario no encontrado o inactivo",
            )

        nuevo_payload = {"sub": str(usuario.id), "usuario": usuario.usuario}
        nuevo_access = create_access_token(nuevo_payload)
        nuevo_refresh = create_refresh_token(nuevo_payload)

        set_auth_cookies(response, nuevo_access, nuevo_refresh)
        return {"mensaje": "Token renovado correctamente"}

    # ─── Recuperar contraseña (envío de correo) ──────────────────
    async def recuperar_password(self, data: RecuperarPasswordRequest) -> dict:
        usuario = await self.repo.obtener_por_correo(data.correo)

        # Siempre respondemos igual por seguridad (no revelar si existe el correo)
        if not usuario:
            return {"mensaje": "Si el correo existe, recibirás un enlace de recuperación"}

        # Generar token seguro con expiración de 30 minutos
        token = serializer.dumps(data.correo, salt="recuperar-password")
        reset_url = f"{settings.FRONTEND_URL}/reset-password?token={token}"

        # Enviar correo con Resend
        resend.api_key = settings.RESEND_API_KEY
        try:
            resend.Emails.send({
                "from": settings.RESEND_FROM_EMAIL,
                "to": data.correo,
                "subject": "Recuperación de contraseña",
                "html": f"""
                    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                        <h2>Recuperación de contraseña</h2>
                        <p>Hola <strong>{usuario.nombre}</strong>,</p>
                        <p>Recibimos una solicitud para restablecer tu contraseña.</p>
                        <p>Haz clic en el siguiente botón para continuar:</p>
                        <a href="{reset_url}"
                           style="display: inline-block; padding: 12px 24px;
                                  background-color: #4F46E5; color: white;
                                  text-decoration: none; border-radius: 6px;
                                  margin: 16px 0;">
                            Restablecer contraseña
                        </a>
                        <p>Este enlace expirará en <strong>30 minutos</strong>.</p>
                        <p>Si no solicitaste esto, ignora este correo.</p>
                    </div>
                """,
            })
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Error al enviar el correo: {str(e)}",
            )

        return {"mensaje": "Si el correo existe, recibirás un enlace de recuperación"}

    # ─── Reset contraseña ────────────────────────────────────────
    async def reset_password(self, data: ResetPasswordRequest) -> dict:
        try:
            # Token válido por 30 minutos (1800 segundos)
            correo = serializer.loads(
                data.token,
                salt="recuperar-password",
                max_age=1800,
            )
        except SignatureExpired:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="El enlace de recuperación ha expirado",
            )
        except BadSignature:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="El enlace de recuperación es inválido",
            )

        usuario = await self.repo.obtener_por_correo(correo)
        if not usuario:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Usuario no encontrado",
            )

        await self.repo.actualizar_password(usuario.id, data.nueva_password)
        return {"mensaje": "Contraseña restablecida correctamente"}

    # ─── Google OAuth - Obtener URL ──────────────────────────────
    async def google_auth_url(self) -> dict:
        params = {
            "client_id": settings.GOOGLE_CLIENT_ID,
            "redirect_uri": settings.GOOGLE_REDIRECT_URI,
            "response_type": "code",
            "scope": "openid email profile",
            "access_type": "offline",
        }
        query = "&".join(f"{k}={v}" for k, v in params.items())
        url = f"https://accounts.google.com/o/oauth2/v2/auth?{query}"
        return {"url": url}

    # ─── Google OAuth - Callback ─────────────────────────────────
    async def google_callback(self, code: str, response: Response) -> dict:
        # 1. Intercambiar code por tokens de Google
        async with httpx.AsyncClient() as client:
            token_response = await client.post(
                "https://oauth2.googleapis.com/token",
                data={
                    "code": code,
                    "client_id": settings.GOOGLE_CLIENT_ID,
                    "client_secret": settings.GOOGLE_CLIENT_SECRET,
                    "redirect_uri": settings.GOOGLE_REDIRECT_URI,
                    "grant_type": "authorization_code",
                },
            )
            if token_response.status_code != 200:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Error al obtener token de Google",
                )
            token_data = token_response.json()

            # 2. Obtener info del usuario de Google
            user_response = await client.get(
                "https://www.googleapis.com/oauth2/v3/userinfo",
                headers={"Authorization": f"Bearer {token_data['access_token']}"},
            )
            if user_response.status_code != 200:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Error al obtener información del usuario de Google",
                )
            google_user = user_response.json()

        correo = google_user.get("email")
        nombre = google_user.get("given_name", "")
        apellido = google_user.get("family_name", "")
        foto = google_user.get("picture", "")

        # 3. Verificar si ya existe el usuario
        usuario = await self.repo.obtener_por_correo(correo)

        if not usuario:
            # 4. Crear usuario nuevo desde Google
            username_base = correo.split("@")[0]
            username = username_base
            contador = 1
            while await self.repo.obtener_por_usuario(username):
                username = f"{username_base}{contador}"
                contador += 1

            usuario = await self.repo.crear_desde_google(
                nombre=nombre,
                apellido=apellido,
                correo=correo,
                usuario=username,
                url=foto,
            )

        if not usuario.estado:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Usuario inactivo, contacte al administrador",
            )

        # 5. Generar JWT y setear cookies
        payload = {"sub": str(usuario.id), "usuario": usuario.usuario}
        access_token = create_access_token(payload)
        refresh_token = create_refresh_token(payload)
        set_auth_cookies(response, access_token, refresh_token)

        return {
            "mensaje": "Autenticación con Google exitosa",
            "usuario": {
                "id": usuario.id,
                "nombre": usuario.nombre,
                "apellido": usuario.apellido,
                "usuario": usuario.usuario,
                "correo": usuario.correo,
                "url": usuario.url,
            },
        }