CREATE TABLE "public"."solicitudes_eliminacion" (
  "id"               uuid                        NOT NULL DEFAULT gen_random_uuid(),
  "reporte_id"       uuid                        NOT NULL,
  "usuario_id"       uuid                        NOT NULL,
  "estado_solicitud" character varying(20)       NOT NULL DEFAULT 'pendiente'::character varying,
  "motivo"           text,
  "fecha_solicitud"  timestamp without time zone NOT NULL DEFAULT now(),
  "fecha_resolucion" timestamp without time zone,
  "admin_id"         uuid,
  CONSTRAINT "solicitudes_eliminacion_estado_solicitud_check"
    CHECK (((estado_solicitud)::text = ANY ((ARRAY['pendiente'::character varying, 'aprobada'::character varying, 'rechazada'::character varying])::text[]))),
  CONSTRAINT "solicitudes_eliminacion_pkey" PRIMARY KEY (id),
  CONSTRAINT "solicitudes_eliminacion_reporte_id_fkey" FOREIGN KEY (reporte_id) REFERENCES public.reportes(id) ON DELETE CASCADE,
  CONSTRAINT "solicitudes_eliminacion_admin_id_fkey" FOREIGN KEY (admin_id) REFERENCES public.usuarios(id) ON DELETE SET NULL,
  CONSTRAINT "solicitudes_eliminacion_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE CASCADE
);

ALTER TABLE "public"."solicitudes_eliminacion"
  ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_solicitudes_estado ON public.solicitudes_eliminacion USING btree (estado_solicitud);

CREATE INDEX idx_solicitudes_reporte ON public.solicitudes_eliminacion USING btree (reporte_id);

CREATE INDEX idx_solicitudes_usuario ON public.solicitudes_eliminacion USING btree (usuario_id);

CREATE UNIQUE INDEX uniq_solicitud_pendiente_por_reporte ON public.solicitudes_eliminacion USING btree (reporte_id)
  WHERE ((estado_solicitud)::text = 'pendiente'::text);

CREATE POLICY "solicitudes_no_direct_access" ON "public"."solicitudes_eliminacion"
  FOR ALL
  TO PUBLIC
  USING (false);

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."solicitudes_eliminacion" TO "anon", "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."solicitudes_eliminacion" TO "service_role";

REVOKE ALL ON TABLE "public"."solicitudes_eliminacion" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."solicitudes_eliminacion" TO "postgres";
