CREATE OR REPLACE FUNCTION public.asignar_o_crear_incidente()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $function$
DECLARE
    incidente_existente UUID;
    centroide_lat       NUMERIC(9,6);
    centroide_lng       NUMERIC(9,6);
    RADIO_METROS        CONSTANT NUMERIC := 150;
BEGIN

    -- =====================================================
    -- CAMINO A: Cualquier reporte CON coordenadas GPS
    -- (urbano o rural que sí tenga GPS)
    -- =====================================================
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
                latitud_centro       = (i.latitud_centro  * i.cantidad_reportes + NEW.latitud)
                                       / (i.cantidad_reportes + 1),
                longitud_centro      = (i.longitud_centro * i.cantidad_reportes + NEW.longitud)
                                       / (i.cantidad_reportes + 1),
                reporte_principal_id = CASE
                    WHEN NEW.tipo_reportante = 'victima' THEN NEW.id
                    ELSE i.reporte_principal_id
                END
            WHERE i.id = incidente_existente;
        ELSE
            INSERT INTO public.incidentes (
                reporte_principal_id, tipo_hurto, fecha_incidente,
                franja_horaria, latitud_centro, longitud_centro,
                zona_id, comuna,
                corregimiento_id, vereda_id,
                cantidad_reportes, tiene_coordenadas
            ) VALUES (
                NEW.id, NEW.tipo_hurto, NEW.fecha_incidente,
                NEW.franja_horaria, NEW.latitud, NEW.longitud,
                NEW.zona_id, NEW.comuna,
                NEW.corregimiento_id, NEW.vereda_id,
                1, true
            )
            RETURNING id INTO NEW.incidente_id;
        END IF;

    -- =====================================================
    -- CAMINO B: Rural SIN GPS pero con vereda conocida
    -- Agrupa por vereda + fecha + franja + tipo
    -- Usa ST_Centroid del polígono del corregimiento
    -- =====================================================
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

        -- Centroide calculado desde el polígono geom del corregimiento
        SELECT
            ST_Y(ST_Centroid(c.geom)),
            ST_X(ST_Centroid(c.geom))
        INTO centroide_lat, centroide_lng
        FROM public.veredas v
        JOIN public.corregimientos c ON c.id = v.corregimiento_id
        WHERE v.id = NEW.vereda_id
          AND c.geom IS NOT NULL;

        -- Si hay centroide disponible, asignarlo al reporte
        -- para que aparezca en el mapa de calor
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

    -- =====================================================
    -- CAMINO C: Sin GPS y sin vereda — incidente huérfano
    -- Cuenta en estadísticas pero no aparece en el mapa
    -- =====================================================
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

GRANT EXECUTE ON FUNCTION "public"."asignar_o_crear_incidente"() TO PUBLIC, "anon", "authenticated";

GRANT EXECUTE ON FUNCTION "public"."asignar_o_crear_incidente"() TO "service_role";

REVOKE ALL ON FUNCTION "public"."asignar_o_crear_incidente"() FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."asignar_o_crear_incidente"() TO "postgres";
