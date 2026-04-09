from fastapi import APIRouter
from app.api.gestion_usuario.usuario.usuario_route import router as usuario_router
from app.api.gestion_usuario.rol.rol_route import router as rol_router
from app.api.gestion_usuario.auth_route import router as auth_router

api_router = APIRouter(prefix="/api")

api_router.include_router(auth_router)
api_router.include_router(usuario_router)
api_router.include_router(rol_router)