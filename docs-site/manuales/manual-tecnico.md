# CivicTrackIO - Manual técnico de instalación y configuración (Developer)

*Versión 1.0 · Backend, dashboard web y app móvil*

> **Nota sobre los comandos.** Los comandos de este manual siguen las convenciones habituales de cada stack (Node/npm, Vite, Flutter). Verifique los nombres exactos de los scripts en el `package.json` y en el `pubspec.yaml` de cada repositorio y ajústelos si difieren.

## 1. Visión general

CivicTrackIO es un sistema de reporte y seguimiento ciudadano de hurtos compuesto por tres capas:

```
App Móvil (Flutter, Android) ──┐
                               ├──▶ Backend (Node.js / Express 5 REST API) ──▶ Supabase (PostgreSQL + PostGIS + Storage)
Dashboard Web (React/Vite) ───┘                  │
  (solo admins)                                   ├──▶ Firebase Auth (Google Sign-In) y FCM (push)
                                                  └──▶ Resend (correos)
```

| Componente | Tecnología | Producción |
| --- | --- | --- |
| Backend | Node.js + Express 5 | https://civictracio-project.onrender.com |
| Base de datos | Supabase (PostgreSQL + PostGIS) | Cloud |
| Dashboard web | React + Vite | https://civictrackio.com (Netlify) |
| App móvil | Flutter / Dart, solo Android | APK distribuido directamente |
| Autenticación | JWT propio (8 h) + Firebase Auth para Google |  |
| Notificaciones push | Firebase Cloud Messaging |  |
| Correos | Resend (dominio `mail.civictrackio.com`) |  |
| Mapas | Mapbox (`streets-v12` y `dark-v11`) |  |

## 2. Requisitos previos

### Herramientas

| Herramienta | Uso |
| --- | --- |
| Git | Control de versiones |
| Node.js (LTS reciente) y npm | Backend y dashboard. Express 5 requiere una versión moderna de Node |
| Flutter SDK + Dart | App móvil |
| Android Studio / Android SDK | Compilar y probar en Android |
| Un editor (VS Code, etc.) | Desarrollo |

### Cuentas y servicios externos

- **Supabase:** proyecto con PostgreSQL y extensión PostGIS habilitada.
- **Firebase:** proyecto con Authentication (proveedor Google) y Cloud Messaging.
- **Mapbox:** token de acceso público.
- **Resend:** cuenta con dominio verificado.
- **Render** y **Netlify:** para el despliegue (ver el Manual de despliegue).

## 3. Arquitectura del backend

El backend sigue una **arquitectura limpia** en cuatro capas:

| Capa | Responsabilidad |
| --- | --- |
| `domain` | Entidades y reglas de negocio |
| `application` | Casos de uso |
| `infrastructure` | Acceso a Supabase, Resend, FCM, JWT, etc. |
| `interfaces` | Rutas, controladores y middlewares HTTP |

Las dependencias apuntan hacia adentro: `interfaces` e `infrastructure` dependen de `application` y `domain`, nunca al rrevés.

## 4. Base de datos (Supabase)

### 4.1 Tablas principales

| Tabla | Contenido |
| --- | --- |
| `usuarios` | id, username, correo, password\_hash, rol (user/admin), estado, fcm\_token |
| `reportes` | id, usuario\_id, tipo\_hurto, tipo\_reportante, fecha\_incidente, franja\_horaria, latitud, longitud, direccion, barrio\_ingresado, comuna, zona\_tipo (urbana/rural), corregimiento\_id, vereda\_id, estado (activo/oculto/eliminado) |
| `zonas` | Polígonos de barrios urbanos (PostGIS) |
| `corregimientos` | 17 corregimientos de Pasto (MultiPolygon PostGIS) |
| `veredas` | Subdivisiones de corregimientos |
| `secciones_dane` | Polígonos de comunas |
| `incidentes` | Agregación de reportes por zona |
| `solicitudes_eliminacion` | estado\_solicitud: pendiente / aprobada / rechazada |
| `notificaciones_usuario` | Alertas push recibidas |
| `configuracion_alertas` | Radio y tipos configurados por usuario |

### 4.2 Funciones RPC (PostGIS)

| Función | Resultado |
| --- | --- |
| `get_zona_por_coordenadas(lat, lng)` | Comuna y barrios |
| `get_corregimiento_por_coordenadas(lat, lng)` | Corregimiento y veredas |
| `buscar_barrio_similar(texto)` | Búsqueda fuzzy de barrios |

Además existen **triggers automáticos** que asignan la zona a cada reporte nuevo.

### 4.3 Preparación

1. Cree el proyecto en Supabase.
2. Habilite las extensiones necesarias: `postgis` y, para la búsqueda fuzzy, la extensión de similitud de texto que use la función `buscar_barrio_similar` (habitualmente `pg_trgm`).
3. Ejecute los scripts SQL del proyecto en este orden: tablas, datos geográficos (zonas, corregimientos, veredas, secciones DANE), funciones RPC y triggers.
4. Cree al menos un usuario con `rol = 'admin'` (ver sección 9).
5. Copie la **URL del proyecto** y la **service role key** (Settings → API).

> **Seguridad.** La `SUPABASE_SERVICE_ROLE_KEY` omite las políticas RLS. Utilícela **solo en el backend**; jamás en el dashboard ni en la app.

## 5. Instalación del backend

```bash
git clone https://github.com/TU_ORG/CivicTrackIO.git
cd CivicTrackIO/backend
npm install
```

### 5.1 Variables de entorno

Cree un archivo `.env` en la raíz del backend (no lo suba a Git):

```env
SUPABASE_URL=https://zfgfgymzfjyunyoeddjy.supabase.co
SUPABASE_SERVICE_ROLE_KEY=<service-role-key-de-supabase>
JWT_SECRET=<cadena-larga-aleatoria>
JWT_EXPIRES_IN=8h
PORT=3000
NODE_ENV=development
RESEND_API_KEY=<api-key-de-resend>
RESEND_FROM_EMAIL=no-reply@mail.civictrackio.com
FRONTEND_WEB_URL=http://localhost:5173
FRONTEND_APP_URL=saferoute://reset-password
GOOGLE_SHEET_ID=<id-del-sheet>
GOOGLE_KEY_FILE=credenciales-google.json
```

| Variable | Descripción |
| --- | --- |
| `SUPABASE_URL` | URL del proyecto Supabase (`https://zfgfgymzfjyunyoeddjy.supabase.co`) |
| `SUPABASE_SERVICE_ROLE_KEY` | Clave de servicio (secreta); nunca exponerla al cliente |
| `JWT_SECRET` | Secreto para firmar los JWT; use un valor largo y aleatorio |
| `JWT_EXPIRES_IN` | Tiempo de vida del token; valor por defecto `8h` |
| `PORT` | Puerto del servidor; por defecto `3000` |
| `NODE_ENV` | `development` en local, `production` en Render |
| `RESEND_API_KEY` | Clave para enviar correos transaccionales |
| `RESEND_FROM_EMAIL` | Dirección remitente: `no-reply@mail.civictrackio.com` |
| `FRONTEND_WEB_URL` | URL del dashboard. Local: `http://localhost:5173`. Producción: `https://civictrackio.com` |
| `FRONTEND_APP_URL` | Deep link de la app para recuperar contraseña: `saferoute://reset-password` |
| `GOOGLE_SHEET_ID` | ID de la hoja de cálculo Google Sheets integrada |
| `GOOGLE_KEY_FILE` | Ruta al archivo de credenciales de Google (`credenciales-google.json`) |

**Firebase.** El backend verifica el `idToken` de Google y envía push por FCM, por lo que necesita credenciales de **Firebase Admin** (cuenta de servicio). Siga el mecanismo que use su código (archivo JSON o variables de entorno) y mantenga esas credenciales fuera del repositorio.

### 5.2 Ejecución

```bash
npm run dev     # desarrollo (si el script existe)
npm start       # producción
```

Por defecto escucha en `http://localhost:3000`.

### 5.3 Verificación rápida

```bash
curl http://localhost:3000/api/reportes/stats-login
```

Debe responder con estadísticas públicas en JSON.

## 6. API REST - referencia resumida

Base local: `http://localhost:3000` · Producción: `https://civictracio-project.onrender.com`

**Leyenda:** 🔒 requiere JWT (`Authorization: Bearer <token>`) · 👑 requiere rol admin.

### Autenticación - `/api/auth`

| Método y ruta | Descripción |
| --- | --- |
| `POST /register` | Registro de usuario |
| `POST /login` | Login local |
| `POST /google` | Login con Google |
| `POST /google/check` | Verifica si el usuario Google existe |
| `POST /admin-login` | Login exclusivo de administrador |
| `POST /logout` 🔒 | Cierre de sesión |
| `PATCH /username` 🔒 | Actualizar apodo |
| `PATCH /fcm-token` 🔒 | Guardar token FCM |
| `POST /forgot-password` | Solicitar reset (límite 5 por 15 min) |
| `POST /reset-password` | Restablecer contraseña (límite 5 por 15 min) |
| `GET /terminos` | Términos y condiciones |

### Reportes - `/api/reportes`

| Método y ruta | Descripción |
| --- | --- |
| `GET /stats-login` | Estadísticas públicas |
| `POST /` 🔒 | Crear reporte |
| `GET /mapa` 🔒 | Reportes para el mapa |
| `GET /mapa/nuevos?desde=` 🔒 | Nuevos desde un timestamp |
| `GET /mapa/filtros` 🔒 | Reportes filtrados |
| `GET /admin` 🔒👑 | Listado admin paginado |
| `GET /admin/resumen` 🔒👑 | Resumen del dashboard |
| `GET /estadisticas` 🔒 | Estadísticas por período |
| `GET /estadisticas/comparacion` 🔒 | Comparación de períodos |
| `GET /zonas/top` 🔒 | Top zonas |
| `GET /barrios?q=` 🔒 | Búsqueda fuzzy de barrios |
| `GET /barrios-por-coordenadas?lat=&lng=` 🔒 | Barrios por GPS |
| `GET /corregimientos` 🔒 | Listar corregimientos |
| `GET /corregimientos/:id/veredas` 🔒 | Veredas de un corregimiento |
| `GET /corregimientos-por-coordenadas?lat=&lng=` 🔒 | Corregimiento por GPS |
| `GET /buscar-rural?q=` 🔒 | Búsqueda fuzzy rural |
| `GET /mis-reportes` 🔒 | Reportes del usuario |
| `PUT /:id` 🔒 | Editar reporte propio |
| `POST /:id/solicitar-eliminacion` 🔒 | Solicitar eliminación |

### Administración - `/api/admin` (todas 🔒👑)

CRUD de usuarios (bloquear, ocultar, reactivar, eliminar, hard delete); CRUD de reportes (cambiar estado, editar tipo, edición completa, eliminar en lote, hard delete); gestión de solicitudes de eliminación (listar, aprobar, rechazar); y `GET /reportes/export` para exportar a CSV/Excel.

### Alertas - `/api/alertas` (todas 🔒)

`GET /configuracion`, `PUT /configuracion`, `GET /` (reportes cercanos) y `PATCH /:id/leida`.

### Perfil - `/api/perfil` (todas 🔒)

`GET /` y `PUT /` (perfil), `PUT /password`, `PUT /notificaciones`, `GET /mensajes`, `PATCH /mensajes/:id/leer`, `PATCH /mensajes/leer-todas` y `DELETE /` (eliminar cuenta).

## 7. Instalación del dashboard web

```bash
git clone https://github.com/TU_ORG/CivicTrackIO.git
cd CivicTrackIO/frontend-web/dashboard
npm install
```

Cree un archivo `.env` (o `.env.local`):

```env
VITE_API_URL=http://localhost:3000
VITE_MAPBOX_TOKEN=<token-publico-de-mapbox>
```

```bash
npm run dev      # servidor de desarrollo (normalmente http://localhost:5173)
npm run build    # compilación de producción
npm run preview  # probar la compilación
```

**Notas:**

- Todas las variables de Vite deben empezar por `VITE_` para quedar expuestas al cliente. **Nunca** ponga secretos en ellas.
- El token del administrador se guarda en `sessionStorage`.
- El backend debe permitir en CORS el origen `FRONTEND_WEB_URL`.

## 8. Instalación de la app móvil

```bash
git clone https://github.com/TU_ORG/CivicTrackIO.git
cd CivicTrackIO/frontend-movil/saferoute_app
flutter pub get
flutter doctor      # verifica que el entorno esté completo
```

### 8.1 Configuración

Cree el archivo `.env` que carga la app en tiempo de compilación:

```env
API_BASE_URL=http://10.0.2.2:3000
MAPBOX_TOKEN=<token-publico-de-mapbox>
```

- En el **emulador de Android**, `10.0.2.2` apunta al `localhost` del computador.
- En un **dispositivo físico**, use la IP local del computador (misma red Wi-Fi) o la URL de producción.
- Para producción use `API_BASE_URL=https://civictracio-project.onrender.com`.

### 8.2 Firebase

1. Registre la app Android en Firebase con el `applicationId`: `com.example.saferoute_app`.
2. Descargue `google-services.json` y colóquelo en `android/app/`.
3. Agregue las huellas **SHA-1 y SHA-256** de su keystore en Firebase. El SHA-1 del debug keystore actual es `27:06:D3:3C:85:C6:53:DD:0B:80:C3:6E:81:92:8F:1A:50:2B:53:A7`. Sin ellas falla Google Sign-In.
4. Verifique que FCM esté habilitado.

### 8.3 Deep link de recuperación

El esquema `saferoute://reset-password` debe estar declarado como `intent-filter` en `AndroidManifest.xml` para que el enlace del correo abra la app.

### 8.4 Ejecución y compilación

```bash
flutter run                   # en emulador o dispositivo conectado
flutter build apk --release   # genera el APK de producción
```

El APK queda en `build/app/outputs/flutter-apk/app-release.apk`. Debe firmarlo con su keystore de release (guárdela de forma segura y haga copia de respaldo).

## 9. Crear el primer administrador

No existe registro público de administradores. Para crear uno:

1. Registre un usuario normal desde la app o con `POST /api/auth/register`.
2. En Supabase (SQL Editor o Table Editor), cambie su rol:

```sql
UPDATE usuarios SET rol = 'admin' WHERE correo = 'admin@ejemplo.com';
```

3. Ingrese al dashboard con ese correo y contraseña (usa `POST /api/auth/admin-login`).

## 10. Reglas de negocio relevantes para desarrollo

- **JWT:** expira a las 8 horas.
- **Rate limit:** `forgot-password` y `reset-password` permiten 5 solicitudes por 15 minutos.
- **Visibilidad de reportes:** los de 2025 o anteriores solo se devuelven en un radio de 500 m del usuario; los de 2026 en adelante no tienen restricción.
- **Polling del mapa:** cada 60 s se consulta `GET /mapa/nuevos?desde=<timestamp>`.
- **Paginación de "Mis reportes":** 8 por página.
- **Clustering:** del lado del cliente; colores por densidad (≤10 azul, 11–50 naranja, 51–200 rojo, >200 rojo oscuro).
- **Estados de reporte:** `activo`, `oculto`, `eliminado`; la eliminación por parte del usuario pasa por una solicitud que el admin aprueba o rechaza.

## 11. Solución de problemas de desarrollo

| Síntoma | Causa probable | Solución |
| --- | --- | --- |
| `401` en todas las rutas 🔒 | Token ausente, vencido o `JWT_SECRET` distinto | Reingrese; verifique que el secreto sea el mismo que firmó el token |
| `403` en `/api/admin` | El usuario no tiene `rol = 'admin'` | Corrija el rol en la tabla `usuarios` |
| Error CORS en el dashboard | `FRONTEND_WEB_URL` no coincide con el origen | Ajuste la variable y reinicie el backend |
| La app no conecta con el backend local | Se usó `localhost` en el emulador | Use `10.0.2.2` o la IP local |
| Google Sign-In falla (`ApiException: 10`) | Falta SHA-1/SHA-256 o `google-services.json` desactualizado | Registre las huellas en Firebase y vuelva a descargar el archivo |
| No se asigna zona al crear reporte | Faltan datos geográficos, función RPC o trigger | Revise la carga de `zonas`, `corregimientos` y los triggers |
| No llegan correos | API key inválida o dominio sin verificar | Revise `RESEND_API_KEY` y el estado del dominio en Resend |
| No llegan push | `fcm_token` vacío o credenciales Firebase Admin ausentes | Verifique `PATCH /fcm-token` y la cuenta de servicio |
| Mapa en blanco | Token de Mapbox inválido o ausente | Revise `MAPBOX_TOKEN` / `VITE_MAPBOX_TOKEN` |

## 12. Buenas prácticas

- No suba `.env`, `google-services.json` privados, keystores ni claves a Git; agréguelos a `.gitignore`.
- Use secretos distintos para desarrollo y producción.
- Rote de inmediato cualquier clave que se haya expuesto.
- Mantenga los scripts SQL versionados en el repositorio para reproducir la base de datos.
- Valide y sanee siempre las entradas en el backend; no confíe en el cliente.
