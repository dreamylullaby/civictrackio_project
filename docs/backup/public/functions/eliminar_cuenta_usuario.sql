CREATE OR REPLACE FUNCTION public.eliminar_cuenta_usuario (
  p_usuario_id uuid
)
  RETURNS void
  LANGUAGE plpgsql
  AS $function$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM public.usuarios WHERE id = p_usuario_id AND estado = 'activo'
    ) THEN
        RAISE EXCEPTION 'Usuario no encontrado o ya inactivo: %', p_usuario_id;
    END IF;

    UPDATE public.usuarios SET
        estado      = 'eliminado',
        username    = 'eliminado_' || p_usuario_id,
        correo      = 'eliminado_' || p_usuario_id || '@saferoute.invalid',
        password_hash = NULL,
        foto_url    = NULL,
        fcm_token   = NULL,
        google_id   = NULL
    WHERE id = p_usuario_id;

    DELETE FROM public.configuracion_alertas WHERE usuario_id = p_usuario_id;
    DELETE FROM public.password_resets        WHERE usuario_id = p_usuario_id;
END;
$function$;

GRANT EXECUTE ON FUNCTION "public"."eliminar_cuenta_usuario"(uuid) TO PUBLIC, "anon", "authenticated";

GRANT EXECUTE ON FUNCTION "public"."eliminar_cuenta_usuario"(uuid) TO "service_role";

REVOKE ALL ON FUNCTION "public"."eliminar_cuenta_usuario"(uuid) FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."eliminar_cuenta_usuario"(uuid) TO "postgres";
