# 🧹 node_modules_cleaner

> Un script bash interactivo para encontrar, listar y eliminar carpetas `node_modules` de forma segura — liberando espacio en disco sin complicaciones.

---

## ¿Por qué existe esto?

Si trabajás en varios proyectos de JavaScript/Node.js, sabés que las carpetas `node_modules` se acumulan rápido. Un proyecto mediano puede pesar entre 200 MB y 1 GB. Diez proyectos abandonados = potencialmente **varios gigas desperdiciados**.

Este script resuelve eso: escanea recursivamente un directorio, te muestra todo lo que encontró con sus pesos, y te deja elegir qué borrar — sin tener que recordar rutas ni correr comandos manuales.

---

## ✨ Funcionalidades

- 🔍 **Búsqueda recursiva** desde cualquier directorio raíz
- 📊 **Tabla formateada** con número, tamaño y ruta de cada `node_modules`
- 🎨 **Colores por tamaño**: verde < 100 MB · amarillo 100–499 MB · rojo ≥ 500 MB
- 🎯 **Selección flexible**: borrar todas, elegir por número, o no borrar nada
- ✅ **Confirmación antes de borrar** con resumen del espacio a liberar
- 🌀 **Spinner animado** mientras busca
- 🚫 Ignora `node_modules` anidados dentro de otros `node_modules`

---

## 📋 Requisitos

- Bash 4.0+
- `bc` (para cálculos de tamaño) — generalmente preinstalado en Linux/macOS
- `du` — estándar en cualquier sistema UNIX

No requiere Node.js, npm, ni ninguna dependencia externa.

---

## 🚀 Instalación y uso

```bash
# 1. Clonar o descargar el script
git clone https://github.com/tu-usuario/node_modules_cleaner.git
cd node_modules_cleaner

# 2. Dar permisos de ejecución
chmod +x node_modules_cleaner.sh

# 3. Ejecutar
./node_modules_cleaner.sh                  # busca en el directorio actual
./node_modules_cleaner.sh ~/proyectos      # busca en un directorio específico
./node_modules_cleaner.sh /home/user/dev   # ruta absoluta
```

---

## 🖥️ Demo

```
  ╔══════════════════════════════════════════════════╗
  ║        🧹  node_modules  C L E A N E R           ║
  ╚══════════════════════════════════════════════════╝

  Directorio raíz: /home/lucas/proyectos

  ⠹  Buscando node_modules en /home/lucas/proyectos...

  ┌──────┬────────────┬───────────────────────────────────────────────────┐
  │  #   │ TAMAÑO     │ RUTA                                              │
  ├──────┼────────────┼───────────────────────────────────────────────────┤
  │    1 │    843.2 MB│ /home/lucas/proyectos/app-vieja/node_modules      │
  │    2 │    241.5 MB│ /home/lucas/proyectos/landing-2023/node_modules   │
  │    3 │     67.3 MB│ /home/lucas/proyectos/scripts-varios/node_modules │
  └──────┴────────────┴───────────────────────────────────────────────────┘

  Total encontrados: 3 carpetas  |  Espacio total: 1.1 GB

  Leyenda tamaños:  ● < 100 MB   ● 100–499 MB   ● ≥ 500 MB

  ¿Qué querés hacer?

   [a]  Borrar TODAS las carpetas
   [n]  Ingresar números separados por coma  (ej: 1,3,5)
   [q]  Salir sin borrar nada

  → 1,2

  Se van a borrar las siguientes carpetas:

   ✗  /home/lucas/proyectos/app-vieja/node_modules  (843.2 MB)
   ✗  /home/lucas/proyectos/landing-2023/node_modules  (241.5 MB)

  Espacio a liberar: 1.0 GB

  ¿Confirmar borrado? [s/N]: s

  Borrando  /home/lucas/proyectos/app-vieja/node_modules         ✓
  Borrando  /home/lucas/proyectos/landing-2023/node_modules      ✓

  ✓ Listo!  Borradas: 2  |  Liberado: 1.0 GB
```

---

## 🛠️ Cómo funciona

### Búsqueda

```bash
find "$ROOT_DIR" \
  -name "node_modules" \
  -type d \
  -not -path "*/node_modules/*/node_modules" \
  2>/dev/null
```

El flag `-not -path "*/node_modules/*/node_modules"` es clave: evita que se listen las subcarpetas `node_modules` que viven *dentro* de otras `node_modules` (que son dependencias de dependencias). Solo se listan los directorios de nivel de proyecto.

### Cálculo de tamaño

```bash
du -sb "$path"   # tamaño en bytes del directorio completo
```

Luego se convierte a KB/MB/GB según corresponda usando `bc` para aritmética de punto flotante en bash.

### Selección y borrado

La selección acepta:
- `a` → agrega todos los paths encontrados al array de borrado
- `1,3,5` → parsea los números, valida que estén en rango, y mapea al path correspondiente
- `q` o Enter → sale sin modificar nada

Antes de ejecutar `rm -rf`, el script pide confirmación explícita con `[s/N]` y muestra exactamente qué se va a borrar y cuánto espacio se va a liberar.

### Estructura del script

```
node_modules_cleaner.sh
├── banner()          — título decorativo
├── usage()           — ayuda con -h / --help
├── spinner()         — animación mientras busca (background PID)
├── human_size()      — convierte bytes a KB/MB/GB
├── size_color()      — elige color ANSI según el tamaño
├── búsqueda          — find en background + mapfile
├── tabla             — renderizado con printf y escape codes
├── menú              — lectura de input con case
└── borrado           — rm -rf con feedback por línea
```

---

## ⚠️ Precauciones

- El borrado es **permanente** (`rm -rf`). No va a la papelera.
- No borres `node_modules` de aplicaciones instaladas en el sistema (Electron apps como VS Code, Slack, Discord, etc.) — van a dejar de funcionar.
- Si tenés dudas, usá la opción `q` para salir y revisar las rutas primero.

---

## 🤖 Hecho con Claude

Este script fue desarrollado con la asistencia de **[Claude](https://claude.ai)**, el asistente de IA de [Anthropic](https://anthropic.com).

El proceso incluyó:
- Diseño de la arquitectura del script y flujo de usuario
- Implementación de la UI interactiva con escape codes ANSI
- Debugging y validación de la sintaxis bash
- Documentación

> Si bien el proyecto final que resuelve este problema es [npkill](https://github.com/voidcosmos/npkill) (que lo hace mucho mejor y en TypeScript con RxJS), este script fue un ejercicio de aprendizaje sobre cómo abordar el problema desde bash puro.

---

## 📚 Alternativas

Si necesitás algo más robusto o con UI interactiva en la terminal, mirá:

| Herramienta | Stack | UI |
|---|---|---|
| [npkill](https://github.com/voidcosmos/npkill) | TypeScript / Node.js | TUI con flechas |
| este script | Bash puro | Selección por número |

```bash
# npkill: instalación y uso
npx npkill
```

---

## 📄 Licencia

MIT — hacé lo que quieras con esto.
