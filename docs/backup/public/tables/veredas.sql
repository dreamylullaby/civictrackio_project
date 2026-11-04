CREATE TABLE "public"."veredas" (
  "id"               integer               NOT NULL DEFAULT nextval('public.veredas_id_seq'::regclass),
  "nombre"           character varying(80) NOT NULL,
  "corregimiento_id" integer               NOT NULL,
  "es_cabecera"      boolean               NOT NULL DEFAULT false,
  CONSTRAINT "chk_vereda_not_empty" CHECK (((nombre)::text <> ''::text)),
  CONSTRAINT "veredas_corregimiento_id_fkey" FOREIGN KEY (corregimiento_id) REFERENCES public.corregimientos(id),
  CONSTRAINT "veredas_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."veredas"
  ENABLE ROW LEVEL SECURITY;

ALTER SEQUENCE "public"."veredas_id_seq" OWNED BY "public"."veredas"."id";

CREATE INDEX idx_veredas_corregimiento ON public.veredas USING btree (corregimiento_id);

CREATE POLICY "veredas_select_public" ON "public"."veredas"
  FOR SELECT
  TO PUBLIC
  USING (true);

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."veredas" TO "anon", "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."veredas" TO "service_role";

REVOKE ALL ON TABLE "public"."veredas" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."veredas" TO "postgres";
