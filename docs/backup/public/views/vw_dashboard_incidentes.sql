CREATE VIEW "public"."vw_dashboard_incidentes" WITH (security_invoker=true) AS  SELECT i.id,
    i.tipo_hurto,
    i.fecha_incidente,
    (EXTRACT(year FROM i.fecha_incidente))::integer AS anio,
    (EXTRACT(month FROM i.fecha_incidente))::integer AS mes,
    to_char((i.fecha_incidente)::timestamp with time zone, 'TMMonth'::text) AS nombre_mes,
    i.franja_horaria,
    (i.comuna)::text AS comuna,
    z.barrio,
    c.nombre AS corregimiento,
    v.nombre AS vereda,
    i.tiene_coordenadas,
    i.cantidad_reportes,
    i.latitud_centro,
    i.longitud_centro,
    public.calcular_nivel_riesgo(i.cantidad_reportes) AS nivel_riesgo,
    ( SELECT count(*) AS count
           FROM public.reportes r2
          WHERE ((r2.incidente_id = i.id) AND ((r2.tipo_reportante)::text = 'victima'::text) AND ((r2.estado)::text = 'activo'::text))) AS victimas,
    ( SELECT count(*) AS count
           FROM public.reportes r3
          WHERE ((r3.incidente_id = i.id) AND ((r3.tipo_reportante)::text = 'testigo'::text) AND ((r3.estado)::text = 'activo'::text))) AS testigos,
    i.fecha_creacion
   FROM ((((public.incidentes i
     LEFT JOIN public.zonas z ON ((i.zona_id = z.id)))
     LEFT JOIN public.corregimientos c ON ((i.corregimiento_id = c.id)))
     LEFT JOIN public.veredas v ON ((i.vereda_id = v.id)))
     JOIN public.reportes r ON ((r.id = i.reporte_principal_id)))
  WHERE ((r.estado)::text = 'activo'::text);

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."vw_dashboard_incidentes" TO "anon", "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."vw_dashboard_incidentes" TO "service_role";

REVOKE ALL ON TABLE "public"."vw_dashboard_incidentes" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."vw_dashboard_incidentes" TO "postgres";
