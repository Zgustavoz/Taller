from pydantic import BaseModel, field_validator
from typing import Optional
from datetime import datetime


class CrearPaymentIntentRequest(BaseModel):
    incidente_id: int
    monto_total: float

    @field_validator("monto_total")
    @classmethod
    def validar_monto(cls, v):
        if v <= 0:
            raise ValueError("El monto debe ser mayor a 0")
        if v > 100000:
            raise ValueError("El monto excede el límite permitido")
        return round(v, 2)


class ConfirmarPagoRequest(BaseModel):
    incidente_id: int
    payment_intent_id: str
    monto_total: float


class PagoResponse(BaseModel):
    id: int
    monto_total: float
    monto_comision: float
    monto_taller: float
    estado_pago: str
    metodo_pago: str
    referencia_externa: Optional[str] = None
    creado_en: datetime
    pagado_en: Optional[datetime] = None

    class Config:
        from_attributes = True