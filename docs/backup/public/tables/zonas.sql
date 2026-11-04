CREATE TABLE "public"."zonas" (
  "id"     integer                            NOT NULL DEFAULT nextval('public.zonas_id_seq'::regclass),
  "barrio" character varying(80)              NOT NULL,
  "comuna" integer                            NOT NULL,
  "geom"   public.geometry(MultiPolygon,4326),
  CONSTRAINT "chk_barrio_not_empty" CHECK (((barrio)::text <> ''::text)),
  CONSTRAINT "uniq_barrio_comuna" UNIQUE (barrio, comuna),
  CONSTRAINT "zonas_comuna_check" CHECK (((comuna >= 1) AND (comuna <= 12))),
  CONSTRAINT "zonas_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."zonas"
  ENABLE ROW LEVEL SECURITY;

ALTER SEQUENCE "public"."zonas_id_seq" OWNED BY "public"."zonas"."id";

ALTER TABLE "public"."zonas"
  ADD CONSTRAINT "unique_barrio_comuna" UNIQUE (barrio, comuna);

CREATE INDEX idx_zonas_geom ON public.zonas USING gist (geom);

CREATE POLICY "zonas_select_public" ON "public"."zonas"
  FOR SELECT
  TO PUBLIC
  USING (true);

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."zonas" TO "anon", "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."zonas" TO "service_role";

REVOKE ALL ON TABLE "public"."zonas" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."zonas" TO "postgres";
