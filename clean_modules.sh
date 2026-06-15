#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║         node_modules cleaner  ·  by lucaas           ║
# ╚══════════════════════════════════════════════════════╝

set -euo pipefail

# ── Colores ────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# ── Banner ─────────────────────────────────────────────
banner() {
  echo ""
  echo -e "${CYAN}${BOLD}  ╔══════════════════════════════════════════════════╗${RESET}"
  echo -e "${CYAN}${BOLD}  ║        🧹  node_modules  C L E A N E R           ║${RESET}"
  echo -e "${CYAN}${BOLD}  ╚══════════════════════════════════════════════════╝${RESET}"
  echo ""
}

# ── Uso ────────────────────────────────────────────────
usage() {
  echo -e "${BOLD}Uso:${RESET}  $0 [directorio_raiz]"
  echo ""
  echo -e "  ${DIM}Si no se pasa un directorio, se usa el directorio actual.${RESET}"
  echo ""
  exit 0
}

[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && usage

ROOT_DIR="${1:-$(pwd)}"

# Verificar que el directorio existe
if [[ ! -d "$ROOT_DIR" ]]; then
  echo -e "${RED}✗ El directorio '${ROOT_DIR}' no existe.${RESET}"
  exit 1
fi

# ── Spinner mientras busca ─────────────────────────────
spinner() {
  local pid=$1
  local delay=0.08
  local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
  while kill -0 "$pid" 2>/dev/null; do
    for frame in "${frames[@]}"; do
      printf "\r  ${CYAN}${frame}${RESET}  Buscando node_modules en ${DIM}${ROOT_DIR}${RESET}...  "
      sleep "$delay"
    done
  done
  printf "\r%*s\r" "60" ""   # limpiar línea
}

# ── Formatear tamaño human-readable ────────────────────
human_size() {
  local bytes=$1
  if   (( bytes >= 1073741824 )); then printf "%.1f GB" "$(echo "scale=1; $bytes/1073741824" | bc)"
  elif (( bytes >= 1048576   )); then printf "%.1f MB" "$(echo "scale=1; $bytes/1048576"    | bc)"
  elif (( bytes >= 1024      )); then printf "%.1f KB" "$(echo "scale=1; $bytes/1024"       | bc)"
  else printf "%d B" "$bytes"
  fi
}

# ── Color según tamaño ─────────────────────────────────
size_color() {
  local bytes=$1
  if   (( bytes >= 536870912  )); then echo -e "${RED}"      # ≥ 500 MB → rojo
  elif (( bytes >= 104857600  )); then echo -e "${YELLOW}"   # ≥ 100 MB → amarillo
  else                                  echo -e "${GREEN}"   # < 100 MB → verde
  fi
}

# ══════════════════════════════════════════════════════
banner

echo -e "  ${DIM}Directorio raíz:${RESET} ${BOLD}${ROOT_DIR}${RESET}"
echo ""

# ── Buscar node_modules (en background para el spinner) ─
TMP_FILE=$(mktemp)

find "$ROOT_DIR" \
  -name "node_modules" \
  -type d \
  -not -path "*/node_modules/*/node_modules" \
  2>/dev/null > "$TMP_FILE" &

FIND_PID=$!
spinner $FIND_PID
wait $FIND_PID

# ── Leer resultados ────────────────────────────────────
mapfile -t NM_PATHS < "$TMP_FILE"
rm -f "$TMP_FILE"

if [[ ${#NM_PATHS[@]} -eq 0 ]]; then
  echo -e "  ${GREEN}✓ No se encontraron carpetas node_modules. ¡Todo limpio!${RESET}"
  echo ""
  exit 0
fi

# ── Calcular tamaños ───────────────────────────────────
declare -a SIZES_BYTES=()
declare -a SIZES_HUMAN=()
TOTAL_BYTES=0

echo -e "  ${DIM}Calculando tamaños...${RESET}"
echo ""

for path in "${NM_PATHS[@]}"; do
  bytes=$(du -sb "$path" 2>/dev/null | awk '{print $1}' || echo "0")
  SIZES_BYTES+=("$bytes")
  SIZES_HUMAN+=("$(human_size "$bytes")")
  TOTAL_BYTES=$(( TOTAL_BYTES + bytes ))
done

# ── Tabla ──────────────────────────────────────────────
COL_W=6   # ancho columna #
SIZE_W=10  # ancho columna tamaño

echo -e "  ${BOLD}${CYAN}┌──────┬────────────┬───────────────────────────────────────────────────┐${RESET}"
printf   "  ${BOLD}${CYAN}│${RESET} ${BOLD}%-4s${RESET} ${CYAN}│${RESET} ${BOLD}%-10s${RESET} ${CYAN}│${RESET} ${BOLD}%-49s${RESET} ${CYAN}│${RESET}\n" "#" "TAMAÑO" "RUTA"
echo -e  "  ${BOLD}${CYAN}├──────┼────────────┼───────────────────────────────────────────────────┤${RESET}"

for i in "${!NM_PATHS[@]}"; do
  num=$(( i + 1 ))
  path="${NM_PATHS[$i]}"
  size_h="${SIZES_HUMAN[$i]}"
  bytes="${SIZES_BYTES[$i]}"
  sc="$(size_color "$bytes")"

  # Truncar ruta si es muy larga
  display_path="$path"
  if [[ ${#path} -gt 49 ]]; then
    display_path="...${path: -46}"
  fi

  printf "  ${CYAN}│${RESET} ${BOLD}%4d${RESET} ${CYAN}│${RESET} ${sc}%10s${RESET} ${CYAN}│${RESET} ${DIM}%-49s${RESET} ${CYAN}│${RESET}\n" \
    "$num" "$size_h" "$display_path"
done

echo -e "  ${BOLD}${CYAN}└──────┴────────────┴───────────────────────────────────────────────────┘${RESET}"
echo ""
echo -e "  ${BOLD}Total encontrados:${RESET} ${#NM_PATHS[@]} carpetas  |  ${BOLD}Espacio total:${RESET} ${RED}${BOLD}$(human_size "$TOTAL_BYTES")${RESET}"
echo ""

# ── Leyenda colores ────────────────────────────────────
echo -e "  ${DIM}Leyenda tamaños:  ${GREEN}● < 100 MB${RESET}${DIM}   ${YELLOW}● 100–499 MB${RESET}${DIM}   ${RED}● ≥ 500 MB${RESET}"
echo ""

# ── Menú de selección ──────────────────────────────────
echo -e "  ${BOLD}¿Qué querés hacer?${RESET}"
echo ""
echo -e "   ${CYAN}[a]${RESET}  Borrar ${BOLD}TODAS${RESET} las carpetas"
echo -e "   ${CYAN}[n]${RESET}  Ingresar números separados por coma  ${DIM}(ej: 1,3,5)${RESET}"
echo -e "   ${CYAN}[q]${RESET}  Salir sin borrar nada"
echo ""
printf "  ${BOLD}→ ${RESET}"
read -r CHOICE
echo ""

# ── Procesar elección ──────────────────────────────────
TO_DELETE=()

case "${CHOICE,,}" in
  q|"")
    echo -e "  ${DIM}Saliendo... no se borró nada.${RESET}"
    echo ""
    exit 0
    ;;
  a)
    TO_DELETE=("${NM_PATHS[@]}")
    ;;
  *)
    # Parsear números separados por coma/espacio
    IFS=', ' read -ra NUMS <<< "$CHOICE"
    for n in "${NUMS[@]}"; do
      if [[ "$n" =~ ^[0-9]+$ ]]; then
        idx=$(( n - 1 ))
        if (( idx >= 0 && idx < ${#NM_PATHS[@]} )); then
          TO_DELETE+=("${NM_PATHS[$idx]}")
        else
          echo -e "  ${YELLOW}⚠ Número ${n} fuera de rango, ignorado.${RESET}"
        fi
      else
        echo -e "  ${YELLOW}⚠ '${n}' no es un número válido, ignorado.${RESET}"
      fi
    done
    ;;
esac

if [[ ${#TO_DELETE[@]} -eq 0 ]]; then
  echo -e "  ${YELLOW}No se seleccionó ninguna carpeta válida.${RESET}"
  echo ""
  exit 0
fi

# ── Confirmación ───────────────────────────────────────
DELETE_BYTES=0
echo -e "  ${BOLD}Se van a borrar las siguientes carpetas:${RESET}"
echo ""
for path in "${TO_DELETE[@]}"; do
  for i in "${!NM_PATHS[@]}"; do
    if [[ "${NM_PATHS[$i]}" == "$path" ]]; then
      DELETE_BYTES=$(( DELETE_BYTES + SIZES_BYTES[i] ))
      echo -e "   ${RED}✗${RESET}  ${DIM}${path}${RESET}  ${YELLOW}(${SIZES_HUMAN[$i]})${RESET}"
      break
    fi
  done
done

echo ""
echo -e "  ${BOLD}Espacio a liberar: ${RED}$(human_size "$DELETE_BYTES")${RESET}"
echo ""
printf "  ${BOLD}${RED}¿Confirmar borrado? [s/N]:${RESET} "
read -r CONFIRM
echo ""

if [[ "${CONFIRM,,}" != "s" ]]; then
  echo -e "  ${DIM}Operación cancelada. No se borró nada.${RESET}"
  echo ""
  exit 0
fi

# ── Borrar ─────────────────────────────────────────────
DELETED=0
ERRORS=0

for path in "${TO_DELETE[@]}"; do
  printf "  ${DIM}Borrando${RESET}  %-55s " "${path: -55}"
  if rm -rf "$path" 2>/dev/null; then
    echo -e "${GREEN}✓${RESET}"
    (( DELETED++ )) || true
  else
    echo -e "${RED}✗ error${RESET}"
    (( ERRORS++ )) || true
  fi
done

echo ""
echo -e "  ${BOLD}${GREEN}✓ Listo!${RESET}  Borradas: ${BOLD}${DELETED}${RESET}  |  Liberado: ${BOLD}${GREEN}$(human_size "$DELETE_BYTES")${RESET}"
[[ $ERRORS -gt 0 ]] && echo -e "  ${YELLOW}⚠ ${ERRORS} carpeta(s) no se pudieron borrar (revisar permisos)${RESET}"
echo ""
