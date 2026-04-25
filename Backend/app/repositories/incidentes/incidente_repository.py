from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update
from sqlalchemy.orm import selectinload
from typing import Optional
from geoalchemy2.functions import ST_MakePoint, ST_SetSRID, ST_X, ST_Y, ST_DWithin
from app.models.incidente_model import Incidente
from app.models.taller_model import Taller


class IncidenteRepository:

    def __init__(self, db: AsyncSession):
        self.db = db

    async def crear(
        self,
        usuario_id: int,
        latitud: float,
        longitud: float,
        descripcion: str | None = None,
        texto_direccion: str | None = None,
        tipo_incidente_id: int | None = None,
        vehiculo_id: int | None = None,
        nivel_prioridad: int | None = None,
    ) -> Incidente:
        punto = ST_SetSRID(ST_MakePoint(longitud, latitud), 4326)
        incidente = Incidente(
            usuario_id=usuario_id,
            vehiculo_id=vehiculo_id,
            tipo_incidente_id=tipo_incidente_id,
            ubicacion=punto,
            texto_direccion=texto_direccion,
            descripcion=descripcion,
            nivel_prioridad=nivel_prioridad,
            estado="pendiente",
        )
        self.db.add(incidente)
        await self.db.flush()
        await self.db.refresh(incidente)
        return incidente

    async def obtener_por_id(self, incidente_id: int) -> Optional[Incidente]:
        result = await self.db.execute(
            select(Incidente)
            .options(selectinload(Incidente.multimedia))
            .options(selectinload(Incidente.asignaciones))
            .options(selectinload(Incidente.historial))
            .where(Incidente.id == incidente_id)
        )
        return result.scalar_one_or_none()

    async def listar_por_usuario(self, usuario_id: int) -> list[Incidente]:
        result = await self.db.execute(
            select(Incidente)
            .options(selectinload(Incidente.multimedia))
            .where(Incidente.usuario_id == usuario_id)
            .order_by(Incidente.creado_at.desc())
        )
        return result.scalars().all()

    async def listar_todos(self, estado: str | None = None) -> list[Incidente]:
        query = select(Incidente).order_by(Incidente.creado_at.desc())
        if estado:
            query = query.where(Incidente.estado == estado)
        result = await self.db.execute(query)
        return result.scalars().all()

    async def actualizar_estado(
        self,
        incidente_id: int,
        estado: str,
        taller_id: int | None = None,
        tecnico_id: int | None = None,
        tiempo_estimado: int | None = None,
        resuelto_at = None,
    ) -> Optional[Incidente]:
        valores: dict = {"estado": estado}
        if taller_id is not None:
            valores["taller_asignado_id"] = taller_id
        if tecnico_id is not None:
            valores["tecnico_asignado_id"] = tecnico_id
        if tiempo_estimado is not None:
            valores["tiempo_estimado_llegada_min"] = tiempo_estimado
        if resuelto_at is not None:
            valores["resuelto_at"] = resuelto_at
        await self.db.execute(
            update(Incidente).where(Incidente.id == incidente_id).values(**valores)
        )
        await self.db.flush()
        return await self.obtener_por_id(incidente_id)

    async def actualizar_ia(
        self,
        incidente_id: int,
        analisis_ia: str,
        ficha_resumen: str,
        nivel_prioridad: int | None,
        tipo_incidente_id: int | None,
    ) -> Optional[Incidente]:
        valores: dict = {
            "analisis_ia": analisis_ia,
            "ficha_resumen": ficha_resumen,
            "estado": "notificando",
        }
        if nivel_prioridad:
            valores["nivel_prioridad"] = nivel_prioridad
        if tipo_incidente_id:
            valores["tipo_incidente_id"] = tipo_incidente_id
        await self.db.execute(
            update(Incidente).where(Incidente.id == incidente_id).values(**valores)
        )
        await self.db.flush()
        return await self.obtener_por_id(incidente_id)

    async def obtener_coordenadas(self, incidente_id: int) -> dict | None:
        result = await self.db.execute(
            select(
                ST_X(Incidente.ubicacion).label("longitud"),
                ST_Y(Incidente.ubicacion).label("latitud"),
            ).where(Incidente.id == incidente_id)
        )
        row = result.first()
        return {"latitud": row.latitud, "longitud": row.longitud} if row else None

    async def talleres_cercanos(
        self,
        latitud: float,
        longitud: float,
        radio_km: float = 15.0,
        limite: int = 5,
    ) -> list[Taller]:
        punto = ST_SetSRID(ST_MakePoint(longitud, latitud), 4326)
        result = await self.db.execute(
            select(Taller)
            .where(Taller.esta_disponible == True)
            .where(Taller.esta_activo == True)
            .where(ST_DWithin(Taller.ubicacion, punto, radio_km * 1000))
            .limit(limite)
        )
        return result.scalars().all()

    async def talleres_cercanos_con_coordenadas(
        self,
        latitud: float,
        longitud: float,
        radio_km: float = 15.0,
        limite: int = 5,
        especialidades: list[str] | None = None,
    ) -> list[dict]:
        """
        Talleres cercanos con lat/lng extraídas via PostGIS.
        Si se pasa especialidades, filtra talleres que tengan AL MENOS UNA
        de esas especialidades en su array. Si la lista está vacía, devuelve todos.
        """
        from sqlalchemy import cast
        from sqlalchemy.dialects.postgresql import ARRAY
        from sqlalchemy import String

        punto = ST_SetSRID(ST_MakePoint(longitud, latitud), 4326)

        query = (
            select(
                Taller.id,
                Taller.nombre_negocio,
                Taller.telefono,
                Taller.especialidades,
                Taller.calificacion_promedio,
                Taller.esta_disponible,
                Taller.token_fcm,
                ST_Y(Taller.ubicacion).label("latitud"),
                ST_X(Taller.ubicacion).label("longitud"),
            )
            .where(Taller.esta_disponible == True)
            .where(Taller.esta_activo == True)
            .where(ST_DWithin(Taller.ubicacion, punto, radio_km * 1000))
        )

        # Filtrar por especialidad si se especifica
        # Usa el operador && de PostgreSQL: arrays se solapan
        if especialidades:
            from sqlalchemy import text
            # especialidades_str = "{" + ",".join(especialidades) + "}"
            query = query.where(
                text("especialidades && CAST(:esp AS TEXT[])")
            ).params(esp=especialidades)

        query = query.limit(limite)

        result = await self.db.execute(query)
        rows = result.mappings().all()
        return [dict(r) for r in rows]

    async def eliminar(self, incidente_id: int) -> bool:
        from sqlalchemy import delete
        result = await self.db.execute(
            delete(Incidente).where(Incidente.id == incidente_id)
        )
        return result.rowcount > 0