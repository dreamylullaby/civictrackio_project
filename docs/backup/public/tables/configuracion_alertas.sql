CREATE TABLE "public"."configuracion_alertas" (
  "id"                  uuid                        NOT NULL DEFAULT gen_random_uuid(),
  "usuario_id"          uuid                        NOT NULL,
  "radio_metros"        integer                     NOT NULL DEFAULT 500,
  "activo"              boolean                     NOT NULL DEFAULT true,
  "fecha_creacion"      timestamp without time zone NOT NULL DEFAULT now(),
  "fecha_actualizacion" timestamp without time zone,
  CONSTRAINT "chk_radio_maximo" CHECK ((radio_metros <= 5000)),
  CONSTRAINT "chk_radio_minimo" CHECK ((radio_metros >= 100)),
  CONSTRAINT "configuracion_alertas_pkey" PRIMARY KEY (id),
  CONSTRAINT "configuracion_alertas_usuario_id_key" UNIQUE (usuario_id),
  CONSTRAINT "fk_config_usuario" FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE CASCADE
);

ALTER TABLE "public"."configuracion_alertas"
  ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_configuracion_alertas_usuario_id ON public.configuracion_alertas USING btree (usuario_id);

CREATE POLICY "config_alertas_no_direct_access" ON "public"."configuracion_alertas"
  FOR ALL
  TO PUBLIC
  USING (false);

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."configuracion_alertas" TO "anon", "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."configuracion_alertas" TO "service_role";

REVOKE ALL ON TABLE "public"."configuracion_alertas" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."configuracion_alertas" TO "postgres";
