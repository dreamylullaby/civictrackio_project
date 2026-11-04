CREATE TABLE "public"."zonas_riesgo" (
  "id"                uuid                        NOT NULL DEFAULT gen_random_uuid(),
  "latitud_centro"    numeric(9,6)                NOT NULL,
  "longitud_centro"   numeric(9,6)                NOT NULL,
  "radio"             integer                     NOT NULL DEFAULT 200,
  "nivel_riesgo"      character varying(20)       NOT NULL,
  "cantidad_reportes" integer                     NOT NULL DEFAULT 0,
  "fecha_calculo"     timestamp without time zone NOT NULL DEFAULT now(),
  "comuna"            integer,
  CONSTRAINT "chk_comuna_valida" CHECK (((comuna IS NULL) OR ((comuna >= 1) AND (comuna <= 12)))),
  CONSTRAINT "chk_radio_positivo" CHECK ((radio > 0)),
  CONSTRAINT "zonas_riesgo_nivel_riesgo_check"
    CHECK (((nivel_riesgo)::text = ANY ((ARRAY['seguro'::character varying, 'medio'::character varying, 'alto'::character varying, 'peligroso'::character varying])::text[]))),
  CONSTRAINT "zonas_riesgo_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."zonas_riesgo"
  ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_zonas_riesgo_comuna ON public.zonas_riesgo USING btree (comuna)
  WHERE (comuna IS NOT NULL);

CREATE INDEX idx_zonas_riesgo_coords ON public.zonas_riesgo USING btree (latitud_centro, longitud_centro);

CREATE INDEX idx_zonas_riesgo_fecha ON public.zonas_riesgo USING btree (fecha_calculo DESC);

CREATE INDEX idx_zonas_riesgo_nivel_fecha ON public.zonas_riesgo USING btree (nivel_riesgo, fecha_calculo DESC);

CREATE INDEX idx_zonas_riesgo_nivel ON public.zonas_riesgo USING btree (nivel_riesgo);

CREATE POLICY "zonas_riesgo_no_direct_access" ON "public"."zonas_riesgo"
  FOR ALL
  TO PUBLIC
  USING (false);

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."zonas_riesgo" TO "anon", "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."zonas_riesgo" TO "service_role";

REVOKE ALL ON TABLE "public"."zonas_riesgo" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."zonas_riesgo" TO "postgres";
