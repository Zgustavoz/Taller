from sqlalchemy import Column, Integer, String, Boolean, TIMESTAMP, ForeignKey, func
from sqlalchemy.orm import relationship
from app.core.db import Base


class Vehiculo(Base):
    __tablename__ = "vehiculos"

    id = Column(Integer, primary_key=True, index=True)
    usuario_id = Column(Integer, ForeignKey("usuario.id", ondelete="CASCADE"), nullable=False)
    marca = Column(String(100), nullable=False)
    modelo = Column(String(100), nullable=False)
    year = Column(Integer, nullable=False)
    placa = Column(String(20), unique=True, nullable=False)
    color = Column(String(50), nullable=True)
    tipo = Column(String(50), nullable=True)       # sedan, suv, pickup, moto, etc.
    url_foto = Column(String(255), nullable=True)
    estado = Column(Boolean, default=True)
    fecha_creacion = Column(TIMESTAMP, server_default=func.now())

    usuario = relationship("Usuario", back_populates="vehiculos")
    incidentes = relationship("Incidente", back_populates="vehiculo", cascade="all, delete-orphan")