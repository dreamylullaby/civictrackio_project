CREATE OR REPLACE FUNCTION public.get_zona_por_coordenadas (
  lat double precision,
  lng double precision
)
  RETURNS TABLE (
    comuna  integer,
    barrios text[]
  )
  LANGUAGE sql
  AS $function$
  SELECT 
    s.comuna,
    ARRAY_AGG(z.barrio ORDER BY z.barrio) AS barrios
  FROM public.secciones_dane s
  JOIN public.zonas z ON z.comuna = s.comuna
  WHERE ST_Contains(
    s.geom,
    ST_SetSRID(ST_MakePoint(lng, lat), 4326)
  )
  GROUP BY s.comuna
  LIMIT 1;
$function$;

GRANT EXECUTE ON FUNCTION "public"."get_zona_por_coordenadas"(double precision, double precision) TO PUBLIC, "anon", "authenticated";

GRANT EXECUTE ON FUNCTION "public"."get_zona_por_coordenadas"(double precision, double precision) TO "service_role";

REVOKE ALL ON FUNCTION "public"."get_zona_por_coordenadas"(double precision, double precision) FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."get_zona_por_coordenadas"(double precision, double precision) TO "postgres";
