from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.db import get_db
from app.core.security import get_current_user_from_cookie
from app.services.notificaciones.notificacion_service import NotificacionService

router = APIRouter(prefix="/notificaciones", tags=["Notificaciones"])


@router.post("/test-push")
async def test_push(
    titulo: str = "🔔 Prueba de notificación",
    cuerpo: str = "Este es un push de prueba para validar Firebase",
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user_from_cookie),
):
    return await NotificacionService(db).enviar_prueba_usuario(
        usuario_id=int(current_user["sub"]),
        titulo=titulo,
        cuerpo=cuerpo,
    )


@router.get("/mis-notificaciones")
async def mis_notificaciones(
    solo_no_leidas: bool = False,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user_from_cookie),
):
    return await NotificacionService(db).mis_notificaciones(
        usuario_id=int(current_user["sub"]),
        solo_no_leidas=solo_no_leidas,
    )


@router.get("/no-leidas")
async def contar_no_leidas(
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user_from_cookie),
):
    return await NotificacionService(db).contar_no_leidas(int(current_user["sub"]))


@router.patch("/{notif_id}/leer")
async def marcar_leida(
    notif_id: int,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    return await NotificacionService(db).marcar_leida(notif_id)

@router.patch("/todas/leer")
async def marcar_todas_leidas(
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user_from_cookie),
):
    return await NotificacionService(db).marcar_todas_leidas(
        int(current_user["sub"])
    )