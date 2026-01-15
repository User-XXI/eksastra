#!/usr/bin/env bash
set -euo pipefail

# Вопрос 19: Построение безопасной аутентификации ОССН на основе архитектуры подключаемых модулей аутентификации (PAM)

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
  echo "$(bold 'Вопрос 19: Безопасная аутентификация на основе PAM')"
  hr
}

block_0_intro(){
  title
  echo "$(bold '0) Архитектура PAM (Pluggable Authentication Modules)')"
  hr
  echo "PAM обеспечивает:"
  echo "  1. Модульную архитектуру аутентификации"
  echo "  2. Гибкую конфигурацию методов аутентификации"
  echo "  3. Поддержку множественных факторов аутентификации"
  echo "  4. Интеграцию с различными системами хранения учётных данных"
  echo "  5. Аудит событий аутентификации"
  hr
  pause
}

block_1_pam_structure(){
  title
  echo "$(bold '1) Структура PAM')"
  hr
  
  run_cmd "ls -la /lib/x86_64-linux-gnu/security/ | head -20 || ls -la /lib64/security/ | head -20 || echo 'Директория модулей PAM недоступна'" \
    "Модули PAM (библиотеки аутентификации)"
  
  run_cmd "ls -la /etc/pam.d/ | head -15 || echo 'Конфигурационные файлы PAM недоступны'" \
    "Конфигурационные файлы PAM для различных сервисов"
  
  run_cmd "cat /etc/pam.d/common-auth 2>/dev/null | head -20 || echo 'common-auth недоступен'" \
    "Общая конфигурация аутентификации"
  
  echo "$(bold 'Структура PAM:')"
  echo "  - Модули: /lib*/security/*.so"
  echo "  - Конфигурация: /etc/pam.d/*"
  echo "  - Типы модулей: auth, account, password, session"
  hr
}

block_2_pam_types(){
  title
  echo "$(bold '2) Типы модулей PAM')"
  hr
  
  run_cmd "cat /etc/pam.d/login 2>/dev/null | head -20 || echo 'login конфиг недоступен'" \
    "Пример конфигурации login (показывает типы модулей)"
  
  echo "$(bold 'Типы модулей PAM:')"
  echo "  1. auth: аутентификация (проверка пароля, биометрия)"
  echo "  2. account: управление учётными записями (блокировка, срок действия)"
  echo "  3. password: изменение пароля"
  echo "  4. session: управление сессией (логирование, монтирование)"
  hr
  
  run_cmd "cat /etc/pam.d/common-session 2>/dev/null | head -15 || echo 'common-session недоступен'" \
    "Конфигурация управления сессиями"
}

block_3_pam_control(){
  title
  echo "$(bold '3) Типы контроля PAM')"
  hr
  
  echo "$(bold 'Типы контроля (как обрабатывать результат модуля):')"
  echo "  - required: обязательно, продолжается проверка"
  echo "  - requisite: обязательно, прекращается при ошибке"
  echo "  - sufficient: достаточно, если успешно — аутентификация успешна"
  echo "  - optional: опционально, не влияет на результат"
  hr
  
  run_cmd "cat /etc/pam.d/common-auth 2>/dev/null | grep -v '^#' | grep -v '^$'" \
    "Примеры использования типов контроля"
  
  run_cmd "cat /etc/pam.d/sudo 2>/dev/null | head -15 || echo 'sudo PAM конфиг недоступен'" \
    "PAM конфигурация для sudo"
}

block_4_pam_modules(){
  title
  echo "$(bold '4) Основные модули PAM')"
  hr
  
  run_cmd "ls /lib/x86_64-linux-gnu/security/pam_*.so 2>/dev/null | head -20 || ls /lib64/security/pam_*.so 2>/dev/null | head -20 || echo 'Модули не найдены'" \
    "Список установленных модулей PAM"
  
  echo "$(bold 'Основные модули:')"
  echo "  - pam_unix: аутентификация через /etc/passwd, /etc/shadow"
  echo "  - pam_ldap: аутентификация через LDAP"
  echo "  - pam_krb5: аутентификация через Kerberos"
  echo "  - pam_tally2: блокировка после неудачных попыток"
  echo "  - pam_limits: ограничения ресурсов"
  hr
  
  run_cmd "dpkg -l | grep -i 'pam-' | head -15 || echo 'PAM пакеты не найдены'" \
    "Установленные пакеты PAM"
}

block_5_security_features(){
  title
  echo "$(bold '5) Функции безопасности PAM в Astra')"
  hr
  
  run_cmd "cat /etc/pam.d/common-auth 2>/dev/null | grep -v '^#' | grep -v '^$'" \
    "Конфигурация безопасной аутентификации"
  
  run_cmd "cat /etc/pam.d/common-password 2>/dev/null | grep -v '^#' | grep -v '^$' | head -10 || echo 'common-password недоступен'" \
    "Конфигурация безопасности паролей"
  
  run_cmd "grep -r 'pam_tally\|pam_faillock' /etc/pam.d/ 2>/dev/null | head -10 || echo 'Модули блокировки не найдены'" \
    "Модули защиты от брутфорса"
  
  echo "$(bold 'Функции безопасности:')"
  echo "  - Блокировка после неудачных попыток"
  echo "  - Требования к сложности пароля"
  echo "  - Ограничение времени сессии"
  echo "  - Аудит событий аутентификации"
  hr
}

block_6_mfa_support(){
  title
  echo "$(bold '6) Поддержка многофакторной аутентификации')"
  hr
  
  run_cmd "grep -r 'pam_otp\|pam_google\|pam_u2f' /etc/pam.d/ 2>/dev/null | head -10 || echo 'MFA модули не найдены'" \
    "Модули многофакторной аутентификации"
  
  run_cmd "dpkg -l | grep -i 'pam.*otp\|pam.*u2f\|pam.*yubico' | head -10 || echo 'MFA пакеты не найдены'" \
    "Установленные пакеты MFA"
  
  echo "$(bold 'MFA через PAM:')"
  echo "  - Модули для OTP (одноразовые пароли)"
  echo "  - Поддержка U2F/WebAuthn"
  echo "  - Интеграция с токенами"
  echo "  - Комбинирование факторов аутентификации"
  hr
}

block_7_pam_audit(){
  title
  echo "$(bold '7) Аудит аутентификации через PAM')"
  hr
  
  run_cmd "grep -r 'pam_lastlog\|pam_warn' /etc/pam.d/ 2>/dev/null | head -10 || echo 'Модули логирования не найдены'" \
    "Модули PAM для логирования"
  
  if have auditctl; then
    run_cmd "sudo auditctl -l 2>/dev/null | grep -i 'login\|auth' | head -10 || echo 'Правила аудита аутентификации не найдены'" \
      "Правила аудита событий аутентификации"
  fi
  
  run_cmd "tail -20 /var/log/auth.log 2>/dev/null || tail -20 /var/log/secure 2>/dev/null || echo 'Логи аутентификации недоступны'" \
    "Логи событий аутентификации"
  
  echo "$(bold 'Аудит через PAM:')"
  echo "  - Фиксация успешных и неудачных попыток входа"
  echo "  - Логирование через pam_lastlog, pam_warn"
  echo "  - Интеграция с auditd"
  echo "  - Отслеживание изменений паролей"
  hr
}

block_8_summary(){
  title
  echo "$(bold 'Итог: безопасная аутентификация на основе PAM')"
  hr
  cat <<'EOF'
Безопасная аутентификация на основе PAM:

1. Архитектура PAM:
   - Модульная структура
   - Гибкая конфигурация
   - Поддержка множественных методов

2. Типы модулей:
   - auth: аутентификация
   - account: управление учётными записями
   - password: изменение пароля
   - session: управление сессией

3. Типы контроля:
   - required: обязательно
   - requisite: обязательно, прекращение при ошибке
   - sufficient: достаточно
   - optional: опционально

4. Основные модули:
   - pam_unix: локальная аутентификация
   - pam_ldap: LDAP аутентификация
   - pam_krb5: Kerberos аутентификация
   - pam_tally2: защита от брутфорса

5. Функции безопасности:
   - Блокировка после неудачных попыток
   - Требования к паролям
   - Ограничения сессий
   - Аудит событий

6. MFA поддержка:
   - OTP модули
   - U2F/WebAuthn
   - Интеграция с токенами

7. Аудит:
   - Фиксация попыток входа
   - Логирование через PAM модули
   - Интеграция с auditd
EOF
  hr
  pause
}

menu(){
  title
  echo "  0) Введение"
  echo "  1) Структура PAM"
  echo "  2) Типы модулей"
  echo "  3) Типы контроля"
  echo "  4) Основные модули"
  echo "  5) Функции безопасности"
  echo "  6) Поддержка MFA"
  echo "  7) Аудит аутентификации"
  echo "  8) Итог"
  echo "  a) Всё по порядку"
  echo "  q) Выход"
  read -r -p "$(dim 'Выбор: ')" ch
  case "$ch" in
    0) block_0_intro ;;
    1) block_1_pam_structure ;;
    2) block_2_pam_types ;;
    3) block_3_pam_control ;;
    4) block_4_pam_modules ;;
    5) block_5_security_features ;;
    6) block_6_mfa_support ;;
    7) block_7_pam_audit ;;
    8) block_8_summary ;;
    a|A)
      block_0_intro
      block_1_pam_structure
      block_2_pam_types
      block_3_pam_control
      block_4_pam_modules
      block_5_security_features
      block_6_mfa_support
      block_7_pam_audit
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

