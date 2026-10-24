# CivicTrackIO - Manual de usuario final (App móvil)

*Versión 1.0 · Aplicación Android · Reporte y seguimiento ciudadano de hurtos en Pasto*

## 1. Introducción

CivicTrackIO es una aplicación para que la ciudadanía reporte hurtos (atracos, raponazos, fleteos y cosquilleos), consulte en un mapa dónde ocurren y reciba alertas cuando se registren nuevos hechos cerca de su ubicación.

Con la app puede:

- Ver los reportes en un mapa interactivo, como marcadores o como mapa de calor.
- Registrar un incidente como víctima o testigo.
- Consultar, editar y solicitar la eliminación de sus propios reportes.
- Configurar alertas por proximidad y tipo de hurto.
- Administrar su perfil y su cuenta.

### Requisitos

| Requisito | Detalle |
| --- | --- |
| Sistema operativo | Android (la app no está disponible para iOS) |
| Conexión | Internet (datos móviles o Wi-Fi) |
| Permisos | Ubicación (GPS) y notificaciones |
| Instalación | Archivo APK distribuido directamente |

## 2. Instalación

1. Descargue el archivo APK que le entregó el equipo de CivicTrackIO.
2. Abra el archivo desde la carpeta de descargas de su teléfono.
3. Si Android lo solicita, active **Permitir instalar aplicaciones de esta fuente** para el navegador o administrador de archivos que esté usando.
4. Pulse **Instalar** y espere a que termine.
5. Abra la app. Cuando se le pida, **acepte los permisos de ubicación y notificaciones**: son necesarios para el mapa y las alertas.

> **Nota:** como la app no se distribuye por Play Store, instálela solo desde el enlace o archivo oficial del proyecto.

## 3. Registro e inicio de sesión

### 3.1 Crear una cuenta (registro local)

1. En la pantalla de inicio pulse **Registrarse**.
2. Complete el nombre de usuario (apodo), el correo electrónico y la contraseña.
3. La app valida el formato de cada campo; si alguno es incorrecto verá un mensaje indicando qué corregir.
4. Lea y acepte los **Términos y condiciones** y confirme el registro.

### 3.2 Iniciar sesión con correo y contraseña

Ingrese su correo y contraseña y pulse **Iniciar sesión**. La sesión permanece activa hasta por **8 horas**; después deberá ingresar de nuevo.

### 3.3 Iniciar sesión con Google

Pulse **Continuar con Google** y elija su cuenta. No necesita contraseña adicional. Los usuarios de Google no pueden cambiar contraseña dentro de la app, porque no tienen una.

### 3.4 Recuperar la contraseña

1. En la pantalla de inicio de sesión pulse **¿Olvidó su contraseña?**.
2. Escriba su correo y solicite el restablecimiento.
3. Revise su bandeja de entrada (y la carpeta de correo no deseado). Recibirá un mensaje con un enlace.
4. Abra el enlace desde el teléfono: se abrirá la app en la pantalla de nueva contraseña.
5. Escriba la nueva contraseña y confirme.

> Por seguridad, solo puede solicitar el restablecimiento **5 veces cada 15 minutos**.

### 3.5 Cierre de sesión por inactividad

Si deja la app sin usar durante el tiempo de inactividad configurado, la sesión se cierra automáticamente para proteger su cuenta. Solo tendrá que iniciar sesión otra vez.

## 4. El mapa

Es la pantalla principal. Muestra los reportes de hurto sobre un mapa de Mapbox y su ubicación actual en tiempo real.

### 4.1 Modos de visualización

**Marcadores.** Cada reporte aparece como un punto. Cuando hay muchos cerca, se agrupan en un círculo con un número (clúster). El color indica la densidad:

| Color | Cantidad de reportes agrupados |
| --- | --- |
| Azul | 10 o menos |
| Naranja | de 11 a 50 |
| Rojo | de 51 a 200 |
| Rojo oscuro | más de 200 |

Toque un clúster o acérquese con el zoom para ver los reportes individuales; toque un marcador para ver su detalle.

**Mapa de calor.** Muestra la intensidad de hurtos por zonas: mientras más intenso el color, mayor concentración de reportes en esa vecindad. Es útil para identificar de un vistazo los sectores más afectados.

### 4.2 Filtros

Puede refinar lo que ve en el mapa por:

- **Tipo de hurto:** atraco, raponazo, fleteo o cosquilleo.
- **Comuna** (zona urbana) o **corregimiento** (zona rural).
- **Franja horaria.**
- **Rango de fechas.**
- **Modo urbano o rural.**

### 4.3 Reglas de visibilidad

- Los reportes de **2026 en adelante** se muestran sin restricción de distancia.
- Los reportes de **2025 o años anteriores** solo se muestran dentro de un radio de **500 metros** de su ubicación.

Si no ve reportes antiguos que esperaba, es por esta regla: acérquese a la zona o consulte reportes recientes.

### 4.4 Otras funciones del mapa

- **Actualización automática:** cada 60 segundos la app trae únicamente los reportes nuevos.
- **Su ubicación:** se actualiza cuando se desplaza más de 50 metros.
- **Modo oscuro / claro:** puede cambiar el estilo del mapa según su preferencia o la luz ambiente.

## 5. Registrar un incidente

1. Pulse el botón de **nuevo reporte**.
2. Indique si es **víctima** o **testigo**.
3. Seleccione el **tipo de hurto**: atraco, raponazo, fleteo o cosquilleo.
4. Indique la **fecha** y la **franja horaria** del hecho.
5. Ubique el lugar:
   - **Zona urbana:** escriba la dirección y el barrio. La búsqueda es aproximada, así que aunque se equivoque en una letra le sugerirá el barrio correcto.
   - **Zona rural:** escriba la vereda o el corregimiento; también tiene búsqueda aproximada.
6. La app **detecta automáticamente la zona** (comuna, barrio o corregimiento) a partir de las coordenadas GPS del punto.
7. Opcionalmente agregue el **objeto hurtado**, el **número de agresores** y una **descripción**.
8. Pulse **Enviar**.

> **Consejo:** entre más preciso sea el punto en el mapa y más completa la información, más útil será el reporte para toda la comunidad.

> **Importante:** CivicTrackIO es una herramienta de información ciudadana. **No reemplaza la denuncia ante las autoridades**. En una emergencia, comuníquese primero con la Policía (123).

## 6. Mis reportes

En esta sección encuentra todos los reportes que usted ha creado.

- La lista se carga de **8 en 8**; al desplazarse hacia abajo se cargan más automáticamente.
- **Ver detalle:** toque un reporte para ver toda su información.
- **Editar:** puede modificar los campos de su propio reporte y guardar los cambios.
- **Solicitar eliminación:** pulse la opción de eliminar. El reporte **no se borra de inmediato**: la solicitud queda pendiente y un administrador la revisa. Será aprobada o rechazada, y usted recibirá la respuesta como notificación.

## 7. Alertas y notificaciones

### 7.1 Configurar alertas

1. Entre a **Alertas** (o a la configuración de alertas en su perfil).
2. Active las alertas.
3. Defina el **radio de proximidad** (qué tan cerca de usted debe ocurrir el hecho).
4. Seleccione los **tipos de hurto** sobre los que quiere ser avisado.
5. Guarde la configuración.

Desde ese momento recibirá una **notificación push** cada vez que se registre un reporte nuevo dentro de su radio que coincida con los tipos elegidos.

### 7.2 Bandeja de notificaciones

Todas las alertas y mensajes quedan guardados en la bandeja. Un contador le muestra cuántas **no ha leído**. Puede marcar una por una o **marcar todas como leídas**.

## 8. Perfil y cuenta

| Acción | Cómo hacerlo | Notas |
| --- | --- | --- |
| Cambiar nombre de usuario | Perfil → editar usuario → guardar | Disponible para todos |
| Cambiar contraseña | Perfil → cambiar contraseña | Solo usuarios con registro local (no Google) |
| Alertas | Perfil → activar/desactivar y ajustar radio |  |
| Eliminar cuenta | Perfil → eliminar cuenta → confirmar | **Acción permanente** |

## 9. Preguntas frecuentes y solución de problemas

**La app tarda mucho en responder la primera vez.** El servidor entra en reposo tras 15 minutos sin uso. La primera consulta puede tardar hasta un minuto en despertarlo; después funciona con normalidad. Espere y reintente.

**No veo mi ubicación en el mapa.** Verifique que el GPS esté activo y que la app tenga permiso de ubicación (Ajustes → Aplicaciones → CivicTrackIO → Permisos).

**No me llegan las alertas.** Revise que las alertas estén activadas, que el radio y los tipos de hurto estén configurados, y que las notificaciones de la app no estén bloqueadas en Android ni restringidas por el ahorro de batería.

**No me llega el correo de recuperación.** Revise la carpeta de spam, confirme que escribió bien su correo y recuerde el límite de 5 intentos cada 15 minutos.

**El enlace de recuperación no abre la app.** Ábralo desde el mismo teléfono donde está instalada la app, preferiblemente desde la aplicación de correo.

**No encuentro mi barrio o vereda.** Pruebe con menos letras o sin tildes; la búsqueda es aproximada. También puede mover el punto en el mapa y dejar que la app detecte la zona por GPS.

**¿Mi reporte fue eliminado?** Los administradores pueden ocultar o eliminar reportes que no cumplan las normas. Si usted solicitó la eliminación, recibirá la respuesta como notificación.

## 10. Uso responsable

- Reporte únicamente hechos reales y de los que tenga conocimiento directo.
- No incluya nombres, documentos ni datos personales de terceros en la descripción.
- Los reportes falsos o abusivos pueden llevar al bloqueo de la cuenta por parte de los administradores.
- Consulte los **Términos y condiciones** desde la pantalla de registro para conocer el tratamiento de sus datos.
