import stripe
from fastapi import HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.config import settings
from app.models.incidente_model import Incidente
from app.repositories.pagos.pago_repository import PagoRepository

stripe.api_key = settings.STRIPE_SECRET_KEY


class PagoService:

    def __init__(self, db: AsyncSession):
        self.db = db
        self.repo = PagoRepository(db)

    # ── Paso 1: Crear PaymentIntent en Stripe ─────────────────
    # Flutter llama esto para obtener el client_secret
    async def crear_payment_intent(
        self,
        incidente_id: int,
        monto_total: float,
        usuario_id: int,
    ) -> dict:
        # Verificar que el incidente existe y está resuelto
        result = await self.db.execute(
            select(Incidente).where(Incidente.id == incidente_id)
        )
        incidente = result.scalar_one_or_none()

        if not incidente:
            raise HTTPException(status_code=404, detail="Incidente no encontrado")

        if incidente.estado != "resuelto":
            raise HTTPException(
                status_code=400,
                detail=f"El incidente debe estar resuelto para pagar. Estado actual: {incidente.estado}"
            )

        if not incidente.taller_asignado_id:
            raise HTTPException(
                status_code=400,
                detail="El incidente no tiene taller asignado"
            )

        # Verificar que no tenga pago completado ya
        pago_existente = await self.repo.obtener_por_incidente(incidente_id)
        if pago_existente and pago_existente.estado_pago == "completado":
            raise HTTPException(
                status_code=400,
                detail="Este incidente ya fue pagado"
            )

        # Convertir a centavos (Stripe usa la unidad mínima de la moneda)
        # Si usas BOB (bolivianos), Stripe no lo soporta nativamente
        # Usa USD como moneda de prueba: 1 BOB ≈ 0.14 USD aprox
        # Para producción ajusta según tu moneda
        monto_centavos = int(monto_total * 100)

        try:
            intent = stripe.PaymentIntent.create(
                amount=monto_centavos,
                currency="usd",  # cambia a tu moneda si Stripe la soporta
                metadata={
                    "incidente_id": str(incidente_id),
                    "usuario_id": str(usuario_id),
                    "taller_id": str(incidente.taller_asignado_id),
                },
                automatic_payment_methods={"enabled": True},
            )
        except stripe.StripeError as e:
            raise HTTPException(status_code=400, detail=f"Error Stripe: {str(e)}")

        return {
            "client_secret": intent.client_secret,
            "payment_intent_id": intent.id,
            "monto_total": monto_total,
            "monto_comision": round(monto_total * 0.10, 2),
            "monto_taller": round(monto_total * 0.90, 2),
        }

    # ── Paso 2: Confirmar pago después de que Stripe lo procesa ──
    # Flutter llama esto cuando el Payment Sheet termina exitosamente
    async def confirmar_pago(
        self,
        incidente_id: int,
        payment_intent_id: str,
        monto_total: float,
        usuario_id: int,
    ) -> dict:
        # Verificar el pago directamente con Stripe
        try:
            intent = stripe.PaymentIntent.retrieve(payment_intent_id)
        except stripe.StripeError as e:
            raise HTTPException(status_code=400, detail=f"Error verificando pago: {str(e)}")

        if intent.status != "succeeded":
            raise HTTPException(
                status_code=400,
                detail=f"El pago no fue completado. Estado Stripe: {intent.status}"
            )

        # Obtener el incidente para saber el taller
        result = await self.db.execute(
            select(Incidente).where(Incidente.id == incidente_id)
        )
        incidente = result.scalar_one_or_none()
        if not incidente:
            raise HTTPException(status_code=404, detail="Incidente no encontrado")

        # Verificar si ya existe un pago registrado
        pago_existente = await self.repo.obtener_por_incidente(incidente_id)

        if pago_existente:
            if pago_existente.estado_pago == "completado":
                raise HTTPException(status_code=400, detail="Pago ya registrado")
            # Actualizar el existente
            pago = await self.repo.marcar_completado(pago_existente.id)
        else:
            # Crear nuevo registro de pago
            pago = await self.repo.crear(
                id_incidente=incidente_id,
                id_usuario=usuario_id,
                id_taller=incidente.taller_asignado_id,
                monto_total=monto_total,
                referencia_externa=payment_intent_id,
                metodo_pago="tarjeta",
            )
            pago = await self.repo.marcar_completado(pago.id)

        await self.db.commit()

        return {
            "ok": True,
            "pago_id": pago.id,
            "monto_total": float(pago.monto_total),
            "monto_comision": float(pago.monto_comision),
            "monto_taller": float(pago.monto_taller),
            "estado_pago": pago.estado_pago,
            "referencia_externa": pago.referencia_externa,
        }

    # ── Obtener estado del pago de un incidente ───────────────
    async def obtener_pago(self, incidente_id: int) -> dict | None:
        pago = await self.repo.obtener_por_incidente(incidente_id)
        if not pago:
            return None
        return {
            "id": pago.id,
            "monto_total": float(pago.monto_total),
            "monto_comision": float(pago.monto_comision),
            "monto_taller": float(pago.monto_taller),
            "estado_pago": pago.estado_pago,
            "metodo_pago": pago.metodo_pago,
            "referencia_externa": pago.referencia_externa,
            "creado_en": pago.creado_en,
            "pagado_en": pago.pagado_en,
        }
    
    # ── Listar pagos de un usuario ─────────────────────────
    async def listar_pagos_usuario(self, usuario_id: int):
        pagos = await self.repo.listar_por_usuario(usuario_id)

        return [
            {
                "id": p.id,
                "id_incidente": p.id_incidente,
                "monto_total": p.monto_total,
                "estado_pago": p.estado_pago,
                "metodo_pago": p.metodo_pago,
                "pagado_en": p.pagado_en.isoformat()
                if p.pagado_en
                else None,
            }
            for p in pagos
        ]