#!/usr/bin/env bash
set -euo pipefail

# Вопрос 6: Функциональные возможности средств администрирования ОС Астра Линукс

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
  echo "$(bold 'Вопрос 6: Средства администрирования Astra Linux')"
  hr
}

block_0_intro(){
  title
  echo "$(bold '0) Инструменты администрирования')"
  hr
  echo "Средства администрирования:"
  echo "  1. Fly-admin: графический инструмент администрирования"
  echo "  2. Командная строка: стандартные и специализированные утилиты"
  echo "  3. Управление политиками безопасности"
  echo "  4. Управление пользователями и группами"
  echo "  5. Управление службами и пакетами"
  hr
  pause
}

block_1_fly_admin(){
  title
  echo "$(bold '1) Fly-admin — графический инструмент администрирования')"
  hr
  
  run_cmd "dpkg -l | grep -i 'fly-admin\|fly' | head -10 || true" \
    "Проверяю наличие пакетов Fly-admin"
  
  run_cmd "command -v fly-admin >/dev/null && fly-admin --version 2>/dev/null || echo 'fly-admin не найден'" \
    "Проверка наличия fly-admin"
  
  run_cmd "ls -la /usr/bin/*fly* /usr/sbin/*fly* 2>/dev/null | head -10 || echo 'Утилиты Fly не найдены'" \
    "Утилиты семейства Fly"
  
  run_cmd "systemctl list-units | grep -i fly || echo 'Службы Fly не найдены'" \
    "Службы, связанные с Fly"
}

block_2_policy_management(){
  title
  echo "$(bold '2) Управление политиками безопасности')"
  hr
  
  run_cmd "command -v astra-security-monitor >/dev/null && sudo astra-security-monitor 2>/dev/null || echo 'astra-security-monitor недоступен'" \
    "Монитор безопасности — просмотр состояния политик"
  
  run_cmd "cat /sys/module/parsec/parameters/* 2>/dev/null | head -20 || echo 'Параметры PARSEC недоступны'" \
    "Параметры политики безопасности (могут изменяться администратором)"
  
  run_cmd "command -v pdpl-file >/dev/null && pdpl-file -h 2>/dev/null | head -20 || echo 'pdpl-file недоступен'" \
    "Управление мандатными метками"
  
  if have auditctl; then
    run_cmd "sudo auditctl -s 2>/dev/null || true" "Статус подсистемы аудита"
    run_cmd "sudo auditctl -l 2>/dev/null | head -20 || true" \
      "Правила аудита (управление администратором)"
  fi
}

block_3_user_management(){
  title
  echo "$(bold '3) Управление пользователями и группами')"
  hr
  
  run_cmd "getent passwd | wc -l" "Общее количество пользователей"
  run_cmd "getent group | wc -l" "Общее количество групп"
  run_cmd "cat /etc/passwd | head -5" "Локальные пользователи"
  run_cmd "cat /etc/group | head -5" "Локальные группы"
  
  run_cmd "systemctl status sssd --no-pager 2>/dev/null | head -10 || echo 'SSSD не активен'" \
    "Служба доменных пользователей (SSSD)"
  
  run_cmd "getent passwd | head -5" "Все пользователи (локальные + доменные через SSSD)"
}

block_4_service_management(){
  title
  echo "$(bold '4) Управление службами')"
  hr
  
  run_cmd "systemctl list-units --type=service --state=running | wc -l" "Количество активных служб"
  run_cmd "systemctl list-units --type=service --state=failed 2>/dev/null | head -5 || echo 'Нет упавших служб'" \
    "Упавшие службы"
  
  run_cmd "systemctl status auditd --no-pager 2>/dev/null | head -10 || echo 'auditd недоступен'" \
    "Статус службы аудита (критичная для безопасности)"
  
  run_cmd "systemctl list-unit-files | grep enabled | wc -l" "Включённые службы"
}

block_5_package_management(){
  title
  echo "$(bold '5) Управление пакетами')"
  hr
  
  run_cmd "apt-cache policy 2>/dev/null | head -10 || echo 'apt недоступен'" \
    "Политика репозиториев"
  
  run_cmd "apt list --upgradable 2>/dev/null | head -10 || echo 'Нет доступных обновлений'" \
    "Доступные обновления"
  
  run_cmd "dpkg -l | wc -l" "Количество установленных пакетов"
  
  run_cmd "dpkg -l | grep -i 'security\|parsec\|audit' | head -10 || true" \
    "Пакеты безопасности"
}

block_6_security_config(){
  title
  echo "$(bold '6) Конфигурация безопасности')"
  hr
  
  run_cmd "cat /etc/audit/auditd.conf 2>/dev/null | grep -v '^#' | grep -v '^$' | head -20 || echo 'Конфиг недоступен'" \
    "Конфигурация аудита"
  
  run_cmd "cat /etc/pam.d/common-auth 2>/dev/null | head -10 || echo 'PAM конфиг недоступен'" \
    "Конфигурация аутентификации (PAM)"
  
  run_cmd "iptables -L -n 2>/dev/null | head -20 || echo 'iptables недоступен'" \
    "Правила firewall"
  
  run_cmd "ufw status 2>/dev/null || echo 'ufw не активен'" "UFW firewall"
}

block_7_logs_monitoring(){
  title
  echo "$(bold '7) Мониторинг и логи')"
  hr
  
  run_cmd "journalctl -p warning..alert -n 20 --no-pager 2>/dev/null || true" \
    "Важные события системы"
  
  run_cmd "tail -20 /var/log/syslog 2>/dev/null || tail -20 /var/log/messages 2>/dev/null || echo 'Логи недоступны'" \
    "Системные логи"
  
  run_cmd "tail -10 /var/log/audit/audit.log 2>/dev/null || echo 'Логи аудита недоступны'" \
    "Логи аудита"
  
  run_cmd "df -h | head -10" "Использование дискового пространства (важно для логов)"
}

block_8_summary(){
  title
  echo "$(bold 'Итог: средства администрирования')"
  hr
  cat <<'EOF'
Инструменты администрирования Astra Linux SE:

1. Графические:
   - Fly-admin: централизованный GUI для администрирования
   - Системные настройки

2. Командная строка:
   - Стандартные утилиты Linux
   - Специализированные утилиты (pdpl-file, astra-security-monitor)
   - systemctl для управления службами

3. Управление безопасностью:
   - Настройка политик PARSEC
   - Управление мандатными метками
   - Конфигурация аудита
   - Управление firewall

4. Администрирование системы:
   - Пользователи и группы (локальные + доменные)
   - Службы и сервисы
   - Пакеты и обновления
   - Мониторинг и логи
EOF
  hr
  pause
}

menu(){
  title
  echo "  0) Введение"
  echo "  1) Fly-admin"
  echo "  2) Управление политиками"
  echo "  3) Управление пользователями"
  echo "  4) Управление службами"
  echo "  5) Управление пакетами"
  echo "  6) Конфигурация безопасности"
  echo "  7) Мониторинг и логи"
  echo "  8) Итог"
  echo "  a) Всё по порядку"
  echo "  q) Выход"
  read -r -p "$(dim 'Выбор: ')" ch
  case "$ch" in
    0) block_0_intro ;;
    1) block_1_fly_admin ;;
    2) block_2_policy_management ;;
    3) block_3_user_management ;;
    4) block_4_service_management ;;
    5) block_5_package_management ;;
    6) block_6_security_config ;;
    7) block_7_logs_monitoring ;;
    8) block_8_summary ;;
    a|A)
      block_0_intro
      block_1_fly_admin
      block_2_policy_management
      block_3_user_management
      block_4_service_management
      block_5_package_management
      block_6_security_config
      block_7_logs_monitoring
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

