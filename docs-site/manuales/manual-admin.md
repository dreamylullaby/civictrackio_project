# CivicTrackIO - Manual de administrador (Dashboard web)

*Versión 1.0 · Panel web exclusivo para administradores · https://civictrackio.com*

## 1. Introducción

El dashboard web es la herramienta con la que el equipo administrador de CivicTrackIO supervisa los reportes ciudadanos de hurtos, gestiona usuarios, atiende las solicitudes de eliminación y analiza estadísticas.

**Alcance del rol administrador:**

- Ver indicadores globales y tendencias.
- Moderar reportes: cambiar su estado, corregirlos, eliminarlos y exportarlos.
- Moderar usuarios: bloquear, ocultar, reactivar y eliminar.
- Resolver las solicitudes de eliminación enviadas desde la app móvil.

> **Acceso restringido.** Solo las cuentas con rol `admin` pueden entrar. Una cuenta de usuario común de la app móvil no tiene acceso al panel.

### Requisitos

| Requisito | Detalle |
| --- | --- |
| Navegador | Versión reciente de Chrome, Edge, Firefox o Safari |
| Conexión | Internet estable |
| Credenciales | Correo y contraseña de administrador |

## 2. Ingreso al panel

1. Abra **https://civictrackio.com** en su navegador.
2. Escriba su **correo** y **contraseña** de administrador.
3. Pulse **Ingresar**.

**Sobre la sesión:**

- La sesión se guarda en el navegador (`sessionStorage`) mediante un token JWT.
- Al **cerrar la pestaña o el navegador, la sesión se pierde** y deberá ingresar de nuevo.
- Si el token vence, el panel le pedirá autenticarse otra vez.
- Cierre sesión siempre que use un equipo compartido.

> **Primer ingreso lento.** El servidor entra en reposo tras 15 minutos sin tráfico. Si el login o los datos tardan hasta un minuto en aparecer, es el servidor despertando; espere y no recargue repetidamente.

## 3. Estructura del panel

El panel se organiza en pestañas (tabs):

| Pestaña | Para qué sirve |
| --- | --- |
| Dashboard | Resumen general e indicadores |
| Gestión de Incidentes | Moderar, editar y exportar reportes |
| Gestión de Usuarios | Moderar cuentas |
| Estadísticas | Análisis por período y comparaciones |
| Solicitudes de eliminación | Aprobar o rechazar peticiones de los usuarios |
| Mi Perfil | Datos de su cuenta de administrador |

## 4. Dashboard (resumen)

Muestra el estado general del sistema:

- **Contadores:** total de reportes activos, usuarios, corregimientos y comunas.
- **Gráficas:** distribución de reportes por **tipo de hurto** y por **estado**.
- **Top de zonas:** los sectores con mayor número de hurtos.

Use esta vista como punto de partida diario para detectar picos inusuales o zonas críticas.

## 5. Gestión de incidentes

Tabla paginada con todos los reportes registrados.

### 5.1 Búsqueda y filtros

Puede filtrar por:

- Tipo de hurto
- Estado (activo, oculto, eliminado)
- Fecha
- Comuna y zona
- Franja horaria
- Búsqueda de texto por barrio o por usuario

Los filtros se pueden combinar para encontrar reportes concretos rápidamente.

### 5.2 Cambiar el estado de un reporte

Cada reporte tiene un estado que controla su visibilidad:

| Estado | Efecto |
| --- | --- |
| **Activo** | Visible en el mapa de la app y cuenta en las estadísticas |
| **Oculto** | No se muestra en la app; se conserva para revisión |
| **Eliminado** | Eliminación lógica: deja de mostrarse pero el registro permanece en la base de datos |

Para cambiarlo: seleccione el reporte, elija el nuevo estado y confirme.

### 5.3 Editar reportes

- **Editar el tipo de hurto:** corrija una clasificación errónea (atraco, raponazo, fleteo, cosquilleo).
- **Edición completa:** disponible para reportes **reasignados**, permite corregir todos sus campos (ubicación, zona, descripción, etc.).

### 5.4 Eliminación

- **Eliminación en lote:** marque varios reportes y elimínelos juntos.
- **Hard delete (eliminación definitiva):** borra el registro de forma **permanente e irreversible**.

> **Precaución.** Prefiera siempre cambiar el estado a *oculto* o *eliminado* (reversible). Use el hard delete solo cuando sea estrictamente necesario, por ejemplo por requerimiento legal o limpieza de datos de prueba.

### 5.5 Exportar datos

Desde esta pestaña puede exportar los reportes a **CSV o Excel**, útil para informes y análisis externos. Aplique primero los filtros que necesite para exportar solo el subconjunto deseado. Trate el archivo como información sensible y no lo comparta fuera de los canales autorizados.

## 6. Gestión de usuarios

Lista paginada de usuarios registrados, con las siguientes acciones:

| Acción | Qué hace | Reversible |
| --- | --- | --- |
| **Bloquear** | Impide que el usuario inicie sesión o use la app | Sí |
| **Ocultar** | Oculta al usuario y su actividad | Sí |
| **Reactivar** | Devuelve la cuenta a estado normal | — |
| **Eliminar (lógico)** | Marca la cuenta como eliminada, conservando el registro | Parcialmente |
| **Hard delete** | Borra la cuenta de forma permanente | **No** |

**Criterios recomendados:**

- Bloquee cuentas con reportes falsos, abusivos o repetitivos.
- Reactive cuentas bloqueadas por error o tras una revisión.
- Reserve el hard delete para casos justificados y documentados.

## 7. Estadísticas

Permite analizar la evolución de los hurtos:

- **Gráficas por período:** día, semana o mes.
- **Comparación entre períodos:** por ejemplo, este mes frente al anterior, para ver si los hurtos suben o bajan.
- **Tendencias:** comportamiento general a lo largo del tiempo.

Seleccione el período y, si aplica, los dos rangos que desea comparar.

## 8. Solicitudes de eliminación

Cuando un usuario pide eliminar uno de sus reportes desde la app, la petición llega aquí con estado **pendiente**.

**Procedimiento:**

1. Abra la pestaña **Solicitudes de eliminación**.
2. Filtre por estado: pendientes, aprobadas o rechazadas.
3. Revise el reporte asociado y el motivo de la solicitud.
4. Elija una acción:
   - **Aprobar:** el reporte se elimina y la solicitud queda como *aprobada*.
   - **Rechazar:** el reporte se mantiene y la solicitud queda como *rechazada*.

**Buenas prácticas:**

- Atienda las pendientes con regularidad.
- Apruebe cuando el reporte sea erróneo, duplicado o el solicitante tenga motivo legítimo.
- Rechace cuando eliminar el reporte distorsionaría información de interés público y no exista justificación suficiente.

## 9. Mi perfil

Muestra los datos de la cuenta de administrador autenticada (usuario, correo y rol). Es de consulta; verifique aquí con qué cuenta está operando.

## 10. Buenas prácticas y seguridad

- Use contraseñas largas y únicas; no las comparta.
- Cierre sesión al terminar, sobre todo en equipos compartidos.
- Prefiera acciones reversibles (ocultar, bloquear, eliminación lógica) a las definitivas.
- Documente internamente el motivo de bloqueos y eliminaciones.
- Proteja los archivos exportados: contienen datos de ubicación y de usuarios.
- Conceda el rol de administrador solo a quien lo necesite.

## 11. Solución de problemas

**No puedo ingresar.** Verifique correo y contraseña, y confirme que su cuenta tenga rol de administrador. Si sigue fallando, pida a otro administrador o al equipo técnico que revise su cuenta.

**El panel queda cargando o muestra errores de red.** El backend puede estar "dormido" (plan gratuito). Espere hasta un minuto y recargue una vez.

**Me cerró la sesión.** Es normal al cerrar la pestaña o al vencer el token. Ingrese de nuevo.

**Los números no coinciden con lo que esperaba.** Revise los filtros activos (estado, fechas, zona). Los contadores del resumen consideran reportes **activos**.

**La exportación no descarga.** Reduzca el rango con filtros y reintente; verifique que el navegador no bloquee la descarga.
