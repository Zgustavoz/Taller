from pydantic import BaseModel, EmailStr
from typing import Optional


class LoginRequest(BaseModel):
    usuario: str
    password: str                          # ← cambio


class LoginResponse(BaseModel):
    mensaje: str = "Inicio de sesión exitoso"
    usuario: dict


class RecuperarPasswordRequest(BaseModel): # ← cambio de nombre
    correo: EmailStr


class ResetPasswordRequest(BaseModel):     # ← cambio de nombre
    token: str
    nueva_password: str                    # ← cambio


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class GoogleCallbackRequest(BaseModel):
    code: str
    state: Optional[str] = None


class TallerLoginRequest(BaseModel):
    correo: EmailStr
    password: str