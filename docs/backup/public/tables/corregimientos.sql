CREATE TABLE "public"."corregimientos" (
  "id"     integer                            NOT NULL DEFAULT nextval('public.corregimientos_id_seq'::regclass),
  "nombre" character varying(80)              NOT NULL,
  "geom"   public.geometry(MultiPolygon,4326),
  CONSTRAINT "chk_corregimiento_not_empty" CHECK (((nombre)::text <> ''::text)),
  CONSTRAINT "corregimientos_pkey" PRIMARY KEY (id),
  CONSTRAINT "uniq_corregimiento" UNIQUE (nombre)
);

ALTER TABLE "public"."corregimientos"
  ENABLE ROW LEVEL SECURITY;

ALTER SEQUENCE "public"."corregimientos_id_seq" OWNED BY "public"."corregimientos"."id";

CREATE INDEX idx_corregimientos_geom ON public.corregimientos USING gist (geom);

CREATE POLICY "corregimientos_select_public" ON "public"."corregimientos"
  FOR SELECT
  TO PUBLIC
  USING (true);

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."corregimientos" TO "anon", "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."corregimientos" TO "service_role";

REVOKE ALL ON TABLE "public"."corregimientos" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."corregimientos" TO "postgres";
