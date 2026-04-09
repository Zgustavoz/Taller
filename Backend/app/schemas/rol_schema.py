from pydantic import BaseModel
from typing import Optional
from datetime import datetime


# ─── Base ────────────────────────────────────────────────────────
class RolBase(BaseModel):
    nombre: str
    descripcion: Optional[str] = None
    estado: Optional[bool] = True


# ─── Crear ───────────────────────────────────────────────────────
class RolCreate(RolBase):
    pass


# ─── Actualizar ──────────────────────────────────────────────────
class RolUpdate(BaseModel):
    nombre: Optional[str] = None
    descripcion: Optional[str] = None
    estado: Optional[bool] = None


# ─── Respuesta ───────────────────────────────────────────────────
class RolResponse(RolBase):
    id: int
    fecha_creacion: datetime

    class Config:
        from_attributes = True