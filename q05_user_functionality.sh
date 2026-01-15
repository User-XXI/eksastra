#!/usr/bin/env bash
set -euo pipefail

# Вопрос 5: Функциональные возможности, предоставляемые пользователям в ОС Астра Линукс

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
  echo "$(bold 'Вопрос 5: Функциональные возможности для пользователей Astra Linux')"
  hr
}

block_0_intro(){
  title
  echo "$(bold '0) Основные возможности для пользователей')"
  hr
  echo "Функциональность пользователя:"
  echo "  1. Работа с файловой системой (с учётом мандатного контроля)"
  echo "  2. Запуск приложений (с контролем целостности)"
  echo "  3. Графический интерфейс (с изоляцией объектов)"
  echo "  4. Сетевые возможности"
  echo "  5. Работа в доменной инфраструктуре"
  hr
  pause
}

block_1_basic_operations(){
  title
  echo "$(bold '1) Базовые операции пользователя')"
  hr
  
  run_cmd "whoami" "Текущий пользователь"
  run_cmd "id" "Права и группы пользователя"
  run_cmd "pwd" "Текущая директория"
  run_cmd "ls -la ~ | head -15" "Содержимое домашней директории"
  run_cmd "umask" "Маска прав по умолчанию"
  run_cmd "groups" "Группы пользователя"
}

block_2_file_operations(){
  title
  echo "$(bold '2) Работа с файлами (в т.ч. с мандатными метками)')"
  hr
  
  if [[ "$DEMO_MUTATE" == "1" ]]; then
    DEMO_DIR="/tmp/user_demo_$$"
    run_cmd "mkdir -p \"$DEMO_DIR\" && cd \"$DEMO_DIR\"" "Создаю тестовую директорию"
    run_cmd "echo 'test content' > file1.txt && ls -la" "Создание файла пользователем"
    run_cmd "chmod 644 file1.txt && ls -la file1.txt" "Изменение прав доступа"
    run_cmd "getfattr -d -m- file1.txt 2>/dev/null || echo 'xattr пусты'" "Проверка расширенных атрибутов"
    run_cmd "cd ~ && rm -rf \"$DEMO_DIR\"" "Очистка"
  else
    run_cmd "ls -la ~/ | head -10" "Файлы пользователя"
    run_cmd "getfattr -d -m- ~/.bashrc 2>/dev/null | head -5 || echo 'xattr не найдены'" \
      "Проверка расширенных атрибутов пользовательских файлов"
  fi
}

block_3_applications(){
  title
  echo "$(bold '3) Запуск приложений (с контролем целостности)')"
  hr
  
  run_cmd "which bash" "Путь к интерпретатору"
  run_cmd "getfattr -n security.ILEV -m security.ILEV /bin/bash 2>/dev/null | head -3 || echo 'Уровень целостности не настроен'" \
    "Уровень целостности приложения"
  run_cmd "ps aux | grep -v grep | grep -E 'bash|ksh|zsh' | head -5 || true" "Запущенные процессы пользователя"
  run_cmd "echo 'echo hello' | bash" "Выполнение команды"
}

block_4_graphical_interface(){
  title
  echo "$(bold '4) Графический интерфейс (изоляция объектов)')"
  hr
  
  run_cmd "echo \$DISPLAY" "Переменная DISPLAY (графическая сессия)"
  run_cmd "ps aux | grep -iE 'xorg|wayland|desktop' | grep -v grep | head -5 || echo 'Графическая среда не найдена'" \
    "Графические процессы"
  run_cmd "systemctl --user list-units 2>/dev/null | head -10 || echo 'User systemd недоступен'" \
    "Пользовательские службы (графические сессии)"
}

block_5_network_user(){
  title
  echo "$(bold '5) Сетевые возможности пользователя')"
  hr
  
  run_cmd "hostname" "Имя хоста"
  run_cmd "ip addr show 2>/dev/null | grep -E 'inet ' | head -5 || ifconfig | grep inet" \
    "Сетевые интерфейсы"
  run_cmd "ping -c 2 127.0.0.1 2>/dev/null || echo 'ping недоступен'" "Сетевая связность"
  run_cmd "curl --version 2>/dev/null | head -1 || wget --version 2>/dev/null | head -1 || echo 'HTTP клиенты недоступны'" \
    "Сетевые утилиты"
}

block_6_domain_user(){
  title
  echo "$(bold '6) Работа в доменной инфраструктуре')"
  hr
  
  run_cmd "id" "Текущие группы (в т.ч. доменные)"
  run_cmd "klist 2>/dev/null || echo 'Kerberos билеты отсутствуют'" "Kerberos аутентификация"
  run_cmd "getent passwd | wc -l" "Доступные пользователи (локальные + доменные)"
  run_cmd "groups | tr ' ' '\n' | head -10" "Группы пользователя (могут быть доменные)"
}

block_7_environment(){
  title
  echo "$(bold '7) Пользовательское окружение')"
  hr
  
  run_cmd "env | grep -E '^USER|^HOME|^PATH|^SHELL' | sort" "Ключевые переменные окружения"
  run_cmd "cat ~/.bashrc 2>/dev/null | head -10 || echo 'Файл не найден'" "Пользовательские настройки"
  run_cmd "ulimit -a" "Ограничения пользователя"
}

block_8_summary(){
  title
  echo "$(bold 'Итог: возможности пользователя')"
  hr
  cat <<'EOF'
Пользователь в Astra Linux SE имеет:

1. Базовые операции:
   - Работа с файлами и директориями
   - Стандартные права доступа (DAC)

2. Расширенные возможности:
   - Работа с мандатными метками (через pdpl-file)
   - Контроль целостности при запуске приложений
   - Изоляция графических объектов

3. Сетевые и доменные:
   - Работа в доменной инфраструктуре
   - Kerberos аутентификация
   - Сетевые утилиты

4. Ограничения безопасности:
   - Политика мандатного контроля
   - Ограничения целостности
   - Аудит всех действий
EOF
  hr
  pause
}

menu(){
  title
  echo "  0) Введение"
  echo "  1) Базовые операции"
  echo "  2) Работа с файлами"
  echo "  3) Запуск приложений"
  echo "  4) Графический интерфейс"
  echo "  5) Сетевые возможности"
  echo "  6) Доменная инфраструктура"
  echo "  7) Пользовательское окружение"
  echo "  8) Итог"
  echo "  a) Всё по порядку"
  echo "  q) Выход"
  read -r -p "$(dim 'Выбор: ')" ch
  case "$ch" in
    0) block_0_intro ;;
    1) block_1_basic_operations ;;
    2) block_2_file_operations ;;
    3) block_3_applications ;;
    4) block_4_graphical_interface ;;
    5) block_5_network_user ;;
    6) block_6_domain_user ;;
    7) block_7_environment ;;
    8) block_8_summary ;;
    a|A)
      block_0_intro
      block_1_basic_operations
      block_2_file_operations
      block_3_applications
      block_4_graphical_interface
      block_5_network_user
      block_6_domain_user
      block_7_environment
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

