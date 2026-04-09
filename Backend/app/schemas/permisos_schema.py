from pydantic import BaseModel
from typing import Optional
from datetime import datetime


# ─── Base ────────────────────────────────────────────────────────
class PermisosBase(BaseModel):
    usuario_id: int
    rol_id: int

    # Permisos principales
    crear: Optional[bool] = False
    registrar: Optional[bool] = False
    editar: Optional[bool] = False
    eliminar: Optional[bool] = False
    visualizar: Optional[bool] = False
    cambiar_estado: Optional[bool] = False

    # Permisos adicionales
    exportar: Optional[bool] = False
    importar: Optional[bool] = False
    aprobar: Optional[bool] = False
    rechazar: Optional[bool] = False
    imprimir: Optional[bool] = False
    administrar: Optional[bool] = False

    estado: Optional[bool] = True


# ─── Crear ───────────────────────────────────────────────────────
class PermisosCreate(PermisosBase):
    pass


# ─── Actualizar ──────────────────────────────────────────────────
class PermisosUpdate(BaseModel):
    crear: Optional[bool] = None
    registrar: Optional[bool] = None
    editar: Optional[bool] = None
    eliminar: Optional[bool] = None
    visualizar: Optional[bool] = None
    cambiar_estado: Optional[bool] = None
    exportar: Optional[bool] = None
    importar: Optional[bool] = None
    aprobar: Optional[bool] = None
    rechazar: Optional[bool] = None
    imprimir: Optional[bool] = None
    administrar: Optional[bool] = None
    estado: Optional[bool] = None


# ─── Respuesta ───────────────────────────────────────────────────
class PermisosResponse(PermisosBase):
    id: int
    fecha_creacion: datetime

    class Config:
        from_attributes = True