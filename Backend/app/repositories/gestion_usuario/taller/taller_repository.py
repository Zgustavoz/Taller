from decimal import Decimal
from typing import Optional

from sqlalchemy import delete, func, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import hash_password
from app.models.taller_model import Taller
from app.schemas.taller_schema import TallerCreate, TallerUpdate


class TallerRepository:

    def __init__(self, db: AsyncSession):
        self.db = db

    def _to_payload(self, row) -> dict:
        data = dict(row)
        data["ubicacion"] = {
            "latitud": float(data.pop("latitud")),
            "longitud": float(data.pop("longitud")),
        }

        if isinstance(data.get("radio_cobertura_km"), Decimal):
            data["radio_cobertura_km"] = float(data["radio_cobertura_km"])
        if isinstance(data.get("calificacion_promedio"), Decimal):
            data["calificacion_promedio"] = float(data["calificacion_promedio"])

        if data.get("especialidades") is None:
            data["especialidades"] = []

        return data

    def _ubicacion_expr(self, latitud: float, longitud: float):
        return func.ST_SetSRID(func.ST_MakePoint(longitud, latitud), 4326)

    def _base_select(self):
        return select(
            Taller.id,
            Taller.nombre_propietario,
            Taller.nombre_negocio,
            Taller.correo,
            Taller.telefono,
            Taller.direccion,
            Taller.radio_cobertura_km,
            Taller.especialidades,
            Taller.esta_disponible,
            Taller.calificacion_promedio,
            Taller.token_fcm,
            Taller.esta_activo,
            Taller.creado_en,
            func.ST_Y(Taller.ubicacion).label("latitud"),
            func.ST_X(Taller.ubicacion).label("longitud"),
        )

    async def crear(self, data: TallerCreate) -> dict:
        datos = data.model_dump(exclude={"contrasena", "ubicacion"})
        datos["contrasena_hash"] = hash_password(data.contrasena)
        datos["ubicacion"] = self._ubicacion_expr(
            data.ubicacion.latitud,
            data.ubicacion.longitud,
        )

        taller = Taller(**datos)
        self.db.add(taller)
        await self.db.flush()
        return await self.obtener_por_id(taller.id)

    async def obtener_por_id(self, taller_id: int) -> Optional[dict]:
        result = await self.db.execute(
            self._base_select().where(Taller.id == taller_id)
        )
        row = result.mappings().one_or_none()
        if not row:
            return None
        return self._to_payload(row)

    async def obtener_por_correo(self, correo: str) -> Optional[Taller]:
        result = await self.db.execute(
            select(Taller).where(Taller.correo == correo)
        )
        return result.scalar_one_or_none()

    async def listar(self, solo_activos: bool = False) -> list[dict]:
        query = self._base_select()
        if solo_activos:
            query = query.where(Taller.esta_activo == True)

        result = await self.db.execute(query)
        rows = result.mappings().all()
        return [self._to_payload(row) for row in rows]

    async def actualizar(self, taller_id: int, data: TallerUpdate) -> Optional[dict]:
        valores = {
            k: v for k, v in data.model_dump(exclude={"ubicacion", "contrasena"}).items() if v is not None
        }

        if data.ubicacion is not None:
            valores["ubicacion"] = self._ubicacion_expr(
                data.ubicacion.latitud,
                data.ubicacion.longitud,
            )

        if data.contrasena is not None:
            valores["contrasena_hash"] = hash_password(data.contrasena)

        if not valores:
            return await self.obtener_por_id(taller_id)

        await self.db.execute(
            update(Taller).where(Taller.id == taller_id).values(**valores)
        )
        await self.db.flush()
        return await self.obtener_por_id(taller_id)

    async def cambiar_estado(self, taller_id: int, estado: bool) -> Optional[dict]:
        await self.db.execute(
            update(Taller).where(Taller.id == taller_id).values(esta_activo=estado)
        )
        await self.db.flush()
        return await self.obtener_por_id(taller_id)

    async def eliminar(self, taller_id: int) -> bool:
        result = await self.db.execute(
            delete(Taller).where(Taller.id == taller_id)
        )
        return result.rowcount > 0
