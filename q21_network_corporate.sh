#!/usr/bin/env bash
set -euo pipefail

# Вопрос 21: Построение корпоративного уровня сетевого взаимодействия ОССН для обеспечения единого пространства пользователей

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
  echo "$(bold 'Вопрос 21: Корпоративный уровень сетевого взаимодействия')"
  hr
}

block_0_intro(){
  title
  echo "$(bold '0) Единое пространство пользователей')"
  hr
  echo "Корпоративный уровень включает:"
  echo "  1. Доменную инфраструктуру (ALD/LDAP/Kerberos)"
  echo "  2. Централизованную аутентификацию"
  echo "  3. Единое хранилище пользователей"
  echo "  4. Синхронизацию времени (NTP/chrony)"
  echo "  5. Сетевое взаимодействие для доменных служб"
  hr
  pause
}

block_1_domain_services(){
  title
  echo "$(bold '1) Доменные службы')"
  hr
  
  run_cmd "systemctl list-units | grep -iE 'ald|ldap|sssd|krb5' | head -10 || echo 'Доменные службы не найдены'" \
    "Доменные службы системы"
  
  run_cmd "systemctl status sssd --no-pager 2>/dev/null | head -15 || echo 'SSSD не активен'" \
    "Статус SSSD (System Security Services Daemon)"
  
  run_cmd "systemctl status slapd --no-pager 2>/dev/null | head -15 || echo 'LDAP сервер не активен'" \
    "Статус LDAP сервера (если установлен)"
  
  run_cmd "dpkg -l | grep -iE 'ald|sssd|ldap|krb5' | head -15 || echo 'Доменные пакеты не найдены'" \
    "Установленные пакеты доменной инфраструктуры"
}

block_2_ldap_integration(){
  title
  echo "$(bold '2) Интеграция с LDAP')"
  hr
  
  run_cmd "cat /etc/sssd/sssd.conf 2>/dev/null | head -30 || echo 'SSSD конфигурация недоступна'" \
    "Конфигурация SSSD (интеграция с LDAP)"
  
  run_cmd "test -f /etc/ldap/ldap.conf && cat /etc/ldap/ldap.conf | grep -v '^#' | grep -v '^$' | head -10 || echo 'LDAP конфиг недоступен'" \
    "Конфигурация LDAP клиента"
  
  run_cmd "getent passwd | wc -l" "Общее количество пользователей (локальные + доменные)"
  
  run_cmd "getent passwd | head -5" "Примеры пользователей (могут быть доменные)"
  
  echo "$(bold 'LDAP интеграция:')"
  echo "  - SSSD кэширует учётные данные LDAP"
  echo "  - Прозрачный доступ к доменным пользователям"
  echo "  - Аудит доступа к доменным ресурсам"
  hr
}

block_3_kerberos(){
  title
  echo "$(bold '3) Kerberos аутентификация')"
  hr
  
  run_cmd "klist 2>/dev/null || echo 'Kerberos билеты отсутствуют или пакет не установлен'" \
    "Текущие Kerberos билеты (SSO)"
  
  run_cmd "test -f /etc/krb5.conf && cat /etc/krb5.conf | grep -v '^#' | grep -v '^$' | head -30 || echo 'Kerberos конфиг недоступен'" \
    "Конфигурация Kerberos"
  
  run_cmd "systemctl status krb5-kdc --no-pager 2>/dev/null | head -10 || systemctl status krb5-admin-server --no-pager 2>/dev/null | head -10 || echo 'Kerberos серверы не активны'" \
    "Статус Kerberos серверов (если установлены)"
  
  run_cmd "command -v kinit >/dev/null && echo 'kinit найден' || echo 'kinit не найден'" \
    "Доступность утилит Kerberos"
}

block_4_time_sync(){
  title
  echo "$(bold '4) Синхронизация времени (критично для Kerberos)')"
  hr
  
  run_cmd "systemctl status chronyd --no-pager 2>/dev/null | head -15 || echo 'chronyd не активен'" \
    "Статус chronyd (синхронизация времени)"
  
  run_cmd "systemctl status ntp --no-pager 2>/dev/null | head -15 || echo 'ntp не активен'" \
    "Статус NTP (альтернативный сервис времени)"
  
  run_cmd "timedatectl 2>/dev/null || date" \
    "Текущее время и статус синхронизации"
  
  run_cmd "chronyc sources 2>/dev/null | head -15 || echo 'chronyc недоступен'" \
    "Источники синхронизации времени (chrony)"
  
  echo "$(bold 'Важность синхронизации:')"
  echo "  - Kerberos требует точной синхронизации времени"
  echo "  - Разница времени может привести к отказу аутентификации"
  echo "  - NTP/chrony обеспечивают синхронизацию"
  hr
}

block_5_unified_users(){
  title
  echo "$(bold '5) Единое пространство пользователей')"
  hr
  
  run_cmd "id" "Текущий пользователь (может быть доменным)"
  
  run_cmd "groups" "Группы пользователя (могут включать доменные группы)"
  
  run_cmd "getent group | wc -l" "Общее количество групп (локальные + доменные)"
  
  run_cmd "getent passwd | grep -E '^[a-z]+' | head -10" \
    "Примеры пользователей (показывает доменных и локальных)"
  
  echo "$(bold 'Единое пространство:')"
  echo "  - Локальные и доменные пользователи видны одинаково"
  echo "  - Прозрачный доступ к доменным ресурсам"
  echo "  - Централизованное управление пользователями"
  hr
}

block_6_network_security_domain(){
  title
  echo "$(bold '6) Сетевая безопасность доменной инфраструктуры')"
  hr
  
  run_cmd "ss -tulpn 2>/dev/null | grep -E '389|636|88|464' | head -10 || echo 'Порты доменных служб не найдены'" \
    "Порты доменных служб (LDAP: 389/636, Kerberos: 88/464)"
  
  run_cmd "iptables -L -n 2>/dev/null | grep -E '389|636|88|464' | head -10 || echo 'Правила firewall для домена не найдены'" \
    "Firewall правила для доменных служб"
  
  echo "$(bold 'Безопасность домена:')"
  echo "  - Защита портов LDAP/Kerberos"
  echo "  - Использование TLS/SSL для LDAP"
  echo "  - Аудит доступа к доменным службам"
  echo "  - Контроль доступа к доменным ресурсам"
  hr
}

block_7_pam_domain(){
  title
  echo "$(bold '7) Интеграция PAM с доменом')"
  hr
  
  run_cmd "cat /etc/pam.d/common-auth 2>/dev/null | grep -iE 'ldap|krb5|pam_sss' | head -10 || echo 'PAM доменная конфигурация не найдена'" \
    "PAM модули для доменной аутентификации"
  
  run_cmd "grep -r 'pam_ldap\|pam_krb5\|pam_sss' /etc/pam.d/ 2>/dev/null | head -10 || echo 'Доменные PAM модули не найдены'" \
    "Использование доменных модулей PAM"
  
  echo "$(bold 'PAM и домен:')"
  echo "  - pam_ldap: аутентификация через LDAP"
  echo "  - pam_krb5: аутентификация через Kerberos"
  echo "  - pam_sss: аутентификация через SSSD"
  hr
}

block_8_summary(){
  title
  echo "$(bold 'Итог: корпоративный уровень сетевого взаимодействия')"
  hr
  cat <<'EOF'
Корпоративный уровень сетевого взаимодействия:

1. Доменная инфраструктура:
   - ALD (Astra Linux Domain)
   - LDAP для хранения пользователей
   - Kerberos для аутентификации

2. Централизованная аутентификация:
   - SSSD для кэширования учётных данных
   - Kerberos билеты (SSO)
   - PAM модули для доменной аутентификации

3. Единое пространство пользователей:
   - Прозрачный доступ к доменным пользователям
   - Централизованное управление
   - Локальные и доменные пользователи видны одинаково

4. Синхронизация времени:
   - NTP/chrony для синхронизации
   - Критично для Kerberos
   - Обеспечение точного времени

5. Сетевое взаимодействие:
   - Порты LDAP (389/636)
   - Порты Kerberos (88/464)
   - Защита через firewall

6. Безопасность:
   - TLS/SSL для LDAP
   - Защита портов доменных служб
   - Аудит доступа к доменным ресурсам
   - Контроль доступа через МРД

7. Преимущества:
   - Единое управление пользователями
   - Упрощение администрирования
   - Централизованная безопасность
EOF
  hr
  pause
}

menu(){
  title
  echo "  0) Введение"
  echo "  1) Доменные службы"
  echo "  2) Интеграция с LDAP"
  echo "  3) Kerberos аутентификация"
  echo "  4) Синхронизация времени"
  echo "  5) Единое пространство пользователей"
  echo "  6) Сетевая безопасность домена"
  echo "  7) Интеграция PAM с доменом"
  echo "  8) Итог"
  echo "  a) Всё по порядку"
  echo "  q) Выход"
  read -r -p "$(dim 'Выбор: ')" ch
  case "$ch" in
    0) block_0_intro ;;
    1) block_1_domain_services ;;
    2) block_2_ldap_integration ;;
    3) block_3_kerberos ;;
    4) block_4_time_sync ;;
    5) block_5_unified_users ;;
    6) block_6_network_security_domain ;;
    7) block_7_pam_domain ;;
    8) block_8_summary ;;
    a|A)
      block_0_intro
      block_1_domain_services
      block_2_ldap_integration
      block_3_kerberos
      block_4_time_sync
      block_5_unified_users
      block_6_network_security_domain
      block_7_pam_domain
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

