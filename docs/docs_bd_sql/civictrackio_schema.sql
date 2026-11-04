-- =============================================================
-- CivicTrackIO — Script BD Consolidado (Esquema completo)
-- Base: PostgreSQL 17 (Supabase) · PostGIS
-- Generado desde backup Supabase — Noviembre 2026
-- Tablas: 17 · Funciones: 8 · Triggers: 3 · Vistas: 9
-- =============================================================

-- =============================================================
-- EXTENSIONES
-- =============================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp"   WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pgcrypto      WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS unaccent      WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS fuzzystrmatch WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS postgis;

-- =============================================================
-- SECUENCIAS
-- =============================================================
CREATE SEQUENCE IF NOT EXISTS public.zonas_id_seq         AS integer START 1;
CREATE SEQUENCE IF NOT EXISTS public.corregimientos_id_seq AS integer START 1;
CREATE SEQUENCE IF NOT EXISTS public.veredas_id_seq        AS integer START 1;
CREATE SEQUENCE IF NOT EXISTS public.secciones_dane_id_seq AS integer START 1;

-- =============================================================
-- TABLA: zonas (HU-01)
-- Catálogo de barrios con su comuna correspondiente (Pasto)
-- Sprint 1: estructura base · Sprint 2: columna geom (PostGIS)
-- =============================================================
CREATE TABLE public.zonas (
    id      INTEGER                          NOT NULL DEFAULT nextval('public.zonas_id_seq'::regclass),
    barrio  CHARACTER VARYING(80)            NOT NULL,
    comuna  INTEGER                          NOT NULL,
    geom    public.geometry(MultiPolygon,4326),
    CONSTRAINT zonas_pkey              PRIMARY KEY (id),
    CONSTRAINT chk_barrio_not_empty    CHECK (barrio <> ''),
    CONSTRAINT zonas_comuna_check      CHECK (comuna >= 1 AND comuna <= 12),
    CONSTRAINT uniq_barrio_comuna      UNIQUE (barrio, comuna)
);

ALTER SEQUENCE public.zonas_id_seq OWNED BY public.zonas.id;
ALTER TABLE public.zonas ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_zonas_geom ON public.zonas USING gist (geom);

CREATE POLICY "zonas_select_public" ON public.zonas
    FOR SELECT TO PUBLIC USING (true);

-- =============================================================
-- TABLA: usuarios (HU-02)
-- Sprint 1: estructura base · Sprint 2: columna fcm_token
-- =============================================================
CREATE TABLE public.usuarios (
    id              UUID                         NOT NULL DEFAULT gen_random_uuid(),
    username        CHARACTER VARYING(50)        NOT NULL,
    correo          CHARACTER VARYING(150)       NOT NULL,
    password_hash   TEXT,
    foto_url        TEXT,
    rol             CHARACTER VARYING(20)        NOT NULL,
    auth_provider   TEXT[]                       NOT NULL,
    google_id       CHARACTER VARYING(255),
    fecha_creacion  TIMESTAMP WITHOUT TIME ZONE  NOT NULL DEFAULT now(),
    estado          CHARACTER VARYING(20)        NOT NULL,
    fcm_token       TEXT,
    CONSTRAINT usuarios_pkey               PRIMARY KEY (id),
    CONSTRAINT usuarios_correo_key         UNIQUE (correo),
    CONSTRAINT usuarios_username_key       UNIQUE (username),
    CONSTRAINT usuarios_google_id_key      UNIQUE (google_id),
    CONSTRAINT usuarios_rol_check          CHECK (rol IN ('usuario', 'admin')),
    CONSTRAINT usuarios_estado_check       CHECK (estado IN ('activo', 'bloqueado', 'eliminado', 'oculto')),
    CONSTRAINT usuarios_auth_provider_check
        CHECK (auth_provider <@ ARRAY['local', 'google']::TEXT[] AND array_length(auth_provider, 1) > 0)
);

ALTER TABLE public.usuarios ENABLE ROW LEVEL SECURITY;

CREATE POLICY "usuarios_no_direct_access" ON public.usuarios
    FOR ALL TO PUBLIC USING (false);

-- =============================================================
-- TABLA: corregimientos (Sprint 2 · HU-08)
-- Zonas rurales de Pasto con geometría PostGIS
-- =============================================================
CREATE TABLE public.corregimientos (
    id      INTEGER                          NOT NULL DEFAULT nextval('public.corregimientos_id_seq'::regclass),
    nombre  CHARACTER VARYING(80)            NOT NULL,
    geom    public.geometry(MultiPolygon,4326),
    CONSTRAINT corregimientos_pkey         PRIMARY KEY (id),
    CONSTRAINT chk_corregimiento_not_empty CHECK (nombre <> ''),
    CONSTRAINT uniq_corregimiento          UNIQUE (nombre)
);

ALTER SEQUENCE public.corregimientos_id_seq OWNED BY public.corregimientos.id;
ALTER TABLE public.corregimientos ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_corregimientos_geom ON public.corregimientos USING gist (geom);

CREATE POLICY "corregimientos_select_public" ON public.corregimientos
    FOR SELECT TO PUBLIC USING (true);

-- =============================================================
-- TABLA: veredas (Sprint 2 · HU-08)
-- Subdivisiones dentro de corregimientos
-- =============================================================
CREATE TABLE public.veredas (
    id               INTEGER               NOT NULL DEFAULT nextval('public.veredas_id_seq'::regclass),
    nombre           CHARACTER VARYING(80) NOT NULL,
    corregimiento_id INTEGER               NOT NULL,
    es_cabecera      BOOLEAN               NOT NULL DEFAULT false,
    CONSTRAINT veredas_pkey             PRIMARY KEY (id),
    CONSTRAINT chk_vereda_not_empty     CHECK (nombre <> ''),
    CONSTRAINT veredas_corregimiento_id_fkey
        FOREIGN KEY (corregimiento_id) REFERENCES public.corregimientos(id)
);

ALTER SEQUENCE public.veredas_id_seq OWNED BY public.veredas.id;
ALTER TABLE public.veredas ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_veredas_corregimiento ON public.veredas USING btree (corregimiento_id);

CREATE POLICY "veredas_select_public" ON public.veredas
    FOR SELECT TO PUBLIC USING (true);

-- =============================================================
-- TABLA: secciones_dane (Sprint 2 · HU-08)
-- Secciones censales DANE con geometría para geolocalización
-- =============================================================
CREATE TABLE public.secciones_dane (
    id          INTEGER                          NOT NULL DEFAULT nextval('public.secciones_dane_id_seq'::regclass),
    secu_ccdgo  CHARACTER VARYING(10),
    setu_ccdgo  CHARACTER VARYING(10),
    comuna      INTEGER,
    geom        public.geometry(MultiPolygon,4326),
    CONSTRAINT secciones_dane_pkey PRIMARY KEY (id)
);

ALTER SEQUENCE public.secciones_dane_id_seq OWNED BY public.secciones_dane.id;
ALTER TABLE public.secciones_dane ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_secciones_geom ON public.secciones_dane USING gist (geom);

CREATE POLICY "secciones_dane_select_public" ON public.secciones_dane
    FOR SELECT TO PUBLIC USING (true);

-- =============================================================
-- FUNCIÓN: buscar_barrio_similar (Sprint 1 · HU-01)
-- Búsqueda difusa por distancia Levenshtein + unaccent
-- =============================================================
CREATE OR REPLACE FUNCTION public.buscar_barrio_similar(texto_usuario TEXT)
RETURNS TABLE(id INTEGER, barrio CHARACTER VARYING, comuna INTEGER, similitud INTEGER)
LANGUAGE sql AS $function$
    SELECT
        z.id, z.barrio, z.comuna,
        levenshtein(unaccent(lower(z.barrio)), unaccent(lower(texto_usuario))) AS similitud
    FROM zonas z
    ORDER BY similitud ASC
    LIMIT 5;
$function$;

-- =============================================================
-- FUNCIÓN: asignar_zona_y_comuna (Sprint 2 · HU-08)
-- Trigger: asigna zona_id y comuna por coordenadas PostGIS
-- Prioridad 1: ST_Contains · Prioridad 2: nombre exacto
-- =============================================================
CREATE OR REPLACE FUNCTION public.asignar_zona_y_comuna()
RETURNS TRIGGER LANGUAGE plpgsql AS $function$
DECLARE
    zona_encontrada   INTEGER;
    comuna_encontrada INTEGER;
BEGIN
    IF NEW.latitud IS NOT NULL AND NEW.longitud IS NOT NULL THEN
        SELECT z.id, z.comuna INTO zona_encontrada, comuna_encontrada
        FROM public.secciones_dane s
        JOIN public.zonas z ON z.comuna = s.comuna
        WHERE ST_Contains(s.geom, ST_SetSRID(ST_MakePoint(NEW.longitud::float8, NEW.latitud::float8), 4326))
          AND unaccent(lower(z.barrio)) = unaccent(lower(NEW.barrio_ingresado))
        LIMIT 1;
    END IF;

    IF zona_encontrada IS NULL AND NEW.barrio_ingresado IS NOT NULL THEN
        SELECT z.id, z.comuna INTO zona_encontrada, comuna_encontrada
        FROM public.zonas z
        WHERE unaccent(lower(z.barrio)) = unaccent(lower(NEW.barrio_ingresado))
        LIMIT 1;
    END IF;

    NEW.zona_id := zona_encontrada;
    NEW.comuna  := comuna_encontrada;
    RETURN NEW;
END;
$function$;

-- =============================================================
-- FUNCIÓN: asignar_zona_automatica (Sprint 2 · HU-08)
-- Trigger fallback: asigna zona por similitud Levenshtein
-- Se ejecuta solo cuando zona_id sigue siendo NULL
-- =============================================================
CREATE OR REPLACE FUNCTION public.asignar_zona_automatica()
RETURNS TRIGGER LANGUAGE plpgsql AS $function$
DECLARE
    zona_encontrada INTEGER;
BEGIN
    SELECT id INTO zona_encontrada
    FROM buscar_barrio_similar(NEW.barrio_ingresado)
    LIMIT 1;

    NEW.zona_id = zona_encontrada;
    RETURN NEW;
END;
$function$;

-- =============================================================
-- FUNCIÓN: calcular_nivel_riesgo (Sprint 3 · HU-12)
-- Clasifica zonas según cantidad de reportes
-- ≤3 seguro · ≤7 medio · ≤10 alto · >10 peligroso
-- =============================================================
CREATE OR REPLACE FUNCTION public.calcular_nivel_riesgo(cantidad INTEGER)
RETURNS CHARACTER VARYING
LANGUAGE sql IMMUTABLE AS $function$
    SELECT CASE
        WHEN cantidad <= 3  THEN 'seguro'
        WHEN cantidad <= 7  THEN 'medio'
        WHEN cantidad <= 10 THEN 'alto'
        ELSE 'peligroso'
    END;
$function$;

-- =============================================================
-- TABLA: reportes (HU-01, HU-06)
-- Tabla central del sistema.
-- Sprint 1: estructura base
-- Sprint 2: actualizado_por, fecha_actualizacion, zona_tipo,
--           corregimiento_id, vereda_id
-- Sprint 3: incidente_id
-- Producción: coordenadas_exactas
-- =============================================================
CREATE TABLE public.reportes (
    id                  UUID                        NOT NULL DEFAULT gen_random_uuid(),
    usuario_id          UUID                        NOT NULL DEFAULT '645c346d-e56a-4022-b488-e8142e0c96a5'::uuid,
    tipo_reportante     CHARACTER VARYING(20),
    fecha_incidente     DATE                        NOT NULL,
    franja_horaria      CHARACTER VARYING(20),
    latitud             NUMERIC(9,6),
    longitud            NUMERIC(9,6),
    direccion           CHARACTER VARYING(100),
    tipo_hurto          CHARACTER VARYING(30),
    descripcion         CHARACTER VARYING(300),
    objeto_hurtado      CHARACTER VARYING(50),
    numero_agresores    CHARACTER VARYING(20),
    fecha_creacion      TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
    fecha_actualizacion TIMESTAMP WITHOUT TIME ZONE,
    actualizado_por     UUID,
    estado              CHARACTER VARYING(20)       NOT NULL,
    barrio_ingresado    CHARACTER VARYING(80)       NOT NULL DEFAULT 'SIN DEFINIR',
    zona_id             INTEGER,
    comuna              INTEGER,
    zona_tipo           CHARACTER VARYING(10)       NOT NULL DEFAULT 'urbana',
    corregimiento_id    INTEGER,
    vereda_id           INTEGER,
    incidente_id        UUID,
    coordenadas_exactas BOOLEAN                     NOT NULL DEFAULT true,
    CONSTRAINT reportes_pkey                  PRIMARY KEY (id),
    CONSTRAINT reportes_estado_check          CHECK (estado IN ('activo', 'oculto', 'eliminado')),
    CONSTRAINT reportes_tipo_reportante_check CHECK (tipo_reportante IN ('victima', 'testigo')),
    CONSTRAINT reportes_franja_horaria_check  CHECK (franja_horaria IN ('00:00-05:59', '06:00-11:59', '12:00-17:59', '18:00-23:59')),
    CONSTRAINT reportes_tipo_hurto_check      CHECK (tipo_hurto IN ('atraco', 'raponazo', 'cosquilleo', 'fleteo')),
    CONSTRAINT reportes_objeto_hurtado_check  CHECK (objeto_hurtado IN ('celular', 'dinero', 'tarjetas_documentos', 'articulos_personales', 'dispositivos_electronicos')),
    CONSTRAINT reportes_numero_agresores_check CHECK (numero_agresores IN ('1', '2', '3+', 'desconocido')),
    CONSTRAINT reportes_zona_tipo_check       CHECK (zona_tipo IN ('urbana', 'rural')),
    CONSTRAINT fk_usuario          FOREIGN KEY (usuario_id)       REFERENCES public.usuarios(id) ON DELETE SET DEFAULT,
    CONSTRAINT fk_actualizado_por  FOREIGN KEY (actualizado_por)  REFERENCES public.usuarios(id) ON DELETE SET NULL,
    CONSTRAINT fk_zona             FOREIGN KEY (zona_id)          REFERENCES public.zonas(id),
    CONSTRAINT reportes_corregimiento_id_fkey FOREIGN KEY (corregimiento_id) REFERENCES public.corregimientos(id),
    CONSTRAINT reportes_vereda_id_fkey        FOREIGN KEY (vereda_id)        REFERENCES public.veredas(id)
);

ALTER TABLE public.reportes ENABLE ROW LEVEL SECURITY;

-- Índices Sprint 1
CREATE INDEX idx_reportes_fecha_incidente   ON public.reportes USING btree (fecha_incidente);
CREATE INDEX idx_reportes_zona_id           ON public.reportes USING btree (zona_id);
CREATE INDEX idx_reportes_comuna            ON public.reportes USING btree (comuna);
CREATE INDEX idx_reportes_tipo_hurto        ON public.reportes USING btree (tipo_hurto);
CREATE INDEX idx_reportes_estado            ON public.reportes USING btree (estado);
CREATE INDEX idx_reportes_usuario_id        ON public.reportes USING btree (usuario_id);
-- Índices Sprint 2
CREATE INDEX idx_reportes_franja_horaria    ON public.reportes USING btree (franja_horaria);
CREATE INDEX idx_reportes_estado_fecha      ON public.reportes USING btree (estado, fecha_incidente);
CREATE INDEX idx_reportes_estado_zona       ON public.reportes USING btree (estado, zona_id);
CREATE INDEX idx_reportes_latitud_longitud  ON public.reportes USING btree (latitud, longitud);
CREATE INDEX idx_reportes_estado_coords     ON public.reportes USING btree (estado, latitud, longitud);
CREATE INDEX idx_reportes_fecha_creacion    ON public.reportes USING btree (fecha_creacion DESC);
CREATE INDEX idx_reportes_corregimiento     ON public.reportes USING btree (corregimiento_id);
CREATE INDEX idx_reportes_zona_tipo         ON public.reportes USING btree (zona_tipo);
CREATE INDEX idx_reportes_actualizado_por   ON public.reportes USING btree (actualizado_por)
    WHERE (actualizado_por IS NOT NULL);
-- Índices Sprint 3
CREATE INDEX idx_reportes_incidente_id         ON public.reportes USING btree (incidente_id);
CREATE INDEX idx_reportes_estado_tipo_hurto    ON public.reportes USING btree (estado, tipo_hurto);
CREATE INDEX idx_reportes_estado_comuna_tipo   ON public.reportes USING btree (estado, comuna, tipo_hurto);
CREATE INDEX idx_reportes_fecha_zona_tipo      ON public.reportes USING btree (fecha_incidente, zona_id, tipo_hurto);
-- Índices Sprint 4
CREATE INDEX idx_reportes_estado_fecha_export  ON public.reportes USING btree (estado, fecha_incidente DESC);
CREATE INDEX idx_reportes_zona_estado_fecha    ON public.reportes USING btree (zona_id, estado, fecha_incidente DESC);
CREATE INDEX idx_reportes_comuna_estado_fecha  ON public.reportes USING btree (comuna, estado, fecha_incidente DESC);
CREATE INDEX idx_reportes_estado_fecha_zona    ON public.reportes USING btree (estado, fecha_incidente, zona_id);
CREATE INDEX idx_reportes_estado_fecha_comuna  ON public.reportes USING btree (estado, fecha_incidente, comuna);
-- Índice producción
CREATE INDEX idx_reportes_coordenadas_exactas  ON public.reportes USING btree (coordenadas_exactas);

CREATE POLICY "reportes_no_direct_access" ON public.reportes
    FOR ALL TO PUBLIC USING (false);

-- Triggers sobre reportes
CREATE TRIGGER trigger_asignar_zona_comuna
    BEFORE INSERT OR UPDATE ON public.reportes
    FOR EACH ROW EXECUTE FUNCTION public.asignar_zona_y_comuna();

CREATE TRIGGER trigger_asignar_zona
    BEFORE INSERT OR UPDATE ON public.reportes
    FOR EACH ROW
    WHEN (NEW.zona_id IS NULL)
    EXECUTE FUNCTION public.asignar_zona_automatica();

-- =============================================================
-- TABLA: incidentes (Sprint 3 · HU-10, HU-11, HU-12)
-- Agrupación automática de reportes en radio de 150m
-- Producción: corregimiento_id, vereda_id, tiene_coordenadas
-- =============================================================
CREATE TABLE public.incidentes (
    id                   UUID                        NOT NULL DEFAULT gen_random_uuid(),
    reporte_principal_id UUID                        NOT NULL,
    tipo_hurto           CHARACTER VARYING(30),
    fecha_incidente      DATE                        NOT NULL,
    franja_horaria       CHARACTER VARYING(20),
    latitud_centro       NUMERIC(9,6),
    longitud_centro      NUMERIC(9,6),
    zona_id              INTEGER,
    comuna               INTEGER,
    cantidad_reportes    INTEGER                     NOT NULL DEFAULT 1,
    fecha_creacion       TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
    corregimiento_id     INTEGER,
    vereda_id            INTEGER,
    tiene_coordenadas    BOOLEAN                     NOT NULL DEFAULT true,
    CONSTRAINT incidentes_pkey             PRIMARY KEY (id),
    CONSTRAINT chk_incidente_comuna        CHECK (comuna IS NULL OR (comuna >= 1 AND comuna <= 12)),
    CONSTRAINT incidentes_franja_horaria_check CHECK (franja_horaria IN ('00:00-05:59', '06:00-11:59', '12:00-17:59', '18:00-23:59')),
    CONSTRAINT incidentes_tipo_hurto_check    CHECK (tipo_hurto IN ('atraco', 'raponazo', 'cosquilleo', 'fleteo')),
    CONSTRAINT fk_incidente_zona          FOREIGN KEY (zona_id)          REFERENCES public.zonas(id),
    CONSTRAINT fk_incidente_corregimiento FOREIGN KEY (corregimiento_id) REFERENCES public.corregimientos(id),
    CONSTRAINT fk_incidente_vereda        FOREIGN KEY (vereda_id)        REFERENCES public.veredas(id)
);

ALTER TABLE public.incidentes ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_incidentes_fecha         ON public.incidentes USING btree (fecha_incidente);
CREATE INDEX idx_incidentes_tipo_hurto    ON public.incidentes USING btree (tipo_hurto);
CREATE INDEX idx_incidentes_zona          ON public.incidentes USING btree (zona_id);
CREATE INDEX idx_incidentes_comuna        ON public.incidentes USING btree (comuna);
CREATE INDEX idx_incidentes_coords        ON public.incidentes USING btree (latitud_centro, longitud_centro);
CREATE INDEX idx_incidentes_corregimiento ON public.incidentes USING btree (corregimiento_id);
CREATE INDEX idx_incidentes_vereda        ON public.incidentes USING btree (vereda_id);
CREATE INDEX idx_incidentes_tiene_coords  ON public.incidentes USING btree (tiene_coordenadas);

CREATE POLICY "incidentes_no_direct_access" ON public.incidentes
    FOR ALL TO PUBLIC USING (false);

-- Foreign keys cíclicas (reportes ↔ incidentes)
ALTER TABLE public.incidentes
    ADD CONSTRAINT fk_reporte_principal
        FOREIGN KEY (reporte_principal_id) REFERENCES public.reportes(id)
        ON DELETE RESTRICT DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE public.reportes
    ADD CONSTRAINT fk_reporte_incidente
        FOREIGN KEY (incidente_id) REFERENCES public.incidentes(id) ON DELETE SET NULL;

-- =============================================================
-- FUNCIÓN: asignar_o_crear_incidente (Sprint 3 · HU-10)
-- Trigger BEFORE INSERT en reportes.
-- Camino A: reporte con GPS → agrupa por radio 150m
-- Camino B: rural sin GPS + vereda → agrupa por vereda,
--           usa ST_Centroid del corregimiento para el mapa
-- Camino C: sin GPS ni vereda → incidente huérfano (stats)
-- =============================================================
CREATE OR REPLACE FUNCTION public.asignar_o_crear_incidente()
RETURNS TRIGGER LANGUAGE plpgsql AS $function$
DECLARE
    incidente_existente UUID;
    centroide_lat       NUMERIC(9,6);
    centroide_lng       NUMERIC(9,6);
    RADIO_METROS        CONSTANT NUMERIC := 150;
BEGIN
    -- CAMINO A: reporte CON coordenadas GPS
    IF NEW.latitud IS NOT NULL AND NEW.longitud IS NOT NULL THEN

        SELECT i.id INTO incidente_existente
        FROM public.incidentes i
        WHERE i.tipo_hurto        = NEW.tipo_hurto
          AND i.fecha_incidente   = NEW.fecha_incidente
          AND i.franja_horaria    = NEW.franja_horaria
          AND i.tiene_coordenadas = true
          AND (
              6371000 * acos(
                  LEAST(1.0,
                      cos(radians(i.latitud_centro::float8))
                      * cos(radians(NEW.latitud::float8))
                      * cos(radians(NEW.longitud::float8) - radians(i.longitud_centro::float8))
                      + sin(radians(i.latitud_centro::float8))
                      * sin(radians(NEW.latitud::float8))
                  )
              )
          ) <= RADIO_METROS
        ORDER BY i.fecha_creacion ASC
        LIMIT 1;

        IF incidente_existente IS NOT NULL THEN
            NEW.incidente_id := incidente_existente;
            UPDATE public.incidentes i
            SET
                cantidad_reportes    = i.cantidad_reportes + 1,
                latitud_centro       = (i.latitud_centro  * i.cantidad_reportes + NEW.latitud)  / (i.cantidad_reportes + 1),
                longitud_centro      = (i.longitud_centro * i.cantidad_reportes + NEW.longitud) / (i.cantidad_reportes + 1),
                reporte_principal_id = CASE
                    WHEN NEW.tipo_reportante = 'victima' THEN NEW.id
                    ELSE i.reporte_principal_id
                END
            WHERE i.id = incidente_existente;
        ELSE
            INSERT INTO public.incidentes (
                reporte_principal_id, tipo_hurto, fecha_incidente,
                franja_horaria, latitud_centro, longitud_centro,
                zona_id, comuna, corregimiento_id, vereda_id,
                cantidad_reportes, tiene_coordenadas
            ) VALUES (
                NEW.id, NEW.tipo_hurto, NEW.fecha_incidente,
                NEW.franja_horaria, NEW.latitud, NEW.longitud,
                NEW.zona_id, NEW.comuna, NEW.corregimiento_id, NEW.vereda_id,
                1, true
            )
            RETURNING id INTO NEW.incidente_id;
        END IF;

    -- CAMINO B: rural SIN GPS pero con vereda conocida
    ELSIF NEW.zona_tipo = 'rural' AND NEW.vereda_id IS NOT NULL THEN

        SELECT i.id INTO incidente_existente
        FROM public.incidentes i
        WHERE i.tipo_hurto        = NEW.tipo_hurto
          AND i.fecha_incidente   = NEW.fecha_incidente
          AND i.franja_horaria    = NEW.franja_horaria
          AND i.vereda_id         = NEW.vereda_id
          AND i.tiene_coordenadas = false
        ORDER BY i.fecha_creacion ASC
        LIMIT 1;

        SELECT ST_Y(ST_Centroid(c.geom)), ST_X(ST_Centroid(c.geom))
        INTO centroide_lat, centroide_lng
        FROM public.veredas v
        JOIN public.corregimientos c ON c.id = v.corregimiento_id
        WHERE v.id = NEW.vereda_id AND c.geom IS NOT NULL;

        IF centroide_lat IS NOT NULL THEN
            NEW.latitud             := centroide_lat;
            NEW.longitud            := centroide_lng;
            NEW.coordenadas_exactas := false;
        END IF;

        IF incidente_existente IS NOT NULL THEN
            NEW.incidente_id := incidente_existente;
            UPDATE public.incidentes
            SET
                cantidad_reportes    = cantidad_reportes + 1,
                reporte_principal_id = CASE
                    WHEN NEW.tipo_reportante = 'victima' THEN NEW.id
                    ELSE reporte_principal_id
                END
            WHERE id = incidente_existente;
        ELSE
            INSERT INTO public.incidentes (
                reporte_principal_id, tipo_hurto, fecha_incidente,
                franja_horaria, latitud_centro, longitud_centro,
                corregimiento_id, vereda_id,
                cantidad_reportes, tiene_coordenadas
            ) VALUES (
                NEW.id, NEW.tipo_hurto, NEW.fecha_incidente,
                NEW.franja_horaria, centroide_lat, centroide_lng,
                NEW.corregimiento_id, NEW.vereda_id,
                1, false
            )
            RETURNING id INTO NEW.incidente_id;
        END IF;

    -- CAMINO C: sin GPS y sin vereda — incidente huérfano
    ELSE
        INSERT INTO public.incidentes (
            reporte_principal_id, tipo_hurto, fecha_incidente,
            franja_horaria, latitud_centro, longitud_centro,
            cantidad_reportes, tiene_coordenadas
        ) VALUES (
            NEW.id, NEW.tipo_hurto, NEW.fecha_incidente,
            NEW.franja_horaria, NULL, NULL,
            1, false
        )
        RETURNING id INTO NEW.incidente_id;
    END IF;

    RETURN NEW;
END;
$function$;

-- Trigger sobre reportes (debe declararse después de la función)
CREATE TRIGGER trigger_asignar_incidente
    BEFORE INSERT ON public.reportes
    FOR EACH ROW EXECUTE FUNCTION public.asignar_o_crear_incidente();

-- =============================================================
-- TABLA: configuracion_alertas (Sprint 2 · HU-07)
-- Una configuración por usuario, radio entre 100 y 5000m
-- =============================================================
CREATE TABLE public.configuracion_alertas (
    id                  UUID                        NOT NULL DEFAULT gen_random_uuid(),
    usuario_id          UUID                        NOT NULL,
    radio_metros        INTEGER                     NOT NULL DEFAULT 500,
    activo              BOOLEAN                     NOT NULL DEFAULT true,
    fecha_creacion      TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
    fecha_actualizacion TIMESTAMP WITHOUT TIME ZONE,
    CONSTRAINT configuracion_alertas_pkey         PRIMARY KEY (id),
    CONSTRAINT configuracion_alertas_usuario_id_key UNIQUE (usuario_id),
    CONSTRAINT chk_radio_minimo CHECK (radio_metros >= 100),
    CONSTRAINT chk_radio_maximo CHECK (radio_metros <= 5000),
    CONSTRAINT fk_config_usuario FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE CASCADE
);

ALTER TABLE public.configuracion_alertas ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_configuracion_alertas_usuario_id ON public.configuracion_alertas USING btree (usuario_id);

CREATE POLICY "config_alertas_no_direct_access" ON public.configuracion_alertas
    FOR ALL TO PUBLIC USING (false);

-- =============================================================
-- TABLA: alertas (Sprint 2 · HU-07)
-- Notificaciones generadas por reportes cercanos al usuario
-- =============================================================
CREATE TABLE public.alertas (
    id               UUID                        NOT NULL DEFAULT gen_random_uuid(),
    usuario_id       UUID                        NOT NULL,
    reporte_id       UUID                        NOT NULL,
    distancia_metros NUMERIC(8,2),
    leida            BOOLEAN                     NOT NULL DEFAULT false,
    fecha_creacion   TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
    fecha_leida      TIMESTAMP WITHOUT TIME ZONE,
    CONSTRAINT alertas_pkey        PRIMARY KEY (id),
    CONSTRAINT fk_alerta_usuario   FOREIGN KEY (usuario_id)  REFERENCES public.usuarios(id)  ON DELETE CASCADE,
    CONSTRAINT fk_alerta_reporte   FOREIGN KEY (reporte_id)  REFERENCES public.reportes(id)  ON DELETE CASCADE
);

ALTER TABLE public.alertas ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_alertas_usuario_leida ON public.alertas USING btree (usuario_id, leida);
CREATE INDEX idx_alertas_reporte       ON public.alertas USING btree (reporte_id);

CREATE POLICY "alertas_no_direct_access" ON public.alertas
    FOR ALL TO PUBLIC USING (false);

-- =============================================================
-- TABLA: password_resets (Sprint 2 · HU-13)
-- Tokens de recuperación de contraseña con expiración
-- =============================================================
CREATE TABLE public.password_resets (
    id             UUID                        NOT NULL DEFAULT gen_random_uuid(),
    usuario_id     UUID                        NOT NULL,
    token          TEXT                        NOT NULL,
    expiration     TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usado          BOOLEAN                     NOT NULL DEFAULT false,
    fecha_creacion TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
    CONSTRAINT password_resets_pkey          PRIMARY KEY (id),
    CONSTRAINT password_resets_usuario_id_fkey
        FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE CASCADE
);

ALTER TABLE public.password_resets ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_password_resets_token   ON public.password_resets USING btree (token);
CREATE INDEX idx_password_resets_usuario ON public.password_resets USING btree (usuario_id);

CREATE POLICY "password_resets_no_direct_access" ON public.password_resets
    FOR ALL TO PUBLIC USING (false);

-- =============================================================
-- TABLA: auditoria_usuarios (Sprint 4 · HU-14)
-- Registro de acciones administrativas sobre cuentas
-- =============================================================
CREATE TABLE public.auditoria_usuarios (
    id         UUID                        NOT NULL DEFAULT gen_random_uuid(),
    admin_id   UUID                        NOT NULL,
    usuario_id UUID                        NOT NULL,
    accion     CHARACTER VARYING(30)       NOT NULL,
    fecha      TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
    detalle    TEXT,
    CONSTRAINT auditoria_usuarios_pkey       PRIMARY KEY (id),
    CONSTRAINT chk_auditoria_usuarios_accion CHECK (accion IN ('ver', 'bloquear', 'desbloquear', 'reactivar', 'eliminar')),
    CONSTRAINT auditoria_usuarios_admin_id_fkey
        FOREIGN KEY (admin_id)   REFERENCES public.usuarios(id) ON DELETE SET NULL,
    CONSTRAINT auditoria_usuarios_usuario_id_fkey
        FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE CASCADE
);

ALTER TABLE public.auditoria_usuarios ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_auditoria_usuarios_estado_fecha ON public.auditoria_usuarios USING btree (admin_id, fecha DESC);
CREATE INDEX idx_auditoria_usuarios_usuario      ON public.auditoria_usuarios USING btree (usuario_id, fecha DESC);

CREATE POLICY "audit_usuarios_no_direct_access" ON public.auditoria_usuarios
    FOR ALL TO PUBLIC USING (false);

-- =============================================================
-- TABLA: auditoria_reportes (Sprint 4 · HU-16)
-- Registro de acciones admin sobre reportes
-- =============================================================
CREATE TABLE public.auditoria_reportes (
    id         UUID                        NOT NULL DEFAULT gen_random_uuid(),
    admin_id   UUID                        NOT NULL,
    reporte_id UUID                        NOT NULL,
    accion     CHARACTER VARYING(30)       NOT NULL,
    fecha      TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
    detalle    TEXT,
    CONSTRAINT auditoria_reportes_pkey       PRIMARY KEY (id),
    CONSTRAINT chk_auditoria_reportes_accion CHECK (accion IN ('ocultar', 'eliminar', 'restaurar', 'marcar_duplicado', 'marcar_fraudulento')),
    CONSTRAINT auditoria_reportes_admin_id_fkey
        FOREIGN KEY (admin_id)   REFERENCES public.usuarios(id)  ON DELETE SET NULL,
    CONSTRAINT auditoria_reportes_reporte_id_fkey
        FOREIGN KEY (reporte_id) REFERENCES public.reportes(id)  ON DELETE CASCADE
);

ALTER TABLE public.auditoria_reportes ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_auditoria_reportes_estado  ON public.auditoria_reportes USING btree (accion, fecha DESC);
CREATE INDEX idx_auditoria_reportes_reporte ON public.auditoria_reportes USING btree (reporte_id, fecha DESC);
CREATE INDEX idx_auditoria_reportes_admin   ON public.auditoria_reportes USING btree (admin_id, fecha DESC);

CREATE POLICY "audit_reportes_no_direct_access" ON public.auditoria_reportes
    FOR ALL TO PUBLIC USING (false);

-- =============================================================
-- TABLA: auditoria_edicion_reportes (Sprint 4 · HU-17)
-- Historial de campos modificados y valores anteriores
-- =============================================================
CREATE TABLE public.auditoria_edicion_reportes (
    id                  UUID                        NOT NULL DEFAULT gen_random_uuid(),
    admin_id            UUID                        NOT NULL,
    reporte_id          UUID                        NOT NULL,
    campos_modificados  TEXT[]                      NOT NULL,
    valores_anteriores  JSONB,
    fecha               TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
    CONSTRAINT auditoria_edicion_reportes_pkey PRIMARY KEY (id),
    CONSTRAINT auditoria_edicion_reportes_admin_id_fkey
        FOREIGN KEY (admin_id)   REFERENCES public.usuarios(id)  ON DELETE SET NULL,
    CONSTRAINT auditoria_edicion_reportes_reporte_id_fkey
        FOREIGN KEY (reporte_id) REFERENCES public.reportes(id)  ON DELETE CASCADE
);

ALTER TABLE public.auditoria_edicion_reportes ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_auditoria_edicion_reporte_id ON public.auditoria_edicion_reportes USING btree (reporte_id, fecha DESC);
CREATE INDEX idx_auditoria_edicion_admin      ON public.auditoria_edicion_reportes USING btree (admin_id, fecha DESC);

CREATE POLICY "audit_edicion_no_direct_access" ON public.auditoria_edicion_reportes
    FOR ALL TO PUBLIC USING (false);

-- =============================================================
-- TABLA: solicitudes_eliminacion (Sprint 4 · HU-18, HU-20)
-- Solicitudes de usuario para eliminar su propio reporte
-- Un reporte no puede tener múltiples solicitudes pendientes
-- =============================================================
CREATE TABLE public.solicitudes_eliminacion (
    id               UUID                        NOT NULL DEFAULT gen_random_uuid(),
    reporte_id       UUID                        NOT NULL,
    usuario_id       UUID                        NOT NULL,
    estado_solicitud CHARACTER VARYING(20)       NOT NULL DEFAULT 'pendiente',
    motivo           TEXT,
    fecha_solicitud  TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
    fecha_resolucion TIMESTAMP WITHOUT TIME ZONE,
    admin_id         UUID,
    CONSTRAINT solicitudes_eliminacion_pkey PRIMARY KEY (id),
    CONSTRAINT solicitudes_eliminacion_estado_solicitud_check
        CHECK (estado_solicitud IN ('pendiente', 'aprobada', 'rechazada')),
    CONSTRAINT solicitudes_eliminacion_reporte_id_fkey
        FOREIGN KEY (reporte_id)  REFERENCES public.reportes(id)  ON DELETE CASCADE,
    CONSTRAINT solicitudes_eliminacion_usuario_id_fkey
        FOREIGN KEY (usuario_id)  REFERENCES public.usuarios(id)  ON DELETE CASCADE,
    CONSTRAINT solicitudes_eliminacion_admin_id_fkey
        FOREIGN KEY (admin_id)    REFERENCES public.usuarios(id)  ON DELETE SET NULL
);

ALTER TABLE public.solicitudes_eliminacion ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_solicitudes_estado  ON public.solicitudes_eliminacion USING btree (estado_solicitud);
CREATE INDEX idx_solicitudes_reporte ON public.solicitudes_eliminacion USING btree (reporte_id);
CREATE INDEX idx_solicitudes_usuario ON public.solicitudes_eliminacion USING btree (usuario_id);
CREATE UNIQUE INDEX uniq_solicitud_pendiente_por_reporte ON public.solicitudes_eliminacion USING btree (reporte_id)
    WHERE (estado_solicitud = 'pendiente');

CREATE POLICY "solicitudes_no_direct_access" ON public.solicitudes_eliminacion
    FOR ALL TO PUBLIC USING (false);

-- =============================================================
-- TABLA: zonas_riesgo (Sprint 4 · HU-15, HU-12)
-- Zonas calculadas con nivel de riesgo georreferenciado
-- =============================================================
CREATE TABLE public.zonas_riesgo (
    id                UUID                        NOT NULL DEFAULT gen_random_uuid(),
    latitud_centro    NUMERIC(9,6)                NOT NULL,
    longitud_centro   NUMERIC(9,6)                NOT NULL,
    radio             INTEGER                     NOT NULL DEFAULT 200,
    nivel_riesgo      CHARACTER VARYING(20)       NOT NULL,
    cantidad_reportes INTEGER                     NOT NULL DEFAULT 0,
    fecha_calculo     TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
    comuna            INTEGER,
    CONSTRAINT zonas_riesgo_pkey            PRIMARY KEY (id),
    CONSTRAINT chk_radio_positivo           CHECK (radio > 0),
    CONSTRAINT chk_comuna_valida            CHECK (comuna IS NULL OR (comuna >= 1 AND comuna <= 12)),
    CONSTRAINT zonas_riesgo_nivel_riesgo_check CHECK (nivel_riesgo IN ('seguro', 'medio', 'alto', 'peligroso'))
);

ALTER TABLE public.zonas_riesgo ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_zonas_riesgo_coords      ON public.zonas_riesgo USING btree (latitud_centro, longitud_centro);
CREATE INDEX idx_zonas_riesgo_nivel       ON public.zonas_riesgo USING btree (nivel_riesgo);
CREATE INDEX idx_zonas_riesgo_fecha       ON public.zonas_riesgo USING btree (fecha_calculo DESC);
CREATE INDEX idx_zonas_riesgo_nivel_fecha ON public.zonas_riesgo USING btree (nivel_riesgo, fecha_calculo DESC);
CREATE INDEX idx_zonas_riesgo_comuna      ON public.zonas_riesgo USING btree (comuna)
    WHERE (comuna IS NOT NULL);

CREATE POLICY "zonas_riesgo_no_direct_access" ON public.zonas_riesgo
    FOR ALL TO PUBLIC USING (false);

-- =============================================================
-- TABLA: aceptacion_terminos (Sprint 4 · HU-04 mejora)
-- Registro de consentimiento del usuario con versión e IP
-- =============================================================
CREATE TABLE public.aceptacion_terminos (
    id               UUID                        NOT NULL DEFAULT gen_random_uuid(),
    usuario_id       UUID                        NOT NULL,
    version_terminos CHARACTER VARYING(10)       NOT NULL DEFAULT 'v1.0',
    fecha_aceptacion TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
    ip_origen        CHARACTER VARYING(45),
    CONSTRAINT aceptacion_terminos_pkey PRIMARY KEY (id),
    CONSTRAINT aceptacion_terminos_usuario_id_fkey
        FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE CASCADE
);

ALTER TABLE public.aceptacion_terminos ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_aceptacion_usuario ON public.aceptacion_terminos USING btree (usuario_id);
CREATE INDEX idx_aceptacion_version ON public.aceptacion_terminos USING btree (version_terminos);

CREATE POLICY "aceptacion_no_direct_access" ON public.aceptacion_terminos
    FOR ALL TO PUBLIC USING (false);

-- =============================================================
-- TABLA: notificaciones_usuario (Producción)
-- Notificaciones in-app: solicitudes aprobadas/rechazadas,
-- reportes ocultados/restaurados y mensajes del sistema
-- =============================================================
CREATE TABLE public.notificaciones_usuario (
    id             UUID                        NOT NULL DEFAULT gen_random_uuid(),
    usuario_id     UUID                        NOT NULL,
    titulo         CHARACTER VARYING(100)      NOT NULL,
    mensaje        TEXT                        NOT NULL,
    tipo           CHARACTER VARYING(30)       NOT NULL,
    referencia_id  UUID,
    leida          BOOLEAN                     NOT NULL DEFAULT false,
    fecha_creacion TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
    CONSTRAINT notificaciones_usuario_pkey PRIMARY KEY (id),
    CONSTRAINT notificaciones_usuario_tipo_check
        CHECK (tipo IN ('solicitud_aprobada', 'solicitud_rechazada', 'reporte_oculto', 'reporte_restaurado', 'sistema')),
    CONSTRAINT notificaciones_usuario_usuario_id_fkey
        FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE CASCADE
);

ALTER TABLE public.notificaciones_usuario ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_notificaciones_usuario ON public.notificaciones_usuario USING btree (usuario_id, leida);
CREATE INDEX idx_notificaciones_fecha   ON public.notificaciones_usuario USING btree (fecha_creacion DESC);

CREATE POLICY "notif_no_direct_access" ON public.notificaciones_usuario
    FOR ALL TO PUBLIC USING (false);

-- =============================================================
-- FUNCIÓN: get_zona_por_coordenadas (Sprint 2 · HU-08)
-- RPC: retorna comuna y barrios dado un punto GPS
-- =============================================================
CREATE OR REPLACE FUNCTION public.get_zona_por_coordenadas(lat DOUBLE PRECISION, lng DOUBLE PRECISION)
RETURNS TABLE(comuna INTEGER, barrios TEXT[])
LANGUAGE sql AS $function$
    SELECT
        s.comuna,
        ARRAY_AGG(z.barrio ORDER BY z.barrio) AS barrios
    FROM public.secciones_dane s
    JOIN public.zonas z ON z.comuna = s.comuna
    WHERE ST_Contains(s.geom, ST_SetSRID(ST_MakePoint(lng, lat), 4326))
    GROUP BY s.comuna
    LIMIT 1;
$function$;

-- =============================================================
-- FUNCIÓN: get_corregimiento_por_coordenadas (Sprint 2 · HU-08)
-- RPC: retorna corregimiento y sus veredas para zona rural
-- =============================================================
CREATE OR REPLACE FUNCTION public.get_corregimiento_por_coordenadas(lat DOUBLE PRECISION, lng DOUBLE PRECISION)
RETURNS TABLE(corregimiento_id INTEGER, corregimiento TEXT, veredas TEXT[])
LANGUAGE sql AS $function$
    SELECT
        c.id, c.nombre,
        ARRAY_AGG(v.nombre ORDER BY v.nombre) AS veredas
    FROM public.corregimientos c
    JOIN public.veredas v ON v.corregimiento_id = c.id
    WHERE ST_Contains(c.geom, ST_SetSRID(ST_MakePoint(lng, lat), 4326))
    GROUP BY c.id, c.nombre
    LIMIT 1;
$function$;

-- =============================================================
-- FUNCIÓN: eliminar_cuenta_usuario (Sprint 4 · HU-21)
-- Soft delete con anonimización: cambia estado a eliminado,
-- sobrescribe datos personales, borra tokens y config alertas
-- =============================================================
CREATE OR REPLACE FUNCTION public.eliminar_cuenta_usuario(p_usuario_id UUID)
RETURNS VOID LANGUAGE plpgsql AS $function$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM public.usuarios WHERE id = p_usuario_id AND estado = 'activo'
    ) THEN
        RAISE EXCEPTION 'Usuario no encontrado o ya inactivo: %', p_usuario_id;
    END IF;

    UPDATE public.usuarios SET
        estado        = 'eliminado',
        username      = 'eliminado_' || p_usuario_id,
        correo        = 'eliminado_' || p_usuario_id || '@saferoute.invalid',
        password_hash = NULL,
        foto_url      = NULL,
        fcm_token     = NULL,
        google_id     = NULL
    WHERE id = p_usuario_id;

    DELETE FROM public.configuracion_alertas WHERE usuario_id = p_usuario_id;
    DELETE FROM public.password_resets        WHERE usuario_id = p_usuario_id;
END;
$function$;

-- =============================================================
-- VISTAS DE ANÁLISIS
-- =============================================================

-- Sprint 3 · HU-11: Estadísticas básicas para usuario
CREATE OR REPLACE VIEW public.vw_estadisticas_basicas WITH (security_invoker=true) AS
WITH reportes_activos AS (
    SELECT id, fecha_incidente, franja_horaria, tipo_hurto, comuna, zona_id, fecha_creacion
    FROM public.reportes WHERE estado = 'activo'
), total AS (
    SELECT count(*) AS total_reportes FROM reportes_activos
), por_dia AS (
    SELECT fecha_incidente, count(*) AS cantidad FROM reportes_activos GROUP BY fecha_incidente
), por_franja AS (
    SELECT franja_horaria, count(*) AS cantidad FROM reportes_activos GROUP BY franja_horaria
)
SELECT t.total_reportes, pd.fecha_incidente, pd.cantidad AS reportes_dia,
    pf.franja_horaria, pf.cantidad AS reportes_franja
FROM total t CROSS JOIN por_dia pd CROSS JOIN por_franja pf;

-- Sprint 3 · HU-12: Top zonas con más hurtos (por comuna)
CREATE OR REPLACE VIEW public.vw_top_zonas_hurtos WITH (security_invoker=true) AS
WITH conteo_comuna AS (
    SELECT i.comuna, count(*) AS total_incidentes,
        sum(i.cantidad_reportes) AS total_reportes_vinculados,
        max(i.fecha_incidente) AS ultimo_incidente
    FROM public.incidentes i
    JOIN public.reportes r ON r.id = i.reporte_principal_id
    WHERE r.estado = 'activo' AND i.comuna IS NOT NULL
    GROUP BY i.comuna
), tipo_frecuente AS (
    SELECT DISTINCT ON (i.comuna) i.comuna, i.tipo_hurto, count(*) AS cantidad_tipo
    FROM public.incidentes i
    JOIN public.reportes r ON r.id = i.reporte_principal_id
    WHERE r.estado = 'activo' AND i.comuna IS NOT NULL
    GROUP BY i.comuna, i.tipo_hurto
    ORDER BY i.comuna, count(*) DESC
)
SELECT cc.comuna, cc.total_incidentes, cc.total_reportes_vinculados,
    cc.ultimo_incidente, tf.tipo_hurto AS tipo_hurto_frecuente,
    tf.cantidad_tipo AS cantidad_tipo_frecuente
FROM conteo_comuna cc
LEFT JOIN tipo_frecuente tf ON cc.comuna = tf.comuna
ORDER BY cc.total_incidentes DESC;

-- Sprint 3 · HU-12: Top barrios con más hurtos
CREATE OR REPLACE VIEW public.vw_top_barrios_hurtos WITH (security_invoker=true) AS
SELECT i.comuna, z.barrio, i.zona_id,
    count(*) AS total_incidentes,
    sum(i.cantidad_reportes) AS total_reportes_vinculados,
    max(i.fecha_incidente) AS ultimo_incidente
FROM public.incidentes i
JOIN public.zonas z ON i.zona_id = z.id
JOIN public.reportes r ON r.id = i.reporte_principal_id
WHERE r.estado = 'activo' AND i.zona_id IS NOT NULL
GROUP BY i.comuna, z.barrio, i.zona_id
ORDER BY count(*) DESC;

-- Sprint 3 · HU-10: Dashboard de incidentes (panel admin)
-- Producción: incluye corregimiento, vereda y tiene_coordenadas
CREATE OR REPLACE VIEW public.vw_dashboard_incidentes WITH (security_invoker=true) AS
SELECT
    i.id, i.tipo_hurto, i.fecha_incidente,
    (EXTRACT(year  FROM i.fecha_incidente))::integer AS anio,
    (EXTRACT(month FROM i.fecha_incidente))::integer AS mes,
    to_char(i.fecha_incidente::timestamp WITH TIME ZONE, 'TMMonth') AS nombre_mes,
    i.franja_horaria,
    (i.comuna)::text AS comuna,
    z.barrio,
    c.nombre AS corregimiento,
    v.nombre AS vereda,
    i.tiene_coordenadas,
    i.cantidad_reportes,
    i.latitud_centro, i.longitud_centro,
    public.calcular_nivel_riesgo(i.cantidad_reportes) AS nivel_riesgo,
    (SELECT count(*) FROM public.reportes r2
     WHERE r2.incidente_id = i.id AND r2.tipo_reportante = 'victima' AND r2.estado = 'activo') AS victimas,
    (SELECT count(*) FROM public.reportes r3
     WHERE r3.incidente_id = i.id AND r3.tipo_reportante = 'testigo' AND r3.estado = 'activo') AS testigos,
    i.fecha_creacion
FROM public.incidentes i
LEFT JOIN public.zonas z          ON i.zona_id          = z.id
LEFT JOIN public.corregimientos c ON i.corregimiento_id = c.id
LEFT JOIN public.veredas v        ON i.vereda_id        = v.id
JOIN public.reportes r ON r.id = i.reporte_principal_id
WHERE r.estado = 'activo';

-- Sprint 4 · HU-15: Estadísticas avanzadas admin
CREATE OR REPLACE VIEW public.vw_estadisticas_admin WITH (security_invoker=true) AS
SELECT
    r.comuna, z.barrio, r.tipo_hurto, r.franja_horaria,
    r.estado AS estado_reporte,
    date_trunc('month', r.fecha_incidente::timestamp WITH TIME ZONE)::date AS mes,
    count(*) AS total_reportes,
    count(DISTINCT r.incidente_id) AS total_incidentes,
    min(r.fecha_incidente) AS primer_incidente,
    max(r.fecha_incidente) AS ultimo_incidente
FROM public.reportes r
LEFT JOIN public.zonas z ON r.zona_id = z.id
GROUP BY r.comuna, z.barrio, r.tipo_hurto, r.franja_horaria, r.estado,
    date_trunc('month', r.fecha_incidente::timestamp WITH TIME ZONE)
ORDER BY count(*) DESC;

-- Sprint 4 · HU-15: Tendencias por zona y tipo de hurto
CREATE OR REPLACE VIEW public.vw_tendencias_zona_tipo WITH (security_invoker=true) AS
SELECT
    r.comuna, z.barrio, r.tipo_hurto,
    date_trunc('week', r.fecha_incidente::timestamp WITH TIME ZONE)::date AS semana_inicio,
    count(*) AS total_reportes,
    count(DISTINCT r.incidente_id) AS total_incidentes
FROM public.reportes r
LEFT JOIN public.zonas z ON r.zona_id = z.id
WHERE r.estado = 'activo'
GROUP BY r.comuna, z.barrio, r.tipo_hurto,
    date_trunc('week', r.fecha_incidente::timestamp WITH TIME ZONE)
ORDER BY semana_inicio DESC, count(*) DESC;

-- Sprint 4 · HU-15: Conteo de reportes por estado
CREATE OR REPLACE VIEW public.vw_conteo_estado_reportes WITH (security_invoker=true) AS
SELECT
    estado, count(*) AS total,
    count(DISTINCT usuario_id) AS usuarios_distintos,
    min(fecha_creacion) AS primer_reporte,
    max(fecha_creacion) AS ultimo_reporte
FROM public.reportes
GROUP BY estado;

-- Sprint 4 · HU-15: Estadísticas por periodo semanal
CREATE OR REPLACE VIEW public.vw_estadisticas_por_periodo WITH (security_invoker=true) AS
SELECT
    date_trunc('week', fecha_incidente::timestamp WITH TIME ZONE)::date AS semana_inicio,
    count(*) AS total_reportes,
    count(DISTINCT fecha_incidente) AS dias_con_reportes,
    round(count(*)::numeric / NULLIF(count(DISTINCT fecha_incidente), 0)::numeric, 2) AS promedio_diario
FROM public.reportes
WHERE estado = 'activo'
GROUP BY date_trunc('week', fecha_incidente::timestamp WITH TIME ZONE)
ORDER BY semana_inicio DESC;

-- Sprint 4 · HU-22: Vista de exportación masiva admin
CREATE OR REPLACE VIEW public.vw_export_reportes_admin WITH (security_invoker=true) AS
SELECT
    r.id AS reporte_id, r.fecha_incidente, r.franja_horaria, r.tipo_hurto,
    r.tipo_reportante, r.objeto_hurtado, r.numero_agresores, r.descripcion,
    r.direccion, r.barrio_ingresado,
    z.barrio AS barrio_normalizado, r.comuna, r.zona_tipo,
    c.nombre AS corregimiento, v.nombre AS vereda,
    r.latitud, r.longitud, r.estado,
    r.fecha_creacion, r.fecha_actualizacion,
    u_autor.correo AS correo_reportante,
    u_admin.correo AS actualizado_por_correo,
    r.incidente_id
FROM public.reportes r
LEFT JOIN public.zonas z          ON r.zona_id          = z.id
LEFT JOIN public.corregimientos c ON r.corregimiento_id = c.id
LEFT JOIN public.veredas v        ON r.vereda_id        = v.id
LEFT JOIN public.usuarios u_autor ON r.usuario_id       = u_autor.id
LEFT JOIN public.usuarios u_admin ON r.actualizado_por  = u_admin.id
ORDER BY r.fecha_incidente DESC, r.fecha_creacion DESC;
