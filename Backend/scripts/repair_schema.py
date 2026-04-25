import asyncio
import sys
from pathlib import Path

BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from app.core.db import AsyncSessionLocal
from app.core.schema_bootstrap import repair_schema


async def main() -> None:
    async with AsyncSessionLocal() as db:
        print("[schema] Aplicando ajustes de compatibilidad...")
        await repair_schema(db)
        await db.commit()
        print("[schema] Ajustes aplicados correctamente")


if __name__ == "__main__":
    asyncio.run(main())
