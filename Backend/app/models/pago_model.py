from sqlalchemy import (
    Column, Integer, Numeric, String, Boolean, TIMESTAMP, ForeignKey, func, Text
)
from sqlalchemy.orm import relationship
from app.core.db import Base


class Pago(Base):
    __tablename__ = "pagos"

    id                = Column(Integer, primary_key=True, index=True)
    id_incidente      = Column(Integer, ForeignKey("incidentes.id"), unique=True, nullable=False)
    id_usuario        = Column(Integer, ForeignKey("usuario.id"), nullable=False)
    id_taller         = Column(Integer, ForeignKey("talleres.id"), nullable=False)
    monto_total       = Column(Numeric(10, 2), nullable=False)
    monto_comision    = Column(Numeric(10, 2), nullable=False)  # 10%
    monto_taller      = Column(Numeric(10, 2), nullable=False)  # 90%
    metodo_pago       = Column(String(30), nullable=False, default="tarjeta")
    referencia_externa = Column(Text, nullable=True)   # payment_intent_id de Stripe
    estado_pago       = Column(String(20), nullable=False, default="pendiente")
    # pendiente | completado | fallido | reembolsado
    comision_pagada   = Column(Boolean, nullable=False, default=False)
    creado_en         = Column(TIMESTAMP(timezone=True), nullable=False, server_default=func.now())
    pagado_en         = Column(TIMESTAMP(timezone=True), nullable=True)

    # Relaciones
    incidente = relationship("Incidente", back_populates="pago")
    usuario   = relationship("Usuario")
    taller    = relationship("Taller")