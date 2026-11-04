CREATE VIEW "public"."vw_conteo_estado_reportes" WITH (security_invoker=true) AS  SELECT estado,
    count(*) AS total,
    count(DISTINCT usuario_id) AS usuarios_distintos,
    min(fecha_creacion) AS primer_reporte,
    max(fecha_creacion) AS ultimo_reporte
   FROM public.reportes
  GROUP BY estado;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."vw_conteo_estado_reportes" TO "anon", "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."vw_conteo_estado_reportes" TO "service_role";

REVOKE ALL ON TABLE "public"."vw_conteo_estado_reportes" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."vw_conteo_estado_reportes" TO "postgres";
