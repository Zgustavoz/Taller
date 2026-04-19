from sqlalchemy import Column, Integer, String, Text, BigInteger, Numeric, TIMESTAMP, ForeignKey, func
from sqlalchemy.orm import relationship
from app.core.db import Base


class IncidenteMultimedia(Base):
    __tablename__ = "incidente_multimedia"

    id = Column(Integer, primary_key=True, index=True)
    incidente_id = Column(Integer, ForeignKey("incidentes.id", ondelete="CASCADE"), nullable=False)

    tipo_archivo = Column(String(10), nullable=False)   # image | audio | video
    url_almacenamiento = Column(Text, nullable=False)
    public_id_cloudinary = Column(Text, nullable=True)
    tipo_mime = Column(String(50), nullable=True)
    duracion_seg = Column(Numeric(6, 2), nullable=True)
    tamano_archivo_bytes = Column(BigInteger, nullable=True)

    # Resultados IA por archivo
    transcripcion = Column(Text, nullable=True)     # speech-to-text para audios
    resultado_ia = Column(Text, nullable=True)      # análisis imagen/video como JSON

    subido_at = Column(TIMESTAMP(timezone=True), server_default=func.now())

    incidente = relationship("Incidente", back_populates="multimedia")