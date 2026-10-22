# Toka

Toka is an open-source household task app by [Tucunar Labs](https://tucunar.com),
a brand of Tucunar SpA.

Tareas domésticas compartidas. Una casa, varias personas, plantillas de tarea que se
regeneran solas cuando alguien las completa.

App Android (Kotlin + Compose) que usa **Firebase Auth (Google) + Firestore directamente**,
sin servidor propio, y funciona sin conexión gracias a la caché persistente de Firestore.
Misma arquitectura que la app Finanzas.

## Cómo funciona

Un **household** agrupa a varias **people**. Cada **template** describe una tarea
("sacar la basura, cada 7 días") y va generando **tasks** concretas.

Al completar una tarea recurrente se crea la siguiente con
`dueAt = momento de completar + recurrenceDays`, en el mismo `WriteBatch`. Se cuenta desde el
completado y no desde el vencimiento original, a propósito: atrasarse un día no deja la
siguiente a un día de distancia. La recurrencia no castiga.

Modelo de datos y reglas de seguridad: ver `CLAUDE.md` y `firestore.rules`.

## Desarrollo local (sin Google ni Firebase reales)

Requiere Android SDK, Java 21+ (para los emuladores de Firebase) y `npx`.

```bash
scripts/dev.sh            # emuladores Firebase + emulador Android + instala "Toka DEV"
scripts/test-rules.sh     # prueba firestore.rules (54 comprobaciones, emulador propio)
cd android && ./gradlew compileDebugKotlin
```

La build debug (`com.toka.app.dev`, "Toka DEV") apunta a los emuladores y ofrece "Entrar como
Ana/Beto (dev)". Los emuladores de Toka usan Auth 9199 / Firestore 8185 / UI 4100, para no
chocar con los de Finanzas (9099 / 8085), que nunca se tocan. Con un teléfono real:
`DISPOSITIVO=<serial> scripts/dev.sh` (pasa `-Ptoka.emulador=<ip del PC>`).

## Firebase real: checklist de consola

El build oficial usa un proyecto Firebase de Tucunar Labs (Firestore en
`southamerica-west1`, plan Spark). Para levantar el tuyo con la misma
arquitectura:

- [ ] Firebase console → crear proyecto (o agregar Firebase a un proyecto de
      Google Cloud) → Firestore Database → modo producción, región
      `southamerica-west1`.
- [ ] Authentication → "Comenzar" → proveedor **Google** → Habilitar (con un
      correo de asistencia). Eso crea el cliente OAuth web que necesita el login.
- [ ] Descargar `google-services.json` y dejarlo en
      `android/app/google-services.json` (gitignoreado); para CI, en base64 como
      secret `GOOGLE_SERVICES_JSON_BASE64`.
- [ ] Publicar las reglas con `scripts/publicar-reglas.sh` cada vez que cambie
      `firestore.rules`.

## Releases e instalación con Obtainium

Cada tag `vX.Y.Z` dispara `.github/workflows/release.yml`, que compila un APK firmado y
lo publica como GitHub Release. [Obtainium](https://github.com/ImranR98/Obtainium) lee
esos releases y actualiza la app sola.

1. Instala Obtainium.
2. "Add App" → pega `https://github.com/tucunar-labs/toka`.
3. Obtainium detecta los releases y el asset `.apk` sin configuración extra.

Para publicar una versión:

```bash
git tag v0.2.0
git push origin v0.2.0
```

El workflow verifica la firma (`apksigner verify`) y falla si faltan los secrets, en vez de
publicar un APK sin firmar. Deriva `versionName` del tag y `versionCode = major*10000 + minor*100 + patch`,
así que un tag más alto siempre instala por encima del anterior. La firma usa el keystore
guardado en los secrets `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
`ANDROID_KEY_ALIAS` y `ANDROID_KEY_PASSWORD`; además necesita `GOOGLE_SERVICES_JSON_BASE64`
(el `google-services.json` real) y falla si falta.

### Segundo canal: F-Droid

El mismo APK firmado también se puede publicar en un repo F-Droid propio:

```bash
cd android && ./gradlew assembleRelease -PtokaVersionName=0.3.0 -PtokaVersionCode=300   # versión del tag, no la de desarrollo
scripts/publicar-apk.sh                                                                    # publica en el repo F-Droid configurado
```

Los dos canales (Obtainium y F-Droid) deben servir **el mismo APK** (misma firma y mismo `versionCode`) para que
se actualicen entre sí sin reinstalar.

**Guarda `android/release.jks` y `android/keystore.properties`** (están gitignoreados).
Son la única forma de firmar actualizaciones que Android acepte como del mismo
desarrollador; si se pierden, hay que desinstalar y reinstalar. El APK de release y el de
debug tienen firmas distintas: para pasar de uno a otro hay que desinstalar.

## Backend legado (opcional)

La app actual usa Firebase y no necesita servidor. El backend Go + SQLite queda
en el repo como referencia y para migrar datos antiguos.

Local: `make run-seed` (Go 1.26, SQLite en `toka.db`, sirve en :3000, lee `db/`
desde la raíz del repo); `make smoke` lo prueba contra una base temporal. El seed
es solo de desarrollo (hogar "Demo" con credenciales públicas).

Si lo operás en un host propio, los scripts de `deploy/` (backup, restore-check,
rotación de credenciales) siguen en el repo. **No cargues el seed en producción.**
Los hogares reales se crean desde la app.

## Decisiones que vale la pena conocer

**El aislamiento entre casas lo aplican las reglas de Firestore.** No hay servidor que filtre:
`firestore.rules` exige ser miembro del hogar para leer o escribir, y valida que asignados y
miembros pertenezcan al hogar. Se prueban con `scripts/test-rules.sh`.

**Las escrituras no esperan la red.** Firestore las guarda en su caché y las sube solas; la UI
nunca hace `await` de una escritura. El indicador ⟳ N cuenta los documentos con escrituras pendientes.

**La recurrencia vive en el cliente y es idempotente.** La tarea siguiente tiene un id determinista
(hash del id de la actual), así que dos teléfonos que completan lo mismo sin conexión no la duplican.
Deshacer devuelve la tarea a pendiente y borra la siguiente si aún está pendiente.

**Unirse a un hogar va en dos pasos** (miembros + perfil, luego el puntero `users/{uid}`) para evitar
una carrera de permisos, y los listeners reintentan ante `PERMISSION_DENIED`.

**Recordatorios locales.** `ReminderWorker` (WorkManager, cada 15 min) y el widget "Mis tareas de
hoy" leen de la caché de Firestore; no hay push remoto.

Todo está desarrollado en `CLAUDE.md`, que es también el contexto que usan los agentes que
trabajan en este repositorio.

## Estado

Migración a Firestore hecha en la rama `firestore`: auth, hogar, tareas y recurrencia en el cliente,
con reglas probadas en emulador. Falta completar el checklist de consola y migrar los datos del
backend legado antes de retirarlo.

## Licencia

Apache License 2.0. Ver [`LICENSE`](LICENSE), [`NOTICE`](NOTICE) y
[`TRADEMARK.md`](TRADEMARK.md). El código es abierto; la marca y las releases
oficiales son de Tucunar SpA.
