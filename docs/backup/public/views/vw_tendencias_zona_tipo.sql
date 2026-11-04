CREATE VIEW "public"."vw_tendencias_zona_tipo" WITH (security_invoker=true) AS  SELECT r.comuna,
    z.barrio,
    r.tipo_hurto,
    (date_trunc('week'::text, (r.fecha_incidente)::timestamp with time zone))::date AS semana_inicio,
    count(*) AS total_reportes,
    count(DISTINCT r.incidente_id) AS total_incidentes
   FROM (public.reportes r
     LEFT JOIN public.zonas z ON ((r.zona_id = z.id)))
  WHERE ((r.estado)::text = 'activo'::text)
  GROUP BY r.comuna, z.barrio, r.tipo_hurto, (date_trunc('week'::text, (r.fecha_incidente)::timestamp with time zone))
  ORDER BY ((date_trunc('week'::text, (r.fecha_incidente)::timestamp with time zone))::date) DESC, (count(*)) DESC;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."vw_tendencias_zona_tipo" TO "anon", "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."vw_tendencias_zona_tipo" TO "service_role";

REVOKE ALL ON TABLE "public"."vw_tendencias_zona_tipo" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."vw_tendencias_zona_tipo" TO "postgres";
