from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import update, select
from geoalchemy2.functions import ST_MakePoint, ST_SetSRID, ST_X, ST_Y
from app.core.db import get_db
from app.core.security import get_current_taller_from_cookie, get_current_user_from_cookie
from app.schemas.tecnico_schema import TecnicoCreate, TecnicoResponse, TecnicoUpdate
from app.services.gestion_usuario.tecnico_service import TecnicoService
from app.models.tecnico_model import Tecnico
from app.models.incidente_model import Incidente

router = APIRouter(prefix="/tecnicos", tags=["Técnicos"])


@router.post("/", response_model=TecnicoResponse, status_code=status.HTTP_201_CREATED)
async def crear_tecnico(
    data: TecnicoCreate,
    db: AsyncSession = Depends(get_db),
):
    return await TecnicoService(db).crear(data)


@router.get("/", response_model=list[TecnicoResponse])
async def listar_tecnicos(
    solo_activos: bool = False,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    return await TecnicoService(db).listar(solo_activos)


@router.get("/me", response_model=list[TecnicoResponse])
async def listar_mis_tecnicos(
    solo_activos: bool = False,
    db: AsyncSession = Depends(get_db),
    current_taller: dict = Depends(get_current_taller_from_cookie),
):
    taller_id = int(current_taller.get("sub"))
    return await TecnicoService(db).listar_por_taller(
        taller_id=taller_id, solo_activos=solo_activos
    )


# ── Obtener ubicación del técnico asignado a un incidente ──────
# Este endpoint lo llama Flutter cada 5 segundos para el tracking
@router.get("/ubicacion-incidente/{incidente_id}")
async def obtener_ubicacion_tecnico_por_incidente(
    incidente_id: int,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    """
    Devuelve la ubicación actual del técnico asignado al incidente.
    Flutter lo llama cada 5 segundos para mostrar el movimiento en el mapa.
    """
    # Buscar el técnico asignado al incidente
    result = await db.execute(
        select(Incidente).where(Incidente.id == incidente_id)
    )
    incidente = result.scalar_one_or_none()

    if not incidente or not incidente.tecnico_asignado_id:
        return {"tiene_tecnico": False, "latitud": None, "longitud": None}

    # Obtener coordenadas del técnico
    result = await db.execute(
        select(
            Tecnico.id,
            Tecnico.nombre_completo,
            ST_Y(Tecnico.ubicacion_actual).label("latitud"),
            ST_X(Tecnico.ubicacion_actual).label("longitud"),
            Tecnico.esta_disponible,
        ).where(Tecnico.id == incidente.tecnico_asignado_id)
    )
    row = result.first()

    if not row or row.latitud is None:
        return {
            "tiene_tecnico": True,
            "tecnico_id": incidente.tecnico_asignado_id,
            "latitud": None,
            "longitud": None,
        }

    return {
        "tiene_tecnico": True,
        "tecnico_id": row.id,
        "nombre": row.nombre_completo,
        "latitud": row.latitud,
        "longitud": row.longitud,
    }


# ── Actualizar ubicación del técnico (lo llama la app web/técnico) ──
@router.patch("/{tecnico_id}/ubicacion")
async def actualizar_ubicacion_tecnico(
    tecnico_id: int,
    latitud: float,
    longitud: float,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    """
    La app web del taller llama este endpoint cada X segundos
    para actualizar la posición GPS del técnico en ruta.
    """
    punto = ST_SetSRID(ST_MakePoint(longitud, latitud), 4326)
    await db.execute(
        update(Tecnico)
        .where(Tecnico.id == tecnico_id)
        .values(ubicacion_actual=punto)
    )
    await db.commit()
    return {"ok": True, "tecnico_id": tecnico_id, "latitud": latitud, "longitud": longitud}


@router.get("/{tecnico_id}", response_model=TecnicoResponse)
async def obtener_tecnico(
    tecnico_id: int,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    return await TecnicoService(db).obtener_por_id(tecnico_id)


@router.put("/{tecnico_id}", response_model=TecnicoResponse)
async def actualizar_tecnico(
    tecnico_id: int,
    data: TecnicoUpdate,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    return await TecnicoService(db).actualizar(tecnico_id, data)


@router.patch("/{tecnico_id}/estado", response_model=TecnicoResponse)
async def cambiar_estado_tecnico(
    tecnico_id: int,
    estado: bool,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    return await TecnicoService(db).cambiar_estado(tecnico_id, estado)


@router.delete("/{tecnico_id}")
async def eliminar_tecnico(
    tecnico_id: int,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    return await TecnicoService(db).eliminar(tecnico_id)