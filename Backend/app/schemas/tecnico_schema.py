from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel


class UbicacionActualInput(BaseModel):
    latitud: float
    longitud: float


class TecnicoBase(BaseModel):
    taller_id: int
    nombre_completo: str
    telefono: Optional[str] = None
    ubicacion_actual: Optional[UbicacionActualInput] = None
    especialidades: Optional[List[str]] = None
    esta_disponible: Optional[bool] = True
    token_fcm: Optional[str] = None
    esta_activo: Optional[bool] = True


class TecnicoCreate(TecnicoBase):
    pass


class TecnicoUpdate(BaseModel):
    nombre_completo: Optional[str] = None
    telefono: Optional[str] = None
    ubicacion_actual: Optional[UbicacionActualInput] = None
    especialidades: Optional[List[str]] = None
    esta_disponible: Optional[bool] = None
    token_fcm: Optional[str] = None
    esta_activo: Optional[bool] = None


class TecnicoResponse(BaseModel):
    id: int
    taller_id: int
    nombre_completo: str
    telefono: Optional[str] = None
    ubicacion_actual: Optional[dict] = None
    especialidades: List[str] = []
    esta_disponible: bool
    token_fcm: Optional[str] = None
    esta_activo: bool
    creado_en: datetime

    class Config:
        from_attributes = True
