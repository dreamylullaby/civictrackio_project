CREATE TABLE "public"."notificaciones_usuario" (
  "id"             uuid                        NOT NULL DEFAULT gen_random_uuid(),
  "usuario_id"     uuid                        NOT NULL,
  "titulo"         character varying(100)      NOT NULL,
  "mensaje"        text                        NOT NULL,
  "tipo"           character varying(30)       NOT NULL,
  "referencia_id"  uuid,
  "leida"          boolean                     NOT NULL DEFAULT false,
  "fecha_creacion" timestamp without time zone NOT NULL DEFAULT now(),
  CONSTRAINT "notificaciones_usuario_pkey" PRIMARY KEY (id),
  CONSTRAINT "notificaciones_usuario_tipo_check"
    CHECK
    (((tipo)::text = ANY ((ARRAY['solicitud_aprobada'::character varying, 'solicitud_rechazada'::character varying, 'reporte_oculto'::character varying,
    'reporte_restaurado'::character varying, 'sistema'::character varying])::text[]))),
  CONSTRAINT "notificaciones_usuario_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE CASCADE
);

ALTER TABLE "public"."notificaciones_usuario"
  ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_notificaciones_fecha ON public.notificaciones_usuario USING btree (fecha_creacion DESC);

CREATE INDEX idx_notificaciones_usuario ON public.notificaciones_usuario USING btree (usuario_id, leida);

CREATE POLICY "notif_no_direct_access" ON "public"."notificaciones_usuario"
  FOR ALL
  TO PUBLIC
  USING (false);

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."notificaciones_usuario" TO "anon", "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."notificaciones_usuario" TO "service_role";

REVOKE ALL ON TABLE "public"."notificaciones_usuario" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."notificaciones_usuario" TO "postgres";
