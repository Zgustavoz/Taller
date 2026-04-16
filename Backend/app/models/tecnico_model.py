from sqlalchemy import (
    Column, Integer, String, Boolean, Text, TIMESTAMP, ForeignKey, func
)
from sqlalchemy.dialects.postgresql import ARRAY
from sqlalchemy.orm import relationship
from geoalchemy2 import Geometry
from app.core.db import Base


class Tecnico(Base):
    __tablename__ = "tecnicos"

    id = Column(Integer, primary_key=True, index=True)
    taller_id = Column(Integer, ForeignKey("talleres.id"), nullable=False)
    nombre_completo = Column(String(150), nullable=False)
    telefono = Column(String(20), nullable=True)
    ubicacion_actual = Column(Geometry(geometry_type="POINT", srid=4326), nullable=True)
    especialidades = Column( ARRAY(Text),nullable=False, default=list)
    esta_disponible = Column(Boolean, nullable=False, server_default="true")
    token_fcm = Column(Text, nullable=True)
    esta_activo = Column(Boolean, nullable=False, server_default="true")
    creado_en = Column(TIMESTAMP(timezone=True), nullable=False, server_default=func.now())

    taller = relationship("Taller")
    incidentes = relationship("Incidente", back_populates="tecnico")
