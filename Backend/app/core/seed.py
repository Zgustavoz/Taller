import asyncio

from sqlalchemy import text
from app.core.db import AsyncSessionLocal
from app.core.security import hash_password


async def seed_database():
    async with AsyncSessionLocal() as db:

        try:
            print("🌱 Iniciando seed limpio...")

            # -------------------------------------------------
            # LIMPIAR TABLAS
            # -------------------------------------------------

            await db.execute(text("""
                TRUNCATE TABLE
                tecnicos,
                talleres,
                tipos_incidente
                RESTART IDENTITY CASCADE;
            """))

            print("🧹 Tablas limpiadas")

            # -------------------------------------------------
            # TIPOS DE INCIDENTE (COMPATIBLE)
            # -------------------------------------------------

            await db.execute(text("""

                INSERT INTO tipos_incidente
                (codigo, nombre, prioridad_base)

                VALUES

                (
                    'bateria',
                    'Problema de batería',
                    3
                ),

                (
                    'llanta',
                    'Pinchazo de llanta',
                    2
                ),

                (
                    'choque',
                    'Accidente leve',
                    5
                ),

                (
                    'motor',
                    'Problema de motor',
                    4
                );

            """))

            await db.commit()

            print("✅ Tipos de incidente creados")

            # -------------------------------------------------
            # TALLERES (Nuevo Abasto Santa Cruz)
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
                    especialidades,
                    esta_disponible,
                    esta_activo
                )

                VALUES

                (
                    'Carlos Rojas',
                    'Taller Rojas',
                    'taller1@test.com',
                    :p1,
                    '70000001',
                    'Zona Nuevo Abasto 1',
                    ST_GeomFromText('POINT(-63.1870 -17.7885)',4326),
                    ARRAY['bateria','llanta'],
                    true,
                    true
                ),

                (
                    'Luis Fernandez',
                    'AutoServicio Fernandez',
                    'taller2@test.com',
                    :p2,
                    '70000002',
                    'Zona Nuevo Abasto 2',
                    ST_GeomFromText('POINT(-63.1855 -17.7890)',4326),
                    ARRAY['motor','choque'],
                    true,
                    true
                ),

                (
                    'Miguel Suarez',
                    'Taller Suarez',
                    'taller3@test.com',
                    :p3,
                    '70000003',
                    'Zona Nuevo Abasto 3',
                    ST_GeomFromText('POINT(-63.1882 -17.7875)',4326),
                    ARRAY['bateria','motor'],
                    true,
                    true
                ),

                (
                    'Jose Vargas',
                    'Taller Vargas',
                    'taller4@test.com',
                    :p4,
                    '70000004',
                    'Zona Nuevo Abasto 4',
                    ST_GeomFromText('POINT(-63.1878 -17.7902)',4326),
                    ARRAY['choque'],
                    true,
                    true
                ),

                (
                    'Andres Lopez',
                    'Auto Lopez',
                    'taller5@test.com',
                    :p5,
                    '70000005',
                    'Zona Nuevo Abasto 5',
                    ST_GeomFromText('POINT(-63.1862 -17.7868)',4326),
                    ARRAY['llanta'],
                    true,
                    true
                ),

                (
                    'Raul Mendez',
                    'Taller Mendez',
                    'taller6@test.com',
                    :p6,
                    '70000006',
                    'Zona Nuevo Abasto 6',
                    ST_GeomFromText('POINT(-63.1849 -17.7881)',4326),
                    ARRAY['motor'],
                    true,
                    true
                ),

                (
                    'Pedro Castillo',
                    'Taller Castillo',
                    'taller7@test.com',
                    :p7,
                    '70000007',
                    'Zona Nuevo Abasto 7',
                    ST_GeomFromText('POINT(-63.1889 -17.7898)',4326),
                    ARRAY['bateria','choque'],
                    true,
                    true
                ),

                (
                    'Jorge Salazar',
                    'Auto Salazar',
                    'taller8@test.com',
                    :p8,
                    '70000008',
                    'Zona Nuevo Abasto 8',
                    ST_GeomFromText('POINT(-63.1838 -17.7879)',4326),
                    ARRAY['llanta'],
                    true,
                    true
                ),

                (
                    'Mario Paredes',
                    'Taller Paredes',
                    'taller9@test.com',
                    :p9,
                    '70000009',
                    'Zona Nuevo Abasto 9',
                    ST_GeomFromText('POINT(-63.1873 -17.7862)',4326),
                    ARRAY['motor'],
                    true,
                    true
                ),

                (
                    'Ricardo Flores',
                    'Taller Flores',
                    'taller10@test.com',
                    :p10,
                    '70000010',
                    'Zona Nuevo Abasto 10',
                    ST_GeomFromText('POINT(-63.1860 -17.7905)',4326),
                    ARRAY['bateria','motor','llanta'],
                    true,
                    true
                );

            """), {
                "p1": hash_password("123456"),
                "p2": hash_password("123456"),
                "p3": hash_password("123456"),
                "p4": hash_password("123456"),
                "p5": hash_password("123456"),
                "p6": hash_password("123456"),
                "p7": hash_password("123456"),
                "p8": hash_password("123456"),
                "p9": hash_password("123456"),
                "p10": hash_password("123456"),
            })

            await db.commit()

            print("✅ 10 Talleres creados")

            # -------------------------------------------------
            # TECNICOS
            # -------------------------------------------------

            await db.execute(text("""

                INSERT INTO tecnicos (
                    taller_id,
                    nombre_completo,
                    telefono,
                    ubicacion_actual,
                    especialidades,
                    esta_disponible
                )

                VALUES

                (1,'Juan Perez','71000001',
                ST_GeomFromText('POINT(-63.1871 -17.7886)',4326),
                ARRAY['bateria'],true),

                (2,'Luis Gomez','71000002',
                ST_GeomFromText('POINT(-63.1854 -17.7891)',4326),
                ARRAY['motor'],true),

                (3,'Carlos Medina','71000003',
                ST_GeomFromText('POINT(-63.1883 -17.7876)',4326),
                ARRAY['bateria'],true),

                (4,'Pedro Arias','71000004',
                ST_GeomFromText('POINT(-63.1879 -17.7903)',4326),
                ARRAY['choque'],true),

                (5,'Jose Rivas','71000005',
                ST_GeomFromText('POINT(-63.1863 -17.7869)',4326),
                ARRAY['llanta'],true),

                (6,'Mario Soto','71000006',
                ST_GeomFromText('POINT(-63.1850 -17.7882)',4326),
                ARRAY['motor'],true),

                (7,'Jorge Molina','71000007',
                ST_GeomFromText('POINT(-63.1888 -17.7899)',4326),
                ARRAY['choque'],true),

                (8,'Raul Peña','71000008',
                ST_GeomFromText('POINT(-63.1839 -17.7880)',4326),
                ARRAY['llanta'],true),

                (9,'Luis Flores','71000009',
                ST_GeomFromText('POINT(-63.1874 -17.7863)',4326),
                ARRAY['motor'],true),

                (10,'Ricardo Nuñez','71000010',
                ST_GeomFromText('POINT(-63.1861 -17.7906)',4326),
                ARRAY['bateria'],true);

            """))

            await db.commit()

            print("✅ 10 Técnicos creados")

            print("🎉 SEED COMPLETADO")

        except Exception as e:
            await db.rollback()
            print("❌ ERROR:", e)


if __name__ == "__main__":
    asyncio.run(seed_database())