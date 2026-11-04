CREATE TABLE "public"."secciones_dane" (
  "id"         integer                            NOT NULL DEFAULT nextval('public.secciones_dane_id_seq'::regclass),
  "secu_ccdgo" character varying(10),
  "setu_ccdgo" character varying(10),
  "comuna"     integer,
  "geom"       public.geometry(MultiPolygon,4326),
  CONSTRAINT "secciones_dane_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."secciones_dane"
  ENABLE ROW LEVEL SECURITY;

ALTER SEQUENCE "public"."secciones_dane_id_seq" OWNED BY "public"."secciones_dane"."id";

CREATE INDEX idx_secciones_geom ON public.secciones_dane USING gist (geom);

CREATE POLICY "secciones_dane_select_public" ON "public"."secciones_dane"
  FOR SELECT
  TO PUBLIC
  USING (true);

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."secciones_dane" TO "anon", "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."secciones_dane" TO "service_role";

REVOKE ALL ON TABLE "public"."secciones_dane" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."secciones_dane" TO "postgres";
