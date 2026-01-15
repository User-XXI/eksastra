#!/usr/bin/env bash
set -euo pipefail

# Вопрос 14: Уровень ролевого управления доступом ОССН: структура иерархического представления; элементы состояния системы

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
  echo "$(bold 'Вопрос 14: Ролевое управление доступом - структура иерархии')"
  hr
}

block_0_intro(){
  title
  echo "$(bold '0) Ролевая модель доступа (RBAC)')"
  hr
  echo "Ролевое управление доступом:"
  echo "  1. Иерархическая структура ролей"
  echo "  2. Роли определяют набор прав доступа"
  echo "  3. Пользователи назначаются на роли"
  echo "  4. Роли могут наследоваться друг от друга"
  echo "  5. Элементы состояния системы: пользователи, роли, права, сессии"
  hr
  pause
}

block_1_user_roles(){
  title
  echo "$(bold '1) Пользователи и роли')"
  hr
  
  run_cmd "id" "Текущий пользователь и его группы (роли в Linux)"
  
  run_cmd "groups" "Группы пользователя (представляют роли)"
  
  run_cmd "getent group | head -10" "Список групп (ролей) в системе"
  
  run_cmd "getent passwd | head -5" "Пользователи системы"
  
  echo "$(bold 'В Astra Linux SE:')"
  echo "  - Группы Linux используются для представления ролей"
  echo "  - Роли могут быть иерархическими (группы в группах)"
  hr
}

block_2_hierarchy(){
  title
  echo "$(bold '2) Иерархическая структура ролей')"
  hr
  
  run_cmd "getent group | grep -E 'admin|sudo|wheel' || echo 'Административные роли не найдены'" \
    "Административные роли (верхний уровень иерархии)"
  
  run_cmd "getent group | grep -E 'users|staff|developers' || echo 'Пользовательские роли не найдены'" \
    "Пользовательские роли (нижний уровень иерархии)"
  
  echo "$(bold 'Иерархия ролей:')"
  echo "  - Администратор (root) — полный доступ"
  echo "  - Административные роли (sudo, admin) — расширенные права"
  echo "  - Пользовательские роли (users, staff) — базовые права"
  echo "  - Ограниченные роли — минимальные права"
  hr
}

block_3_sudo_roles(){
  title
  echo "$(bold '3) Роли через sudo (ролевой доступ)')"
  hr
  
  run_cmd "sudo -l 2>/dev/null | head -20 || echo 'Нет sudo прав или не настроен'" \
    "Назначенные роли через sudo"
  
  run_cmd "cat /etc/sudoers 2>/dev/null | grep -v '^#' | grep -v '^$' | head -20 || echo 'sudoers недоступен или пуст'" \
    "Конфигурация ролей sudo"
  
  run_cmd "ls -la /etc/sudoers.d/ 2>/dev/null | head -10 || echo 'Директория sudoers.d недоступна'" \
    "Дополнительные конфигурации ролей"
  
  echo "$(bold 'Роли через sudo:')"
  echo "  - Определяют набор команд для роли"
  echo "  - Могут быть ограничены по времени/хосту"
  echo "  - Аудит всех действий роли"
  hr
}

block_4_session_state(){
  title
  echo "$(bold '4) Элементы состояния системы')"
  hr
  
  echo "$(bold 'Элементы состояния ролевой модели:')"
  echo "  1. Пользователи (субъекты доступа)"
  echo "  2. Роли (наборы прав)"
  echo "  3. Права доступа (разрешения на операции)"
  echo "  4. Сессии (активные взаимодействия пользователя с системой)"
  echo "  5. Объекты доступа (файлы, процессы, ресурсы)"
  hr
  
  run_cmd "who" "Активные сессии пользователей"
  
  run_cmd "ps aux | head -5" "Процессы (субъекты в сессии)"
  
  run_cmd "id $(whoami)" "Текущий пользователь и его роли (состояние)"
  
  run_cmd "ls -la /proc/$$/fd 2>/dev/null | head -10 || echo 'Дескрипторы файлов недоступны'" \
    "Открытые ресурсы в текущей сессии"
}

block_5_role_management(){
  title
  echo "$(bold '5) Управление ролями')"
  hr
  
  run_cmd "getent group | wc -l" "Общее количество ролей (групп) в системе"
  
  run_cmd "getent group admin sudo wheel 2>/dev/null || echo 'Административные роли не найдены'" \
    "Проверка конкретных ролей"
  
  echo "$(bold 'Управление ролями:')"
  echo "  - Создание ролей: groupadd"
  echo "  - Назначение пользователей: usermod -aG"
  echo "  - Настройка прав роли: sudoers, файловые права"
  hr
  
  run_cmd "groups $(whoami)" "Роли текущего пользователя"
}

block_6_audit_roles(){
  title
  echo "$(bold '6) Аудит ролевого доступа')"
  hr
  
  if have auditctl; then
    run_cmd "sudo auditctl -l 2>/dev/null | grep -i 'sudo\|role\|group' | head -10 || echo 'Правила ролей не найдены'" \
      "Правила аудита для ролевого доступа"
  fi
  
  run_cmd "journalctl -u auditd -n 20 --no-pager 2>/dev/null | grep -i 'sudo\|su' | head -10 || echo 'События ролей не найдены'" \
    "События использования ролевого доступа"
  
  echo "$(bold 'Аудит ролей:')"
  echo "  - Фиксация активации ролей (sudo, su)"
  echo "  - Логирование действий от имени роли"
  echo "  - Отслеживание изменений ролей"
  hr
}

block_7_summary(){
  title
  echo "$(bold 'Итог: структура ролевого управления')"
  hr
  cat <<'EOF'
Структура ролевого управления доступом:

1. Иерархическая структура ролей:
   - Администратор (root) — верхний уровень
   - Административные роли (sudo, admin)
   - Пользовательские роли (users, staff)
   - Ограниченные роли — нижний уровень

2. Элементы состояния системы:
   - Пользователи: субъекты доступа
   - Роли: наборы прав (группы Linux)
   - Права: разрешения на операции
   - Сессии: активные взаимодействия
   - Объекты: файлы, процессы, ресурсы

3. Управление ролями:
   - Создание через groupadd
   - Назначение через usermod
   - Настройка прав через sudoers

4. Реализация в Astra:
   - Группы Linux как роли
   - sudo для ролевого доступа
   - Аудит всех действий ролей

5. Иерархия:
   - Роли могут наследоваться
   - Права наследуются от роли
   - Сессии связывают пользователя и роль
EOF
  hr
  pause
}

menu(){
  title
  echo "  0) Введение"
  echo "  1) Пользователи и роли"
  echo "  2) Иерархическая структура"
  echo "  3) Роли через sudo"
  echo "  4) Элементы состояния"
  echo "  5) Управление ролями"
  echo "  6) Аудит ролевого доступа"
  echo "  7) Итог"
  echo "  a) Всё по порядку"
  echo "  q) Выход"
  read -r -p "$(dim 'Выбор: ')" ch
  case "$ch" in
    0) block_0_intro ;;
    1) block_1_user_roles ;;
    2) block_2_hierarchy ;;
    3) block_3_sudo_roles ;;
    4) block_4_session_state ;;
    5) block_5_role_management ;;
    6) block_6_audit_roles ;;
    7) block_7_summary ;;
    a|A)
      block_0_intro
      block_1_user_roles
      block_2_hierarchy
      block_3_sudo_roles
      block_4_session_state
      block_5_role_management
      block_6_audit_roles
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

