from sqlalchemy import (
    Column, Integer, String, Text, BigInteger,
    Numeric, TIMESTAMP, ForeignKey, func
)
from sqlalchemy.orm import relationship
from app.core.db import Base


class IncidenteMultimedia(Base):
    __tablename__ = "incidente_multimedia"

    id = Column(Integer, primary_key=True, index=True)
    incidente_id = Column(Integer, ForeignKey("incidentes.id", ondelete="CASCADE"), nullable=False)

    tipo_archivo = Column(String(20), nullable=False)   # imagen | audio | video
    url_almacenamiento = Column(Text, nullable=False)
    public_id_cloudinary = Column(Text, nullable=True)  # para poder eliminar de Cloudinary
    tipo_mime = Column(String(50), nullable=True)
    duracion_seg = Column(Numeric(6, 2), nullable=True)
    tamano_archivo_bytes = Column(BigInteger, nullable=True)
    resultado_ia = Column(Text, nullable=True)
    subido_at = Column(TIMESTAMP(timezone=True), server_default=func.now())

    incidente = relationship("Incidente", back_populates="multimedia")