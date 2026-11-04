CREATE VIEW "public"."vw_top_zonas_hurtos" WITH (security_invoker=true) AS  WITH conteo_comuna AS (
         SELECT i.comuna,
            count(*) AS total_incidentes,
            sum(i.cantidad_reportes) AS total_reportes_vinculados,
            max(i.fecha_incidente) AS ultimo_incidente
           FROM (public.incidentes i
             JOIN public.reportes r ON ((r.id = i.reporte_principal_id)))
          WHERE (((r.estado)::text = 'activo'::text) AND (i.comuna IS NOT NULL))
          GROUP BY i.comuna
        ), tipo_frecuente AS (
         SELECT DISTINCT ON (i.comuna) i.comuna,
            i.tipo_hurto,
            count(*) AS cantidad_tipo
           FROM (public.incidentes i
             JOIN public.reportes r ON ((r.id = i.reporte_principal_id)))
          WHERE (((r.estado)::text = 'activo'::text) AND (i.comuna IS NOT NULL))
          GROUP BY i.comuna, i.tipo_hurto
          ORDER BY i.comuna, (count(*)) DESC
        )
 SELECT cc.comuna,
    cc.total_incidentes,
    cc.total_reportes_vinculados,
    cc.ultimo_incidente,
    tf.tipo_hurto AS tipo_hurto_frecuente,
    tf.cantidad_tipo AS cantidad_tipo_frecuente
   FROM (conteo_comuna cc
     LEFT JOIN tipo_frecuente tf ON ((cc.comuna = tf.comuna)))
  ORDER BY cc.total_incidentes DESC;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."vw_top_zonas_hurtos" TO "anon", "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."vw_top_zonas_hurtos" TO "service_role";

REVOKE ALL ON TABLE "public"."vw_top_zonas_hurtos" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."vw_top_zonas_hurtos" TO "postgres";
