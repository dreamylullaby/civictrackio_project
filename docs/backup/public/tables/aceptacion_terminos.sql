CREATE TABLE "public"."aceptacion_terminos" (
  "id"               uuid                        NOT NULL DEFAULT gen_random_uuid(),
  "usuario_id"       uuid                        NOT NULL,
  "version_terminos" character varying(10)       NOT NULL DEFAULT 'v1.0'::character varying,
  "fecha_aceptacion" timestamp without time zone NOT NULL DEFAULT now(),
  "ip_origen"        character varying(45),
  CONSTRAINT "aceptacion_terminos_pkey" PRIMARY KEY (id),
  CONSTRAINT "aceptacion_terminos_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE CASCADE
);

ALTER TABLE "public"."aceptacion_terminos"
  ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_aceptacion_usuario ON public.aceptacion_terminos USING btree (usuario_id);

CREATE INDEX idx_aceptacion_version ON public.aceptacion_terminos USING btree (version_terminos);

CREATE POLICY "aceptacion_no_direct_access" ON "public"."aceptacion_terminos"
  FOR ALL
  TO PUBLIC
  USING (false);

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."aceptacion_terminos" TO "anon", "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."aceptacion_terminos" TO "service_role";

REVOKE ALL ON TABLE "public"."aceptacion_terminos" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."aceptacion_terminos" TO "postgres";
