from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.db import get_db
from app.core.security import get_current_user_from_cookie
from app.services.gestion_usuario.vehiculo_service import VehiculoService
from app.schemas.vehiculo_schema import VehiculoCreate, VehiculoUpdate, VehiculoResponse

router = APIRouter(prefix="/vehiculos", tags=["Vehículos"])


@router.post("/", response_model=VehiculoResponse, status_code=status.HTTP_201_CREATED)
async def crear_vehiculo(
    data: VehiculoCreate,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user_from_cookie),
):
    return await VehiculoService(db).crear(data, int(current_user["sub"]))


@router.get("/mis-vehiculos", response_model=list[VehiculoResponse])
async def mis_vehiculos(
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user_from_cookie),
):
    return await VehiculoService(db).listar_mis_vehiculos(int(current_user["sub"]))


@router.get("/{vehiculo_id}", response_model=VehiculoResponse)
async def obtener_vehiculo(
    vehiculo_id: int,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    return await VehiculoService(db).obtener_por_id(vehiculo_id)


@router.put("/{vehiculo_id}", response_model=VehiculoResponse)
async def actualizar_vehiculo(
    vehiculo_id: int,
    data: VehiculoUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user_from_cookie),
):
    return await VehiculoService(db).actualizar(vehiculo_id, data, int(current_user["sub"]))


@router.patch("/{vehiculo_id}/estado", response_model=VehiculoResponse)
async def cambiar_estado(
    vehiculo_id: int,
    estado: bool,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user_from_cookie),
):
    return await VehiculoService(db).cambiar_estado(vehiculo_id, estado)


@router.delete("/{vehiculo_id}")
async def eliminar_vehiculo(
    vehiculo_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user_from_cookie),
):
    return await VehiculoService(db).eliminar(vehiculo_id, int(current_user["sub"]))