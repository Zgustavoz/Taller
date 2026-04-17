from fastapi import HTTPException, status, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession
from app.repositories.gestion_usuario.vehiculo_repository import VehiculoRepository
from app.schemas.vehiculo_schema import VehiculoCreate, VehiculoUpdate, VehiculoResponse
from app.services.incidentes.cloudinary_service import subir_archivo_cloudinary


class VehiculoService:

    def __init__(self, db: AsyncSession):
        self.repo = VehiculoRepository(db)

    async def crear(self, data: VehiculoCreate, usuario_id: int) -> VehiculoResponse:
        existente = await self.repo.obtener_por_placa(data.placa)
        if existente:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Ya existe un vehículo con la placa '{data.placa}'",
            )
        vehiculo = await self.repo.crear(data, usuario_id)
        return VehiculoResponse.model_validate(vehiculo)

    async def obtener_por_id(self, vehiculo_id: int) -> VehiculoResponse:
        v = await self.repo.obtener_por_id(vehiculo_id)
        if not v:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Vehículo {vehiculo_id} no encontrado",
            )
        return VehiculoResponse.model_validate(v)

    async def listar_mis_vehiculos(self, usuario_id: int) -> list[VehiculoResponse]:
        vehiculos = await self.repo.listar_por_usuario(usuario_id)
        return [VehiculoResponse.model_validate(v) for v in vehiculos]

    async def actualizar(self, vehiculo_id: int, data: VehiculoUpdate, usuario_id: int) -> VehiculoResponse:
        v = await self.repo.obtener_por_id(vehiculo_id)
        if not v:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Vehículo no encontrado")
        if v.usuario_id != usuario_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No tienes permiso")
        if data.placa:
            existente = await self.repo.obtener_por_placa(data.placa)
            if existente and existente.id != vehiculo_id:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Ya existe un vehículo con la placa '{data.placa}'",
                )
        vehiculo = await self.repo.actualizar(vehiculo_id, data)
        return VehiculoResponse.model_validate(vehiculo)

    async def subir_foto(self, vehiculo_id: int, foto: UploadFile, usuario_id: int) -> VehiculoResponse:
        v = await self.repo.obtener_por_id(vehiculo_id)
        if not v:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Vehículo no encontrado")
        if v.usuario_id != usuario_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No tienes permiso")

        resultado = await subir_archivo_cloudinary(foto, carpeta="vehiculos")
        vehiculo = await self.repo.actualizar(
            vehiculo_id,
            VehiculoUpdate.model_validate({"url_foto": resultado["url"]}),
        )
        return VehiculoResponse.model_validate(vehiculo)

    async def cambiar_estado(self, vehiculo_id: int, estado: bool) -> VehiculoResponse:
        await self.obtener_por_id(vehiculo_id)
        v = await self.repo.cambiar_estado(vehiculo_id, estado)
        return VehiculoResponse.model_validate(v)

    async def eliminar(self, vehiculo_id: int, usuario_id: int) -> dict:
        v = await self.repo.obtener_por_id(vehiculo_id)
        if not v:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Vehículo no encontrado")
        if v.usuario_id != usuario_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No tienes permiso")
        await self.repo.eliminar(vehiculo_id)
        return {"mensaje": f"Vehículo {vehiculo_id} eliminado"}