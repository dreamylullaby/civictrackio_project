CREATE OR REPLACE FUNCTION public.asignar_zona_y_comuna()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $function$
DECLARE
  zona_encontrada INTEGER;
  comuna_encontrada INTEGER;
BEGIN
  -- Prioridad 1: por coordenadas geográficas
  IF NEW.latitud IS NOT NULL AND NEW.longitud IS NOT NULL THEN
    SELECT z.id, z.comuna INTO zona_encontrada, comuna_encontrada
    FROM public.secciones_dane s
    JOIN public.zonas z ON z.comuna = s.comuna
    WHERE ST_Contains(
      s.geom,
      ST_SetSRID(ST_MakePoint(NEW.longitud::float8, NEW.latitud::float8), 4326)
    )
    AND unaccent(lower(z.barrio)) = unaccent(lower(NEW.barrio_ingresado))
    LIMIT 1;
  END IF;

  -- Prioridad 2: por nombre exacto (fallback)
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

GRANT EXECUTE ON FUNCTION "public"."asignar_zona_y_comuna"() TO PUBLIC, "anon", "authenticated";

GRANT EXECUTE ON FUNCTION "public"."asignar_zona_y_comuna"() TO "service_role";

REVOKE ALL ON FUNCTION "public"."asignar_zona_y_comuna"() FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."asignar_zona_y_comuna"() TO "postgres";
