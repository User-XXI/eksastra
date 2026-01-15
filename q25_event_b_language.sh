#!/usr/bin/env bash
set -euo pipefail

# Вопрос 25: Основные принципы построения формализованного языка Event-B

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
  echo "$(bold 'Вопрос 25: Основные принципы построения языка Event-B')"
  hr
}

block_0_intro(){
  title
  echo "$(bold '0) Event-B — формализованный язык для моделирования систем')"
  hr
  echo "Event-B основан на:"
  echo "  1. Теории множеств и логике первого порядка"
  echo "  2. Моделировании реактивных систем"
  echo "  3. Методе пошаговой разработки (refinement)"
  echo "  4. Автоматической верификации через доказательства"
  hr
  pause
}

block_1_event_b_structure(){
  title
  echo "$(bold '1) Структура Event-B модели')"
  hr
  
  echo "$(bold 'Компоненты Event-B модели:')"
  echo "  - Контексты (Contexts): определения типов и констант"
  echo "  - Машины (Machines): описание поведения системы"
  echo "  - Переменные (Variables): состояние системы"
  echo "  - Инварианты (Invariants): свойства, которые всегда истинны"
  echo "  - События (Events): операции, изменяющие состояние"
  hr
  
  echo "$(bold 'Пример структуры:')"
  cat <<'EXAMPLE'
MACHINE Example
VARIABLES x
INVARIANT x ∈ NAT
INITIALISATION x := 0
EVENTS
  Increment = 
    BEGIN
      x := x + 1
    END
END
EXAMPLE
  hr
}

block_2_refinement(){
  title
  echo "$(bold '2) Принцип пошаговой разработки (Refinement)')"
  hr
  
  echo "$(bold 'Refinement в Event-B:')"
  echo "  - Начальная модель: абстрактное описание системы"
  echo "  - Последовательные уточнения: добавление деталей"
  echo "  - Финальная модель: конкретная реализация"
  echo "  - Каждое уточнение доказывается корректным"
  hr
  
  echo "$(bold 'Преимущества:')"
  echo "  - Управление сложностью через абстракцию"
  echo "  - Постепенное добавление деталей"
  echo "  - Автоматическая проверка корректности уточнений"
  hr
}

block_3_events(){
  title
  echo "$(bold '3) События (Events) в Event-B')"
  hr
  
  echo "$(bold 'Структура события:')"
  echo "  - Имя события"
  echo "  - Условие (WHEN): когда событие может произойти"
  echo "  - Действие (THEN): что изменяется при событии"
  hr
  
  cat <<'EXAMPLE'
EVENT ExampleEvent
  WHEN
    x < 10
  THEN
    x := x + 1
  END
EXAMPLE
  hr
  
  echo "$(bold 'Типы событий:')"
  echo "  - Обычные события: с условиями и действиями"
  echo "  - Инициализация (INITIALISATION): начальное состояние"
  hr
}

block_4_invariants(){
  title
  echo "$(bold '4) Инварианты (Invariants)')"
  hr
  
  echo "$(bold 'Инварианты в Event-B:')"
  echo "  - Свойства, которые всегда истинны"
  echo "  - Проверяются до и после каждого события"
  echo "  - Обеспечивают корректность модели"
  hr
  
  cat <<'EXAMPLE'
INVARIANT
  x ∈ NAT ∧
  x ≤ 100
EXAMPLE
  hr
  
  echo "$(bold 'Типы инвариантов:')"
  echo "  - Типовые инварианты: определяют типы переменных"
  echo "  - Функциональные инварианты: определяют функции"
  echo "  - Свойства безопасности: требуемые свойства системы"
  hr
}

block_5_rodin_platform(){
  title
  echo "$(bold '5) Платформа Rodin для работы с Event-B')"
  hr
  
  run_cmd "command -v rodin >/dev/null && rodin -version 2>/dev/null || echo 'Rodin не установлен'" \
    "Проверка наличия Rodin (платформа для Event-B)"
  
  run_cmd "dpkg -l | grep -i rodin | head -10 || rpm -qa | grep -i rodin | head -10 || echo 'Пакеты Rodin не найдены'" \
    "Установленные пакеты Rodin"
  
  run_cmd "find /usr -name '*rodin*' 2>/dev/null | head -10 || echo 'Файлы Rodin не найдены'" \
    "Поиск файлов Rodin"
  
  if have rodin; then
    echo "$(grn 'Rodin доступен для работы с Event-B моделями')"
  else
    echo "$(ylw 'Rodin обычно запускается как Eclipse-плагин или отдельное приложение')"
  fi
  hr
}

block_6_proof(){
  title
  echo "$(bold '6) Автоматическое доказательство в Event-B')"
  hr
  
  echo "$(bold 'Процесс доказательства:')"
  echo "  - Генерация обязательств для доказательства (PO - Proof Obligations)"
  echo "  - Автоматическое доказательство простых обязательств"
  echo "  - Интерактивное доказательство сложных обязательств"
  echo "  - Проверка корректности уточнений"
  hr
  
  echo "$(bold 'Обязательства для доказательства:')"
  echo "  - Корректность инициализации"
  echo "  - Сохранение инвариантов при событиях"
  echo "  - Корректность уточнений (refinement)"
  hr
}

block_7_applications(){
  title
  echo "$(bold '7) Применение Event-B')"
  hr
  
  echo "$(bold 'Области применения:')"
  echo "  - Моделирование реактивных систем"
  echo "  - Разработка встраиваемых систем"
  echo "  - Верификация протоколов"
  echo "  - Моделирование систем безопасности"
  hr
  
  echo "$(bold 'В контексте Astra Linux SE:')"
  echo "  - Моделирование компонентов системы безопасности"
  echo "  - Верификация протоколов PARSEC"
  echo "  - Доказательство свойств безопасности"
  hr
}

block_8_summary(){
  title
  echo "$(bold 'Итог: основные принципы Event-B')"
  hr
  cat <<'EOF'
Основные принципы построения Event-B:

1. Основа:
   - Теория множеств и логика первого порядка
   - Моделирование реактивных систем
   - Формализованный язык спецификаций

2. Структура модели:
   - Контексты: типы и константы
   - Машины: поведение системы
   - Переменные: состояние системы
   - Инварианты: свойства системы
   - События: операции над состоянием

3. Принцип пошаговой разработки:
   - Refinement: уточнение модели
   - Абстракция → Детализация
   - Доказательство корректности уточнений

4. События:
   - WHEN: условия срабатывания
   - THEN: действия при событии
   - Инициализация начального состояния

5. Инварианты:
   - Свойства, всегда истинные
   - Проверка до и после событий
   - Обеспечение корректности

6. Платформа Rodin:
   - Инструмент для работы с Event-B
   - Генерация обязательств для доказательства
   - Автоматическое и интерактивное доказательство

7. Применение:
   - Моделирование реактивных систем
   - Верификация протоколов
   - Разработка встраиваемых систем
   - Моделирование систем безопасности
EOF
  hr
  pause
}

menu(){
  title
  echo "  0) Введение"
  echo "  1) Структура Event-B модели"
  echo "  2) Принцип Refinement"
  echo "  3) События"
  echo "  4) Инварианты"
  echo "  5) Платформа Rodin"
  echo "  6) Автоматическое доказательство"
  echo "  7) Применение"
  echo "  8) Итог"
  echo "  a) Всё по порядку"
  echo "  q) Выход"
  read -r -p "$(dim 'Выбор: ')" ch
  case "$ch" in
    0) block_0_intro ;;
    1) block_1_event_b_structure ;;
    2) block_2_refinement ;;
    3) block_3_events ;;
    4) block_4_invariants ;;
    5) block_5_rodin_platform ;;
    6) block_6_proof ;;
    7) block_7_applications ;;
    8) block_8_summary ;;
    a|A)
      block_0_intro
      block_1_event_b_structure
      block_2_refinement
      block_3_events
      block_4_invariants
      block_5_rodin_platform
      block_6_proof
      block_7_applications
      block_8_summary
      ;;
    q|Q) exit 0 ;;
    *) echo "$(ylw 'Не понял')"; pause ;;
  esac
}

while true; do
  menu
  pause
done

