-- Foreign keys in a cross-table reference cycle are split out of their
-- table's file: each file loads atomically, so keeping them inline would
-- deadlock the loader (every file would need a table another pending file
-- creates). These statements apply once all referenced tables exist.

ALTER TABLE "public"."reportes"
  ADD CONSTRAINT "fk_reporte_incidente" FOREIGN KEY (incidente_id) REFERENCES public.incidentes(id) ON DELETE SET NULL;
