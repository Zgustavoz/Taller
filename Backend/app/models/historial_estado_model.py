from sqlalchemy import (
    Column, BigInteger, Integer, String, Text, TIMESTAMP, ForeignKey, func
)
from sqlalchemy.orm import relationship
from app.core.db import Base


class HistorialEstado(Base):
    __tablename__ = "historial_estados"

    id = Column(BigInteger, primary_key=True, autoincrement=True)
    incidente_id = Column(Integer, ForeignKey("incidentes.id"), nullable=False)
    estado_anterior = Column(String(30), nullable=True)
    estado_nuevo = Column(String(30), nullable=False)
    tipo_actor = Column(String(10), nullable=False)
    id_actor = Column(Integer, nullable=True)
    notas = Column(Text, nullable=True)
    creado_en = Column(TIMESTAMP(timezone=True), nullable=False, server_default=func.now())

    incidente = relationship("Incidente", back_populates="historial")
