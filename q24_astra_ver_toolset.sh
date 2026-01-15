#!/usr/bin/env bash
set -euo pipefail

# Вопрос 24: Инструменты дедуктивной верификации программ (пакет Astra Ver Toolset)

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
  echo "$(bold 'Вопрос 24: Astra Ver Toolset')"
  hr
}

block_0_intro(){
  title
  echo "$(bold '0) Astra Ver Toolset — инструменты верификации для Astra Linux')"
  hr
  echo "Astra Ver Toolset включает:"
  echo "  1. Инструменты верификации программ"
  echo "  2. Поддержку ACSL спецификаций"
  echo "  3. Интеграцию с Frama-C"
  echo "  4. Специализированные инструменты для Astra"
  hr
  pause
}

block_1_package_check(){
  title
  echo "$(bold '1) Проверка наличия Astra Ver Toolset')"
  hr
  
  run_cmd "dpkg -l | grep -i 'astra.*ver\|ver.*toolset' | head -10 || echo 'Пакеты Astra Ver Toolset не найдены'" \
    "Поиск пакетов Astra Ver Toolset"
  
  run_cmd "dpkg -l | grep -i 'frama\|verif\|acsl' | head -15 || echo 'Пакеты верификации не найдены'" \
    "Связанные пакеты верификации"
  
  run_cmd "find /usr -name '*ver*' -o -name '*astra*ver*' 2>/dev/null | head -10 || echo 'Файлы Astra Ver не найдены'" \
    "Поиск файлов Astra Ver Toolset"
  
  run_cmd "find /opt -name '*ver*' -o -name '*astra*ver*' 2>/dev/null | head -10 || echo 'В /opt файлы не найдены'" \
    "Поиск в /opt (часто инструменты устанавливаются туда)"
}

block_2_toolset_components(){
  title
  echo "$(bold '2) Компоненты Astra Ver Toolset')"
  hr
  
  echo "$(bold 'Возможные компоненты:')"
  echo "  - Инструменты верификации на основе Frama-C"
  echo "  - Поддержка ACSL спецификаций"
  echo "  - Интеграция с Why3"
  echo "  - Специализированные проверки для Astra"
  echo "  - Документация и примеры"
  hr
  
  run_cmd "ls -la /usr/share/doc/*ver* 2>/dev/null | head -10 || echo 'Документация не найдена'" \
    "Документация по инструментам верификации"
  
  run_cmd "find /usr/share -name '*ver*' -o -name '*acsl*' 2>/dev/null | head -10 || echo 'Данные верификации не найдены'" \
    "Данные и примеры верификации"
}

block_3_integration(){
  title
  echo "$(bold '3) Интеграция с системой Astra Linux')"
  hr
  
  run_cmd "cat /etc/os-release | grep -i astra || echo 'Astra Linux не обнаружен'" \
    "Подтверждение системы Astra Linux"
  
  echo "$(bold 'Интеграция:')"
  echo "  - Инструменты адаптированы для Astra Linux SE"
  echo "  - Совместимость с политиками безопасности"
  echo "  - Поддержка специфичных компонентов Astra"
  hr
}

block_4_usage(){
  title
  echo "$(bold '4) Использование Astra Ver Toolset')"
  hr
  
  echo "$(bold 'Типичное использование:')"
  echo "  1. Подготовка кода с ACSL аннотациями"
  echo "  2. Запуск инструментов верификации"
  echo "  3. Анализ результатов"
  echo "  4. Доказательство свойств безопасности"
  hr
  
  run_cmd "command -v frama-c >/dev/null && echo 'Frama-C доступен (может быть частью Astra Ver)' || echo 'Frama-C не найден'" \
    "Проверка доступности базовых инструментов"
}

block_5_security_verification(){
  title
  echo "$(bold '5) Верификация безопасности в контексте Astra')"
  hr
  
  echo "$(bold 'Применение для верификации безопасности:')"
  echo "  - Верификация компонентов PARSEC"
  echo "  - Доказательство корректности критичного кода"
  echo "  - Проверка соответствия требованиям безопасности"
  echo "  - Верификация модулей системы безопасности"
  hr
  
  run_cmd "getfattr -n security.ILEV -m security.ILEV /usr/bin/* 2>/dev/null | head -5 || echo 'ILEV метки не найдены'" \
    "Связь с системой целостности (верифицированный код может иметь высокие уровни ILEV)"
}

block_6_documentation(){
  title
  echo "$(bold '6) Документация и примеры')"
  hr
  
  run_cmd "find /usr/share/doc -name '*verif*' -o -name '*acsl*' -o -name '*frama*' 2>/dev/null | head -10 || echo 'Документация не найдена'" \
    "Поиск документации по верификации"
  
  run_cmd "find /usr/share -name '*example*verif*' -o -name '*demo*verif*' 2>/dev/null | head -10 || echo 'Примеры не найдены'" \
    "Поиск примеров верификации"
}

block_7_summary(){
  title
  echo "$(bold 'Итог: Astra Ver Toolset')"
  hr
  cat <<'EOF'
Astra Ver Toolset для верификации:

1. Назначение:
   - Инструменты верификации для Astra Linux
   - Поддержка ACSL спецификаций
   - Дедуктивная верификация программ

2. Компоненты:
   - Инструменты на основе Frama-C
   - Интеграция с Why3
   - Специализированные проверки
   - Документация и примеры

3. Интеграция с Astra:
   - Адаптация для Astra Linux SE
   - Совместимость с политиками безопасности
   - Поддержка специфичных компонентов

4. Применение:
   - Верификация критичного кода
   - Доказательство безопасности компонентов
   - Проверка соответствия требованиям
   - Верификация модулей PARSEC

5. Использование:
   - Подготовка кода с ACSL
   - Запуск инструментов верификации
   - Анализ результатов
   - Доказательство свойств
EOF
  hr
  pause
}

menu(){
  title
  echo "  0) Введение"
  echo "  1) Проверка наличия"
  echo "  2) Компоненты Toolset"
  echo "  3) Интеграция с Astra"
  echo "  4) Использование"
  echo "  5) Верификация безопасности"
  echo "  6) Документация"
  echo "  7) Итог"
  echo "  a) Всё по порядку"
  echo "  q) Выход"
  read -r -p "$(dim 'Выбор: ')" ch
  case "$ch" in
    0) block_0_intro ;;
    1) block_1_package_check ;;
    2) block_2_toolset_components ;;
    3) block_3_integration ;;
    4) block_4_usage ;;
    5) block_5_security_verification ;;
    6) block_6_documentation ;;
    7) block_7_summary ;;
    a|A)
      block_0_intro
      block_1_package_check
      block_2_toolset_components
      block_3_integration
      block_4_usage
      block_5_security_verification
      block_6_documentation
      block_7_summary
      ;;
    q|Q) exit 0 ;;
    *) echo "$(ylw 'Не понял')"; pause ;;
  esac
}

while true; do
  menu
  pause
done

