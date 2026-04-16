from sqlalchemy import Column, Integer, String, Boolean, TIMESTAMP, Text, func
from sqlalchemy.orm import relationship
from app.core.db import Base

class Usuario(Base):
    __tablename__ = "usuario"

    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String(100), nullable=False)
    apellido = Column(String(100), nullable=False)
    usuario = Column(String(50), unique=True, nullable=False)
    correo = Column(String(150), unique=True, nullable=False)
    password = Column("contraseña", String(255), nullable=False)
    telefono = Column(String(20), nullable=True)
    url = Column(String(255), nullable=True)
    token_fcm = Column(Text, nullable=True)
    estado = Column(Boolean, default=True)
    fecha_creacion = Column(TIMESTAMP, server_default=func.now())

    # Relaciones
    permisos = relationship("Permiso", back_populates="usuario", cascade="all, delete")
    incidentes = relationship("Incidente", back_populates="usuario", cascade="all, delete") 
    vehiculos = relationship("Vehiculo", back_populates="usuario", cascade="all, delete")