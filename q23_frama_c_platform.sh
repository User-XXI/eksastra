#!/usr/bin/env bash
set -euo pipefail

# Вопрос 23: Инструменты дедуктивной верификации программ (платформа Frama-C)

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
  echo "$(bold 'Вопрос 23: Платформа Frama-C для верификации')"
  hr
}

block_0_intro(){
  title
  echo "$(bold '0) Frama-C — платформа для анализа и верификации C кода')"
  hr
  echo "Frama-C предоставляет:"
  echo "  1. Парсинг и анализ C кода"
  echo "  2. Поддержку ACSL спецификаций"
  echo "  3. Различные плагины для анализа"
  echo "  4. Интеграцию с Why3 для доказательств"
  echo "  5. Инструменты для верификации"
  hr
  pause
}

block_1_frama_c_installation(){
  title
  echo "$(bold '1) Проверка установки Frama-C')"
  hr
  
  run_cmd "command -v frama-c >/dev/null && frama-c -version 2>/dev/null || echo 'Frama-C не установлен'" \
    "Версия Frama-C (если установлен)"
  
  run_cmd "dpkg -l | grep -i frama | head -15 || rpm -qa | grep -i frama | head -15 || echo 'Пакеты Frama-C не найдены'" \
    "Установленные пакеты Frama-C"
  
  run_cmd "find /usr -name '*frama*' 2>/dev/null | head -10 || echo 'Файлы Frama-C не найдены'" \
    "Поиск файлов Frama-C в системе"
  
  if have frama-c; then
    run_cmd "frama-c -help 2>/dev/null | head -30" \
      "Справка по использованию Frama-C"
  fi
}

block_2_frama_c_plugins(){
  title
  echo "$(bold '2) Плагины Frama-C')"
  hr
  
  if have frama-c; then
    run_cmd "frama-c -plugins 2>/dev/null | head -30 || echo 'Список плагинов недоступен'" \
      "Доступные плагины Frama-C"
  fi
  
  echo "$(bold 'Основные плагины:')"
  echo "  - WP (Weakest Precondition): верификация через weakest precondition"
  echo "  - Value: анализ значений"
  echo "  - E-ACSL: runtime проверка ACSL"
  echo "  - From: анализ потоков данных"
  echo "  - Sparecode: поиск неиспользуемого кода"
  hr
}

block_3_wp_plugin(){
  title
  echo "$(bold '3) Плагин WP (Weakest Precondition) для верификации')"
  hr
  
  if have frama-c; then
    run_cmd "frama-c -wp-help 2>/dev/null | head -40 || echo 'WP плагин недоступен'" \
      "Справка по плагину WP"
  fi
  
  echo "$(bold 'WP плагин:')"
  echo "  - Генерирует задачи верификации из ACSL спецификаций"
  echo "  - Интегрируется с Why3 для доказательств"
  echo "  - Поддерживает различные проверы теорем"
  echo "  - Автоматическая верификация контрактов"
  hr
  
  if have frama-c; then
    echo "$(grn 'Использование: frama-c -wp file.c')"
    echo "$(grn 'Или: frama-c -wp -wp-prover alt-ergo file.c')"
  fi
}

block_4_why3_integration(){
  title
  echo "$(bold '4) Интеграция с Why3')"
  hr
  
  run_cmd "command -v why3 >/dev/null && why3 --version 2>/dev/null || echo 'Why3 не установлен'" \
    "Проверка наличия Why3"
  
  if have why3; then
    run_cmd "why3 list-provers 2>/dev/null | head -20 || echo 'Список проверов недоступен'" \
      "Доступные проверы теорем в Why3"
  fi
  
  echo "$(bold 'Интеграция Frama-C и Why3:')"
  echo "  - Frama-C генерирует задачи для Why3"
  echo "  - Why3 распределяет задачи по проверам"
  echo "  - Проверы доказывают свойства"
  echo "  - Результаты возвращаются в Frama-C"
  hr
}

block_5_verification_example(){
  title
  echo "$(bold '5) Пример процесса верификации')"
  hr
  
  echo "$(bold 'Процесс верификации с Frama-C:')"
  echo "  1. Написание C кода с ACSL аннотациями"
  echo "  2. Запуск Frama-C с плагином WP: frama-c -wp file.c"
  echo "  3. Генерация задач верификации"
  echo "  4. Автоматическое доказательство через Why3"
  echo "  5. Анализ результатов"
  hr
  
  cat <<'EXAMPLE'
Пример файла для верификации (example.c):
/*@ requires x >= 0;
    ensures \result >= 0 && \result == x * x;
*/
int square(int x) {
  return x * x;
}

Команда верификации:
frama-c -wp example.c
EXAMPLE
  hr
}

block_6_frama_c_features(){
  title
  echo "$(bold '6) Возможности Frama-C')"
  hr
  
  echo "$(bold 'Анализ:')"
  echo "  - Статический анализ кода"
  echo "  - Анализ значений"
  echo "  - Анализ потоков данных"
  echo "  - Поиск ошибок"
  hr
  
  echo "$(bold 'Верификация:')"
  echo "  - Дедуктивная верификация через WP"
  echo "  - Runtime проверка через E-ACSL"
  echo "  - Доказательство корректности"
  hr
  
  if have frama-c; then
    run_cmd "frama-c -kernel-help 2>/dev/null | head -30 || echo 'Справка недоступна'" \
      "Основные опции Frama-C"
  fi
}

block_7_summary(){
  title
  echo "$(bold 'Итог: платформа Frama-C')"
  hr
  cat <<'EOF'
Платформа Frama-C для верификации:

1. Назначение:
   - Анализ и верификация C кода
   - Поддержка ACSL спецификаций
   - Дедуктивная верификация

2. Архитектура:
   - Модульная структура с плагинами
   - Поддержка различных типов анализа
   - Интеграция с внешними инструментами

3. Основные плагины:
   - WP: верификация через weakest precondition
   - Value: анализ значений
   - E-ACSL: runtime проверка
   - From: анализ потоков данных

4. Интеграция с Why3:
   - Генерация задач верификации
   - Автоматическое доказательство
   - Поддержка различных проверов

5. Процесс верификации:
   - Написание кода с ACSL аннотациями
   - Запуск Frama-C с плагином WP
   - Генерация и доказательство задач
   - Анализ результатов

6. Применение:
   - Верификация критичного кода
   - Доказательство безопасности
   - Соответствие спецификациям
EOF
  hr
  pause
}

menu(){
  title
  echo "  0) Введение"
  echo "  1) Проверка установки"
  echo "  2) Плагины Frama-C"
  echo "  3) Плагин WP"
  echo "  4) Интеграция с Why3"
  echo "  5) Пример верификации"
  echo "  6) Возможности Frama-C"
  echo "  7) Итог"
  echo "  a) Всё по порядку"
  echo "  q) Выход"
  read -r -p "$(dim 'Выбор: ')" ch
  case "$ch" in
    0) block_0_intro ;;
    1) block_1_frama_c_installation ;;
    2) block_2_frama_c_plugins ;;
    3) block_3_wp_plugin ;;
    4) block_4_why3_integration ;;
    5) block_5_verification_example ;;
    6) block_6_frama_c_features ;;
    7) block_7_summary ;;
    a|A)
      block_0_intro
      block_1_frama_c_installation
      block_2_frama_c_plugins
      block_3_wp_plugin
      block_4_why3_integration
      block_5_verification_example
      block_6_frama_c_features
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

