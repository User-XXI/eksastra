#!/usr/bin/env bash
set -euo pipefail

# Вопрос 12: Порядок включения, настройки и выключения мандатного контроля целостности после установки ОС

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
  echo "$(bold 'Вопрос 12: Включение, настройка и выключение МКЦ')"
  hr
}

block_0_intro(){
  title
  echo "$(bold '0) Этапы настройки МКЦ')"
  hr
  echo "Порядок настройки МКЦ:"
  echo "  1. Проверка текущего состояния"
  echo "  2. Включение контроля целостности"
  echo "  3. Настройка параметров"
  echo "  4. Установка меток целостности на объекты"
  echo "  5. Проверка работы МКЦ"
  echo "  6. Выключение (при необходимости)"
  hr
  pause
}

block_1_check_status(){
  title
  echo "$(bold '1) Проверка текущего состояния МКЦ')"
  hr
  
  run_cmd "cat /sys/module/parsec/parameters/integrity_enabled 2>/dev/null || echo 'Параметр недоступен'" \
    "Проверка включения контроля целостности"
  
  run_cmd "cat /sys/module/parsec/parameters/max_ilev 2>/dev/null || echo 'max_ilev недоступен'" \
    "Максимальный уровень целостности (потолок системы)"
  
  run_cmd "command -v astra-security-monitor >/dev/null && sudo astra-security-monitor 2>/dev/null | grep -i integrity | head -10 || echo 'astra-security-monitor недоступен'" \
    "Статус контроля целостности через монитор безопасности"
  
  run_cmd "getfattr -n security.ILEV -m security.ILEV /bin/bash 2>/dev/null | head -3 || echo 'ILEV метки не найдены (возможно, МКЦ не настроен)'" \
    "Проверка наличия меток целостности на системных файлах"
}

block_2_enable_integrity(){
  title
  echo "$(bold '2) Включение контроля целостности')"
  hr
  
  echo "$(bold 'ВАЖНО: Включение/выключение МКЦ обычно требует прав root и может требовать перезагрузки')"
  hr
  
  run_cmd "cat /sys/module/parsec/parameters/integrity_enabled 2>/dev/null || echo 'Текущий статус недоступен'" \
    "Текущий статус включения"
  
  echo "$(bold 'Методы включения:')"
  echo "  1. Через параметр ядра при загрузке"
  echo "  2. Через изменение параметров PARSEC (если поддерживается)"
  echo "  3. Через инструменты администрирования (Fly-admin)"
  hr
  
  run_cmd "cat /proc/cmdline | grep -i integrity || echo 'Параметры целостности не найдены в cmdline'" \
    "Параметры загрузки, связанные с целостностью"
  
  run_cmd "cat /sys/module/parsec/parameters/*enable* 2>/dev/null || echo 'Параметры включения не найдены'" \
    "Параметры включения/выключения"
}

block_3_configure_parameters(){
  title
  echo "$(bold '3) Настройка параметров МКЦ')"
  hr
  
  run_cmd "cat /sys/module/parsec/parameters/max_ilev 2>/dev/null || echo 'max_ilev недоступен'" \
    "Максимальный уровень целостности (настройка потолка системы)"
  
  run_cmd "cat /sys/module/parsec/parameters/* 2>/dev/null | grep -i 'integrity\|ilev' | head -10 || echo 'Параметры целостности не найдены'" \
    "Все параметры, связанные с целостностью"
  
  echo "$(bold 'Параметры настройки МКЦ:')"
  echo "  - max_ilev: максимальный уровень целостности системы"
  echo "  - integrity_enabled: включение/выключение контроля"
  echo "  - Другие параметры политики целостности"
  hr
  
  echo "$(ylw 'Внимание: Изменение параметров может потребовать перезагрузки или перезагрузки модуля')"
  hr
}

block_4_set_labels(){
  title
  echo "$(bold '4) Установка меток целостности на объекты')"
  hr
  
  if have pdpl-file; then
    run_cmd "pdpl-file -h 2>/dev/null | head -30" \
      "Справка по установке меток целостности"
  fi
  
  run_cmd "getfattr -n security.ILEV -m security.ILEV /bin/bash 2>/dev/null | head -3 || echo 'ILEV метка не установлена'" \
    "Проверка меток целостности на исполняемых файлах"
  
  run_cmd "getfattr -n security.ILEV -m security.ILEV /etc/passwd 2>/dev/null | head -3 || echo 'ILEV метка не установлена'" \
    "Проверка меток целостности на системных файлах"
  
  echo "$(bold 'Установка меток целостности:')"
  echo "  - pdpl-file для установки меток"
  echo "  - На системные файлы устанавливаются высокие уровни"
  echo "  - На пользовательские данные — низкие уровни"
  hr
  
  if [[ "$DEMO_MUTATE" == "1" ]] && have pdpl-file; then
    DEMO_DIR="/tmp/integrity_setup_$$"
    run_cmd "mkdir -p \"$DEMO_DIR\" && echo 'test' > \"$DEMO_DIR\"/file1" \
      "Создаю тестовый файл"
    
    run_cmd "sudo pdpl-file -i 2 \"$DEMO_DIR\"/file1 2>/dev/null || echo 'Не удалось установить ILEV (возможны ограничения)'" \
      "Пример установки уровня целостности"
    
    run_cmd "getfattr -n security.ILEV -m security.ILEV \"$DEMO_DIR\"/file1 2>/dev/null || echo 'Метка не найдена'" \
      "Проверка установленной метки"
    
    run_cmd "rm -rf \"$DEMO_DIR\"" "Очистка"
  fi
}

block_5_verify_work(){
  title
  echo "$(bold '5) Проверка работы МКЦ')"
  hr
  
  run_cmd "cat /sys/module/parsec/parameters/integrity_enabled 2>/dev/null || echo 'Статус недоступен'" \
    "Подтверждение включения"
  
  run_cmd "find /bin /usr/bin -maxdepth 1 -type f -exec getfattr -n security.ILEV -m security.ILEV {} \; 2>/dev/null | head -20 || echo 'ILEV метки не найдены'" \
    "Проверка меток на системных исполняемых файлах"
  
  run_cmd "systemctl status auditd --no-pager 2>/dev/null | head -5 || echo 'auditd недоступен'" \
    "Проверка работы аудита (фиксирует события МКЦ)"
  
  if have auditctl; then
    run_cmd "sudo auditctl -l 2>/dev/null | grep -i 'integrity\|ilev' | head -10 || echo 'Правила целостности не найдены'" \
      "Правила аудита, связанные с целостностью"
  fi
  
  echo "$(bold 'Проверка работы:')"
  echo "  - Попытка модификации высокоцелостного объекта из низкого уровня должна блокироваться"
  echo "  - События фиксируются в аудите"
  hr
}

block_6_disable_integrity(){
  title
  echo "$(bold '6) Выключение контроля целостности (при необходимости)')"
  hr
  
  echo "$(bold 'ВАЖНО: Выключение МКЦ снижает уровень защиты системы!')"
  hr
  
  run_cmd "cat /sys/module/parsec/parameters/integrity_enabled 2>/dev/null || echo 'Статус недоступен'" \
    "Текущий статус"
  
  echo "$(bold 'Методы выключения:')"
  echo "  1. Изменение параметра integrity_enabled (если поддерживается)"
  echo "  2. Изменение параметров загрузки ядра"
  echo "  3. Через инструменты администрирования"
  echo "  4. Требует прав root и может потребовать перезагрузки"
  hr
  
  echo "$(ylw 'Внимание: Выключение МКЦ должно выполняться только администратором с пониманием последствий')"
  hr
}

block_7_summary(){
  title
  echo "$(bold 'Итог: настройка МКЦ')"
  hr
  cat <<'EOF'
Порядок настройки МКЦ:

1. Проверка состояния:
   - integrity_enabled: статус включения
   - max_ilev: максимальный уровень целостности
   - Наличие меток на объектах

2. Включение МКЦ:
   - Через параметры ядра при загрузке
   - Через параметры PARSEC (если поддерживается)
   - Требует прав root

3. Настройка параметров:
   - max_ilev: установка потолка системы
   - Другие параметры политики
   - Может потребовать перезагрузки

4. Установка меток:
   - pdpl-file для установки ILEV меток
   - Высокие уровни на системные файлы
   - Низкие уровни на пользовательские данные

5. Проверка работы:
   - Подтверждение включения
   - Проверка меток
   - Тестирование контроля доступа

6. Выключение (при необходимости):
   - Только администратором
   - С пониманием последствий
   - Может потребовать перезагрузки
EOF
  hr
  pause
}

menu(){
  title
  echo "  0) Введение"
  echo "  1) Проверка состояния"
  echo "  2) Включение МКЦ"
  echo "  3) Настройка параметров"
  echo "  4) Установка меток"
  echo "  5) Проверка работы"
  echo "  6) Выключение"
  echo "  7) Итог"
  echo "  a) Всё по порядку"
  echo "  q) Выход"
  read -r -p "$(dim 'Выбор: ')" ch
  case "$ch" in
    0) block_0_intro ;;
    1) block_1_check_status ;;
    2) block_2_enable_integrity ;;
    3) block_3_configure_parameters ;;
    4) block_4_set_labels ;;
    5) block_5_verify_work ;;
    6) block_6_disable_integrity ;;
    7) block_7_summary ;;
    a|A)
      block_0_intro
      block_1_check_status
      block_2_enable_integrity
      block_3_configure_parameters
      block_4_set_labels
      block_5_verify_work
      block_6_disable_integrity
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

