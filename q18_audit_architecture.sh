#!/usr/bin/env bash
set -euo pipefail

# Вопрос 18: Архитектура подсистемы аудита ОССН

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
  echo "$(bold 'Вопрос 18: Архитектура подсистемы аудита ОССН')"
  hr
}

block_0_intro(){
  title
  echo "$(bold '0) Компоненты архитектуры аудита')"
  hr
  echo "Архитектура подсистемы аудита:"
  echo "  1. auditd — демон аудита (сбор событий)"
  echo "  2. auditctl — утилита управления правилами"
  echo "  3. audispd — плагин для обработки событий"
  echo "  4. Хранилище записей аудита (логи)"
  echo "  5. Инструменты анализа (ausearch, aureport)"
  hr
  pause
}

block_1_auditd_daemon(){
  title
  echo "$(bold '1) Демон аудита (auditd)')"
  hr
  
  run_cmd "systemctl status auditd --no-pager 2>/dev/null | head -20 || echo 'auditd недоступен'" \
    "Статус службы аудита"
  
  run_cmd "systemctl is-active auditd 2>/dev/null && echo 'Аудит активен' || echo 'Аудит неактивен'" \
    "Проверка активности аудита"
  
  run_cmd "ps aux | grep auditd | grep -v grep | head -5 || echo 'Процесс auditd не найден'" \
    "Процесс демона аудита"
  
  run_cmd "cat /etc/audit/auditd.conf 2>/dev/null | grep -v '^#' | grep -v '^$' | head -20 || echo 'Конфигурация недоступна'" \
    "Конфигурация демона аудита"
}

block_2_audit_rules(){
  title
  echo "$(bold '2) Правила аудита (auditctl)')"
  hr
  
  if have auditctl; then
    run_cmd "sudo auditctl -s 2>/dev/null || true" "Статус подсистемы аудита"
    
    run_cmd "sudo auditctl -l 2>/dev/null | head -30 || echo 'Правила не найдены'" \
      "Текущие правила аудита"
    
    run_cmd "cat /etc/audit/rules.d/*.rules 2>/dev/null | grep -v '^#' | grep -v '^$' | head -30 || echo 'Правила в файлах не найдены'" \
      "Правила из конфигурационных файлов"
  else
    echo "$(ylw 'auditctl недоступен. Показываю конфигурационные файлы:')"
    run_cmd "ls -la /etc/audit/rules.d/ 2>/dev/null || echo 'Директория правил недоступна'"
  fi
}

block_3_audit_logs(){
  title
  echo "$(bold '3) Хранилище записей аудита')"
  hr
  
  run_cmd "ls -la /var/log/audit/ 2>/dev/null | head -15 || echo 'Директория логов аудита недоступна'" \
    "Файлы логов аудита"
  
  run_cmd "tail -20 /var/log/audit/audit.log 2>/dev/null || echo 'Файл логов недоступен'" \
    "Последние записи в журнале аудита"
  
  run_cmd "df -h /var/log/audit 2>/dev/null || df -h /var/log" \
    "Использование дискового пространства для логов"
  
  echo "$(bold 'Хранилище записей:')"
  echo "  - /var/log/audit/audit.log — основной журнал"
  echo "  - Ротация логов по размеру/времени"
  echo "  - Защита от модификации (только добавление)"
  hr
}

block_4_audit_analysis(){
  title
  echo "$(bold '4) Инструменты анализа аудита')"
  hr
  
  if have ausearch; then
    run_cmd "ausearch --help 2>/dev/null | head -20" \
      "Справка по ausearch (поиск событий)"
    
    run_cmd "sudo ausearch -m all 2>/dev/null | tail -10 || echo 'События не найдены'" \
      "Последние события аудита"
  else
    echo "$(ylw 'ausearch недоступен')"
  fi
  
  if have aureport; then
    run_cmd "aureport --help 2>/dev/null | head -20" \
      "Справка по aureport (отчёты)"
    
    run_cmd "sudo aureport --summary 2>/dev/null | head -20 || echo 'Отчёт недоступен'" \
      "Сводный отчёт по событиям аудита"
  else
    echo "$(ylw 'aureport недоступен')"
  fi
  
  run_cmd "journalctl -u auditd -n 20 --no-pager 2>/dev/null || true" \
    "Логи службы аудита через journal"
}

block_5_audit_events(){
  title
  echo "$(bold '5) Типы событий аудита')"
  hr
  
  echo "$(bold 'Категории событий:')"
  echo "  - file_access: доступ к файлам"
  echo "  - system_call: системные вызовы"
  echo "  - user_login: вход пользователей"
  echo "  - permission_change: изменение прав"
  echo "  - network: сетевые операции"
  echo "  - security: события безопасности"
  hr
  
  if have ausearch; then
    run_cmd "sudo ausearch -m file_access 2>/dev/null | tail -5 || echo 'События доступа не найдены'" \
      "Примеры событий доступа к файлам"
    
    run_cmd "sudo ausearch -m user_login 2>/dev/null | tail -5 || echo 'События входа не найдены'" \
      "Примеры событий входа пользователей"
  fi
}

block_6_audit_integration(){
  title
  echo "$(bold '6) Интеграция аудита с системой безопасности')"
  hr
  
  run_cmd "dmesg | grep -i audit | tail -10 || echo 'Сообщения ядра об аудите не найдены'" \
    "Интеграция аудита с ядром"
  
  run_cmd "cat /sys/module/parsec/parameters/* 2>/dev/null | grep -i audit | head -5 || echo 'Параметры интеграции не найдены'" \
    "Интеграция аудита с PARSEC"
  
  echo "$(bold 'Интеграция аудита:')"
  echo "  - Аудит тесно интегрирован с ядром"
  echo "  - События безопасности фиксируются PARSEC и передаются в аудит"
  echo "  - Невозможность отключения критичного аудита"
  hr
}

block_7_audit_security(){
  title
  echo "$(bold '7) Защита подсистемы аудита')"
  hr
  
  run_cmd "ls -la /var/log/audit/audit.log 2>/dev/null" \
    "Права доступа к журналу аудита"
  
  run_cmd "chattr /var/log/audit/audit.log 2>/dev/null || lsattr /var/log/audit/audit.log 2>/dev/null || echo 'Атрибуты файла недоступны'" \
    "Проверка атрибутов файла (защита от удаления)"
  
  echo "$(bold 'Защита подсистемы аудита:')"
  echo "  - Логи защищены от модификации"
  echo "  - Только добавление записей разрешено"
  echo "  - Ротация логов с сохранением целостности"
  echo "  - Резервное копирование логов"
  hr
}

block_8_summary(){
  title
  echo "$(bold 'Итог: архитектура подсистемы аудита')"
  hr
  cat <<'EOF'
Архитектура подсистемы аудита ОССН:

1. Компоненты:
   - auditd: демон сбора событий
   - auditctl: управление правилами
   - audispd: обработка событий
   - Хранилище: /var/log/audit/

2. Правила аудита:
   - Определяют, какие события фиксировать
   - Настраиваются через auditctl
   - Хранятся в /etc/audit/rules.d/

3. Хранилище записей:
   - Основной журнал: audit.log
   - Ротация по размеру/времени
   - Защита от модификации

4. Инструменты анализа:
   - ausearch: поиск событий
   - aureport: генерация отчётов
   - journalctl: просмотр через systemd

5. Типы событий:
   - Доступ к файлам
   - Системные вызовы
   - Вход пользователей
   - Изменение прав
   - Сетевые операции

6. Интеграция:
   - Интеграция с ядром
   - Интеграция с PARSEC
   - Невозможность отключения критичного аудита

7. Защита:
   - Защита логов от модификации
   - Только добавление записей
   - Резервное копирование
EOF
  hr
  pause
}

menu(){
  title
  echo "  0) Введение"
  echo "  1) Демон auditd"
  echo "  2) Правила аудита"
  echo "  3) Хранилище записей"
  echo "  4) Инструменты анализа"
  echo "  5) Типы событий"
  echo "  6) Интеграция с безопасностью"
  echo "  7) Защита подсистемы"
  echo "  8) Итог"
  echo "  a) Всё по порядку"
  echo "  q) Выход"
  read -r -p "$(dim 'Выбор: ')" ch
  case "$ch" in
    0) block_0_intro ;;
    1) block_1_auditd_daemon ;;
    2) block_2_audit_rules ;;
    3) block_3_audit_logs ;;
    4) block_4_audit_analysis ;;
    5) block_5_audit_events ;;
    6) block_6_audit_integration ;;
    7) block_7_audit_security ;;
    8) block_8_summary ;;
    a|A)
      block_0_intro
      block_1_auditd_daemon
      block_2_audit_rules
      block_3_audit_logs
      block_4_audit_analysis
      block_5_audit_events
      block_6_audit_integration
      block_7_audit_security
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

