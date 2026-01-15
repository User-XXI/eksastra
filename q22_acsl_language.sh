#!/usr/bin/env bash
set -euo pipefail

# Вопрос 22: Инструменты дедуктивной верификации программ (язык ACSL)

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
  echo "$(bold 'Вопрос 22: Дедуктивная верификация программ (язык ACSL)')"
  hr
}

block_0_intro(){
  title
  echo "$(bold '0) Язык ACSL (ANSI/ISO C Specification Language)')"
  hr
  echo "ACSL используется для:"
  echo "  1. Спецификации свойств программ на C"
  echo "  2. Формального описания требований"
  echo "  3. Дедуктивной верификации программ"
  echo "  4. Доказательства корректности кода"
  hr
  pause
}

block_1_acsl_basics(){
  title
  echo "$(bold '1) Основы ACSL')"
  hr
  
  echo "$(bold 'Конструкции ACSL:')"
  echo "  - //@ requires P: предусловие функции"
  echo "  - //@ ensures Q: постусловие функции"
  echo "  - //@ assigns L: список изменяемых переменных"
  echo "  - //@ behavior: описание поведения"
  echo "  - //@ invariant: инвариант цикла"
  echo "  - //@ assert P: утверждение в коде"
  hr
  
  cat <<'EXAMPLE'
Пример спецификации ACSL:
/*@ requires x >= 0;
    ensures \result == x * x;
    assigns \nothing;
*/
int square(int x) {
  return x * x;
}
EXAMPLE
  hr
}

block_2_frama_c_check(){
  title
  echo "$(bold '2) Проверка наличия Frama-C (использует ACSL)')"
  hr
  
  run_cmd "command -v frama-c >/dev/null && frama-c -version 2>/dev/null || echo 'Frama-C не установлен'" \
    "Проверка наличия Frama-C (платформа верификации с поддержкой ACSL)"
  
  run_cmd "dpkg -l | grep -i 'frama' | head -10 || rpm -qa | grep -i frama | head -10 || echo 'Пакеты Frama-C не найдены'" \
    "Установленные пакеты Frama-C"
  
  if have frama-c; then
    run_cmd "frama-c -plugins 2>/dev/null | head -20 || echo 'Список плагинов недоступен'" \
      "Плагины Frama-C (включая верификацию)"
  fi
}

block_3_acsl_specifications(){
  title
  echo "$(bold '3) Типы спецификаций в ACSL')"
  hr
  
  echo "$(bold 'Спецификации:')"
  echo "  1. Предусловия (requires): условия, которые должны быть выполнены при вызове"
  echo "  2. Постусловия (ensures): условия, которые выполняются после завершения"
  echo "  3. Инварианты (invariant): условия, истинные на протяжении выполнения"
  echo "  4. Утверждения (assert): проверяемые условия в коде"
  echo "  5. Поведения (behavior): описание альтернативных вариантов поведения"
  hr
  
  echo "$(bold 'Примеры спецификаций:')"
  cat <<'EXAMPLE'
// Предусловие и постусловие
/*@ requires n > 0;
    ensures \result >= 0;
*/
int abs(int n);

// Инвариант цикла
/*@ loop invariant i <= n;
*/
for(int i = 0; i < n; i++) { ... }

// Утверждение
/*@ assert x > 0; */
EXAMPLE
  hr
}

block_4_why3_integration(){
  title
  echo "$(bold '4) Интеграция с Why3 (доказательство свойств)')"
  hr
  
  run_cmd "command -v why3 >/dev/null && why3 --version 2>/dev/null || echo 'Why3 не установлен'" \
    "Проверка наличия Why3 (платформа для доказательств)"
  
  if have why3; then
    run_cmd "why3 list-provers 2>/dev/null | head -10 || echo 'Список проверов недоступен'" \
      "Доступные проверы (доказатели теорем)"
  fi
  
  echo "$(bold 'Интеграция ACSL-Why3:')"
  echo "  - Frama-C генерирует задачи для Why3"
  echo "  - Why3 доказывает свойства программ"
  echo "  - Используются различные проверы (Alt-Ergo, Z3, CVC4 и др.)"
  hr
}

block_5_verification_process(){
  title
  echo "$(bold '5) Процесс верификации с ACSL')"
  hr
  
  echo "$(bold 'Этапы верификации:')"
  echo "  1. Написание спецификации в ACSL"
  echo "  2. Аннотирование кода спецификациями"
  echo "  3. Генерация задач верификации (Frama-C)"
  echo "  4. Доказательство свойств (Why3)"
  echo "  5. Анализ результатов верификации"
  hr
  
  if have frama-c; then
    echo "$(grn 'Frama-C доступен для демонстрации процесса верификации')"
    echo "$(dim 'Пример использования: frama-c -wp file.c')"
  else
    echo "$(ylw 'Frama-C не установлен. Для верификации нужен Frama-C с плагином WP.')"
  fi
  hr
}

block_6_acsl_contracts(){
  title
  echo "$(bold '6) Контракты в ACSL')"
  hr
  
  echo "$(bold 'Контракты функций:')"
  echo "  - requires: что функция ожидает на входе"
  echo "  - ensures: что функция гарантирует на выходе"
  echo "  - assigns: какие переменные функция может изменить"
  echo "  - allocates/deallocates: управление памятью"
  hr
  
  cat <<'EXAMPLE'
/*@ requires \valid(a) && \valid(b);
    requires *a >= 0 && *b >= 0;
    ensures *a == \old(*b) && *b == \old(*a);
    assigns *a, *b;
*/
void swap(int* a, int* b) {
  int tmp = *a;
  *a = *b;
  *b = tmp;
}
EXAMPLE
  hr
}

block_7_summary(){
  title
  echo "$(bold 'Итог: язык ACSL для верификации')"
  hr
  cat <<'EOF'
Язык ACSL для дедуктивной верификации:

1. Назначение:
   - Спецификация свойств программ на C
   - Формальное описание требований
   - Дедуктивная верификация

2. Основные конструкции:
   - requires: предусловия
   - ensures: постусловия
   - invariant: инварианты
   - assert: утверждения
   - behavior: поведения

3. Контракты функций:
   - Описание входных условий
   - Гарантии выходных условий
   - Контроль изменяемых переменных

4. Интеграция с инструментами:
   - Frama-C: анализ и генерация задач
   - Why3: доказательство свойств
   - Проверы: автоматические доказатели теорем

5. Процесс верификации:
   - Написание спецификаций
   - Аннотирование кода
   - Генерация задач
   - Доказательство свойств

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
  echo "  1) Основы ACSL"
  echo "  2) Проверка Frama-C"
  echo "  3) Типы спецификаций"
  echo "  4) Интеграция с Why3"
  echo "  5) Процесс верификации"
  echo "  6) Контракты в ACSL"
  echo "  7) Итог"
  echo "  a) Всё по порядку"
  echo "  q) Выход"
  read -r -p "$(dim 'Выбор: ')" ch
  case "$ch" in
    0) block_0_intro ;;
    1) block_1_acsl_basics ;;
    2) block_2_frama_c_check ;;
    3) block_3_acsl_specifications ;;
    4) block_4_why3_integration ;;
    5) block_5_verification_process ;;
    6) block_6_acsl_contracts ;;
    7) block_7_summary ;;
    a|A)
      block_0_intro
      block_1_acsl_basics
      block_2_frama_c_check
      block_3_acsl_specifications
      block_4_why3_integration
      block_5_verification_process
      block_6_acsl_contracts
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

