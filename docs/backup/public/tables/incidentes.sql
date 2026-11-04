CREATE TABLE "public"."incidentes" (
  "id"                   uuid                        NOT NULL DEFAULT gen_random_uuid(),
  "reporte_principal_id" uuid                        NOT NULL,
  "tipo_hurto"           character varying(30),
  "fecha_incidente"      date                        NOT NULL,
  "franja_horaria"       character varying(20),
  "latitud_centro"       numeric(9,6),
  "longitud_centro"      numeric(9,6),
  "zona_id"              integer,
  "comuna"               integer,
  "cantidad_reportes"    integer                     NOT NULL DEFAULT 1,
  "fecha_creacion"       timestamp without time zone NOT NULL DEFAULT now(),
  "corregimiento_id"     integer,
  "vereda_id"            integer,
  "tiene_coordenadas"    boolean                     NOT NULL DEFAULT true,
  CONSTRAINT "chk_incidente_comuna" CHECK (((comuna IS NULL) OR ((comuna >= 1) AND (comuna <= 12)))),
  CONSTRAINT "fk_incidente_corregimiento" FOREIGN KEY (corregimiento_id) REFERENCES public.corregimientos(id),
  CONSTRAINT "incidentes_franja_horaria_check"
    CHECK
    (((franja_horaria)::text = ANY ((ARRAY['00:00-05:59'::character varying, '06:00-11:59'::character varying, '12:00-17:59'::character varying, '18:00-23:59'::character
    varying])::text[]))),
  CONSTRAINT "incidentes_pkey" PRIMARY KEY (id),
  CONSTRAINT "incidentes_tipo_hurto_check"
    CHECK (((tipo_hurto)::text = ANY ((ARRAY['atraco'::character varying, 'raponazo'::character varying, 'cosquilleo'::character varying, 'fleteo'::character varying])::text[]))),
  CONSTRAINT "fk_incidente_vereda" FOREIGN KEY (vereda_id) REFERENCES public.veredas(id),
  CONSTRAINT "fk_incidente_zona" FOREIGN KEY (zona_id) REFERENCES public.zonas(id)
);

ALTER TABLE "public"."incidentes"
  ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_incidentes_comuna ON public.incidentes USING btree (comuna);

CREATE INDEX idx_incidentes_coords ON public.incidentes USING btree (latitud_centro, longitud_centro);

CREATE INDEX idx_incidentes_corregimiento ON public.incidentes USING btree (corregimiento_id);

CREATE INDEX idx_incidentes_fecha ON public.incidentes USING btree (fecha_incidente);

CREATE INDEX idx_incidentes_tiene_coords ON public.incidentes USING btree (tiene_coordenadas);

CREATE INDEX idx_incidentes_tipo_hurto ON public.incidentes USING btree (tipo_hurto);

CREATE INDEX idx_incidentes_vereda ON public.incidentes USING btree (vereda_id);

CREATE INDEX idx_incidentes_zona ON public.incidentes USING btree (zona_id);

CREATE POLICY "incidentes_no_direct_access" ON "public"."incidentes"
  FOR ALL
  TO PUBLIC
  USING (false);

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."incidentes" TO "anon", "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."incidentes" TO "service_role";

REVOKE ALL ON TABLE "public"."incidentes" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."incidentes" TO "postgres";
