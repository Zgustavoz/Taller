from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete
from sqlalchemy.orm import selectinload
from typing import Optional
from geoalchemy2.functions import ST_MakePoint, ST_SetSRID
from app.models.incidente_model import Incidente
from app.schemas.incidente_schema import IncidenteCreate, IncidenteUpdate


class IncidenteRepository:

    def __init__(self, db: AsyncSession):
        self.db = db

    async def crear(self, data: IncidenteCreate, usuario_id: int) -> Incidente:
        punto = ST_SetSRID(ST_MakePoint(data.longitud, data.latitud), 4326)
        incidente = Incidente(
            usuario_id=usuario_id,
            vehiculo_id=data.vehiculo_id,
            tecnico_asignado_id=data.tecnico_asignado_id,
            tipo_incidente_id=data.tipo_incidente_id,
            ubicacion=punto,
            texto_direccion=data.texto_direccion,
            descripcion=data.descripcion,
            nivel_prioridad=data.nivel_prioridad,
            estado="pendiente",
        )
        self.db.add(incidente)
        await self.db.flush()
        await self.db.refresh(incidente)
        return incidente

    async def obtener_por_id(self, incidente_id: int) -> Optional[Incidente]:
        result = await self.db.execute(
            select(Incidente)
            .options(
                selectinload(Incidente.multimedia),
                selectinload(Incidente.vehiculo),
                selectinload(Incidente.taller),
                selectinload(Incidente.tecnico),
                selectinload(Incidente.historial),
            )
            .where(Incidente.id == incidente_id)
        )
        return result.scalar_one_or_none()

    async def listar_por_usuario(self, usuario_id: int) -> list[Incidente]:
        result = await self.db.execute(
            select(Incidente)
            .options(
                selectinload(Incidente.multimedia),
                selectinload(Incidente.vehiculo),
                selectinload(Incidente.taller),
                selectinload(Incidente.tecnico),
                selectinload(Incidente.historial),
            )
            .where(Incidente.usuario_id == usuario_id)
            .order_by(Incidente.creado_at.desc())
        )
        return result.scalars().all()

    async def listar_todos(self, estado: Optional[str] = None) -> list[Incidente]:
        query = (
            select(Incidente)
            .options(
                selectinload(Incidente.multimedia),
                selectinload(Incidente.vehiculo),
                selectinload(Incidente.taller),
                selectinload(Incidente.tecnico),
                selectinload(Incidente.historial),
            )
            .order_by(Incidente.creado_at.desc())
        )
        if estado:
            query = query.where(Incidente.estado == estado)
        result = await self.db.execute(query)
        return result.scalars().all()

    async def actualizar(self, incidente_id: int, data: IncidenteUpdate) -> Optional[Incidente]:
        valores = {k: v for k, v in data.model_dump().items() if v is not None}
        if not valores:
            return await self.obtener_por_id(incidente_id)
        await self.db.execute(
            update(Incidente).where(Incidente.id == incidente_id).values(**valores)
        )
        await self.db.flush()
        return await self.obtener_por_id(incidente_id)

    async def cambiar_estado(self, incidente_id: int, estado: str) -> Optional[Incidente]:
        await self.db.execute(
            update(Incidente)
            .where(Incidente.id == incidente_id)
            .values(estado=estado)
        )
        await self.db.flush()
        return await self.obtener_por_id(incidente_id)

    async def eliminar(self, incidente_id: int) -> bool:
        result = await self.db.execute(
            delete(Incidente).where(Incidente.id == incidente_id)
        )
        return result.rowcount > 0

    # Extrae latitud y longitud desde el campo GEOMETRY
    async def obtener_coordenadas(self, incidente_id: int) -> Optional[dict]:
        from geoalchemy2.functions import ST_X, ST_Y
        result = await self.db.execute(
            select(
                ST_X(Incidente.ubicacion).label("longitud"),
                ST_Y(Incidente.ubicacion).label("latitud"),
            ).where(Incidente.id == incidente_id)
        )
        row = result.first()
        if row:
            return {"latitud": row.latitud, "longitud": row.longitud}
        return None