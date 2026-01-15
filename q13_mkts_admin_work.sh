#!/usr/bin/env bash
set -euo pipefail

# Вопрос 13: Администрирование и работа в ОС при включённом режиме МКЦ

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
  echo "$(bold 'Вопрос 13: Администрирование и работа при включённом МКЦ')"
  hr
}

block_0_intro(){
  title
  echo "$(bold '0) Особенности работы при включённом МКЦ')"
  hr
  echo "При включённом МКЦ:"
  echo "  1. Все объекты и процессы имеют уровни целостности"
  echo "  2. Контроль доступа основан на уровнях целостности"
  echo "  3. Низкоцелостные процессы не могут модифицировать высокоцелостные объекты"
  echo "  4. Все операции аудируются"
  hr
  pause
}

block_1_check_integrity_status(){
  title
  echo "$(bold '1) Проверка статуса МКЦ')"
  hr
  
  run_cmd "cat /sys/module/parsec/parameters/integrity_enabled 2>/dev/null || echo 'Статус недоступен'" \
    "Проверка включения контроля целостности"
  
  run_cmd "cat /sys/module/parsec/parameters/max_ilev 2>/dev/null || echo 'max_ilev недоступен'" \
    "Максимальный уровень целостности"
  
  run_cmd "command -v astra-security-monitor >/dev/null && sudo astra-security-monitor 2>/dev/null | grep -i integrity | head -10 || echo 'astra-security-monitor недоступен'" \
    "Статус через монитор безопасности"
}

block_2_file_operations(){
  title
  echo "$(bold '2) Работа с файлами при МКЦ')"
  hr
  
  run_cmd "getfattr -n security.ILEV -m security.ILEV ~/.bashrc 2>/dev/null | head -3 || echo 'ILEV метка не найдена'" \
    "Уровень целостности пользовательского файла"
  
  run_cmd "getfattr -n security.ILEV -m security.ILEV /etc/passwd 2>/dev/null | head -3 || echo 'ILEV метка не найдена'" \
    "Уровень целостности системного файла"
  
  echo "$(bold 'Ограничения при МКЦ:')"
  echo "  - Низкоцелостный процесс не может модифицировать высокоцелостный файл"
  echo "  - Копирование должно учитывать уровни целостности"
  hr
  
  if [[ "$DEMO_MUTATE" == "1" ]]; then
    DEMO_DIR="/tmp/integrity_work_$$"
    run_cmd "mkdir -p \"$DEMO_DIR\" && echo 'test' > \"$DEMO_DIR\"/file1" \
      "Создаю файл для тестирования"
    
    run_cmd "cat \"$DEMO_DIR\"/file1" "Чтение файла (обычно разрешено)"
    
    run_cmd "rm -rf \"$DEMO_DIR\"" "Очистка"
  fi
}

block_3_execution_control(){
  title
  echo "$(bold '3) Выполнение программ при МКЦ')"
  hr
  
  run_cmd "getfattr -n security.ILEV -m security.ILEV /bin/bash 2>/dev/null | head -3 || echo 'ILEV не найден'" \
    "Уровень целостности интерпретатора"
  
  run_cmd "ps aux | head -5" "Запущенные процессы (каждый имеет уровень целостности)"
  
  echo "$(bold 'Контроль выполнения:')"
  echo "  - Процесс наследует уровень целостности от родителя"
  echo "  - Низкоцелостный процесс не может выполнить высокоцелостный код"
  echo "  - Все попытки выполнения проверяются МКЦ"
  hr
}

block_4_administration_tasks(){
  title
  echo "$(bold '4) Административные задачи при МКЦ')"
  hr
  
  run_cmd "id" "Текущий пользователь (администратор имеет привилегии)"
  
  echo "$(bold 'Административные задачи:')"
  echo "  1. Управление метками целостности (pdpl-file)"
  echo "  2. Мониторинг событий МКЦ (аудит)"
  echo "  3. Настройка параметров МКЦ"
  echo "  4. Разрешение конфликтов доступа"
  hr
  
  run_cmd "sudo -l 2>/dev/null | head -10 || echo 'Нет sudo прав'" \
    "Проверка административных привилегий"
  
  if have pdpl-file; then
    run_cmd "pdpl-file -h 2>/dev/null | head -20" \
      "Инструмент управления метками целостности"
  fi
}

block_5_audit_monitoring(){
  title
  echo "$(bold '5) Мониторинг событий МКЦ через аудит')"
  hr
  
  run_cmd "systemctl status auditd --no-pager 2>/dev/null | head -10 || echo 'auditd недоступен'" \
    "Статус службы аудита"
  
  if have auditctl; then
    run_cmd "sudo auditctl -l 2>/dev/null | grep -i 'integrity\|ilev' | head -10 || echo 'Правила целостности не найдены'" \
      "Правила аудита, связанные с целостностью"
    
    run_cmd "sudo ausearch -m file_access 2>/dev/null | tail -10 || echo 'События доступа не найдены'" \
      "Последние события доступа к файлам"
  fi
  
  run_cmd "journalctl -k -n 20 --no-pager 2>/dev/null | grep -i 'integrity\|parsec' | head -10 || echo 'События не найдены'" \
    "События целостности в журнале ядра"
}

block_6_troubleshooting(){
  title
  echo "$(bold '6) Разрешение проблем при МКЦ')"
  hr
  
  echo "$(bold 'Типичные проблемы:')"
  echo "  1. Доступ к файлу запрещён (несовместимость уровней целостности)"
  echo "  2. Не удаётся выполнить программу (несовместимость уровней)"
  echo "  3. Ошибки при копировании файлов (несовместимость уровней)"
  hr
  
  run_cmd "journalctl -p err -n 20 --no-pager 2>/dev/null | grep -i 'integrity\|parsec' | head -10 || echo 'Ошибки не найдены'" \
    "Ошибки, связанные с целостностью"
  
  echo "$(bold 'Решение проблем:')"
  echo "  - Проверка уровней целостности (getfattr)"
  echo "  - Изменение меток (pdpl-file) администратором"
  echo "  - Анализ логов аудита (ausearch, journalctl)"
  hr
}

block_7_best_practices(){
  title
  echo "$(bold '7) Рекомендации по работе с МКЦ')"
  hr
  
  echo "$(bold 'Рекомендации:')"
  echo "  1. Понимать уровни целостности объектов перед модификацией"
  echo "  2. Использовать правильные метки при создании файлов"
  echo "  3. Мониторить события аудита регулярно"
  echo "  4. Не отключать МКЦ без необходимости"
  echo "  5. Регулярно проверять статус системы безопасности"
  hr
  
  run_cmd "cat /sys/module/parsec/parameters/integrity_enabled 2>/dev/null || echo 'Статус недоступен'" \
    "Регулярная проверка статуса МКЦ"
  
  run_cmd "systemctl is-active auditd 2>/dev/null && echo 'Аудит активен' || echo 'Аудит неактивен'" \
    "Проверка работы аудита"
}

block_8_summary(){
  title
  echo "$(bold 'Итог: работа при включённом МКЦ')"
  hr
  cat <<'EOF'
Работа при включённом МКЦ:

1. Особенности:
   - Все объекты и процессы имеют уровни целостности
   - Контроль доступа на основе уровней
   - Все операции аудируются

2. Работа с файлами:
   - Проверка уровней целостности перед операциями
   - Ограничения на модификацию высокоцелостных объектов
   - Сохранение меток при копировании

3. Выполнение программ:
   - Контроль выполнения на основе уровней
   - Наследование уровней процессами
   - Ограничения на выполнение высокоцелостного кода

4. Администрирование:
   - Управление метками целостности
   - Мониторинг событий МКЦ
   - Разрешение конфликтов доступа

5. Мониторинг:
   - Аудит всех событий МКЦ
   - Анализ логов для выявления проблем
   - Регулярная проверка статуса системы

6. Рекомендации:
   - Понимать политику целостности
   - Использовать правильные метки
   - Не отключать МКЦ без необходимости
EOF
  hr
  pause
}

menu(){
  title
  echo "  0) Введение"
  echo "  1) Проверка статуса"
  echo "  2) Работа с файлами"
  echo "  3) Выполнение программ"
  echo "  4) Административные задачи"
  echo "  5) Мониторинг через аудит"
  echo "  6) Разрешение проблем"
  echo "  7) Рекомендации"
  echo "  8) Итог"
  echo "  a) Всё по порядку"
  echo "  q) Выход"
  read -r -p "$(dim 'Выбор: ')" ch
  case "$ch" in
    0) block_0_intro ;;
    1) block_1_check_integrity_status ;;
    2) block_2_file_operations ;;
    3) block_3_execution_control ;;
    4) block_4_administration_tasks ;;
    5) block_5_audit_monitoring ;;
    6) block_6_troubleshooting ;;
    7) block_7_best_practices ;;
    8) block_8_summary ;;
    a|A)
      block_0_intro
      block_1_check_integrity_status
      block_2_file_operations
      block_3_execution_control
      block_4_administration_tasks
      block_5_audit_monitoring
      block_6_troubleshooting
      block_7_best_practices
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

