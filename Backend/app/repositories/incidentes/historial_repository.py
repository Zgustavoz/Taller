from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.historial_estado_model import HistorialEstado


class HistorialRepository:

    def __init__(self, db: AsyncSession):
        self.db = db

    async def registrar(
        self,
        incidente_id: int,
        estado_nuevo: str,
        tipo_actor: str,
        estado_anterior: str | None = None,
        actor_id: int | None = None,
        notas: str | None = None,
    ) -> HistorialEstado:
        h = HistorialEstado(
            incidente_id=incidente_id,
            estado_anterior=estado_anterior,
            estado_nuevo=estado_nuevo,
            tipo_actor=tipo_actor,
            actor_id=actor_id,
            notas=notas,
        )
        self.db.add(h)
        await self.db.flush()
        return h

    async def listar(self, incidente_id: int) -> list[HistorialEstado]:
        query = select(HistorialEstado)

        if incidente_id is not None:
            query = query.where(
                HistorialEstado.incidente_id == incidente_id
            )

        query = query.order_by(
            HistorialEstado.creado_at.asc()
        )

        result = await self.db.execute(query)

        return result.scalars().all()