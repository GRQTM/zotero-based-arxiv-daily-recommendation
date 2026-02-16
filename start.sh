#!/usr/bin/env bash
set -euo pipefail
umask 077

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_CODEX_BIN="/Applications/Codex.app/Contents/Resources/codex"
if [[ -n "${CODEX_BIN:-}" ]]; then
  CODEX_BIN="${CODEX_BIN}"
elif [[ -x "${DEFAULT_CODEX_BIN}" ]]; then
  CODEX_BIN="${DEFAULT_CODEX_BIN}"
else
  CODEX_BIN="$(command -v codex 2>/dev/null || true)"
fi
API_KEY="${ZOTERO_API_KEY:-}"
USER_ID="${ZOTERO_USER_ID:-}"
KEY_FILE="${ROOT_DIR}/.zotero_api_key"
USER_ID_FILE="${ROOT_DIR}/.zotero_user_id"
PROFILE_FILE="${ROOT_DIR}/context/zotero_recommendation_profile.md"
PROFILE_TEMPLATE_FILE="${ROOT_DIR}/templates/zotero_recommendation_profile.sample.md"

usage() {
  cat <<'EOF'
Usage:
  ./start       # Run recommendation only using existing/template profile
  ./start -r    # Refresh Zotero-based profile, then run recommendation
EOF
}

REFRESH_PROFILE=0
if [[ $# -gt 1 ]]; then
  usage
  exit 1
fi
if [[ $# -eq 1 ]]; then
  case "${1}" in
    -r|--refresh-profile)
      REFRESH_PROFILE=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: unknown option: ${1}"
      usage
      exit 1
      ;;
  esac
fi

if [[ -z "${CODEX_BIN}" || ! -x "${CODEX_BIN}" ]]; then
  echo "Error: codex binary not found."
  echo "Set CODEX_BIN or install Codex desktop app/CLI."
  exit 1
fi

mkdir -p "${ROOT_DIR}/data" "${ROOT_DIR}/context" "${ROOT_DIR}/outputs" "${ROOT_DIR}/logs"

if [[ -z "${USER_ID}" && -f "${USER_ID_FILE}" ]]; then
  USER_ID="$(tr -d '[:space:]' < "${USER_ID_FILE}")"
fi

if [[ "${REFRESH_PROFILE}" -eq 1 ]]; then
  if [[ -z "${API_KEY}" && ! -f "${KEY_FILE}" ]]; then
    cat > "${KEY_FILE}" <<'EOF'
# Paste your Zotero API key on the first line (no quotes).
EOF
    chmod 600 "${KEY_FILE}" || true
    echo "Created ${KEY_FILE} template."
    echo "Please paste your Zotero API key into that file, then run ./start -r again."
    exit 1
  fi
  if [[ -z "${API_KEY}" && -f "${KEY_FILE}" ]]; then
    chmod 600 "${KEY_FILE}" || true
    API_KEY="$(tr -d '[:space:]' < "${KEY_FILE}")"
  fi
  if [[ -z "${API_KEY}" ]]; then
    echo "Error: Zotero API key not found."
    echo "Set ZOTERO_API_KEY or create .zotero_api_key in this folder."
    exit 1
  fi

  echo "[1/4] Fetching Zotero library metadata..."
  if [[ -n "${USER_ID}" ]]; then
    ZOTERO_API_KEY="${API_KEY}" python3 "${ROOT_DIR}/scripts/fetch_zotero_library.py" \
      --user-id "${USER_ID}" \
      --output "${ROOT_DIR}/data/zotero_items.json" \
      --summary "${ROOT_DIR}/data/zotero_items_summary.md"
  else
    ZOTERO_API_KEY="${API_KEY}" python3 "${ROOT_DIR}/scripts/fetch_zotero_library.py" \
      --output "${ROOT_DIR}/data/zotero_items.json" \
      --summary "${ROOT_DIR}/data/zotero_items_summary.md"
  fi
  unset API_KEY

  echo "[2/4] Building Zotero-based recommendation profile..."
  env -u ZOTERO_API_KEY "${CODEX_BIN}" exec --full-auto --skip-git-repo-check --cd "${ROOT_DIR}" \
    -c model_reasoning_effort=\"high\" \
    - \
    < "${ROOT_DIR}/prompts/01_build_zotero_profile.prompt.md" \
    | tee "${ROOT_DIR}/logs/profile_run.log"
else
  if [[ ! -f "${PROFILE_FILE}" ]]; then
    if [[ -f "${PROFILE_TEMPLATE_FILE}" ]]; then
      cp "${PROFILE_TEMPLATE_FILE}" "${PROFILE_FILE}"
      echo "Initialized profile from template: ${PROFILE_FILE}"
    else
      echo "Error: ${PROFILE_FILE} does not exist."
      echo "Run ./start -r once to build the Zotero-based recommendation profile."
      exit 1
    fi
  fi
  echo "Using existing Zotero profile: ${PROFILE_FILE}"
fi

if [[ "${REFRESH_PROFILE}" -eq 1 ]]; then
  echo "[3/4] Fetching recent arXiv astro-ph papers..."
else
  echo "[1/2] Fetching recent arXiv astro-ph papers..."
fi
python3 "${ROOT_DIR}/scripts/fetch_arxiv_astro_ph.py" \
  --days 2 \
  --output "${ROOT_DIR}/data/arxiv_astro_ph_last2days.json" \
  --summary "${ROOT_DIR}/data/arxiv_astro_ph_last2days_summary.md"

if [[ "${REFRESH_PROFILE}" -eq 1 ]]; then
  echo "[4/4] Running recommendation prompt..."
else
  echo "[2/2] Running recommendation prompt..."
fi
env -u ZOTERO_API_KEY "${CODEX_BIN}" exec --full-auto --skip-git-repo-check --cd "${ROOT_DIR}" \
  -c model_reasoning_effort=\"high\" \
  - \
  < "${ROOT_DIR}/prompts/02_recommend_astro_ph_last2days.prompt.md" \
  | tee "${ROOT_DIR}/logs/recommend_run.log"

echo "Done. Check outputs:"
echo " - ${PROFILE_FILE}"
echo " - ${ROOT_DIR}/data/arxiv_astro_ph_last2days_summary.md"
