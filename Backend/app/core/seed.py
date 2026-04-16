import asyncio

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import AsyncSessionLocal
from app.core.security import hash_password

from app.models.usuario_model import Usuario
from app.models.vehiculo_model import Vehiculo
from app.models.tipo_incidente_model import TipoIncidente
from app.models.taller_model import Taller
from app.models.incidente_model import Incidente
from app.models.incidente_multimedia_model import IncidenteMultimedia


async def seed_database():
    async with AsyncSessionLocal() as db:  # ← async session

        try:
            print("🌱 Iniciando seed...")

            # -------------------------------------------------
            # LIMPIAR TABLAS (opcional pero recomendado)
            # -------------------------------------------------

            await db.execute(text("""
                TRUNCATE TABLE
                incidente_multimedia,
                incidentes,
                vehiculos,
                talleres,
                usuario,
                tipos_incidente
                RESTART IDENTITY CASCADE;
            """))

            print("🧹 Tablas limpiadas")

            # -------------------------------------------------
            # TIPOS DE INCIDENTE
            # -------------------------------------------------

            tipos = [
                TipoIncidente(
                    codigo="bateria",
                    nombre="Problema de batería",
                    prioridad_base=3
                ),
                TipoIncidente(
                    codigo="llanta",
                    nombre="Pinchazo de llanta",
                    prioridad_base=2
                ),
                TipoIncidente(
                    codigo="choque",
                    nombre="Accidente leve",
                    prioridad_base=5
                ),
                TipoIncidente(
                    codigo="motor",
                    nombre="Problema de motor",
                    prioridad_base=4
                ),
            ]

            db.add_all(tipos)
            await db.commit()

            print("✅ Tipos creados")

            # Necesario para obtener IDs
            for t in tipos:
                await db.refresh(t)

            # -------------------------------------------------
            # USUARIOS
            # -------------------------------------------------

            usuario1 = Usuario(
                nombre="Carlos",
                apellido="Perez",
                usuario="carlos123",
                correo="carlos@test.com",
                password=hash_password("123456"),
                telefono="70000001",
            )

            usuario2 = Usuario(
                nombre="Maria",
                apellido="Lopez",
                usuario="maria123",
                correo="maria@test.com",
                password=hash_password("123456"),
                telefono="70000002",
            )

            db.add_all([usuario1, usuario2])
            await db.commit()

            await db.refresh(usuario1)
            await db.refresh(usuario2)

            print("✅ Usuarios creados")

            # -------------------------------------------------
            # VEHÍCULOS
            # -------------------------------------------------

            vehiculo1 = Vehiculo(
                usuario_id=usuario1.id,
                marca="Toyota",
                modelo="Corolla",
                year=2018,
                placa="ABC123",
                color="Blanco",
                tipo="Sedan"
            )

            vehiculo2 = Vehiculo(
                usuario_id=usuario2.id,
                marca="Nissan",
                modelo="Frontier",
                year=2020,
                placa="XYZ999",
                color="Rojo",
                tipo="Pickup"
            )

            db.add_all([vehiculo1, vehiculo2])
            await db.commit()

            print("✅ Vehículos creados")

            # -------------------------------------------------
            # TALLERES (PostGIS POINT)
            # -------------------------------------------------

            await db.execute(text("""
                INSERT INTO talleres (
                    nombre_propietario,
                    nombre_negocio,
                    correo,
                    contrasena_hash,
                    telefono,
                    direccion,
                    ubicacion,
                    especialidades
                )
                VALUES
                (
                    'Luis Gómez',
                    'Taller El Rápido',
                    'taller1@test.com',
                    :pass1,
                    '70010001',
                    'Zona Sur',
                    ST_GeomFromText('POINT(-68.1193 -16.4897)', 4326),
                    ARRAY['bateria','llanta']
                ),
                (
                    'Ana Flores',
                    'Mecánica Total',
                    'taller2@test.com',
                    :pass2,
                    '70010002',
                    'Centro',
                    ST_GeomFromText('POINT(-68.1330 -16.5000)', 4326),
                    ARRAY['motor','choque']
                );
            """), {
                "pass1": hash_password("123456"),
                "pass2": hash_password("123456"),
            })

            await db.commit()

            print("✅ Talleres creados")

            # -------------------------------------------------
            # INCIDENTES
            # -------------------------------------------------

            await db.execute(text("""
                INSERT INTO incidentes (
                    usuario_id,
                    taller_asignado_id,
                    tipo_incidente_id,
                    ubicacion,
                    texto_direccion,
                    descripcion,
                    estado,
                    nivel_prioridad
                )
                VALUES
                (
                    1,
                    1,
                    1,
                    ST_GeomFromText('POINT(-68.1200 -16.4900)',4326),
                    'Av. Siempre Viva',
                    'El auto no enciende',
                    'pendiente',
                    3
                ),
                (
                    2,
                    2,
                    2,
                    ST_GeomFromText('POINT(-68.1300 -16.4950)',4326),
                    'Av. Camacho',
                    'Llanta pinchada',
                    'analizando',
                    2
                );
            """))

            await db.commit()

            print("✅ Incidentes creados")

            # -------------------------------------------------
            # MULTIMEDIA
            # -------------------------------------------------

            multimedia = [
                IncidenteMultimedia(
                    incidente_id=1,
                    tipo_archivo="imagen",
                    url_almacenamiento="https://via.placeholder.com/300.jpg",
                    tipo_mime="image/jpeg"
                ),
                IncidenteMultimedia(
                    incidente_id=2,
                    tipo_archivo="audio",
                    url_almacenamiento="https://example.com/audio.mp3",
                    tipo_mime="audio/mpeg"
                ),
            ]

            db.add_all(multimedia)
            await db.commit()

            print("✅ Multimedia creada")

            print("🎉 SEED COMPLETADO")

        except Exception as e:
            await db.rollback()
            print("❌ ERROR:", e)


if __name__ == "__main__":
    asyncio.run(seed_database())