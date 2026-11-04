CREATE TABLE "public"."auditoria_reportes" (
  "id"         uuid                        NOT NULL DEFAULT gen_random_uuid(),
  "admin_id"   uuid                        NOT NULL,
  "reporte_id" uuid                        NOT NULL,
  "accion"     character varying(30)       NOT NULL,
  "fecha"      timestamp without time zone NOT NULL DEFAULT now(),
  "detalle"    text,
  CONSTRAINT "auditoria_reportes_pkey" PRIMARY KEY (id),
  CONSTRAINT "chk_auditoria_reportes_accion"
    CHECK
    (((accion)::text = ANY ((ARRAY['ocultar'::character varying, 'eliminar'::character varying, 'restaurar'::character varying, 'marcar_duplicado'::character varying,
    'marcar_fraudulento'::character varying])::text[]))),
  CONSTRAINT "auditoria_reportes_reporte_id_fkey" FOREIGN KEY (reporte_id) REFERENCES public.reportes(id) ON DELETE CASCADE,
  CONSTRAINT "auditoria_reportes_admin_id_fkey" FOREIGN KEY (admin_id) REFERENCES public.usuarios(id) ON DELETE SET NULL
);

ALTER TABLE "public"."auditoria_reportes"
  ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_auditoria_reportes_admin ON public.auditoria_reportes USING btree (admin_id, fecha DESC);

CREATE INDEX idx_auditoria_reportes_estado ON public.auditoria_reportes USING btree (accion, fecha DESC);

CREATE INDEX idx_auditoria_reportes_reporte ON public.auditoria_reportes USING btree (reporte_id, fecha DESC);

CREATE POLICY "audit_reportes_no_direct_access" ON "public"."auditoria_reportes"
  FOR ALL
  TO PUBLIC
  USING (false);

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."auditoria_reportes" TO "anon", "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."auditoria_reportes" TO "service_role";

REVOKE ALL ON TABLE "public"."auditoria_reportes" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."auditoria_reportes" TO "postgres";
