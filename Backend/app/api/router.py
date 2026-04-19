from fastapi import APIRouter
from app.api.gestion_usuario.usuario.usuario_route import router as usuario_router
from app.api.gestion_usuario.rol.rol_route import router as rol_router
from app.api.gestion_usuario.auth_route import router as auth_router
from app.api.gestion_usuario.taller.taller_route import router as taller_router
from app.api.incidentes.tipo_incidente_route import router as tipo_incidente_router
from app.api.incidentes.incidente_route import router as incidente_router
from app.api.incidentes.incidente_multimedia_route import router as multimedia_router
from app.api.incidentes.historial_estado_route import router as historial_estados_router
from app.api.gestion_usuario.vehiculo_route import router as vehiculo_router
from app.api.gestion_usuario.tecnico.tecnico_route import router as tecnico_router
from app.api.notificaciones.notificacion_route import router as notificacion_router


api_router = APIRouter(prefix="/api")

api_router.include_router(auth_router)
api_router.include_router(usuario_router)
api_router.include_router(vehiculo_router)
api_router.include_router(tecnico_router)
api_router.include_router(rol_router)
api_router.include_router(taller_router)
api_router.include_router(tipo_incidente_router)
api_router.include_router(incidente_router)
api_router.include_router(historial_estados_router)
api_router.include_router(multimedia_router)
api_router.include_router(notificacion_router)
