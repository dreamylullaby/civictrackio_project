CREATE VIEW "public"."vw_top_barrios_hurtos" WITH (security_invoker=true) AS  SELECT i.comuna,
    z.barrio,
    i.zona_id,
    count(*) AS total_incidentes,
    sum(i.cantidad_reportes) AS total_reportes_vinculados,
    max(i.fecha_incidente) AS ultimo_incidente
   FROM ((public.incidentes i
     JOIN public.zonas z ON ((i.zona_id = z.id)))
     JOIN public.reportes r ON ((r.id = i.reporte_principal_id)))
  WHERE (((r.estado)::text = 'activo'::text) AND (i.zona_id IS NOT NULL))
  GROUP BY i.comuna, z.barrio, i.zona_id
  ORDER BY (count(*)) DESC;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."vw_top_barrios_hurtos" TO "anon", "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."vw_top_barrios_hurtos" TO "service_role";

REVOKE ALL ON TABLE "public"."vw_top_barrios_hurtos" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."vw_top_barrios_hurtos" TO "postgres";
