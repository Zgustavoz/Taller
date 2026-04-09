from sqlalchemy import Column, Integer, String, Boolean, Text, TIMESTAMP, func
from app.core.db import Base
from sqlalchemy.orm import relationship

class Rol(Base):
    __tablename__ = "rol"

    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String(100), unique=True, nullable=False)
    descripcion = Column(Text, nullable=True)
    estado = Column(Boolean, default=True)
    fecha_creacion = Column(TIMESTAMP, server_default=func.now())

    # Relación inversa
    permisos = relationship("Permiso", back_populates="rol", cascade="all, delete")