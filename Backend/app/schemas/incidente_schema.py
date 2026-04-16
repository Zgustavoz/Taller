from pydantic import BaseModel, field_validator
from typing import Optional, List
from datetime import datetime


ESTADOS_VALIDOS = [
    "pendiente", "analizando", "asignado",
    "en_progreso", "resuelto", "cancelado"
]


class UbicacionInput(BaseModel):
    latitud: float
    longitud: float


class IncidenteCreate(BaseModel):
    tipo_incidente_id: Optional[int] = None
    vehiculo_id: Optional[int] = None
    tecnico_asignado_id: Optional[int] = None
    latitud: float
    longitud: float
    texto_direccion: Optional[str] = None
    descripcion: Optional[str] = None
    nivel_prioridad: Optional[int] = None

    @field_validator("nivel_prioridad")
    @classmethod
    def validar_prioridad(cls, v):
        if v is not None and not (1 <= v <= 5):
            raise ValueError("El nivel de prioridad debe estar entre 1 y 5")
        return v


class IncidenteUpdate(BaseModel):
    tipo_incidente_id: Optional[int] = None
    vehiculo_id: Optional[int] = None
    tecnico_asignado_id: Optional[int] = None
    texto_direccion: Optional[str] = None
    descripcion: Optional[str] = None
    estado: Optional[str] = None
    nivel_prioridad: Optional[int] = None
    analisis_ia: Optional[str] = None
    ficha_resumen: Optional[str] = None
    tiempo_estimado_llegada_min: Optional[int] = None
    taller_asignado_id: Optional[int] = None
    resuelto_at: Optional[datetime] = None

    @field_validator("estado")
    @classmethod
    def validar_estado(cls, v):
        if v is not None and v not in ESTADOS_VALIDOS:
            raise ValueError(f"Estado inválido. Válidos: {ESTADOS_VALIDOS}")
        return v

    @field_validator("nivel_prioridad")
    @classmethod
    def validar_prioridad(cls, v):
        if v is not None and not (1 <= v <= 5):
            raise ValueError("El nivel de prioridad debe estar entre 1 y 5")
        return v


class VehiculoResumen(BaseModel):
    id: int
    marca: str
    modelo: str
    placa: str
    url_foto: Optional[str] = None


class TallerResumen(BaseModel):
    id: int
    nombre_negocio: str
    telefono: Optional[str] = None
    correo: Optional[str] = None


class TecnicoResumen(BaseModel):
    id: int
    nombre_completo: str
    telefono: Optional[str] = None
    esta_disponible: bool


class HistorialRegistro(BaseModel):
    id: int
    estado_anterior: Optional[str] = None
    estado_nuevo: str
    tipo_actor: str
    id_actor: Optional[int] = None
    notas: Optional[str] = None
    creado_en: datetime


class IncidenteResponse(BaseModel):
    id: int
    usuario_id: int
    vehiculo_id: Optional[int] = None
    taller_asignado_id: Optional[int] = None
    tecnico_asignado_id: Optional[int] = None
    tipo_incidente_id: Optional[int] = None
    latitud: Optional[float] = None
    longitud: Optional[float] = None
    texto_direccion: Optional[str] = None
    descripcion: Optional[str] = None
    estado: str
    nivel_prioridad: Optional[int] = None
    analisis_ia: Optional[str] = None
    ficha_resumen: Optional[str] = None
    tiempo_estimado_llegada_min: Optional[int] = None
    vehiculo: Optional[VehiculoResumen] = None
    taller: Optional[TallerResumen] = None
    tecnico: Optional[TecnicoResumen] = None
    historial: List[HistorialRegistro] = []
    creado_at: datetime
    resuelto_at: Optional[datetime] = None

    class Config:
        from_attributes = True