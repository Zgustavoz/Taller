from logging.config import fileConfig
from sqlalchemy import engine_from_config, pool
from sqlalchemy.ext.asyncio import AsyncEngine
from alembic import context
import asyncio
import os
from dotenv import load_dotenv

load_dotenv()

from app.core.db import Base
# Importar TODOS los modelos para que Alembic los detecte
from app.models.usuario_model import Usuario
from app.models.vehiculo_model import Vehiculo
from app.models.taller_model import Taller
from app.models.tecnico_model import Tecnico
from app.models.incidente_model import Incidente
from app.models.incidente_multimedia_model import IncidenteMultimedia
from app.models.tipo_incidente_model import TipoIncidente
from app.models.asignacion_taller_model import AsignacionTaller
from app.models.historial_estado_model import HistorialEstado
from app.models.notificacion_model import Notificacion
from app.models.pago_model import Pago
from app.models.rol_model import Rol

config = context.config

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata

# URL desde .env
DATABASE_URL = os.getenv("DATABASE_URL", "").replace(
    "postgresql+asyncpg", "postgresql"  # Alembic usa sync
)
config.set_main_option("sqlalchemy.url", DATABASE_URL)


def run_migrations_offline() -> None:
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    connectable = engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )
    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
        )
        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()