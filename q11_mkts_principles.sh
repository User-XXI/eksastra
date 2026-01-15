#!/usr/bin/env bash
set -euo pipefail

# Вопрос 11: Основные принципы мандатного контроля целостности в ОССН

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
  echo "$(bold 'Вопрос 11: Принципы мандатного контроля целостности (МКЦ)')"
  hr
}

block_0_intro(){
  title
  echo "$(bold '0) Основные принципы МКЦ')"
  hr
  echo "Мандатный контроль целостности:"
  echo "  1. Защита от модификации данных низкоцелостными процессами"
  echo "  2. Модель Biba: нельзя писать в высокоцелостные объекты из низких уровней"
  echo "  3. Контроль выполнения: низкоцелостный процесс не может выполнить высокоцелостный код"
  echo "  4. Изоляция уровней целостности"
  echo "  5. Гарантирование неизменности критических данных"
  hr
  pause
}

block_1_integrity_levels(){
  title
  echo "$(bold '1) Уровни целостности (ILEV)')"
  hr
  
  run_cmd "cat /sys/module/parsec/parameters/max_ilev 2>/dev/null || echo 'max_ilev недоступен'" \
    "Максимальный уровень целостности системы (потолок)"
  
  run_cmd "getfattr -n security.ILEV -m security.ILEV /bin/bash 2>/dev/null | head -3 || echo 'ILEV метка не найдена'" \
    "Уровень целостности исполняемого файла"
  
  run_cmd "getfattr -n security.ILEV -m security.ILEV /etc/passwd 2>/dev/null | head -3 || echo 'ILEV метка не найдена'" \
    "Уровень целостности системного файла"
  
  echo "$(bold 'Уровни целостности определяют доверенность объектов:')"
  echo "  - Высокий ILEV: критичные системные файлы, исполняемые"
  echo "  - Низкий ILEV: пользовательские данные, временные файлы"
  hr
}

block_2_biba_model(){
  title
  echo "$(bold '2) Модель Biba (принципы контроля целостности)')"
  hr
  echo "Правила модели Biba:"
  echo "  1. Простое правило целостности: субъект может читать объект, если ILEV(субъекта) <= ILEV(объекта)"
  echo "  2. Правило *-свойства целостности: субъект может писать объект, если ILEV(субъекта) >= ILEV(объекта)"
  echo "  3. Запрет на деградацию: нельзя писать в высокоцелостный объект из низкого уровня"
  hr
  
  run_cmd "cat /sys/module/parsec/parameters/integrity_enabled 2>/dev/null || echo 'Параметр недоступен'" \
    "Проверка включения контроля целостности"
  
  run_cmd "cat /sys/module/parsec/parameters/*integrity* 2>/dev/null || echo 'Параметры целостности не найдены'" \
    "Параметры контроля целостности"
  
  echo "$(bold 'Практическое применение:')"
  echo "  - Пользовательский процесс (низкий ILEV) не может модифицировать системные файлы (высокий ILEV)"
  echo "  - Низкоцелостный скрипт не может выполнить высокоцелостный исполняемый файл"
  hr
}

block_3_execution_control(){
  title
  echo "$(bold '3) Контроль выполнения по целостности')"
  hr
  
  run_cmd "getfattr -n security.ILEV -m security.ILEV /bin/bash 2>/dev/null | head -3 || echo 'ILEV не найден'" \
    "Уровень целостности интерпретатора"
  
  run_cmd "getfattr -n security.ILEV -m security.ILEV /usr/bin/* 2>/dev/null | head -10 || echo 'ILEV метки не найдены'" \
    "Уровни целостности системных утилит"
  
  echo "$(bold 'Контроль выполнения:')"
  echo "  - Процесс наследует уровень целостности от родительского процесса"
  echo "  - При выполнении проверяется уровень целостности исполняемого файла"
  echo "  - Низкоцелостный процесс не может выполнить высокоцелостный код"
  hr
  
  run_cmd "ps aux | head -5" "Текущие процессы (каждый имеет уровень целостности)"
}

block_4_integrity_isolation(){
  title
  echo "$(bold '4) Изоляция уровней целостности')"
  hr
  
  echo "Принципы изоляции:"
  echo "  - Данные разного уровня целостности изолированы"
  echo "  - Невозможность неконтролируемой модификации"
  echo "  - Защита критических системных компонентов"
  hr
  
  run_cmd "cat /sys/module/parsec/parameters/* 2>/dev/null | grep -i 'strict\|isolat' | head -5 || echo 'Параметры изоляции не найдены'" \
    "Параметры изоляции в PARSEC"
  
  if [[ "$DEMO_MUTATE" == "1" ]]; then
    DEMO_DIR="/tmp/integrity_demo_$$"
    run_cmd "mkdir -p \"$DEMO_DIR\" && echo 'low integrity' > \"$DEMO_DIR\"/low_file" \
      "Создаю тестовый файл с низкой целостностью"
    
    run_cmd "getfattr -n security.ILEV -m security.ILEV \"$DEMO_DIR\"/low_file 2>/dev/null || echo 'ILEV не установлен'" \
      "Проверка уровня целостности"
    
    run_cmd "rm -rf \"$DEMO_DIR\"" "Очистка"
  fi
}

block_5_parsec_integrity(){
  title
  echo "$(bold '5) Реализация МКЦ через PARSEC')"
  hr
  
  run_cmd "lsmod | grep -i parsec || echo 'PARSEC не загружен'" \
    "Модуль PARSEC — обеспечивает контроль целостности"
  
  run_cmd "cat /sys/module/parsec/parameters/* 2>/dev/null | head -30 || echo 'Параметры недоступны'" \
    "Параметры PARSEC, связанные с целостностью"
  
  run_cmd "dmesg | grep -i 'integrity\|parsec' | tail -10 || true" \
    "Сообщения ядра о контроле целостности"
  
  run_cmd "systemctl status auditd --no-pager 2>/dev/null | head -5 || echo 'auditd недоступен'" \
    "Аудит фиксирует события контроля целостности"
}

block_6_practical_protection(){
  title
  echo "$(bold '6) Практическая защита от модификации')"
  hr
  
  echo "$(bold 'Что защищает МКЦ:')"
  echo "  - Системные исполняемые файлы от модификации пользовательскими процессами"
  echo "  - Конфигурационные файлы от неавторизованных изменений"
  echo "  - Критические данные от деградации"
  echo "  - От выполнения вредоносного кода в контексте высокоцелостных процессов"
  hr
  
  run_cmd "ls -la /bin/bash /usr/bin/bash" "Системные исполняемые файлы (защищены высоким ILEV)"
  
  run_cmd "getfattr -n security.ILEV -m security.ILEV /bin/* 2>/dev/null | head -10 || echo 'ILEV метки не найдены'" \
    "Уровни целостности системных исполняемых файлов"
  
  run_cmd "getfattr -n security.ILEV -m security.ILEV /etc/*.conf 2>/dev/null | head -10 || echo 'ILEV метки не найдены'" \
    "Уровни целостности конфигурационных файлов"
}

block_7_summary(){
  title
  echo "$(bold 'Итог: принципы МКЦ')"
  hr
  cat <<'EOF'
Основные принципы мандатного контроля целостности:

1. Уровни целостности (ILEV):
   - Каждый объект и субъект имеет уровень целостности
   - Максимальный уровень системы (max_ilev)
   - Хранятся в security.ILEV атрибутах

2. Модель Biba:
   - Простое правило целостности (чтение)
   - *-свойство целостности (запись)
   - Запрет на деградацию данных

3. Контроль выполнения:
   - Процессы наследуют уровень целостности
   - Проверка при выполнении файлов
   - Низкоцелостный процесс не может выполнить высокоцелостный код

4. Изоляция уровней:
   - Данные разного уровня изолированы
   - Защита от неконтролируемой модификации
   - Гарантирование неизменности критических данных

5. Реализация:
   - PARSEC модуль в ядре
   - Проверка на каждой операции записи/выполнения
   - Аудит всех событий контроля целостности

6. Практическая защита:
   - Системные файлы от модификации
   - Критические данные от деградации
   - От выполнения вредоносного кода
EOF
  hr
  pause
}

menu(){
  title
  echo "  0) Введение"
  echo "  1) Уровни целостности"
  echo "  2) Модель Biba"
  echo "  3) Контроль выполнения"
  echo "  4) Изоляция уровней"
  echo "  5) Реализация через PARSEC"
  echo "  6) Практическая защита"
  echo "  7) Итог"
  echo "  a) Всё по порядку"
  echo "  q) Выход"
  read -r -p "$(dim 'Выбор: ')" ch
  case "$ch" in
    0) block_0_intro ;;
    1) block_1_integrity_levels ;;
    2) block_2_biba_model ;;
    3) block_3_execution_control ;;
    4) block_4_integrity_isolation ;;
    5) block_5_parsec_integrity ;;
    6) block_6_practical_protection ;;
    7) block_7_summary ;;
    a|A)
      block_0_intro
      block_1_integrity_levels
      block_2_biba_model
      block_3_execution_control
      block_4_integrity_isolation
      block_5_parsec_integrity
      block_6_practical_protection
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

