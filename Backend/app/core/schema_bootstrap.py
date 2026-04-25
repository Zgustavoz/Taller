from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession


async def repair_schema(db: AsyncSession) -> None:
    """Aplica compatibilidad mínima de esquema con la BD documentada."""
    await db.execute(text("ALTER TABLE historial_estados ADD COLUMN IF NOT EXISTS actor_id INTEGER"))
    await db.execute(text("ALTER TABLE historial_estados ADD COLUMN IF NOT EXISTS creado_at TIMESTAMPTZ DEFAULT NOW()"))
    await db.execute(
        text(
            "UPDATE historial_estados SET actor_id = id_actor WHERE actor_id IS NULL AND id_actor IS NOT NULL"
        )
    )
    await db.execute(
        text(
            "UPDATE historial_estados SET creado_at = creado_en WHERE creado_at IS NULL AND creado_en IS NOT NULL"
        )
    )
    await db.execute(text("ALTER TABLE incidente_multimedia ADD COLUMN IF NOT EXISTS transcripcion TEXT"))