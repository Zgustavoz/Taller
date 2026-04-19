from sqlalchemy import Column, Integer, String, Text, TIMESTAMP, ForeignKey, func
from sqlalchemy.orm import relationship
from app.core.db import Base


class HistorialEstado(Base):
    __tablename__ = "historial_estados"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    incidente_id = Column(Integer, ForeignKey("incidentes.id", ondelete="CASCADE"), nullable=False)

    estado_anterior = Column(String(30), nullable=True)
    estado_nuevo = Column(String(30), nullable=False)

    tipo_actor = Column(String(10), nullable=False)
    # usuario | taller | sistema | ia

    actor_id = Column(Integer, nullable=True)
    notas = Column(Text, nullable=True)

    creado_at = Column(TIMESTAMP(timezone=True), server_default=func.now())

    incidente = relationship("Incidente", back_populates="historial")