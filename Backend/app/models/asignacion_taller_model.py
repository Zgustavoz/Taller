from sqlalchemy import Column, Integer, String, Numeric, TIMESTAMP, ForeignKey, func
from sqlalchemy.orm import relationship
from app.core.db import Base


class AsignacionTaller(Base):
    __tablename__ = "asignaciones_talleres"

    id = Column(Integer, primary_key=True, index=True)
    incidente_id = Column(Integer, ForeignKey("incidentes.id", ondelete="CASCADE"), nullable=False)
    taller_id = Column(Integer, ForeignKey("talleres.id"), nullable=False)
    tecnico_id = Column(Integer, ForeignKey("tecnicos.id"), nullable=True)

    tipo_asignacion = Column(String(15), default="automatica", nullable=False)
    # automatica | manual

    distancia_km = Column(Numeric(6, 2), nullable=True)
    puntuacion_asignacion = Column(Numeric(5, 2), nullable=True)

    estado_respuesta = Column(String(20), default="pendiente", nullable=False)
    # pendiente | aceptado | rechazado | descartado | timeout

    respondido_at = Column(TIMESTAMP(timezone=True), nullable=True)
    creado_at = Column(TIMESTAMP(timezone=True), server_default=func.now())

    # Relaciones
    incidente = relationship("Incidente", back_populates="asignaciones")
    taller = relationship("Taller", back_populates="asignaciones")