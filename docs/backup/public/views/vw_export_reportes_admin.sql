CREATE VIEW "public"."vw_export_reportes_admin" WITH (security_invoker=true) AS  SELECT r.id AS reporte_id,
    r.fecha_incidente,
    r.franja_horaria,
    r.tipo_hurto,
    r.tipo_reportante,
    r.objeto_hurtado,
    r.numero_agresores,
    r.descripcion,
    r.direccion,
    r.barrio_ingresado,
    z.barrio AS barrio_normalizado,
    r.comuna,
    r.zona_tipo,
    c.nombre AS corregimiento,
    v.nombre AS vereda,
    r.latitud,
    r.longitud,
    r.estado,
    r.fecha_creacion,
    r.fecha_actualizacion,
    u_autor.correo AS correo_reportante,
    u_admin.correo AS actualizado_por_correo,
    r.incidente_id
   FROM (((((public.reportes r
     LEFT JOIN public.zonas z ON ((r.zona_id = z.id)))
     LEFT JOIN public.corregimientos c ON ((r.corregimiento_id = c.id)))
     LEFT JOIN public.veredas v ON ((r.vereda_id = v.id)))
     LEFT JOIN public.usuarios u_autor ON ((r.usuario_id = u_autor.id)))
     LEFT JOIN public.usuarios u_admin ON ((r.actualizado_por = u_admin.id)))
  ORDER BY r.fecha_incidente DESC, r.fecha_creacion DESC;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."vw_export_reportes_admin" TO "anon", "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."vw_export_reportes_admin" TO "service_role";

REVOKE ALL ON TABLE "public"."vw_export_reportes_admin" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."vw_export_reportes_admin" TO "postgres";
