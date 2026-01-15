#!/usr/bin/env bash
set -euo pipefail

# Вопрос 7: Основные принципы реализации мандатного управления доступом в ОССН

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
  echo "$(bold 'Вопрос 7: Принципы мандатного управления доступом (МРД)')"
  hr
}

block_0_intro(){
  title
  echo "$(bold '0) Основные принципы МРД')"
  hr
  echo "Принципы мандатного контроля:"
  echo "  1. Маркировка объектов уровнями безопасности"
  echo "  2. Маркировка субъектов (процессов) уровнями"
  echo "  3. Правило простой безопасности (чтение: уровень субъекта >= объекта)"
  echo "  4. Правило *-свойства (запись: уровень субъекта <= объекта)"
  echo "  5. Невозможность обхода политики (даже root подчиняется)"
  hr
  pause
}

block_1_labeling(){
  title
  echo "$(bold '1) Маркировка объектов и субъектов')"
  hr
  
  echo "Объекты имеют метки (security.* атрибуты):"
  echo "  - security.PDPL: полная метка мандатного доступа"
  echo "  - security.CLEV: уровень конфиденциальности"
  echo "  - security.ILEV: уровень целостности"
  hr
  
  run_cmd "getfattr -n security.PDPL -m security.PDPL /etc/passwd 2>/dev/null | head -3 || echo 'PDPL метка не найдена'" \
    "Проверка PDPL метки на объекте"
  
  run_cmd "getfattr -n security.CLEV -m security.CLEV /etc/shadow 2>/dev/null | head -3 || echo 'CLEV не найден'" \
    "Уровень конфиденциальности объекта"
  
  run_cmd "getfattr -n security.ILEV -m security.ILEV /bin/bash 2>/dev/null | head -3 || echo 'ILEV не найден'" \
    "Уровень целостности объекта"
  
  run_cmd "ps aux | head -5" "Процессы (субъекты) также имеют уровни"
}

block_2_parsec_implementation(){
  title
  echo "$(bold '2) Реализация через PARSEC (в ядре)')"
  hr
  
  run_cmd "lsmod | grep -i parsec || echo 'PARSEC не загружен'" \
    "PARSEC модуль — реализация МРД на уровне ядра"
  
  run_cmd "cat /sys/module/parsec/parameters/* 2>/dev/null | head -20 || echo 'Параметры недоступны'" \
    "Параметры политики МРД"
  
  run_cmd "cat /sys/module/parsec/parameters/max_ilev 2>/dev/null || echo 'max_ilev недоступен'" \
    "Максимальный уровень целостности (потолок системы)"
  
  run_cmd "dmesg | grep -i parsec | tail -10 || true" \
    "Инициализация PARSEC при загрузке"
}

block_3_access_rules(){
  title
  echo "$(bold '3) Правила контроля доступа')"
  hr
  echo "Правило простой безопасности (чтение):"
  echo "  Субъект может читать объект, если:"
  echo "  - Уровень субъекта >= Уровень объекта"
  echo "  - Категории субъекта включают категории объекта"
  hr
  echo "Правило *-свойства (запись):"
  echo "  Субъект может писать объект, если:"
  echo "  - Уровень субъекта <= Уровень объекта"
  echo "  - Категории объекта включаются в категории субъекта"
  hr
  
  run_cmd "cat /sys/module/parsec/parameters/mac_enabled 2>/dev/null || echo 'Параметр недоступен'" \
    "Проверка включения МРД"
}

block_4_enforcement(){
  title
  echo "$(bold '4) Принудительное выполнение политики')"
  hr
  echo "Монитор ссылок (Reference Monitor):"
  echo "  - Все операции проходят через проверку"
  echo "  - Нельзя обойти даже с правами root"
  echo "  - Решения принимаются на основе меток"
  hr
  
  run_cmd "id" "Текущий пользователь (даже root подчиняется МРД)"
  
  run_cmd "systemctl status auditd --no-pager 2>/dev/null | head -5 || echo 'auditd недоступен'" \
    "Аудит фиксирует все проверки доступа"
  
  if have auditctl; then
    run_cmd "sudo auditctl -l 2>/dev/null | grep -i 'access\|denied' | head -10 || true" \
      "Правила аудита контроля доступа"
  fi
}

block_5_practical_demo(){
  title
  echo "$(bold '5) Практическая демонстрация (если DEMO_MUTATE=1)')"
  hr
  
  if [[ "$DEMO_MUTATE" == "1" ]]; then
    DEMO_DIR="/tmp/mrd_demo_$$"
    run_cmd "mkdir -p \"$DEMO_DIR\" && echo 'data' > \"$DEMO_DIR/file1\"" \
      "Создание тестовых объектов"
    
    if have pdpl-file; then
      run_cmd "sudo pdpl-file 3:0:-1:CCNR \"$DEMO_DIR/file1\" 2>/dev/null || echo 'Не удалось установить метку (возможны ограничения)'" \
        "Установка мандатной метки на объект"
      
      run_cmd "getfattr -d -m 'security\\.' \"$DEMO_DIR/file1\" 2>/dev/null || echo 'Метки не найдены'" \
        "Проверка установленной метки"
    fi
    
    run_cmd "rm -rf \"$DEMO_DIR\"" "Очистка"
  else
    echo "$(ylw 'DEMO_MUTATE=0: пропускаю практику. Запусти с DEMO_MUTATE=1 для демонстрации')"
  fi
}

block_6_summary(){
  title
  echo "$(bold 'Итог: принципы МРД')"
  hr
  cat <<'EOF'
Основные принципы МРД в ОССН:

1. Маркировка:
   - Все объекты и субъекты имеют уровни безопасности
   - Хранятся в расширенных атрибутах (security.*)

2. Правила доступа:
   - Простое правило безопасности (чтение)
   - *-свойство (запись)
   - На основе сравнения уровней

3. Реализация:
   - PARSEC модуль в ядре
   - Проверка на каждом обращении
   - Невозможность обхода

4. Гарантии:
   - Монитор ссылок (Reference Monitor)
   - Аудит всех проверок
   - Даже root подчиняется политике
EOF
  hr
  pause
}

menu(){
  title
  echo "  0) Введение в принципы"
  echo "  1) Маркировка объектов/субъектов"
  echo "  2) Реализация через PARSEC"
  echo "  3) Правила доступа"
  echo "  4) Принудительное выполнение"
  echo "  5) Практическая демонстрация"
  echo "  6) Итог"
  echo "  a) Всё по порядку"
  echo "  q) Выход"
  read -r -p "$(dim 'Выбор: ')" ch
  case "$ch" in
    0) block_0_intro ;;
    1) block_1_labeling ;;
    2) block_2_parsec_implementation ;;
    3) block_3_access_rules ;;
    4) block_4_enforcement ;;
    5) block_5_practical_demo ;;
    6) block_6_summary ;;
    a|A)
      block_0_intro
      block_1_labeling
      block_2_parsec_implementation
      block_3_access_rules
      block_4_enforcement
      block_5_practical_demo
      block_6_summary
      ;;
    q|Q) exit 0 ;;
    *) echo "$(ylw 'Не понял')"; pause ;;
  esac
}

while true; do
  menu
  pause
done

