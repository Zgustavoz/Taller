from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.repositories.gestion_usuario.taller.taller_repository import TallerRepository
from app.schemas.taller_schema import (
    SolicitudPanelMinimaResponse,
    TallerCreate,
    TallerResponse,
    TallerUpdate,
)
from app.models.incidente_model import Incidente
from app.models.tipo_incidente_model import TipoIncidente
from app.models.usuario_model import Usuario
from app.models.vehiculo_model import Vehiculo
from app.models.asignacion_taller_model import AsignacionTaller


class TallerService:

    def __init__(self, db: AsyncSession):
        self.repo = TallerRepository(db)

    async def crear(self, data: TallerCreate) -> TallerResponse:
        if await self.repo.obtener_por_correo(data.correo):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Ya existe un taller con ese correo",
            )

        taller = await self.repo.crear(data)
        return TallerResponse.model_validate(taller)

    async def obtener_por_id(self, taller_id: int) -> TallerResponse:
        taller = await self.repo.obtener_por_id(taller_id)
        if not taller:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Taller con id {taller_id} no encontrado",
            )
        return TallerResponse.model_validate(taller)

    async def listar(self, solo_activos: bool = False) -> list[TallerResponse]:
        talleres = await self.repo.listar(solo_activos)
        return [TallerResponse.model_validate(t) for t in talleres]

    async def actualizar(self, taller_id: int, data: TallerUpdate) -> TallerResponse:
        await self.obtener_por_id(taller_id)

        if data.correo:
            existente = await self.repo.obtener_por_correo(data.correo)
            if existente and existente.id != taller_id:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Ya existe un taller con ese correo",
                )

        taller = await self.repo.actualizar(taller_id, data)
        return TallerResponse.model_validate(taller)

    async def cambiar_estado(self, taller_id: int, estado: bool) -> TallerResponse:
        await self.obtener_por_id(taller_id)
        taller = await self.repo.cambiar_estado(taller_id, estado)
        return TallerResponse.model_validate(taller)

    async def actualizar_token_fcm(self, taller_id: int, token_fcm: str) -> dict:
        """Actualiza el token FCM de un taller."""
        await self.obtener_por_id(taller_id)
        await self.repo.actualizar_token_fcm(taller_id, token_fcm)
        return {"mensaje": "Token FCM actualizado correctamente"}

    async def eliminar(self, taller_id: int) -> dict:
        await self.obtener_por_id(taller_id)
        await self.repo.eliminar(taller_id)
        return {"mensaje": f"Taller {taller_id} eliminado correctamente"}

    async def listar_solicitudes_minimas(
        self,
        taller_id: int,
        estado: str | None = None,
    ) -> list[SolicitudPanelMinimaResponse]:
        query = (
            select(
                Incidente.id,
                Incidente.estado,
                Incidente.nivel_prioridad,
                TipoIncidente.nombre.label("tipo_incidente_nombre"),
                AsignacionTaller.distancia_km,
                AsignacionTaller.puntuacion_asignacion.label("score"),
                Incidente.creado_at,
                Usuario.nombre.label("usuario_nombre"),
                Vehiculo.placa.label("vehiculo_placa"),
                Incidente.ficha_resumen.label("resumen"),
            )
            .join(AsignacionTaller, AsignacionTaller.incidente_id == Incidente.id)
            .join(Usuario, Usuario.id == Incidente.usuario_id)
            .outerjoin(Vehiculo, Vehiculo.id == Incidente.vehiculo_id)
            .outerjoin(TipoIncidente, TipoIncidente.id == Incidente.tipo_incidente_id)
            .where(AsignacionTaller.taller_id == taller_id)
            .order_by(Incidente.creado_at.desc())
        )

        if estado:
            query = query.where(Incidente.estado == estado)

        result = await self.repo.db.execute(query)
        rows = result.mappings().all()

        return [
            SolicitudPanelMinimaResponse(
                id=row["id"],
                estado=row["estado"],
                nivel_prioridad=row["nivel_prioridad"],
                tipo_incidente_nombre=row["tipo_incidente_nombre"],
                distancia_km=row["distancia_km"],
                score=row["score"],
                creado_at=row["creado_at"],
                usuario_nombre=row["usuario_nombre"],
                vehiculo_placa=row["vehiculo_placa"],
                resumen=row["resumen"],
            )
            for row in rows
        ]
