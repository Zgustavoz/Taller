from fastapi import HTTPException, status, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List
from app.repositories.incidentes.incidente_multimedia_repository import IncidenteMultimediaRepository
from app.repositories.incidentes.incidente_repository import IncidenteRepository
from app.services.incidentes.cloudinary_service import subir_archivo_cloudinary, eliminar_archivo_cloudinary
from app.schemas.incidente_multimedia_schema import MultimediaResponse


class IncidenteMultimediaService:

    def __init__(self, db: AsyncSession):
        self.repo = IncidenteMultimediaRepository(db)
        self.incidente_repo = IncidenteRepository(db)

    async def subir_archivos(
        self,
        incidente_id: int,
        archivos: List[UploadFile],
    ) -> list[MultimediaResponse]:
        # Validar que el incidente existe
        incidente = await self.incidente_repo.obtener_por_id(incidente_id)
        if not incidente:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Incidente {incidente_id} no encontrado",
            )

        if not archivos:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Debes adjuntar al menos un archivo",
            )

        resultados = []
        for archivo in archivos:
            # Subir a Cloudinary
            data = await subir_archivo_cloudinary(
                archivo,
                carpeta=f"incidentes/{incidente_id}",
            )
            # Guardar en BD
            multimedia = await self.repo.crear(
                incidente_id=incidente_id,
                url=data["url"],
                public_id=data["public_id"],
                tipo_archivo=data["tipo_archivo"],
                tipo_mime=data["tipo_mime"],
                tamano_bytes=data["tamano_bytes"],
                duracion_seg=data.get("duracion_seg"),
            )
            resultados.append(MultimediaResponse.model_validate(multimedia))

        return resultados

    async def listar_por_incidente(self, incidente_id: int) -> list[MultimediaResponse]:
        multimedia = await self.repo.listar_por_incidente(incidente_id)
        return [MultimediaResponse.model_validate(m) for m in multimedia]

    async def eliminar(self, multimedia_id: int) -> dict:
        multimedia = await self.repo.obtener_por_id(multimedia_id)
        if not multimedia:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Archivo {multimedia_id} no encontrado",
            )
        # Eliminar de Cloudinary
        if multimedia.public_id_cloudinary:
            resource_type = (
                "video" if multimedia.tipo_archivo == "video"
                else "raw" if multimedia.tipo_archivo == "audio"
                else "image"
            )
            await eliminar_archivo_cloudinary(
                multimedia.public_id_cloudinary,
                resource_type=resource_type,
            )
        # Eliminar de BD
        await self.repo.eliminar(multimedia_id)
        return {"mensaje": f"Archivo {multimedia_id} eliminado correctamente"}