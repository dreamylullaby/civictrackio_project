CREATE TABLE "public"."usuarios" (
  "id"             uuid                        NOT NULL DEFAULT gen_random_uuid(),
  "username"       character varying(50)       NOT NULL,
  "correo"         character varying(150)      NOT NULL,
  "password_hash"  text,
  "foto_url"       text,
  "rol"            character varying(20)       NOT NULL,
  "auth_provider"  text[]                      NOT NULL,
  "google_id"      character varying(255),
  "fecha_creacion" timestamp without time zone NOT NULL DEFAULT now(),
  "estado"         character varying(20)       NOT NULL,
  "fcm_token"      text,
  CONSTRAINT "usuarios_auth_provider_check" CHECK (((auth_provider <@ ARRAY['local'::text, 'google'::text]) AND (array_length(auth_provider, 1) > 0))),
  CONSTRAINT "usuarios_correo_key" UNIQUE (correo),
  CONSTRAINT "usuarios_estado_check"
    CHECK (((estado)::text = ANY ((ARRAY['activo'::character varying, 'bloqueado'::character varying, 'eliminado'::character varying, 'oculto'::character varying])::text[]))),
  CONSTRAINT "usuarios_google_id_key" UNIQUE (google_id),
  CONSTRAINT "usuarios_pkey" PRIMARY KEY (id),
  CONSTRAINT "usuarios_rol_check" CHECK (((rol)::text = ANY ((ARRAY['usuario'::character varying, 'admin'::character varying])::text[]))),
  CONSTRAINT "usuarios_username_key" UNIQUE (username)
);

ALTER TABLE "public"."usuarios"
  ENABLE ROW LEVEL SECURITY;

CREATE POLICY "usuarios_no_direct_access" ON "public"."usuarios"
  FOR ALL
  TO PUBLIC
  USING (false);

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."usuarios" TO "anon", "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."usuarios" TO "service_role";

REVOKE ALL ON TABLE "public"."usuarios" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."usuarios" TO "postgres";
