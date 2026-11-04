CREATE TABLE "public"."auditoria_usuarios" (
  "id"         uuid                        NOT NULL DEFAULT gen_random_uuid(),
  "admin_id"   uuid                        NOT NULL,
  "usuario_id" uuid                        NOT NULL,
  "accion"     character varying(30)       NOT NULL,
  "fecha"      timestamp without time zone NOT NULL DEFAULT now(),
  "detalle"    text,
  CONSTRAINT "auditoria_usuarios_pkey" PRIMARY KEY (id),
  CONSTRAINT "chk_auditoria_usuarios_accion"
    CHECK
    (((accion)::text = ANY ((ARRAY['ver'::character varying, 'bloquear'::character varying, 'desbloquear'::character varying, 'reactivar'::character varying, 'eliminar'::character
    varying])::text[]))),
  CONSTRAINT "auditoria_usuarios_admin_id_fkey" FOREIGN KEY (admin_id) REFERENCES public.usuarios(id) ON DELETE SET NULL,
  CONSTRAINT "auditoria_usuarios_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE CASCADE
);

ALTER TABLE "public"."auditoria_usuarios"
  ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_auditoria_usuarios_estado_fecha ON public.auditoria_usuarios USING btree (admin_id, fecha DESC);

CREATE INDEX idx_auditoria_usuarios_usuario ON public.auditoria_usuarios USING btree (usuario_id, fecha DESC);

CREATE POLICY "audit_usuarios_no_direct_access" ON "public"."auditoria_usuarios"
  FOR ALL
  TO PUBLIC
  USING (false);

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."auditoria_usuarios" TO "anon", "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."auditoria_usuarios" TO "service_role";

REVOKE ALL ON TABLE "public"."auditoria_usuarios" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."auditoria_usuarios" TO "postgres";
