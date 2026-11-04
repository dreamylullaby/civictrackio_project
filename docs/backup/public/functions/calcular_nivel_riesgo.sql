CREATE OR REPLACE FUNCTION public.calcular_nivel_riesgo (
  cantidad integer
)
  RETURNS character varying
  LANGUAGE sql
  IMMUTABLE
  AS $function$
    SELECT CASE
        WHEN cantidad <= 3  THEN 'seguro'
        WHEN cantidad <= 7  THEN 'medio'
        WHEN cantidad <= 10 THEN 'alto'
        ELSE 'peligroso'
    END;
$function$;

GRANT EXECUTE ON FUNCTION "public"."calcular_nivel_riesgo"(integer) TO PUBLIC, "anon", "authenticated";

GRANT EXECUTE ON FUNCTION "public"."calcular_nivel_riesgo"(integer) TO "service_role";

REVOKE ALL ON FUNCTION "public"."calcular_nivel_riesgo"(integer) FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."calcular_nivel_riesgo"(integer) TO "postgres";
