#!/usr/bin/env bash
set -euo pipefail

# Вопрос 3: Назначение ОССН и её общая архитектура

DEMO_MUTATE="${DEMO_MUTATE:-0}"
AUTO_ENTER="${AUTO_ENTER:-0}"
USE_SUDO="${USE_SUDO:-auto}"

bold(){ printf "\033[1m%s\033[0m" "$*"; }
dim(){  printf "\033[2m%s\033[0m" "$*"; }
cyan(){ printf "\033[36m%s\033[0m" "$*"; }
grn(){  printf "\033[32m%s\033[0m" "$*"; }
ylw(){  printf "\033[33m%s\033[0m" "$*"; }
red(){  printf "\033[31m%s\033[0m" "$*"; }
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
  echo "$(bold 'Вопрос 3: Назначение ОССН и её общая архитектура')"
  echo "$(dim 'Демонстрация назначения и архитектурных компонентов ОССН Astra Linux SE')"
  hr
}

block_0_purpose(){
  title
  echo "$(bold '0) Назначение ОССН (Отечественная Специализированная ОС)')"
  hr
  echo "Основные назначения ОССН:"
  echo "  1. Защищённая обработка информации различной степени конфиденциальности"
  echo "  2. Обработка информации, содержащей государственную тайну"
  echo "  3. Выполнение требований регуляторов (ФСТЭК России)"
  echo "  4. Создание защищённых автоматизированных систем"
  echo "  5. Обеспечение гарантированного выполнения политик безопасности"
  hr
  echo "Области применения:"
  echo "  - Государственные информационные системы"
  echo "  - Военные и оборонные системы"
  echo "  - Критически важные объекты инфраструктуры"
  echo "  - Системы обработки персональных данных"
  echo "  - Банковские и финансовые системы"
  hr
  pause
}

block_1_os_architecture(){
  title
  echo "$(bold '1) Общая архитектура ОС: ядро + userland + пакеты + сервисы')"
  hr
  
  run_cmd "cat /etc/os-release" "Идентификация ОС — база архитектуры"
  
  run_cmd "uname -r" "Версия ядра — фундаментальный компонент архитектуры"
  
  run_cmd "uname -m" "Архитектура процессора — аппаратный уровень"
  
  run_cmd "dpkg -l | wc -l" "Количество пакетов — состав программного обеспечения"
  
  run_cmd "systemctl list-units --type=service --state=running | wc -l" \
    "Количество активных служб — сервисный уровень"
  
  run_cmd "lscpu | head -15" "Аппаратные характеристики — среда выполнения"
}

block_2_kernel_layer(){
  title
  echo "$(bold '2) Уровень ядра (Kernel Layer)')"
  hr
  echo "Компоненты ядра:"
  echo "  - Ядро Linux с модификациями для безопасности"
  echo "  - Модуль PARSEC (подсистема мандатного контроля)"
  echo "  - LSM (Linux Security Modules) хуки"
  echo "  - Монитор ссылок (Reference Monitor)"
  hr
  
  run_cmd "cat /proc/version" "Информация о ядре и его сборке"
  
  run_cmd "lsmod | head -20" "Загруженные модули ядра"
  
  run_cmd "lsmod | grep -i parsec || echo 'PARSEC не загружен'" \
    "Модуль PARSEC — ключевой компонент безопасности на уровне ядра"
  
  run_cmd "cat /proc/cmdline" "Параметры загрузки ядра — конфигурация низкого уровня"
  
  run_cmd "dmesg | grep -i 'security\|parsec\|lsm' | tail -10 || true" \
    "Сообщения ядра о подсистемах безопасности"
}

block_3_userland_layer(){
  title
  echo "$(bold '3) Уровень пользовательского пространства (Userland)')"
  hr
  echo "Компоненты userland:"
  echo "  - Стандартные утилиты GNU/Linux"
  echo "  - Специализированные инструменты КСЗ"
  echo "  - Утилиты управления мандатным доступом"
  echo "  - Инструменты администрирования"
  hr
  
  run_cmd "which bash" "Стандартные утилиты — базовый набор"
  
  run_cmd "command -v pdpl-file >/dev/null && echo 'pdpl-file найден' || echo 'pdpl-file не найден'" \
    "Специализированные утилиты КСЗ"
  
  run_cmd "command -v astra-security-monitor >/dev/null && echo 'astra-security-monitor найден' || echo 'не найден'" \
    "Инструменты мониторинга безопасности"
  
  run_cmd "dpkg -l | grep -i 'astra\|fly' | head -10 || true" \
    "Специализированные пакеты Astra Linux"
  
  run_cmd "ls -la /usr/bin/*astra* /usr/sbin/*astra* 2>/dev/null | head -10 || echo 'Утилиты не найдены'" \
    "Утилиты управления системой Astra"
}

block_4_packages_layer(){
  title
  echo "$(bold '4) Уровень пакетов (Packages Layer)')"
  hr
  echo "Типы пакетов:"
  echo "  - Базовые пакеты системы"
  echo "  - Пакеты безопасности (PARSEC, audit)"
  echo "  - Пакеты доменной инфраструктуры (ALD, Kerberos)"
  echo "  - Инструменты администрирования"
  echo "  - Сертифицированное ПО"
  hr
  
  run_cmd "grep -h '^deb ' /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null | head -10" \
    "Репозитории пакетов — источники ПО"
  
  run_cmd "dpkg -l | grep -i 'parsec\|security' | head -15 || true" \
    "Пакеты безопасности"
  
  run_cmd "dpkg -l | grep -i 'ald\|krb5\|sssd' | head -15 || true" \
    "Пакеты доменной инфраструктуры"
  
  run_cmd "dpkg -l | grep -i 'fly-admin\|fly' | head -10 || true" \
    "Пакеты администрирования Fly"
}

block_5_services_layer(){
  title
  echo "$(bold '5) Уровень служб (Services Layer)')"
  hr
  echo "Ключевые службы:"
  echo "  - auditd: служба аудита"
  echo "  - система инициализации (systemd)"
  echo "  - сетевые службы"
  echo "  - доменные службы (SSSD, Kerberos)"
  hr
  
  run_cmd "systemctl status auditd --no-pager 2>/dev/null | head -15 || echo 'auditd недоступен'" \
    "Служба аудита — обязательный компонент ОССН"
  
  run_cmd "systemctl list-units --type=service --state=running | grep -iE 'security|audit|ald|krb' | head -10 || true" \
    "Службы безопасности и домена"
  
  run_cmd "systemctl is-system-running 2>/dev/null || echo 'Статус недоступен'" \
    "Общее состояние системы"
  
  run_cmd "systemctl list-units --failed 2>/dev/null | head -10 || echo 'Нет упавших служб'" \
    "Проверка работоспособности служб"
}

block_6_security_architecture(){
  title
  echo "$(bold '6) Архитектура безопасности ОССН')"
  hr
  echo "Компоненты архитектуры безопасности:"
  echo "  1. КСЗ (Комплекс средств защиты) на базе PARSEC"
  echo "  2. Режимы МРД (Мандатный разграничительный доступ)"
  echo "  3. Режимы МКЦ (Мандатный контроль целостности)"
  echo "  4. Аудит всех событий безопасности"
  echo "  5. Доменная инфраструктура (ALD/LDAP/Kerberos)"
  echo "  6. Управление доступом к графической подсистеме"
  hr
  
  run_cmd "cat /sys/module/parsec/parameters/max_ilev 2>/dev/null || echo 'PARSEC недоступен'" \
    "Параметры КСЗ — максимальный уровень целостности"
  
  run_cmd "systemctl status auditd --no-pager 2>/dev/null | head -5 || echo 'Аудит недоступен'" \
    "Подсистема аудита — фиксация событий"
  
  run_cmd "systemctl list-units | grep -iE 'ald|sssd|krb' | head -5 || true" \
    "Доменная инфраструктура — централизованное управление"
  
  run_cmd "getfattr -n security.PDPL -m security.PDPL / 2>/dev/null | head -3 || echo 'Мандатные метки не найдены'" \
    "Мандатный контроль доступа — наличие меток"
}

block_7_integration_layers(){
  title
  echo "$(bold '7) Интеграция уровней архитектуры')"
  hr
  echo "Взаимодействие уровней:"
  echo "  Ядро → Userland: системные вызовы, /proc, /sys"
  echo "  Userland → Пакеты: управление через менеджеры пакетов"
  echo "  Пакеты → Службы: конфигурация и запуск служб"
  echo "  Службы → Безопасность: обеспечение политик безопасности"
  hr
  
  run_cmd "cat /sys/module/parsec/parameters/* 2>/dev/null | head -15 || echo 'Параметры недоступны'" \
    "Ядро → /sys: параметры PARSEC доступны из userland"
  
  run_cmd "dpkg -l | grep -i 'audit' | head -5 || true" \
    "Пакеты → Службы: пакет auditd обеспечивает службу аудита"
  
  run_cmd "systemctl status auditd --no-pager 2>/dev/null | grep -i 'loaded\|active' | head -3 || true" \
    "Интеграция: пакет → служба → активность"
  
  run_cmd "ls -la /proc/sys/kernel/ | head -10" \
    "Интерфейс ядро-userland через /proc/sys"
}

block_8_summary(){
  title
  echo "$(bold 'Итоговая сводка по архитектуре ОССН')"
  hr
  cat <<'EOF'
Архитектура ОССН Astra Linux SE:

1. Назначение:
   - Защищённая обработка конфиденциальной информации
   - Соответствие требованиям регуляторов
   - Государственные и критически важные системы

2. Уровни архитектуры ОС:
   - Ядро: Linux + PARSEC + LSM хуки
   - Userland: стандартные + специализированные утилиты
   - Пакеты: базовые + безопасность + домен + администрирование
   - Службы: auditd + доменные + сетевые

3. Архитектура безопасности:
   - КСЗ на базе PARSEC
   - Мандатный контроль доступа (МРД)
   - Мандатный контроль целостности (МКЦ)
   - Аудит всех событий
   - Доменная инфраструктура

4. Интеграция:
   - Все уровни взаимосвязаны
   - Безопасность пронизывает всю архитектуру
   - Гарантированное выполнение политик
EOF
  hr
  pause
}

menu(){
  title
  echo "Выбери блок для демонстрации:"
  echo
  echo "  0) Назначение ОССН"
  echo "  1) Общая архитектура ОС"
  echo "  2) Уровень ядра"
  echo "  3) Уровень userland"
  echo "  4) Уровень пакетов"
  echo "  5) Уровень служб"
  echo "  6) Архитектура безопасности"
  echo "  7) Интеграция уровней"
  echo "  8) Итоговая сводка"
  echo "  a) Пройти всё по порядку (0→8)"
  echo "  q) Выход"
  echo
  read -r -p "$(dim 'Твой выбор: ')" ch
  case "$ch" in
    0) block_0_purpose ;;
    1) block_1_os_architecture ;;
    2) block_2_kernel_layer ;;
    3) block_3_userland_layer ;;
    4) block_4_packages_layer ;;
    5) block_5_services_layer ;;
    6) block_6_security_architecture ;;
    7) block_7_integration_layers ;;
    8) block_8_summary ;;
    a|A)
      block_0_purpose
      block_1_os_architecture
      block_2_kernel_layer
      block_3_userland_layer
      block_4_packages_layer
      block_5_services_layer
      block_6_security_architecture
      block_7_integration_layers
      block_8_summary
      ;;
    q|Q) exit 0 ;;
    *) echo "$(ylw 'Не понял. Давай ещё раз.')"; pause ;;
  esac
}

while true; do
  menu
  pause
done

