CREATE VIEW "public"."vw_estadisticas_por_periodo" WITH (security_invoker=true) AS  SELECT (date_trunc('week'::text, (fecha_incidente)::timestamp with time zone))::date AS semana_inicio,
    count(*) AS total_reportes,
    count(DISTINCT fecha_incidente) AS dias_con_reportes,
    round(((count(*))::numeric / (NULLIF(count(DISTINCT fecha_incidente), 0))::numeric), 2) AS promedio_diario
   FROM public.reportes
  WHERE ((estado)::text = 'activo'::text)
  GROUP BY (date_trunc('week'::text, (fecha_incidente)::timestamp with time zone))
  ORDER BY ((date_trunc('week'::text, (fecha_incidente)::timestamp with time zone))::date) DESC;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."vw_estadisticas_por_periodo" TO "anon", "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."vw_estadisticas_por_periodo" TO "service_role";

REVOKE ALL ON TABLE "public"."vw_estadisticas_por_periodo" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."vw_estadisticas_por_periodo" TO "postgres";
