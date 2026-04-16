from pydantic import BaseModel, field_validator
from typing import Optional
from datetime import datetime

TIPOS_VALIDOS = ["sedan", "suv", "pickup", "moto", "camion", "van", "otro"]


class VehiculoBase(BaseModel):
    marca: str
    modelo: str
    year: int
    placa: str
    color: Optional[str] = None
    tipo: Optional[str] = None
    url_foto: Optional[str] = None
    estado: Optional[bool] = True

    @field_validator("year")
    @classmethod
    def validar_year(cls, v):
        from datetime import datetime
        actual = datetime.now().year
        if not (1900 <= v <= actual + 1):
            raise ValueError(f"Año inválido. Debe estar entre 1900 y {actual + 1}")
        return v

    @field_validator("placa")
    @classmethod
    def validar_placa(cls, v):
        return v.upper().strip()


class VehiculoCreate(VehiculoBase):
    pass


class VehiculoUpdate(BaseModel):
    marca: Optional[str] = None
    modelo: Optional[str] = None
    year: Optional[int] = None
    placa: Optional[str] = None
    color: Optional[str] = None
    tipo: Optional[str] = None
    url_foto: Optional[str] = None
    estado: Optional[bool] = None


class VehiculoResponse(VehiculoBase):
    id: int
    usuario_id: int
    fecha_creacion: datetime

    class Config:
        from_attributes = True