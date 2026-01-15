#!/usr/bin/env bash
set -euo pipefail

# Вопрос 9: Управление политикой безопасности в ОССН (уровни безопасности, ведение иерархических категорий, привилегии)

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
  echo "$(bold 'Вопрос 9: Управление политикой безопасности')"
  echo "$(dim 'Уровни безопасности, категории, привилегии')"
  hr
}

block_0_intro(){
  title
  echo "$(bold '0) Компоненты политики безопасности')"
  hr
  echo "Управление политикой включает:"
  echo "  1. Уровни безопасности (иерархия уровней)"
  echo "  2. Иерархические категории (темы/классификации)"
  echo "  3. Привилегии (специальные права доступа)"
  hr
  pause
}

block_1_security_levels(){
  title
  echo "$(bold '1) Уровни безопасности (иерархия)')"
  hr
  
  run_cmd "cat /sys/module/parsec/parameters/max_ilev 2>/dev/null || echo 'max_ilev недоступен'" \
    "Максимальный уровень целостности (верхняя граница системы)"
  
  run_cmd "cat /sys/module/parsec/parameters/* 2>/dev/null | grep -i 'level\|lev' | head -10 || echo 'Параметры уровней не найдены'" \
    "Параметры уровней безопасности в PARSEC"
  
  run_cmd "command -v astra-security-monitor >/dev/null && sudo astra-security-monitor 2>/dev/null | head -30 || echo 'astra-security-monitor недоступен'" \
    "Монитор безопасности — просмотр текущих уровней"
  
  echo "$(bold 'Уровни безопасности обычно представляют числовую иерархию:')"
  echo "  - 0: Публичный"
  echo "  - 1-2: Внутренний"
  echo "  - 3+: Конфиденциальный/Секретный"
  hr
}

block_2_categories(){
  title
  echo "$(bold '2) Иерархические категории')"
  hr
  
  echo "Категории используются для классификации по темам:"
  echo "  - CCNR: Конфиденциальная информация ограниченного распространения"
  echo "  - И другие категории по политике организации"
  hr
  
  run_cmd "getfattr -n security.PDPL -m security.PDPL /etc/passwd 2>/dev/null | head -5 || echo 'PDPL метки не найдены'" \
    "Пример PDPL метки (содержит категории)"
  
  if have pdpl-file; then
    run_cmd "pdpl-file -h 2>/dev/null | grep -i 'categor\|CCNR' | head -10 || pdpl-file -h 2>/dev/null | head -20" \
      "Справка по категориям в pdpl-file"
  fi
  
  run_cmd "getfattr -d -m 'security\\.' /etc/passwd 2>/dev/null | grep -i 'categor\|ccnr' | head -5 || echo 'Категории не найдены'" \
    "Поиск категорий в метках объектов"
}

block_3_privileges(){
  title
  echo "$(bold '3) Привилегии (специальные права)')"
  hr
  
  run_cmd "id" "Текущие привилегии пользователя"
  
  run_cmd "sudo -l 2>/dev/null | head -20 || echo 'Нет sudo прав или не настроен'" \
    "Привилегии sudo (ролевой доступ)"
  
  run_cmd "groups" "Группы пользователя (могут давать привилегии)"
  
  run_cmd "getcap -r /usr/bin 2>/dev/null | head -10 || echo 'getcap недоступен или нет capabilities'" \
    "Capabilities (расширенные привилегии Linux)"
  
  echo "$(bold 'В контексте МРД:')"
  echo "  - Привилегии могут позволять обходить некоторые ограничения"
  echo "  - Но мандатный контроль остаётся обязательным"
  hr
}

block_4_policy_configuration(){
  title
  echo "$(bold '4) Конфигурация политики безопасности')"
  hr
  
  run_cmd "cat /sys/module/parsec/parameters/* 2>/dev/null | head -30 || echo 'Параметры недоступны'" \
    "Текущая конфигурация политики (параметры PARSEC)"
  
  run_cmd "ls -la /etc/security/ 2>/dev/null | head -15 || echo 'Директория безопасности недоступна'" \
    "Конфигурационные файлы политики безопасности"
  
  run_cmd "find /etc -name '*security*' -o -name '*parsec*' -o -name '*policy*' 2>/dev/null | head -15 || true" \
    "Поиск файлов конфигурации политики"
  
  run_cmd "systemctl list-units | grep -i 'security\|policy' || true" \
    "Службы, связанные с управлением политикой"
}

block_5_policy_modification(){
  title
  echo "$(bold '5) Изменение политики (требует прав администратора)')"
  hr
  
  echo "$(bold 'ВАЖНО: Изменение политики безопасности требует прав root и должно выполняться с осторожностью')"
  hr
  
  run_cmd "cat /sys/module/parsec/parameters/mac_enabled 2>/dev/null || echo 'Параметр недоступен'" \
    "Проверка включения мандатного контроля"
  
  run_cmd "cat /sys/module/parsec/parameters/integrity_enabled 2>/dev/null || echo 'Параметр недоступен'" \
    "Проверка включения контроля целостности"
  
  echo "$(ylw 'Примечание: Изменение параметров через /sys обычно требует перезагрузки или перезагрузки модуля')"
  hr
  
  if have pdpl-file; then
    run_cmd "pdpl-file -h 2>/dev/null | head -30" \
      "Инструмент для изменения мандатных меток (часть политики)"
  fi
}

block_6_audit_policy(){
  title
  echo "$(bold '6) Аудит изменений политики')"
  hr
  
  if have auditctl; then
    run_cmd "sudo auditctl -l 2>/dev/null | grep -i 'policy\|security\|parsec' | head -10 || echo 'Правила не найдены'" \
      "Правила аудита изменений политики"
    
    run_cmd "sudo ausearch -m config 2>/dev/null | tail -10 || echo 'События конфигурации не найдены'" \
      "Поиск событий изменения конфигурации"
  fi
  
  run_cmd "journalctl -u auditd -n 20 --no-pager 2>/dev/null | grep -i 'policy\|security' | head -10 || echo 'События не найдены'" \
    "Логи изменений политики через journal"
}

block_7_summary(){
  title
  echo "$(bold 'Итог: управление политикой безопасности')"
  hr
  cat <<'EOF'
Управление политикой безопасности включает:

1. Уровни безопасности:
   - Иерархическая структура уровней
   - Максимальный уровень системы (max_ilev)
   - Назначение уровней объектам и субъектам

2. Иерархические категории:
   - Классификация по темам (CCNR и др.)
   - Часть мандатных меток
   - Используются для разграничения доступа

3. Привилегии:
   - Специальные права доступа
   - Sudo, capabilities, группы
   - Работают совместно с МРД

4. Конфигурация:
   - Параметры PARSEC в /sys/module/parsec/parameters
   - Конфигурационные файлы в /etc
   - Монитор безопасности для просмотра

5. Изменение политики:
   - Требует прав администратора
   - Аудит всех изменений
   - Влияет на всю систему безопасности
EOF
  hr
  pause
}

menu(){
  title
  echo "  0) Введение"
  echo "  1) Уровни безопасности"
  echo "  2) Иерархические категории"
  echo "  3) Привилегии"
  echo "  4) Конфигурация политики"
  echo "  5) Изменение политики"
  echo "  6) Аудит изменений"
  echo "  7) Итог"
  echo "  a) Всё по порядку"
  echo "  q) Выход"
  read -r -p "$(dim 'Выбор: ')" ch
  case "$ch" in
    0) block_0_intro ;;
    1) block_1_security_levels ;;
    2) block_2_categories ;;
    3) block_3_privileges ;;
    4) block_4_policy_configuration ;;
    5) block_5_policy_modification ;;
    6) block_6_audit_policy ;;
    7) block_7_summary ;;
    a|A)
      block_0_intro
      block_1_security_levels
      block_2_categories
      block_3_privileges
      block_4_policy_configuration
      block_5_policy_modification
      block_6_audit_policy
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

