from sqlalchemy import Column, Integer, String, Boolean, Text, TIMESTAMP, Numeric, func, text
from sqlalchemy.dialects.postgresql import ARRAY
from sqlalchemy.orm import relationship
from geoalchemy2 import Geometry
from app.core.db import Base


class Taller(Base):
    __tablename__ = "talleres"

    id = Column(Integer, primary_key=True, index=True)
    nombre_propietario = Column(String(150), nullable=False)
    nombre_negocio = Column(String(200), nullable=False)
    correo = Column(String(150), unique=True, nullable=False)
    contrasena_hash = Column(Text, nullable=False)
    telefono = Column(String(20), nullable=False)
    direccion = Column(Text, nullable=True)
    ubicacion = Column(Geometry(geometry_type="POINT", srid=4326), nullable=False)
    radio_cobertura_km = Column(Numeric(5, 2), nullable=False, server_default=text("10"))
    especialidades = Column(ARRAY(Text), nullable=False, server_default=text("'{}'::text[]"))
    esta_disponible = Column(Boolean, nullable=False, server_default=text("true"))
    calificacion_promedio = Column(Numeric(3, 2), nullable=False, server_default=text("0"))
    token_fcm = Column(Text, nullable=True)
    esta_activo = Column(Boolean, nullable=False, server_default=text("true"))
    creado_en = Column(TIMESTAMP(timezone=True), nullable=False, server_default=func.now())

    #relacion con incidentes
    incidentes = relationship("Incidente", back_populates="taller")
    asignaciones = relationship("AsignacionTaller", back_populates="taller")
