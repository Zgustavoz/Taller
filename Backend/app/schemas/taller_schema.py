from datetime import datetime
from pydantic import BaseModel, EmailStr, Field, field_validator
from typing import Optional
import re


class UbicacionPoint(BaseModel):
    latitud: float = Field(ge=-90, le=90)
    longitud: float = Field(ge=-180, le=180)


class TallerBase(BaseModel):
    nombre_propietario: str
    nombre_negocio: str
    correo: EmailStr
    telefono: str
    direccion: Optional[str] = None
    ubicacion: UbicacionPoint
    radio_cobertura_km: float = Field(default=10, gt=0)
    especialidades: list[str] = Field(default_factory=list)
    esta_disponible: bool = True
    calificacion_promedio: float = Field(default=0, ge=0, le=5)
    token_fcm: Optional[str] = None
    esta_activo: bool = True


class TallerCreate(TallerBase):
    contrasena: str

    @field_validator("contrasena")
    @classmethod
    def validar_contrasena(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError("La contraseña debe tener al menos 8 caracteres")
        if not re.search(r"[A-Z]", v):
            raise ValueError("La contraseña debe tener al menos una mayúscula")
        if not re.search(r"[0-9]", v):
            raise ValueError("La contraseña debe tener al menos un número")
        return v


class TallerUpdate(BaseModel):
    nombre_propietario: Optional[str] = None
    nombre_negocio: Optional[str] = None
    correo: Optional[EmailStr] = None
    contrasena: Optional[str] = None
    telefono: Optional[str] = None
    direccion: Optional[str] = None
    ubicacion: Optional[UbicacionPoint] = None
    radio_cobertura_km: Optional[float] = Field(default=None, gt=0)
    especialidades: Optional[list[str]] = None
    esta_disponible: Optional[bool] = None
    calificacion_promedio: Optional[float] = Field(default=None, ge=0, le=5)
    token_fcm: Optional[str] = None
    esta_activo: Optional[bool] = None

    @field_validator("contrasena")
    @classmethod
    def validar_contrasena(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return v
        if len(v) < 8:
            raise ValueError("La contraseña debe tener al menos 8 caracteres")
        if not re.search(r"[A-Z]", v):
            raise ValueError("La contraseña debe tener al menos una mayúscula")
        if not re.search(r"[0-9]", v):
            raise ValueError("La contraseña debe tener al menos un número")
        return v


class TallerResponse(TallerBase):
    id: int
    creado_en: datetime

    class Config:
        from_attributes = True


class SolicitudPanelMinimaResponse(BaseModel):
    id: int
    estado: str
    nivel_prioridad: Optional[int] = None
    tipo_incidente_nombre: Optional[str] = None
    distancia_km: Optional[float] = None
    score: Optional[float] = None
    creado_at: Optional[datetime] = None
    usuario_nombre: Optional[str] = None
    vehiculo_placa: Optional[str] = None
    resumen: Optional[str] = None
