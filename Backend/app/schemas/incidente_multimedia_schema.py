from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class MultimediaResponse(BaseModel):
    id: int
    incidente_id: int
    tipo_archivo: str
    url_almacenamiento: str
    tipo_mime: Optional[str] = None
    duracion_seg: Optional[float] = None
    tamano_archivo_bytes: Optional[int] = None
    resultado_ia: Optional[str] = None
    subido_at: datetime

    class Config:
        from_attributes = True