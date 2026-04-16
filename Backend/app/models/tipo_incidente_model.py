from sqlalchemy import Column, Integer, String, SmallInteger
from sqlalchemy.orm import relationship
from app.core.db import Base


class TipoIncidente(Base):
    __tablename__ = "tipos_incidente"

    id = Column(Integer, primary_key=True, index=True)
    codigo = Column(String(50), unique=True, nullable=False)
    nombre = Column(String(100), nullable=False)
    prioridad_base = Column(SmallInteger, nullable=True)

    incidentes = relationship("Incidente", back_populates="tipo_incidente")