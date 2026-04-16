from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, delete
from typing import Optional
from app.models.incidente_multimedia_model import IncidenteMultimedia


class IncidenteMultimediaRepository:

    def __init__(self, db: AsyncSession):
        self.db = db

    async def crear(
        self,
        incidente_id: int,
        url: str,
        public_id: str,
        tipo_archivo: str,
        tipo_mime: Optional[str],
        tamano_bytes: Optional[int],
        duracion_seg: Optional[float],
    ) -> IncidenteMultimedia:
        multimedia = IncidenteMultimedia(
            incidente_id=incidente_id,
            url_almacenamiento=url,
            public_id_cloudinary=public_id,
            tipo_archivo=tipo_archivo,
            tipo_mime=tipo_mime,
            tamano_archivo_bytes=tamano_bytes,
            duracion_seg=duracion_seg,
        )
        self.db.add(multimedia)
        await self.db.flush()
        await self.db.refresh(multimedia)
        return multimedia

    async def listar_por_incidente(self, incidente_id: int) -> list[IncidenteMultimedia]:
        result = await self.db.execute(
            select(IncidenteMultimedia)
            .where(IncidenteMultimedia.incidente_id == incidente_id)
            .order_by(IncidenteMultimedia.subido_at.desc())
        )
        return result.scalars().all()

    async def obtener_por_id(self, multimedia_id: int) -> Optional[IncidenteMultimedia]:
        result = await self.db.execute(
            select(IncidenteMultimedia).where(IncidenteMultimedia.id == multimedia_id)
        )
        return result.scalar_one_or_none()

    async def eliminar(self, multimedia_id: int) -> Optional[IncidenteMultimedia]:
        multimedia = await self.obtener_por_id(multimedia_id)
        if multimedia:
            await self.db.execute(
                delete(IncidenteMultimedia).where(IncidenteMultimedia.id == multimedia_id)
            )
            await self.db.flush()
        return multimedia