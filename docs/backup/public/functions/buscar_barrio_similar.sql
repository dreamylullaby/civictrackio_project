CREATE OR REPLACE FUNCTION public.buscar_barrio_similar (
  texto_usuario text
)
  RETURNS TABLE (
    id        integer,
    barrio    character varying,
    comuna    integer,
    similitud integer
  )
  LANGUAGE sql
  AS $function$
    SELECT
        z.id,
        z.barrio,
        z.comuna,

        levenshtein(
            unaccent(lower(z.barrio)),
            unaccent(lower(texto_usuario))
        ) AS similitud

    FROM zonas z

    ORDER BY similitud ASC
    LIMIT 5;
$function$;

GRANT EXECUTE ON FUNCTION "public"."buscar_barrio_similar"(text) TO PUBLIC, "anon", "authenticated";

GRANT EXECUTE ON FUNCTION "public"."buscar_barrio_similar"(text) TO "service_role";

REVOKE ALL ON FUNCTION "public"."buscar_barrio_similar"(text) FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."buscar_barrio_similar"(text) TO "postgres";
