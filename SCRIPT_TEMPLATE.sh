#!/usr/bin/env bash
# Шаблон для создания скриптов вопросов 9-25
# Скопируйте этот файл и адаптируйте под конкретный вопрос

set -euo pipefail

# Вопрос N: [НАЗВАНИЕ ВОПРОСА]

DEMO_MUTATE="${DEMO_MUTATE:-0}"
AUTO_ENTER="${AUTO_ENTER:-0}"
USE_SUDO="${USE_SUDO:-auto}"

bold(){ printf "\033[1m%s\033[0m" "$*"; }
dim(){  printf "\033[2m%s\033[0m" "$*"; }
cyan(){ printf "\033[36m%s\033[0m" "$*"; }
grn(){  printf "\033[32m%s\033[0m" "$*"; }
ylw(){  printf "\033[33m%s\033[0m" "$*"; }
hr(){ printf "%s\n" "$(dim '---------------------------------------------------------------------')"; }

pause(){
  [[ "$AUTO_ENTER" == "1" ]] && return 0
  echo
  read -r -p "$(dim 'Enter — дальше... ')" _
}

have(){ command -v "$1" >/dev/null 2>&1; }
need_sudo(){
  case "$USE_SUDO" in
    always) return 0 ;;
    never)  return 1 ;;
    auto)
      if [[ "$(id -u)" -ne 0 ]] && have sudo; then return 0; else return 1; fi
      ;;
  esac
}

run_cmd(){
  local cmd="$1"
  local why="${2:-}"
  echo
  [[ -n "$why" ]] && echo "$(bold 'Зачем:') $why"
  echo "$(cyan '$') $cmd"
  pause
  if need_sudo; then
    if [[ "$cmd" =~ ^sudo[[:space:]] ]]; then
      bash -lc "$cmd" 2>&1 || true
    else
      sudo bash -lc "$cmd" 2>&1 || bash -lc "$cmd" 2>&1 || true
    fi
  else
    bash -lc "$cmd" 2>&1 || true
  fi
}

title(){
  clear || true
  echo "$(bold 'Вопрос N: [НАЗВАНИЕ]')"
  hr
}

# ========================================
# БЛОКИ ДЕМОНСТРАЦИИ
# Адаптируйте под конкретный вопрос
# ========================================

block_0_intro(){
  title
  echo "$(bold '0) Введение')"
  hr
  echo "[ОПИСАНИЕ ТЕМЫ ВОПРОСА]"
  hr
  pause
}

block_1_demo(){
  title
  echo "$(bold '1) [НАЗВАНИЕ БЛОКА]')"
  hr
  run_cmd "[КОМАНДА]" "[ОБЪЯСНЕНИЕ]"
  # Добавьте больше команд по необходимости
}

# ... добавьте больше блоков ...

block_N_summary(){
  title
  echo "$(bold 'Итог: [НАЗВАНИЕ]')"
  hr
  cat <<'EOF'
[ИТОГОВАЯ СВОДКА]
EOF
  hr
  pause
}

# ========================================
# МЕНЮ
# ========================================

menu(){
  title
  echo "Выбери блок для демонстрации:"
  echo
  echo "  0) Введение"
  # Добавьте пункты меню для каждого блока
  echo "  N) Итог"
  echo "  a) Пройти всё по порядку"
  echo "  q) Выход"
  echo
  read -r -p "$(dim 'Твой выбор: ')" ch
  case "$ch" in
    0) block_0_intro ;;
    # Добавьте case для каждого блока
    N) block_N_summary ;;
    a|A)
      block_0_intro
      # Вызовите все блоки по порядку
      block_N_summary
      ;;
    q|Q) exit 0 ;;
    *) echo "$(ylw 'Не понял. Давай ещё раз.')"; pause ;;
  esac
}

while true; do
  menu
  pause
done

