from datetime import datetime
from typing import Optional

from pydantic import BaseModel


class HistorialEstadoResponse(BaseModel):
    id: int
    incidente_id: int
    estado_anterior: Optional[str] = None
    estado_nuevo: str
    tipo_actor: str
    id_actor: Optional[int] = None
    notas: Optional[str] = None
    creado_en: datetime

    class Config:
        from_attributes = True
