* BD ACTUAL:
CREATE EXTENSION IF NOT EXISTS "pgcrypto"; 

CREATE EXTENSION IF NOT EXISTS "postgis"; 

  

-- 1. USUARIOS 

CREATE TABLE usuarios ( 

    id                  UUID          PRIMARY KEY DEFAULT gen_random_uuid(), 

    nombre_completo     VARCHAR(150)  NOT NULL, 

    telefono            VARCHAR(20)   UNIQUE NOT NULL, 

    correo              VARCHAR(150)  UNIQUE, 

    contrasena_hash     TEXT          NOT NULL, 

    url_foto_perfil     TEXT, 

    token_fcm           TEXT, 

    esta_activo         BOOLEAN       NOT NULL DEFAULT TRUE, 

    creado_en           TIMESTAMPTZ   NOT NULL DEFAULT now() 

); 

  

-- 2. VEHICULOS (NUEVA) 

CREATE TABLE vehiculos ( 

    id           UUID         PRIMARY KEY DEFAULT gen_random_uuid(), 

    id_usuario   UUID         NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE, 

    placa        VARCHAR(20)  UNIQUE NOT NULL, 

    marca        VARCHAR(80)  NOT NULL, 

    modelo       VARCHAR(80)  NOT NULL, 

    anio         SMALLINT     NOT NULL CHECK (anio BETWEEN 1900 AND 2100), 

    color        VARCHAR(50), 

    tipo         VARCHAR(30)  NOT NULL DEFAULT 'car' 

                 CHECK (tipo IN ('car','motorcycle','truck','van')), 

    esta_activo  BOOLEAN      NOT NULL DEFAULT TRUE, 

    creado_en    TIMESTAMPTZ  NOT NULL DEFAULT now() 

); 

  

-- 3. TALLERES (+ horario_desde, horario_hasta) 

CREATE TABLE talleres ( 

    id                    UUID          PRIMARY KEY DEFAULT gen_random_uuid(), 

    nombre_propietario    VARCHAR(150)  NOT NULL, 

    nombre_negocio        VARCHAR(200)  NOT NULL, 

    correo                VARCHAR(150)  UNIQUE NOT NULL, 

    contrasena_hash       TEXT          NOT NULL, 

    telefono              VARCHAR(20)   NOT NULL, 

    direccion             TEXT, 

    ubicacion             GEOMETRY(Point, 4326) NOT NULL, 

    radio_cobertura_km    NUMERIC(5,2)  NOT NULL DEFAULT 10, 

    especialidades        TEXT[]        NOT NULL DEFAULT '{}', 

    esta_disponible       BOOLEAN       NOT NULL DEFAULT TRUE, 

    calificacion_promedio NUMERIC(3,2)  NOT NULL DEFAULT 0, 

    token_fcm             TEXT, 

    horario_desde         TIME, 

    horario_hasta         TIME, 

    esta_activo           BOOLEAN       NOT NULL DEFAULT TRUE, 

    creado_en             TIMESTAMPTZ   NOT NULL DEFAULT now() 

); 

CREATE INDEX idx_talleres_ubicacion ON talleres USING GIST(ubicacion); 

  

-- 4. TECNICOS (NUEVA) 

CREATE TABLE tecnicos ( 

    id                UUID         PRIMARY KEY DEFAULT gen_random_uuid(), 

    id_taller         UUID         NOT NULL REFERENCES talleres(id), 

    nombre_completo   VARCHAR(150) NOT NULL, 

    telefono          VARCHAR(20), 

    ubicacion_actual  GEOMETRY(Point, 4326), 

    especialidades    TEXT[]       NOT NULL DEFAULT '{}', 

    esta_disponible   BOOLEAN      NOT NULL DEFAULT TRUE, 

    token_fcm         TEXT, 

    esta_activo       BOOLEAN      NOT NULL DEFAULT TRUE, 

    creado_en         TIMESTAMPTZ  NOT NULL DEFAULT now() 

); 

CREATE INDEX idx_tecnicos_ubicacion ON tecnicos USING GIST(ubicacion_actual); 

  

-- 5. TIPOS_INCIDENTE 

CREATE TABLE tipos_incidente ( 

    id              SERIAL       PRIMARY KEY, 

    codigo          VARCHAR(50)  UNIQUE NOT NULL, 

    nombre          VARCHAR(100) NOT NULL, 

    prioridad_base  SMALLINT     NOT NULL CHECK (prioridad_base BETWEEN 1 AND 5) 

); 

  

INSERT INTO tipos_incidente (codigo, nombre, prioridad_base) VALUES 

  ('flat_tire',      'Pinchazo / llanta baja',        3), 

  ('battery_dead',   'Bateria descargada',             3), 

  ('engine_overheat','Sobrecalentamiento de motor',    4), 

  ('minor_accident', 'Accidente leve / choque',        5), 

  ('lost_keys',      'Perdida de llaves',              2), 

  ('fuel_empty',     'Sin combustible',                1), 

  ('electrical',     'Falla electrica',                3), 

  ('other',          'Otro / no identificado',         3); 

  

-- 6. INCIDENTES (+ id_vehiculo, id_tecnico_asignado, ficha_resumen) 

CREATE TABLE incidentes ( 

    id                    UUID        PRIMARY KEY DEFAULT gen_random_uuid(), 

    id_usuario            UUID        NOT NULL REFERENCES usuarios(id), 

    id_vehiculo           UUID        REFERENCES vehiculos(id), 

    id_taller_asignado    UUID        REFERENCES talleres(id), 

    id_tecnico_asignado   UUID        REFERENCES tecnicos(id), 

    id_tipo_incidente     INT         REFERENCES tipos_incidente(id), 

    ubicacion             GEOMETRY(Point, 4326) NOT NULL, 

    direccion_texto       TEXT, 

    descripcion           TEXT, 

    estado                VARCHAR(30) NOT NULL DEFAULT 'pendiente' 

                          CHECK (estado IN ('pendiente','analizando','asignado', 

                                            'en_proceso','resuelto','cancelado')), 

    nivel_prioridad       SMALLINT    CHECK (nivel_prioridad BETWEEN 1 AND 5), 

    analisis_ia           JSONB, 

    ficha_resumen         JSONB, 

    min_llegada_estimados SMALLINT, 

    creado_en             TIMESTAMPTZ NOT NULL DEFAULT now(), 

    resuelto_en           TIMESTAMPTZ 

); 

CREATE INDEX idx_incidentes_ubicacion ON incidentes USING GIST(ubicacion); 

CREATE INDEX idx_incidentes_estado    ON incidentes(estado); 

CREATE INDEX idx_incidentes_ia        ON incidentes USING GIN(analisis_ia); 

CREATE INDEX idx_incidentes_ficha     ON incidentes USING GIN(ficha_resumen); 

  

-- 7. ARCHIVOS_MULTIMEDIA (+ transcripcion) 

CREATE TABLE archivos_multimedia ( 

    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(), 

    id_incidente        UUID        NOT NULL REFERENCES incidentes(id) ON DELETE CASCADE, 

    tipo_media          VARCHAR(10) NOT NULL CHECK (tipo_media IN ('image','audio','video')), 

    url_almacenamiento  TEXT        NOT NULL, 

    tipo_mime           VARCHAR(50), 

    duracion_seg        NUMERIC(6,2), 

    tamano_bytes        BIGINT, 

    transcripcion       TEXT, 

    resultado_ia        JSONB, 

    subido_en           TIMESTAMPTZ NOT NULL DEFAULT now() 

); 

  

-- 8. HISTORIAL_ESTADOS 

CREATE TABLE historial_estados ( 

    id              BIGSERIAL   PRIMARY KEY, 

    id_incidente    UUID        NOT NULL REFERENCES incidentes(id), 

    estado_anterior VARCHAR(30), 

    estado_nuevo    VARCHAR(30) NOT NULL, 

    tipo_actor      VARCHAR(10) NOT NULL 

                    CHECK (tipo_actor IN ('usuario','taller','sistema','ia')), 

    id_actor        UUID, 

    notas           TEXT, 

    creado_en       TIMESTAMPTZ NOT NULL DEFAULT now() 

); 

CREATE INDEX idx_historial_incidente ON historial_estados(id_incidente, creado_en); 

  

-- 9. ASIGNACIONES_TALLERES (+ id_tecnico, puntuacion_asignacion) 

CREATE TABLE asignaciones_talleres ( 

    id                    UUID        PRIMARY KEY DEFAULT gen_random_uuid(), 

    id_incidente          UUID        NOT NULL REFERENCES incidentes(id), 

    id_taller             UUID        NOT NULL REFERENCES talleres(id), 

    id_tecnico            UUID        REFERENCES tecnicos(id), 

    tipo_asignacion       VARCHAR(15) NOT NULL 

                          CHECK (tipo_asignacion IN ('automatica','manual')), 

    distancia_km          NUMERIC(6,2), 

    puntuacion_asignacion NUMERIC(5,2), 

    estado_respuesta      VARCHAR(20) NOT NULL DEFAULT 'pendiente' 

                          CHECK (estado_respuesta IN ('pendiente','aceptado', 

                                                      'rechazado','timeout')), 

    respondido_en         TIMESTAMPTZ, 

    creado_en             TIMESTAMPTZ NOT NULL DEFAULT now() 

); 

  

-- 10. NOTIFICACIONES 

CREATE TABLE notificaciones ( 

    id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(), 

    tipo_destinatario VARCHAR(15) NOT NULL  CHECK (tipo_destinatario IN ('usuario','taller','tecnico')), 

    id_destinatario   UUID        NOT NULL, 

    id_incidente      UUID        REFERENCES incidentes(id), 

    titulo            VARCHAR(200), 

    cuerpo            TEXT, 

    datos_extra       JSONB, 

    enviado_en        TIMESTAMPTZ, 

    leido_en          TIMESTAMPTZ, 

    estado            VARCHAR(15) NOT NULL DEFAULT 'pendiente' 
 CHECK (estado IN ('pendiente','enviado','fallido','leido')) 

); 

  

-- 11. PAGOS (NUEVA) 

CREATE TABLE pagos ( 

    id                 UUID        PRIMARY KEY DEFAULT gen_random_uuid(), 

    id_incidente       UUID        UNIQUE NOT NULL REFERENCES incidentes(id), 

    id_usuario         UUID        NOT NULL REFERENCES usuarios(id), 

    id_taller          UUID        NOT NULL REFERENCES talleres(id), 

    monto_total        NUMERIC(10,2) NOT NULL CHECK (monto_total > 0), 

    monto_comision     NUMERIC(10,2) NOT NULL GENERATED ALWAYS AS (ROUND(monto_total * 0.10, 2)) STORED, 

    monto_taller       NUMERIC(10,2) NOT NULL 

                       GENERATED ALWAYS AS (ROUND(monto_total * 0.90, 2)) STORED, 

    metodo_pago        VARCHAR(30) NOT NULL 

                       CHECK (metodo_pago IN ('tarjeta','qr','transferencia','efectivo')), 

    referencia_externa TEXT, 

    estado_pago        VARCHAR(20) NOT NULL DEFAULT 'pendiente' 

                       CHECK (estado_pago IN ('pendiente','completado','fallido','reembolsado')), 

    comision_pagada    BOOLEAN     NOT NULL DEFAULT FALSE, 

    creado_en          TIMESTAMPTZ NOT NULL DEFAULT now(), 

    pagado_en          TIMESTAMPTZ 

); 

  

-- 12. CALIFICACIONES 

CREATE TABLE calificaciones ( 

    id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(), 

    id_incidente UUID        UNIQUE NOT NULL REFERENCES incidentes(id), 

    id_usuario   UUID        NOT NULL REFERENCES usuarios(id), 

    id_taller    UUID        NOT NULL REFERENCES talleres(id), 

    puntuacion   SMALLINT    NOT NULL CHECK (puntuacion BETWEEN 1 AND 5), 

    comentario   TEXT, 

    creado_en    TIMESTAMPTZ NOT NULL DEFAULT now() 

); 