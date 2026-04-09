from pydantic import BaseModel, EmailStr, field_validator
from typing import Optional
from datetime import datetime
import re


class UsuarioBase(BaseModel):
    nombre: str
    apellido: str
    usuario: str
    correo: EmailStr
    telefono: Optional[str] = None
    url: Optional[str] = None
    estado: Optional[bool] = True


class UsuarioCreate(UsuarioBase):
    password: str                          # ← cambio

    @field_validator("password")
    @classmethod
    def validar_password(cls, v):
        if len(v) < 8:
            raise ValueError("La contraseña debe tener al menos 8 caracteres")
        if not re.search(r"[A-Z]", v):
            raise ValueError("La contraseña debe tener al menos una mayúscula")
        if not re.search(r"[0-9]", v):
            raise ValueError("La contraseña debe tener al menos un número")
        return v

    @field_validator("usuario")
    @classmethod
    def validar_usuario(cls, v):
        if len(v) < 3:
            raise ValueError("El usuario debe tener al menos 3 caracteres")
        if not re.match(r"^[a-zA-Z0-9_]+$", v):
            raise ValueError("El usuario solo puede contener letras, números y guiones bajos")
        return v


class UsuarioUpdate(BaseModel):
    nombre: Optional[str] = None
    apellido: Optional[str] = None
    usuario: Optional[str] = None
    telefono: Optional[str] = None
    url: Optional[str] = None
    estado: Optional[bool] = None


class CambiarPassword(BaseModel):                # ← cambio de nombre de clase
    password_actual: str                         # ← cambio
    password_nueva: str                          # ← cambio

    @field_validator("password_nueva")
    @classmethod
    def validar_password_nueva(cls, v):
        if len(v) < 8:
            raise ValueError("La contraseña debe tener al menos 8 caracteres")
        if not re.search(r"[A-Z]", v):
            raise ValueError("La contraseña debe tener al menos una mayúscula")
        if not re.search(r"[0-9]", v):
            raise ValueError("La contraseña debe tener al menos un número")
        return v


class UsuarioResponse(UsuarioBase):
    id: int
    fecha_creacion: datetime

    class Config:
        from_attributes = True


class UsuarioConRolesResponse(UsuarioResponse):
    roles: list[str] = []