#!/usr/bin/env bash
set -euo pipefail

# Вопрос 20: Построение базового уровня сетевого взаимодействия ОССН. Настройка сетевого взаимодействия

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
  echo "$(bold 'Вопрос 20: Базовый уровень сетевого взаимодействия')"
  hr
}

block_0_intro(){
  title
  echo "$(bold '0) Базовое сетевое взаимодействие')"
  hr
  echo "Базовый уровень включает:"
  echo "  1. Настройку сетевых интерфейсов"
  echo "  2. Конфигурацию IP-адресов и маршрутизации"
  echo "  3. Настройку DNS"
  echo "  4. Базовую защиту (firewall)"
  echo "  5. Мониторинг сетевой активности"
  hr
  pause
}

block_1_network_interfaces(){
  title
  echo "$(bold '1) Сетевые интерфейсы')"
  hr
  
  run_cmd "ip addr show 2>/dev/null | head -30 || ifconfig | head -20" \
    "Список сетевых интерфейсов и их конфигурация"
  
  run_cmd "ip link show" "Статус сетевых интерфейсов (включены/выключены)"
  
  run_cmd "ls -la /sys/class/net/" "Сетевые интерфейсы в /sys"
  
  run_cmd "cat /etc/network/interfaces 2>/dev/null | head -20 || echo 'interfaces недоступен'" \
    "Конфигурация сетевых интерфейсов"
}

block_2_ip_configuration(){
  title
  echo "$(bold '2) Конфигурация IP-адресов')"
  hr
  
  run_cmd "ip addr show | grep -E 'inet ' | head -10" \
    "Настроенные IP-адреса"
  
  run_cmd "hostname -I 2>/dev/null || echo 'hostname -I недоступен'" \
    "Все IP-адреса хоста"
  
  run_cmd "hostname" "Имя хоста"
  
  run_cmd "ip route show" "Таблица маршрутизации"
  
  run_cmd "netstat -rn 2>/dev/null | head -10 || ip route | head -10" \
    "Альтернативный вид таблицы маршрутизации"
}

block_3_dns_configuration(){
  title
  echo "$(bold '3) Конфигурация DNS')"
  hr
  
  run_cmd "cat /etc/resolv.conf 2>/dev/null | head -10 || echo 'resolv.conf недоступен'" \
    "DNS серверы (резолверы)"
  
  run_cmd "cat /etc/hosts 2>/dev/null | head -10 || echo 'hosts недоступен'" \
    "Локальная таблица хостов"
  
  run_cmd "systemd-resolve --status 2>/dev/null | head -20 || echo 'systemd-resolve недоступен'" \
    "Статус DNS через systemd-resolve"
  
  run_cmd "nslookup localhost 2>/dev/null || host localhost 2>/dev/null || echo 'DNS утилиты недоступны'" \
    "Тест разрешения имён"
}

block_4_firewall(){
  title
  echo "$(bold '4) Базовая защита (Firewall)')"
  hr
  
  run_cmd "iptables -L -n 2>/dev/null | head -30 || echo 'iptables недоступен'" \
    "Правила firewall через iptables"
  
  run_cmd "ufw status 2>/dev/null || echo 'ufw не активен или недоступен'" \
    "Статус UFW (Uncomplicated Firewall)"
  
  run_cmd "ss -tulpn 2>/dev/null | head -20 || netstat -tulpn 2>/dev/null | head -20 || echo 'Сетевые утилиты недоступны'" \
    "Слушающие порты (поверхность атаки)"
  
  echo "$(bold 'Базовая защита:')"
  echo "  - Блокировка неиспользуемых портов"
  echo "  - Разрешение только необходимых соединений"
  echo "  - Логирование подозрительной активности"
  hr
}

block_5_network_monitoring(){
  title
  echo "$(bold '5) Мониторинг сетевой активности')"
  hr
  
  run_cmd "ss -tulpn 2>/dev/null | head -15 || netstat -tulpn 2>/dev/null | head -15" \
    "Активные сетевые соединения"
  
  run_cmd "ip -s link show 2>/dev/null | head -20" \
    "Статистика сетевых интерфейсов (трафик, ошибки)"
  
  if have iftop; then
    echo "$(grn 'iftop доступен для мониторинга трафика в реальном времени')"
  else
    echo "$(ylw 'iftop не установлен (опциональный инструмент мониторинга)')"
  fi
  
  run_cmd "cat /proc/net/dev 2>/dev/null | head -10" \
    "Статистика сетевых интерфейсов через /proc"
}

block_6_network_services(){
  title
  echo "$(bold '6) Сетевые службы')"
  hr
  
  run_cmd "systemctl list-units --type=service --state=running | grep -iE 'network|dhcp|dns' | head -10 || echo 'Сетевые службы не найдены'" \
    "Активные сетевые службы"
  
  run_cmd "systemctl status networking 2>/dev/null | head -15 || systemctl status NetworkManager 2>/dev/null | head -15 || echo 'Службы сети недоступны'" \
    "Статус службы управления сетью"
  
  run_cmd "systemctl status ssh 2>/dev/null | head -10 || systemctl status sshd 2>/dev/null | head -10 || echo 'SSH служба недоступна'" \
    "Статус SSH (важна для удалённого доступа)"
}

block_7_network_security(){
  title
  echo "$(bold '7) Безопасность базового сетевого уровня')"
  hr
  
  echo "$(bold 'Принципы безопасности:')"
  echo "  - Минимизация открытых портов"
  echo "  - Использование firewall"
  echo "  - Аудит сетевых событий"
  echo "  - Обновление сетевых служб"
  hr
  
  if have auditctl; then
    run_cmd "sudo auditctl -l 2>/dev/null | grep -iE 'network|socket' | head -10 || echo 'Правила аудита сети не найдены'" \
      "Правила аудита сетевой активности"
  fi
  
  run_cmd "journalctl -k -n 30 --no-pager 2>/dev/null | grep -iE 'network|firewall' | head -10 || echo 'События сети не найдены'" \
    "События сети в журнале"
}

block_8_summary(){
  title
  echo "$(bold 'Итог: базовый уровень сетевого взаимодействия')"
  hr
  cat <<'EOF'
Базовый уровень сетевого взаимодействия:

1. Сетевые интерфейсы:
   - Настройка через ip/ifconfig
   - Конфигурация в /etc/network/interfaces
   - Управление через NetworkManager или networking

2. IP-конфигурация:
   - Назначение IP-адресов
   - Настройка маршрутизации
   - Имя хоста

3. DNS:
   - Конфигурация резолверов в /etc/resolv.conf
   - Локальная таблица хостов в /etc/hosts
   - Проверка разрешения имён

4. Firewall:
   - iptables для фильтрации пакетов
   - UFW для упрощённого управления
   - Минимизация открытых портов

5. Мониторинг:
   - Активные соединения (ss/netstat)
   - Статистика трафика
   - Слушающие порты

6. Сетевые службы:
   - Управление сетью (networking/NetworkManager)
   - SSH для удалённого доступа
   - DHCP для автоматической конфигурации

7. Безопасность:
   - Минимизация портов
   - Использование firewall
   - Аудит сетевых событий
   - Обновление служб
EOF
  hr
  pause
}

menu(){
  title
  echo "  0) Введение"
  echo "  1) Сетевые интерфейсы"
  echo "  2) Конфигурация IP"
  echo "  3) Конфигурация DNS"
  echo "  4) Firewall"
  echo "  5) Мониторинг сети"
  echo "  6) Сетевые службы"
  echo "  7) Безопасность сети"
  echo "  8) Итог"
  echo "  a) Всё по порядку"
  echo "  q) Выход"
  read -r -p "$(dim 'Выбор: ')" ch
  case "$ch" in
    0) block_0_intro ;;
    1) block_1_network_interfaces ;;
    2) block_2_ip_configuration ;;
    3) block_3_dns_configuration ;;
    4) block_4_firewall ;;
    5) block_5_network_monitoring ;;
    6) block_6_network_services ;;
    7) block_7_network_security ;;
    8) block_8_summary ;;
    a|A)
      block_0_intro
      block_1_network_interfaces
      block_2_ip_configuration
      block_3_dns_configuration
      block_4_firewall
      block_5_network_monitoring
      block_6_network_services
      block_7_network_security
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

