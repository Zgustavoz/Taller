from typing import Optional

from sqlalchemy import delete, func, select, update
from sqlalchemy.ext.asyncio import AsyncSession
from geoalchemy2.functions import ST_MakePoint, ST_SetSRID

from app.models.tecnico_model import Tecnico
from app.schemas.tecnico_schema import TecnicoCreate, TecnicoUpdate


class TecnicoRepository:

    def __init__(self, db: AsyncSession):
        self.db = db

    def _ubicacion_expr(self, latitud: float, longitud: float):
        return ST_SetSRID(ST_MakePoint(longitud, latitud), 4326)

    def _to_payload(self, row) -> dict:
        data = dict(row)
        if data.get("latitud") is not None and data.get("longitud") is not None:
            data["ubicacion_actual"] = {
                "latitud": float(data.pop("latitud")),
                "longitud": float(data.pop("longitud")),
            }
        else:
            data["ubicacion_actual"] = None
            data.pop("latitud", None)
            data.pop("longitud", None)

        if data.get("especialidades") is None:
            data["especialidades"] = []

        return data

    def _base_select(self):
        return select(
            Tecnico.id,
            Tecnico.taller_id,
            Tecnico.nombre_completo,
            Tecnico.telefono,
            Tecnico.especialidades,
            Tecnico.esta_disponible,
            Tecnico.token_fcm,
            Tecnico.esta_activo,
            Tecnico.creado_en,
            func.ST_Y(Tecnico.ubicacion_actual).label("latitud"),
            func.ST_X(Tecnico.ubicacion_actual).label("longitud"),
        )

    async def crear(self, data: TecnicoCreate) -> Optional[dict]:
        datos = data.model_dump(exclude={"ubicacion_actual"}, exclude_none=True)
        if data.ubicacion_actual is not None:
            datos["ubicacion_actual"] = self._ubicacion_expr(
                data.ubicacion_actual.latitud,
                data.ubicacion_actual.longitud,
            )

        tecnico = Tecnico(**datos)
        self.db.add(tecnico)
        await self.db.flush()
        return await self.obtener_por_id(tecnico.id)

    async def obtener_por_id(self, tecnico_id: int) -> Optional[dict]:
        result = await self.db.execute(
            self._base_select().where(Tecnico.id == tecnico_id)
        )
        row = result.mappings().one_or_none()
        if not row:
            return None
        return self._to_payload(row)

    async def listar(self, solo_activos: bool = False) -> list[dict]:
        query = self._base_select()
        if solo_activos:
            query = query.where(Tecnico.esta_activo == True)

        result = await self.db.execute(query)
        rows = result.mappings().all()
        return [self._to_payload(row) for row in rows]

    async def actualizar(self, tecnico_id: int, data: TecnicoUpdate) -> Optional[dict]:
        valores = data.model_dump(exclude_none=True)
        ubicacion = valores.pop("ubicacion_actual", None)

        if ubicacion is not None:
            valores["ubicacion_actual"] = self._ubicacion_expr(
                ubicacion.latitud,
                ubicacion.longitud,
            )

        if not valores:
            return await self.obtener_por_id(tecnico_id)

        await self.db.execute(
            update(Tecnico).where(Tecnico.id == tecnico_id).values(**valores)
        )
        await self.db.flush()
        return await self.obtener_por_id(tecnico_id)

    async def cambiar_estado(self, tecnico_id: int, estado: bool) -> Optional[dict]:
        await self.db.execute(
            update(Tecnico).where(Tecnico.id == tecnico_id).values(esta_activo=estado)
        )
        await self.db.flush()
        return await self.obtener_por_id(tecnico_id)

    async def eliminar(self, tecnico_id: int) -> bool:
        result = await self.db.execute(
            delete(Tecnico).where(Tecnico.id == tecnico_id)
        )
        return result.rowcount > 0
