CREATE OR REPLACE FUNCTION public.get_corregimiento_por_coordenadas (
  lat double precision,
  lng double precision
)
  RETURNS TABLE (
    corregimiento_id integer,
    corregimiento    text,
    veredas          text[]
  )
  LANGUAGE sql
  AS $function$
    SELECT
        c.id,
        c.nombre,
        ARRAY_AGG(v.nombre ORDER BY v.nombre) AS veredas
    FROM public.corregimientos c
    JOIN public.veredas v ON v.corregimiento_id = c.id
    WHERE ST_Contains(
        c.geom,
        ST_SetSRID(ST_MakePoint(lng, lat), 4326)
    )
    GROUP BY c.id, c.nombre
    LIMIT 1;
$function$;

GRANT EXECUTE ON FUNCTION "public"."get_corregimiento_por_coordenadas"(double precision, double precision) TO PUBLIC, "anon", "authenticated";

GRANT EXECUTE ON FUNCTION "public"."get_corregimiento_por_coordenadas"(double precision, double precision) TO "service_role";

REVOKE ALL ON FUNCTION "public"."get_corregimiento_por_coordenadas"(double precision, double precision) FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."get_corregimiento_por_coordenadas"(double precision, double precision) TO "postgres";
