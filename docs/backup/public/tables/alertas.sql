CREATE TABLE "public"."alertas" (
  "id"               uuid                        NOT NULL DEFAULT gen_random_uuid(),
  "usuario_id"       uuid                        NOT NULL,
  "reporte_id"       uuid                        NOT NULL,
  "distancia_metros" numeric(8,2),
  "leida"            boolean                     NOT NULL DEFAULT false,
  "fecha_creacion"   timestamp without time zone NOT NULL DEFAULT now(),
  "fecha_leida"      timestamp without time zone,
  CONSTRAINT "alertas_pkey" PRIMARY KEY (id),
  CONSTRAINT "fk_alerta_reporte" FOREIGN KEY (reporte_id) REFERENCES public.reportes(id) ON DELETE CASCADE,
  CONSTRAINT "fk_alerta_usuario" FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE CASCADE
);

ALTER TABLE "public"."alertas"
  ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_alertas_reporte ON public.alertas USING btree (reporte_id);

CREATE INDEX idx_alertas_usuario_leida ON public.alertas USING btree (usuario_id, leida);

CREATE POLICY "alertas_no_direct_access" ON "public"."alertas"
  FOR ALL
  TO PUBLIC
  USING (false);

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."alertas" TO "anon", "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."alertas" TO "service_role";

REVOKE ALL ON TABLE "public"."alertas" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."alertas" TO "postgres";
