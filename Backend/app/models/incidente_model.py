from sqlalchemy import (
    Column, Integer, String, Text, SmallInteger,
    TIMESTAMP, ForeignKey, func
)
from sqlalchemy.orm import relationship
from geoalchemy2 import Geometry
from app.core.db import Base


class Incidente(Base):
    __tablename__ = "incidentes"

    id = Column(Integer, primary_key=True, index=True)
    usuario_id = Column(Integer, ForeignKey("usuario.id", ondelete="CASCADE"), nullable=False)
    vehiculo_id = Column(Integer, ForeignKey("vehiculos.id"), nullable=True)
    taller_asignado_id = Column(Integer, ForeignKey("talleres.id"), nullable=True)
    tecnico_asignado_id = Column(Integer, ForeignKey("tecnicos.id"), nullable=True)
    tipo_incidente_id = Column(Integer, ForeignKey("tipos_incidente.id"), nullable=True)

    # Ubicación PostGIS
    ubicacion = Column(Geometry(geometry_type="POINT", srid=4326), nullable=False)
    texto_direccion = Column(Text, nullable=True)
    descripcion = Column(Text, nullable=True)

    estado = Column(
        String(30),
        default="pendiente",
        nullable=False,
    )
    nivel_prioridad = Column(SmallInteger, nullable=True)
    analisis_ia = Column(Text, nullable=True)
    ficha_resumen = Column(Text, nullable=True)
    tiempo_estimado_llegada_min = Column(SmallInteger, nullable=True)

    creado_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    resuelto_at = Column(TIMESTAMP(timezone=True), nullable=True)

    # Relaciones
    usuario = relationship("Usuario", back_populates="incidentes")
    vehiculo = relationship("Vehiculo")
    taller = relationship("Taller", back_populates="incidentes")
    tecnico = relationship("Tecnico")
    tipo_incidente = relationship("TipoIncidente", back_populates="incidentes")
    multimedia = relationship("IncidenteMultimedia", back_populates="incidente", cascade="all, delete")
    historial = relationship("HistorialEstado", back_populates="incidente", cascade="all, delete")