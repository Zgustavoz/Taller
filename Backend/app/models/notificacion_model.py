from sqlalchemy import Column, Integer, String, Text, TIMESTAMP, ForeignKey, func
from sqlalchemy.orm import relationship
from app.core.db import Base


class Notificacion(Base):
    __tablename__ = "notificaciones"

    id = Column(Integer, primary_key=True, index=True)
    tipo_destinatario = Column(String(15), nullable=False)
    # usuario | taller | tecnico

    id_destinatario = Column(Integer, nullable=False)
    incidente_id = Column(Integer, ForeignKey("incidentes.id"), nullable=True)

    titulo = Column(String(200), nullable=True)
    cuerpo = Column(Text, nullable=True)
    datos_extra = Column(Text, nullable=True)   # JSON como texto

    enviado_en = Column(TIMESTAMP(timezone=True), nullable=True)
    leido_en = Column(TIMESTAMP(timezone=True), nullable=True)

    estado = Column(String(15), default="pendiente", nullable=False)
    # pendiente | enviado | fallido | leido

    creado_en = Column(TIMESTAMP(timezone=True), server_default=func.now())

    incidente = relationship("Incidente", back_populates="notificaciones")