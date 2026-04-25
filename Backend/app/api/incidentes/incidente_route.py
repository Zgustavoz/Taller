from fastapi import APIRouter, Depends, UploadFile, File, status, Form
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List, Optional
from app.core.db import get_db
from app.core.security import get_current_user_from_cookie
from app.services.incidentes.incidente_service import IncidenteService

router = APIRouter(prefix="/incidentes", tags=["Incidentes"])


# ── Crear incidente + archivos + IA + notificar talleres ───────
@router.post("/", status_code=status.HTTP_201_CREATED)
async def crear_incidente(
    latitud: float = Form(...),
    longitud: float = Form(...),
    descripcion: Optional[str] = Form(None),
    texto_direccion: Optional[str] = Form(None),
    tipo_incidente_id: Optional[int] = Form(None),
    vehiculo_id: Optional[int] = Form(None),
    nivel_prioridad: Optional[int] = Form(None),
    archivos: List[UploadFile] = File(default=[]),
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user_from_cookie),
):
    """multipart/form-data: latitud, longitud + archivos[]"""
    return await IncidenteService(db).crear_con_archivos(
        usuario_id=int(current_user["sub"]),
        latitud=latitud,
        longitud=longitud,
        archivos=archivos,
        descripcion=descripcion,
        texto_direccion=texto_direccion,
        tipo_incidente_id=tipo_incidente_id,
        vehiculo_id=vehiculo_id,
        nivel_prioridad=nivel_prioridad,
    )


# ── Mis incidentes (con multimedia y historial incluidos) ──────
@router.get("/mis-incidentes")
async def mis_incidentes(
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user_from_cookie),
):
    return await IncidenteService(db).mis_incidentes(int(current_user["sub"]))


# ── Listar todos (admin/taller) ────────────────────────────────
@router.get("/")
async def listar_todos(
    estado: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    incidentes = await IncidenteService(db).repo.listar_todos(estado)
    service = IncidenteService(db)
    return [await service._serializar(i) for i in incidentes]


# ── Detalle completo ───────────────────────────────────────────
@router.get("/{incidente_id}")
async def obtener_incidente(
    incidente_id: int,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    return await IncidenteService(db).obtener(incidente_id)


# ── Taller acepta incidente ────────────────────────────────────
@router.post("/{incidente_id}/aceptar")
async def aceptar_incidente(
    incidente_id: int,
    taller_id: int,
    tecnico_id: Optional[int] = None,
    tiempo_estimado_min: Optional[int] = None,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    return await IncidenteService(db).taller_acepta(
        incidente_id=incidente_id,
        taller_id=taller_id,
        tecnico_id=tecnico_id,
        tiempo_estimado_min=tiempo_estimado_min,
    )


@router.post("/{incidente_id}/rechazar")
async def rechazar_incidente(
    incidente_id: int,
    taller_id: int,
    notas: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    return await IncidenteService(db).taller_rechaza(
        incidente_id=incidente_id,
        taller_id=taller_id,
        notas=notas,
    )


# ── Cambiar estado ─────────────────────────────────────────────
@router.patch("/{incidente_id}/estado")
async def cambiar_estado(
    incidente_id: int,
    estado: str,
    notas: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user_from_cookie),
):
    return await IncidenteService(db).cambiar_estado(
        incidente_id=incidente_id,
        estado=estado,
        actor_id=int(current_user["sub"]),
        notas=notas,
    )


# ── Talleres cercanos al incidente ─────────────────────────────
@router.get("/{incidente_id}/talleres-cercanos")
async def talleres_cercanos(
    incidente_id: int,
    radio_km: float = 15.0,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    return await IncidenteService(db).talleres_cercanos(incidente_id, radio_km)


# ── Historial de estados ───────────────────────────────────────
@router.get("/{incidente_id}/historial")
async def historial_estados(
    incidente_id: int,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    from app.repositories.incidentes.historial_repository import HistorialRepository
    historial = await HistorialRepository(db).listar(incidente_id)
    return [
        {
            "estado_anterior": h.estado_anterior,
            "estado_nuevo": h.estado_nuevo,
            "tipo_actor": h.tipo_actor,
            "notas": h.notas,
            "creado_at": h.creado_at,
        }
        for h in historial
    ]