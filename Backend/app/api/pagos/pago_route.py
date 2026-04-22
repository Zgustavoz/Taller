from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.db import get_db
from app.core.security import get_current_user_from_cookie
from app.schemas.pago_schema import CrearPaymentIntentRequest, ConfirmarPagoRequest
from app.services.pagos.pago_service import PagoService

router = APIRouter(prefix="/pagos", tags=["Pagos"])


# ── Crear PaymentIntent (Flutter llama esto primero) ───────────
@router.post("/crear-intent")
async def crear_payment_intent(
    data: CrearPaymentIntentRequest,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user_from_cookie),
):
    """
    Crea un PaymentIntent en Stripe.
    Flutter recibe el client_secret y abre el Payment Sheet.
    Solo funciona si el incidente está en estado 'resuelto'.
    """
    return await PagoService(db).crear_payment_intent(
        incidente_id=data.incidente_id,
        monto_total=data.monto_total,
        usuario_id=int(current_user["sub"]),
    )


# ── Confirmar pago (Flutter llama esto después del Payment Sheet) ──
@router.post("/confirmar")
async def confirmar_pago(
    data: ConfirmarPagoRequest,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user_from_cookie),
):
    """
    Confirma el pago con Stripe y lo registra en la BD.
    Flutter llama esto cuando el Payment Sheet termina exitosamente.
    """
    return await PagoService(db).confirmar_pago(
        incidente_id=data.incidente_id,
        payment_intent_id=data.payment_intent_id,
        monto_total=data.monto_total,
        usuario_id=int(current_user["sub"]),
    )


# ── Obtener estado del pago de un incidente ────────────────────
@router.get("/incidente/{incidente_id}")
async def obtener_pago_incidente(
    incidente_id: int,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    """Consulta si un incidente ya tiene pago y su estado."""
    pago = await PagoService(db).obtener_pago(incidente_id)
    if not pago:
        return {"tiene_pago": False}
    return {"tiene_pago": True, **pago}

# ── Listar pagos del usuario ─────────────────────────
@router.get("/mis-pagos")
async def listar_mis_pagos(
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user_from_cookie),
):
    return await PagoService(db).listar_pagos_usuario(
        usuario_id=int(current_user["sub"])
    )