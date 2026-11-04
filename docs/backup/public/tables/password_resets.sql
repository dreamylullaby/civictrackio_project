CREATE TABLE "public"."password_resets" (
  "id"             uuid                        NOT NULL DEFAULT gen_random_uuid(),
  "usuario_id"     uuid                        NOT NULL,
  "token"          text                        NOT NULL,
  "expiration"     timestamp without time zone NOT NULL,
  "usado"          boolean                     NOT NULL DEFAULT false,
  "fecha_creacion" timestamp without time zone NOT NULL DEFAULT now(),
  CONSTRAINT "password_resets_pkey" PRIMARY KEY (id),
  CONSTRAINT "password_resets_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE CASCADE
);

ALTER TABLE "public"."password_resets"
  ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_password_resets_token ON public.password_resets USING btree (token);

CREATE INDEX idx_password_resets_usuario ON public.password_resets USING btree (usuario_id);

CREATE POLICY "password_resets_no_direct_access" ON "public"."password_resets"
  FOR ALL
  TO PUBLIC
  USING (false);

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."password_resets" TO "anon", "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."password_resets" TO "service_role";

REVOKE ALL ON TABLE "public"."password_resets" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."password_resets" TO "postgres";
