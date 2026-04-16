from pydantic import BaseModel
from typing import Optional


class TipoIncidenteBase(BaseModel):
    codigo: str
    nombre: str
    prioridad_base: Optional[int] = None


class TipoIncidenteCreate(TipoIncidenteBase):
    pass


class TipoIncidenteUpdate(BaseModel):
    codigo: Optional[str] = None
    nombre: Optional[str] = None
    prioridad_base: Optional[int] = None


class TipoIncidenteResponse(TipoIncidenteBase):
    id: int

    class Config:
        from_attributes = True