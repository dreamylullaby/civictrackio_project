CREATE VIEW "public"."vw_estadisticas_admin" WITH (security_invoker=true) AS  SELECT r.comuna,
    z.barrio,
    r.tipo_hurto,
    r.franja_horaria,
    r.estado AS estado_reporte,
    (date_trunc('month'::text, (r.fecha_incidente)::timestamp with time zone))::date AS mes,
    count(*) AS total_reportes,
    count(DISTINCT r.incidente_id) AS total_incidentes,
    min(r.fecha_incidente) AS primer_incidente,
    max(r.fecha_incidente) AS ultimo_incidente
   FROM (public.reportes r
     LEFT JOIN public.zonas z ON ((r.zona_id = z.id)))
  GROUP BY r.comuna, z.barrio, r.tipo_hurto, r.franja_horaria, r.estado, (date_trunc('month'::text, (r.fecha_incidente)::timestamp with time zone))
  ORDER BY (count(*)) DESC;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."vw_estadisticas_admin" TO "anon", "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."vw_estadisticas_admin" TO "service_role";

REVOKE ALL ON TABLE "public"."vw_estadisticas_admin" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."vw_estadisticas_admin" TO "postgres";
