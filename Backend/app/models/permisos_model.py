from sqlalchemy import (
    Column, Integer, Boolean, TIMESTAMP,
    ForeignKey, UniqueConstraint, func
)
from sqlalchemy.orm import relationship
from app.core.db import Base

class Permiso(Base):
    __tablename__ = "permisos"

    id = Column(Integer, primary_key=True, index=True)

    # Foreign keys
    usuario_id = Column(Integer, ForeignKey("usuario.id", ondelete="CASCADE"), nullable=False)
    rol_id = Column(Integer, ForeignKey("rol.id", ondelete="CASCADE"), nullable=False)

    # Permisos principales
    crear = Column(Boolean, default=False)
    registrar = Column(Boolean, default=False)
    editar = Column(Boolean, default=False)
    eliminar = Column(Boolean, default=False)
    visualizar = Column(Boolean, default=False)
    cambiar_estado = Column(Boolean, default=False)

    # Permisos adicionales
    exportar = Column(Boolean, default=False)
    importar = Column(Boolean, default=False)
    aprobar = Column(Boolean, default=False)
    rechazar = Column(Boolean, default=False)
    imprimir = Column(Boolean, default=False)
    administrar = Column(Boolean, default=False)

    estado = Column(Boolean, default=True)
    fecha_creacion = Column(TIMESTAMP, server_default=func.now())

    # Relaciones
    usuario = relationship("Usuario", back_populates="permisos")
    rol = relationship("Rol", back_populates="permisos")

    # Constraint unique usuario + rol
    __table_args__ = (
        UniqueConstraint("usuario_id", "rol_id", name="unique_usuario_rol"),
    )