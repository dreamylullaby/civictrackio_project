CREATE TABLE "public"."reportes" (
  "id"                  uuid                        NOT NULL DEFAULT gen_random_uuid(),
  "usuario_id"          uuid                        NOT NULL DEFAULT '645c346d-e56a-4022-b488-e8142e0c96a5'::uuid,
  "tipo_reportante"     character varying(20),
  "fecha_incidente"     date                        NOT NULL,
  "franja_horaria"      character varying(20),
  "latitud"             numeric(9,6),
  "longitud"            numeric(9,6),
  "direccion"           character varying(100),
  "tipo_hurto"          character varying(30),
  "descripcion"         character varying(300),
  "objeto_hurtado"      character varying(50),
  "numero_agresores"    character varying(20),
  "fecha_creacion"      timestamp without time zone NOT NULL DEFAULT now(),
  "fecha_actualizacion" timestamp without time zone,
  "actualizado_por"     uuid,
  "estado"              character varying(20)       NOT NULL,
  "barrio_ingresado"    character varying(80)       NOT NULL DEFAULT 'SIN DEFINIR'::character varying,
  "zona_id"             integer,
  "comuna"              integer,
  "zona_tipo"           character varying(10)       NOT NULL DEFAULT 'urbana'::character varying,
  "corregimiento_id"    integer,
  "vereda_id"           integer,
  "incidente_id"        uuid,
  "coordenadas_exactas" boolean                     NOT NULL DEFAULT true,
  CONSTRAINT "reportes_corregimiento_id_fkey" FOREIGN KEY (corregimiento_id) REFERENCES public.corregimientos(id),
  CONSTRAINT "reportes_estado_check" CHECK (((estado)::text = ANY ((ARRAY['activo'::character varying, 'oculto'::character varying, 'eliminado'::character varying])::text[]))),
  CONSTRAINT "reportes_franja_horaria_check"
    CHECK
    (((franja_horaria)::text = ANY ((ARRAY['00:00-05:59'::character varying, '06:00-11:59'::character varying, '12:00-17:59'::character varying, '18:00-23:59'::character
    varying])::text[]))),
  CONSTRAINT "reportes_numero_agresores_check"
    CHECK (((numero_agresores)::text = ANY ((ARRAY['1'::character varying, '2'::character varying, '3+'::character varying, 'desconocido'::character varying])::text[]))),
  CONSTRAINT "reportes_objeto_hurtado_check"
    CHECK
    (((objeto_hurtado)::text = ANY ((ARRAY['celular'::character varying, 'dinero'::character varying, 'tarjetas_documentos'::character varying, 'articulos_personales'::character
    varying, 'dispositivos_electronicos'::character varying])::text[]))),
  CONSTRAINT "reportes_pkey" PRIMARY KEY (id),
  CONSTRAINT "reportes_tipo_hurto_check"
    CHECK (((tipo_hurto)::text = ANY ((ARRAY['atraco'::character varying, 'raponazo'::character varying, 'cosquilleo'::character varying, 'fleteo'::character varying])::text[]))),
  CONSTRAINT "reportes_tipo_reportante_check" CHECK (((tipo_reportante)::text = ANY ((ARRAY['victima'::character varying, 'testigo'::character varying])::text[]))),
  CONSTRAINT "reportes_zona_tipo_check" CHECK (((zona_tipo)::text = ANY ((ARRAY['urbana'::character varying, 'rural'::character varying])::text[]))),
  CONSTRAINT "fk_actualizado_por" FOREIGN KEY (actualizado_por) REFERENCES public.usuarios(id) ON DELETE SET NULL,
  CONSTRAINT "fk_usuario" FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE SET DEFAULT,
  CONSTRAINT "reportes_vereda_id_fkey" FOREIGN KEY (vereda_id) REFERENCES public.veredas(id),
  CONSTRAINT "fk_zona" FOREIGN KEY (zona_id) REFERENCES public.zonas(id)
);

ALTER TABLE "public"."reportes"
  ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_reportes_actualizado_por ON public.reportes USING btree (actualizado_por)
  WHERE (actualizado_por IS NOT NULL);

CREATE INDEX idx_reportes_comuna_estado_fecha ON public.reportes USING btree (comuna, estado, fecha_incidente DESC);

CREATE INDEX idx_reportes_comuna ON public.reportes USING btree (comuna);

CREATE INDEX idx_reportes_coordenadas_exactas ON public.reportes USING btree (coordenadas_exactas);

CREATE INDEX idx_reportes_corregimiento ON public.reportes USING btree (corregimiento_id);

CREATE INDEX idx_reportes_estado_comuna_tipo ON public.reportes USING btree (estado, comuna, tipo_hurto);

CREATE INDEX idx_reportes_estado_coords ON public.reportes USING btree (estado, latitud, longitud);

CREATE INDEX idx_reportes_estado_fecha_comuna ON public.reportes USING btree (estado, fecha_incidente, comuna);

CREATE INDEX idx_reportes_estado_fecha_export ON public.reportes USING btree (estado, fecha_incidente DESC);

CREATE INDEX idx_reportes_estado_fecha_zona ON public.reportes USING btree (estado, fecha_incidente, zona_id);

CREATE INDEX idx_reportes_estado_fecha ON public.reportes USING btree (estado, fecha_incidente);

CREATE INDEX idx_reportes_estado_tipo_hurto ON public.reportes USING btree (estado, tipo_hurto);

CREATE INDEX idx_reportes_estado_zona ON public.reportes USING btree (estado, zona_id);

CREATE INDEX idx_reportes_estado ON public.reportes USING btree (estado);

CREATE INDEX idx_reportes_fecha_creacion ON public.reportes USING btree (fecha_creacion DESC);

CREATE INDEX idx_reportes_fecha_incidente ON public.reportes USING btree (fecha_incidente);

CREATE INDEX idx_reportes_fecha_zona_tipo ON public.reportes USING btree (fecha_incidente, zona_id, tipo_hurto);

CREATE INDEX idx_reportes_franja_horaria ON public.reportes USING btree (franja_horaria);

CREATE INDEX idx_reportes_incidente_id ON public.reportes USING btree (incidente_id);

CREATE INDEX idx_reportes_latitud_longitud ON public.reportes USING btree (latitud, longitud);

CREATE INDEX idx_reportes_tipo_hurto ON public.reportes USING btree (tipo_hurto);

CREATE INDEX idx_reportes_usuario_id ON public.reportes USING btree (usuario_id);

CREATE INDEX idx_reportes_zona_estado_fecha ON public.reportes USING btree (zona_id, estado, fecha_incidente DESC);

CREATE INDEX idx_reportes_zona_id ON public.reportes USING btree (zona_id);

CREATE INDEX idx_reportes_zona_tipo ON public.reportes USING btree (zona_tipo);

CREATE TRIGGER trigger_asignar_incidente
  BEFORE INSERT ON public.reportes
  FOR EACH ROW
  EXECUTE FUNCTION public.asignar_o_crear_incidente();

CREATE TRIGGER trigger_asignar_zona_comuna
  BEFORE INSERT OR UPDATE ON public.reportes
  FOR EACH ROW
  EXECUTE FUNCTION public.asignar_zona_y_comuna();

CREATE TRIGGER trigger_asignar_zona
  BEFORE INSERT OR UPDATE ON public.reportes
  FOR EACH ROW
  WHEN ((new.zona_id IS NULL))
  EXECUTE FUNCTION public.asignar_zona_automatica();

CREATE POLICY "reportes_no_direct_access" ON "public"."reportes"
  FOR ALL
  TO PUBLIC
  USING (false);

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."reportes" TO "anon", "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."reportes" TO "service_role";

REVOKE ALL ON TABLE "public"."reportes" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."reportes" TO "postgres";
