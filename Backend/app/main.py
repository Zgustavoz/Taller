from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
from app.core.db import engine, Base
from app.core.config import settings
from app.api.router import api_router

# Importar modelos para que SQLAlchemy los registre
import app.models  # noqa


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Crear tablas al arrancar (solo para desarrollo)
    # En producción usar Alembic
    async with engine.begin() as conn:
        # Requerido para la columna GEOMETRY(Point, 4326) de talleres.
        await conn.execute(text("CREATE EXTENSION IF NOT EXISTS postgis"))
        await conn.run_sync(Base.metadata.create_all)
    yield
    # Cerrar conexiones al apagar
    await engine.dispose()


app = FastAPI(
    title="Sistema de Información API",
    description="Backend con FastAPI, PostgreSQL, JWT, Google OAuth y Resend",
    version="1.0.0",
    lifespan=lifespan,
)

# ─── CORS ────────────────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        settings.FRONTEND_URL,
        "http://localhost:4200",
        "http://127.0.0.1:4200",
    ],
    allow_credentials=True,   # necesario para cookies
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─── Rutas ───────────────────────────────────────────────────────
app.include_router(api_router)


@app.get("/", tags=["Health"])
async def root():
    return {"estado": "ok", "mensaje": "API funcionando correctamente"}