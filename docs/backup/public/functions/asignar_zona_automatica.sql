CREATE OR REPLACE FUNCTION public.asignar_zona_automatica()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $function$
DECLARE
    zona_encontrada INTEGER;
BEGIN

    -- buscar el barrio más parecido
    SELECT id
    INTO zona_encontrada
    FROM buscar_barrio_similar(NEW.barrio_ingresado)
    LIMIT 1;

    -- asignar zona_id automáticamente
    NEW.zona_id = zona_encontrada;

    RETURN NEW;

END;
$function$;

GRANT EXECUTE ON FUNCTION "public"."asignar_zona_automatica"() TO PUBLIC, "anon", "authenticated";

GRANT EXECUTE ON FUNCTION "public"."asignar_zona_automatica"() TO "service_role";

REVOKE ALL ON FUNCTION "public"."asignar_zona_automatica"() FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."asignar_zona_automatica"() TO "postgres";
