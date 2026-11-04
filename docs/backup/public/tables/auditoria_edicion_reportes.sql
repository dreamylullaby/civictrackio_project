CREATE TABLE "public"."auditoria_edicion_reportes" (
  "id"                 uuid                        NOT NULL DEFAULT gen_random_uuid(),
  "admin_id"           uuid                        NOT NULL,
  "reporte_id"         uuid                        NOT NULL,
  "campos_modificados" text[]                      NOT NULL,
  "valores_anteriores" jsonb,
  "fecha"              timestamp without time zone NOT NULL DEFAULT now(),
  CONSTRAINT "auditoria_edicion_reportes_pkey" PRIMARY KEY (id),
  CONSTRAINT "auditoria_edicion_reportes_reporte_id_fkey" FOREIGN KEY (reporte_id) REFERENCES public.reportes(id) ON DELETE CASCADE,
  CONSTRAINT "auditoria_edicion_reportes_admin_id_fkey" FOREIGN KEY (admin_id) REFERENCES public.usuarios(id) ON DELETE SET NULL
);

ALTER TABLE "public"."auditoria_edicion_reportes"
  ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_auditoria_edicion_admin ON public.auditoria_edicion_reportes USING btree (admin_id, fecha DESC);

CREATE INDEX idx_auditoria_edicion_reporte_id ON public.auditoria_edicion_reportes USING btree (reporte_id, fecha DESC);

CREATE POLICY "audit_edicion_no_direct_access" ON "public"."auditoria_edicion_reportes"
  FOR ALL
  TO PUBLIC
  USING (false);

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."auditoria_edicion_reportes" TO "anon", "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."auditoria_edicion_reportes" TO "service_role";

REVOKE ALL ON TABLE "public"."auditoria_edicion_reportes" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."auditoria_edicion_reportes" TO "postgres";
