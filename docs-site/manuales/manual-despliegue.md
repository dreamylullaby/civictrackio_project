# CivicTrackIO - Manual de despliegue

*Versión 1.0 · Render · Netlify · Supabase · Resend · Firebase · APK Android*

> **Nota.** Las interfaces de Render, Netlify, Supabase, Resend y Firebase cambian con frecuencia; los nombres de menús pueden variar ligeramente. Los valores, variables y URLs corresponden a la configuración actual de CivicTrackIO.

## 1. Mapa de despliegue

| Componente | Plataforma | URL | Notas |
| --- | --- | --- | --- |
| Backend (API REST) | Render (plan gratuito) | https://civictracio-project.onrender.com | Hiberna tras 15 min sin tráfico |
| Dashboard web | Netlify | https://civictrackio.com | Solo administradores |
| Base de datos y Storage | Supabase | — | PostgreSQL + PostGIS |
| Correos | Resend | dominio `mail.civictrackio.com` | DNS gestionado en Netlify |
| Autenticación Google y push | Firebase (Auth + FCM) | — |  |
| App móvil | APK distribuido directamente | — | Solo Android |

## 2. Orden recomendado de despliegue

Respete este orden, porque cada paso depende del anterior:

1. **Supabase:** base de datos, datos geográficos, funciones y triggers.
2. **Firebase:** proyecto, Google Sign-In y FCM.
3. **Resend:** dominio verificado y API key.
4. **Backend en Render.**
5. **Dashboard en Netlify** (apuntando al backend).
6. **Dominio y DNS.**
7. **Compilación y distribución del APK.**
8. **Verificación final.**

## 3. Lista de variables de entorno

### Backend (Render)

| Variable | Valor / origen |
| --- | --- |
| `SUPABASE_URL` | URL del proyecto Supabase |
| `SUPABASE_SERVICE_ROLE_KEY` | Clave de servicio de Supabase (**secreta**) |
| `JWT_SECRET` | Cadena larga y aleatoria (**secreta**) |
| `RESEND_API_KEY` | API key de Resend (**secreta**) |
| `FRONTEND_WEB_URL` | `https://civictrackio.com` |
| `FRONTEND_APP_URL` | `saferoute://reset-password` |

Además, el backend necesita las credenciales de **Firebase Admin** para verificar el login con Google y enviar push. Cargue esas credenciales como variable de entorno o *secret file* según lo que implemente el código.

### Dashboard web (Netlify)

| Variable | Valor |
| --- | --- |
| `VITE_API_URL` | `https://civictracio-project.onrender.com` |
| `VITE_MAPBOX_TOKEN` | Token público de Mapbox |

### App móvil (archivo `.env` en la compilación)

| Variable | Valor |
| --- | --- |
| `API_BASE_URL` | `https://civictracio-project.onrender.com` |
| `MAPBOX_TOKEN` | Token público de Mapbox |

> Las variables `VITE_*` y las del `.env` de la app quedan **visibles en el cliente**. Nunca coloque allí claves secretas.

## 4. Supabase

1. Cree el proyecto en https://supabase.com y elija la región más cercana a los usuarios.
2. En **Database → Extensions** habilite `postgis` y la extensión de similitud de texto usada por `buscar_barrio_similar` (normalmente `pg_trgm`).
3. En el **SQL Editor** ejecute, en orden: tablas, carga de datos geográficos (zonas, 17 corregimientos, veredas, secciones DANE), funciones RPC (`get_zona_por_coordenadas`, `get_corregimiento_por_coordenadas`, `buscar_barrio_similar`) y triggers de asignación automática de zona.
4. Cree el usuario administrador (ver el Manual técnico, sección 9).
5. Copie desde **Settings → API** la `Project URL` y la `service_role key`.
6. Verifique que las funciones respondan, por ejemplo con una coordenada conocida de Pasto.

**Respaldo.** Programe copias de seguridad. El plan gratuito de Supabase tiene opciones limitadas, así que exporte la base periódicamente (`pg_dump`) y guárdela en un lugar seguro.

## 5. Firebase

1. Cree el proyecto en https://console.firebase.google.com.
2. **Authentication → Sign-in method:** habilite **Google**.
3. Registre la app Android con el `applicationId` `com.example.saferoute_app` y descargue `google-services.json` para la app.
4. Agregue las huellas **SHA-1 y SHA-256** de la keystore de release (y de debug para pruebas). El SHA-1 del debug keystore es `27:06:D3:3C:85:C6:53:DD:0B:80:C3:6E:81:92:8F:1A:50:2B:53:A7`.
5. **Project settings → Service accounts:** genere la clave privada de Firebase Admin para el backend y guárdela como secreto.
6. Confirme que **Cloud Messaging** esté habilitado.

## 6. Resend (correos)

Los correos de recuperación de contraseña salen desde el dominio `mail.civictrackio.com`.

1. En Resend, agregue el dominio `mail.civictrackio.com`.
2. Resend entrega registros DNS (normalmente SPF, DKIM y, opcionalmente, DMARC).
3. Cree esos registros en **Netlify DNS** (Domains → DNS settings), donde está gestionado el dominio.
4. Espere la propagación y pulse **Verify** en Resend hasta que el estado sea *Verified*.
5. Cree una **API key** con permiso de envío y guárdela como `RESEND_API_KEY` en Render.

## 7. Backend en Render

### 7.1 Creación del servicio

1. En https://render.com, pulse **New → Web Service** y conecte el repositorio del backend en GitHub.
2. Configure:

| Campo | Valor |
| --- | --- |
| Runtime | Node |
| Branch | La rama de producción (por ejemplo `main`) |
| Build Command | `npm install` |
| Start Command | `npm start` (o el comando definido en `package.json`) |
| Plan | Free |
| Health Check Path | Una ruta pública y liviana, por ejemplo `/api/reportes/stats-login` |

3. En **Environment**, agregue todas las variables del backend (sección 3).
4. Pulse **Create Web Service**. Render compila y publica; la URL resultante debe ser `https://civictracio-project.onrender.com`.

### 7.2 Despliegues posteriores

Con **auto-deploy** activo, cada `git push` a la rama de producción genera un nuevo despliegue. También puede lanzarlo manualmente con **Manual Deploy**.

### 7.3 Limitación del plan gratuito (hibernación)

Tras **15 minutos sin tráfico**, Render suspende el servicio. La primera petición posterior puede tardar hasta un minuto en responder ("arranque en frío"). Efectos y opciones:

| Efecto | Mitigación |
| --- | --- |
| Login o primera carga lentos | Informar a los usuarios; la app y el dashboard deben mostrar indicador de carga y tolerar tiempos de espera largos |
| Alertas retrasadas si el servicio duerme | Usar un servicio de *ping* externo que consulte una ruta liviana cada \~10 minutos |
| Producción con requisitos reales de disponibilidad | Pasar a un plan de pago (instancia siempre activa) |

> Los *pings* periódicos ayudan, pero el plan gratuito tiene un límite mensual de horas de instancia; verifique las condiciones vigentes de Render antes de depender de esta solución.

## 8. Dashboard en Netlify

### 8.1 Creación del sitio

1. En https://app.netlify.com pulse **Add new site → Import an existing project** y conecte el repositorio del dashboard.
2. Configure:

| Campo | Valor |
| --- | --- |
| Build command | `npm run build` |
| Publish directory | `dist` |
| Node version | LTS reciente (puede fijarse con la variable `NODE_VERSION`) |

3. En **Site configuration → Environment variables** agregue `VITE_API_URL` y `VITE_MAPBOX_TOKEN`.
4. Despliegue el sitio.

> Las variables `VITE_*` se incrustan **al compilar**. Si las cambia, debe lanzar un nuevo despliegue (*Trigger deploy → Clear cache and deploy site*).

### 8.2 Rutas de una SPA

Como es una aplicación de una sola página, agregue una regla de reescritura para que recargar la página no dé error 404. Cree `public/_redirects` con:

```
/*    /index.html   200
```

### 8.3 Dominio personalizado

1. En **Domain management**, agregue `civictrackio.com`.
2. Si usa Netlify DNS, apunte los *nameservers* del dominio a los que indica Netlify.
3. Netlify emite el certificado **HTTPS** automáticamente (Let's Encrypt); verifique que quede activo y active la redirección forzada a HTTPS.

## 9. App móvil (APK)

1. Prepare el `.env` de producción (`API_BASE_URL` y `MAPBOX_TOKEN`).
2. Confirme que `android/app/google-services.json` sea el del proyecto Firebase de producción.
3. Suba el número de versión en `pubspec.yaml` (`version: x.y.z+build`).
4. Compile:

```bash
flutter clean
flutter pub get
flutter build apk --release
```

5. Verifique que esté firmado con la **keystore de release** (las actualizaciones solo se instalan si se firman con la misma clave). Respalde la keystore y sus contraseñas.
6. Recoja el archivo en `build/app/outputs/flutter-apk/app-release.apk`.
7. Distríbuyalo por un canal oficial (enlace de descarga controlado, almacenamiento en la nube del proyecto, etc.) e indique a los usuarios que habiliten la instalación desde fuentes externas.

## 10. Lista de verificación posterior al despliegue

| Verificación | Cómo comprobarlo |
| --- | --- |
| Backend responde | Abrir `https://civictracio-project.onrender.com/api/reportes/stats-login` |
| Dashboard carga con HTTPS | Abrir `https://civictrackio.com` |
| Login de administrador | Ingresar con una cuenta admin |
| El dashboard consume el backend correcto | Revisar la pestaña *Network* del navegador; debe llamar a la URL de Render |
| CORS correcto | Sin errores de CORS en la consola |
| Registro y login en la app | Crear una cuenta de prueba |
| Login con Google | Probar en un dispositivo con el APK de release |
| Recuperación de contraseña | Llega el correo desde `mail.civictrackio.com` y el enlace abre la app |
| Crear reporte | La zona se asigna automáticamente |
| Mapa | Aparecen reportes y el mapa de Mapbox carga |
| Notificaciones push | Un reporte cercano dispara la alerta |
| Exportación admin | Descargar CSV/Excel desde el dashboard |

## 11. Mantenimiento y operación

- **Actualizar el backend:** `git push` a la rama de producción; revise los logs en Render tras el despliegue.
- **Actualizar el dashboard:** `git push`; Netlify compila y publica. Si falla, use **Publish deploy** sobre un despliegue anterior para volver atrás rápidamente.
- **Revertir el backend:** en Render, redespliegue un *commit* anterior desde el historial de despliegues.
- **Rotación de secretos:** cambie `JWT_SECRET`, `RESEND_API_KEY` o la clave de Supabase si se exponen; recuerde que cambiar `JWT_SECRET` cierra todas las sesiones.
- **Monitoreo:** revise periódicamente los logs de Render, el uso de Supabase y los límites de envío de Resend.
- **Respaldos:** exporte la base de datos con regularidad y guarde la keystore de Android en lugar seguro.

## 12. Solución de problemas de despliegue

| Problema | Causa probable | Solución |
| --- | --- | --- |
| El build en Render falla | Versión de Node o dependencias | Fije la versión de Node (`engines` en `package.json`) y revise los logs |
| `Application failed to respond` en Render | Falta variable de entorno o el servidor no escucha en el puerto asignado | Verifique las variables y que use `process.env.PORT` |
| Errores de CORS desde `civictrackio.com` | `FRONTEND_WEB_URL` mal configurada | Corríjala (sin barra final) y redespliegue el backend |
| El dashboard llama a `localhost` | `VITE_API_URL` ausente al compilar | Defina la variable en Netlify y vuelva a desplegar con caché limpia |
| 404 al recargar una ruta en Netlify | Falta la regla de SPA | Agregue `_redirects` |
| Los correos no se envían | Dominio sin verificar o API key inválida | Revise registros DNS en Netlify y el estado en Resend |
| El enlace del correo no abre la app | Deep link no declarado o `FRONTEND_APP_URL` incorrecta | Verifique el `intent-filter` y el valor `saferoute://reset-password` |
| Google Sign-In falla en el APK | Falta la huella SHA de release | Agréguela en Firebase y vuelva a descargar `google-services.json` |
| Respuestas muy lentas tras inactividad | Hibernación del plan gratuito de Render | Ver sección 7.3 |
| El APK no actualiza la versión instalada | Firmado con otra keystore o versión no incrementada | Use la misma keystore y aumente el `build number` |
