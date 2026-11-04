CREATE VIEW "public"."vw_estadisticas_basicas" WITH (security_invoker=true) AS  WITH reportes_activos AS (
         SELECT reportes.id,
            reportes.fecha_incidente,
            reportes.franja_horaria,
            reportes.tipo_hurto,
            reportes.comuna,
            reportes.zona_id,
            reportes.fecha_creacion
           FROM public.reportes
          WHERE ((reportes.estado)::text = 'activo'::text)
        ), total AS (
         SELECT count(*) AS total_reportes
           FROM reportes_activos
        ), por_dia AS (
         SELECT reportes_activos.fecha_incidente,
            count(*) AS cantidad
           FROM reportes_activos
          GROUP BY reportes_activos.fecha_incidente
        ), por_franja AS (
         SELECT reportes_activos.franja_horaria,
            count(*) AS cantidad
           FROM reportes_activos
          GROUP BY reportes_activos.franja_horaria
        )
 SELECT t.total_reportes,
    pd.fecha_incidente,
    pd.cantidad AS reportes_dia,
    pf.franja_horaria,
    pf.cantidad AS reportes_franja
   FROM ((total t
     CROSS JOIN por_dia pd)
     CROSS JOIN por_franja pf);

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."vw_estadisticas_basicas" TO "anon", "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."vw_estadisticas_basicas" TO "service_role";

REVOKE ALL ON TABLE "public"."vw_estadisticas_basicas" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."vw_estadisticas_basicas" TO "postgres";
