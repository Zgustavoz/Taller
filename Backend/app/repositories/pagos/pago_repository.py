from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update
from typing import Optional, List
from datetime import datetime, timezone
from app.models.pago_model import Pago


class PagoRepository:

    def __init__(self, db: AsyncSession):
        self.db = db

    async def crear(
        self,
        id_incidente: int,
        id_usuario: int,
        id_taller: int,
        monto_total: float,
        referencia_externa: str,
        metodo_pago: str = "tarjeta",
    ) -> Pago:
        monto_comision = round(monto_total * 0.10, 2)
        monto_taller = round(monto_total * 0.90, 2)

        pago = Pago(
            id_incidente=id_incidente,
            id_usuario=id_usuario,
            id_taller=id_taller,
            monto_total=monto_total,
            monto_comision=monto_comision,
            monto_taller=monto_taller,
            metodo_pago=metodo_pago,
            referencia_externa=referencia_externa,
            estado_pago="pendiente",
        )
        self.db.add(pago)
        await self.db.flush()
        await self.db.refresh(pago)
        return pago

    async def obtener_por_incidente(self, incidente_id: int) -> Optional[Pago]:
        result = await self.db.execute(
            select(Pago).where(Pago.id_incidente == incidente_id)
        )
        return result.scalar_one_or_none()

    async def marcar_completado(self, pago_id: int) -> Optional[Pago]:
        await self.db.execute(
            update(Pago)
            .where(Pago.id == pago_id)
            .values(
                estado_pago="completado",
                pagado_en=datetime.now(timezone.utc),
            )
        )
        await self.db.flush()
        result = await self.db.execute(select(Pago).where(Pago.id == pago_id))
        return result.scalar_one_or_none()

    async def marcar_fallido(self, pago_id: int) -> None:
        await self.db.execute(
            update(Pago).where(Pago.id == pago_id).values(estado_pago="fallido")
        )
        await self.db.flush()

    async def listar_por_usuario(self, usuario_id: int) -> List[Pago]:
        result = await self.db.execute(
            select(Pago)
            .where(Pago.id_usuario == usuario_id)
            .order_by(Pago.id.desc())
        )
        return result.scalars().all()