#!/usr/bin/env bash
set -euo pipefail

# Вопрос 2: Состав и содержание отечественных стандартов серии ГОСТ Р 15408

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
  echo "$(bold 'Вопрос 2: ГОСТ Р 15408 — Отечественные стандарты безопасности')"
  echo "$(dim 'Демонстрация знаний о стандартах серии ГОСТ Р 15408 и их применении в Astra')"
  hr
}

block_0_intro(){
  title
  echo "$(bold '0) Введение в ГОСТ Р 15408')"
  hr
  echo "ГОСТ Р 15408 (российский аналог Common Criteria):"
  echo "  - Часть 1: Введение и общая модель"
  echo "  - Часть 2: Функциональные компоненты безопасности"
  echo "  - Часть 3: Компоненты доверия"
  echo "  - Соответствие международным стандартам ISO/IEC 15408"
  hr
  echo "Ключевые понятия:"
  echo "  - ППМ (Профиль Защиты Мишени) — описание требований"
  echo "  - ЗБ (Заявление о Безопасности) — описание реализации"
  echo "  - ОУ (Объект Оценки) — оцениваемая система"
  hr
  pause
}

block_1_functional_components(){
  title
  echo "$(bold '1) Функциональные компоненты безопасности (ГОСТ Р 15408-2)')"
  hr
  echo "Основные классы функциональности:"
  echo "  - FAU: Аудит безопасности"
  echo "  - FCO: Связь"
  echo "  - FCS: Криптографическая поддержка"
  echo "  - FDP: Защита данных пользователя"
  echo "  - FIA: Идентификация и аутентификация"
  echo "  - FMT: Управление безопасностью"
  echo "  - FPR: Конфиденциальность"
  echo "  - FPT: Защита функций безопасности"
  echo "  - FRU: Использование ресурсов"
  echo "  - FTA: Доступ к объекту оценки"
  echo "  - FTP: Доверенный путь/канал"
  hr
  
  run_cmd "systemctl status auditd --no-pager 2>/dev/null | head -20 || echo 'auditd недоступен'" \
    "FAU: Аудит безопасности — демонстрация функционального компонента"
  
  run_cmd "getfattr -n security.PDPL -m security.PDPL /etc/passwd 2>/dev/null | head -3 || echo 'Метки не найдены'" \
    "FDP: Защита данных пользователя через мандатный контроль"
  
  run_cmd "id" "FIA: Идентификация и аутентификация — текущий пользователь"
  
  run_cmd "cat /sys/module/parsec/parameters/* 2>/dev/null | head -15 || echo 'PARSEC недоступен'" \
    "FMT: Управление безопасностью — параметры политики"
}

block_2_mandatory_access_fdp(){
  title
  echo "$(bold '2) FDP_IFF: Мандатный контроль доступа (функциональный компонент)')"
  hr
  echo "FDP_IFF — мандатная политика контроля доступа:"
  echo "  - FDP_IFF.1: Простая мандатная политика"
  echo "  - FDP_IFF.2: Иерархическая мандатная политика"
  echo "  - FDP_IFF.3: Расширенная мандатная политика"
  echo "  - FDP_IFF.4: Многоуровневая мандатная политика"
  echo "  - FDP_IFF.5: Мандатная политика с ограничениями"
  hr
  
  run_cmd "cat /sys/module/parsec/parameters/max_ilev 2>/dev/null || echo 'max_ilev недоступен'" \
    "Проверяю максимальный уровень целостности — часть мандатной политики"
  
  run_cmd "getfattr -n security.ILEV -m security.ILEV /bin/bash 2>/dev/null | head -3 || echo 'Уровни целостности не найдены'" \
    "Демонстрирую уровни целостности (многоуровневая мандатная политика)"
  
  run_cmd "getfattr -n security.CLEV -m security.CLEV /etc/shadow 2>/dev/null | head -3 || echo 'Уровни конфиденциальности не найдены'" \
    "Уровни конфиденциальности — часть мандатного контроля доступа"
}

block_3_audit_fau(){
  title
  echo "$(bold '3) FAU: Аудит безопасности (ГОСТ Р 15408-2)')"
  hr
  echo "Компоненты аудита:"
  echo "  - FAU_GEN: Генерация событий аудита"
  echo "  - FAU_SAR: Автоматический анализ"
  echo "  - FAU_SEL: Выбор событий"
  echo "  - FAU_STG: Хранение аудита"
  hr
  
  run_cmd "systemctl is-active auditd 2>/dev/null && echo 'Аудит активен' || echo 'Аудит неактивен'" \
    "Проверяю активность подсистемы аудита"
  
  if have auditctl; then
    run_cmd "auditctl -s 2>/dev/null || true" "FAU_GEN: Состояние генерации событий"
    run_cmd "auditctl -l 2>/dev/null | head -20 || true" \
      "FAU_SEL: Правила выбора событий для аудита"
  fi
  
  run_cmd "ls -la /var/log/audit/ 2>/dev/null | head -10 || echo 'Директория аудита недоступна'" \
    "FAU_STG: Хранение записей аудита"
  
  run_cmd "journalctl -u auditd -n 10 --no-pager 2>/dev/null || true" \
    "Проверяю работу службы аудита через journal"
}

block_4_assurance_components(){
  title
  echo "$(bold '4) Компоненты доверия (ГОСТ Р 15408-3)')"
  hr
  echo "Основные классы доверия:"
  echo "  - ACM: Конфигурационное управление"
  echo "  - ADO: Доставка и эксплуатация"
  echo "  - ADV: Разработка"
  echo "  - AGD: Руководства"
  echo "  - ALC: Поддержка жизненного цикла"
  echo "  - ATE: Тестирование"
  echo "  - AVA: Оценка уязвимостей"
  echo "  - ACO: Состав"
  hr
  
  run_cmd "cat /etc/os-release" "ADO: Доставка — информация о поставке системы"
  
  run_cmd "dpkg -l | grep -i 'astra\|parsec\|security' | head -10 || true" \
    "ACO: Состав — компоненты системы безопасности"
  
  run_cmd "find /usr/share/doc -name '*security*' -o -name '*guide*' 2>/dev/null | head -10 || true" \
    "AGD: Руководства — документация для администраторов"
  
  run_cmd "uname -r" "ADV: Разработка — версия ядра показывает уровень разработки"
}

block_5_security_targets(){
  title
  echo "$(bold '5) Профили защиты и заявления о безопасности')"
  hr
  echo "ППМ (Профиль Защиты Мишени):"
  echo "  - Описание типовых угроз"
  echo "  - Цели безопасности"
  echo "  - Требования безопасности"
  echo ""
  echo "ЗБ (Заявление о Безопасности):"
  echo "  - Описание реализации"
  echo "  - ППМ, на который опирается"
  echo "  - Дополнительные требования"
  hr
  
  run_cmd "dpkg -l | grep -i 'certificate\|fstec\|gost' | head -10 || true" \
    "Ищу информацию о сертификации и соответствии ППМ"
  
  run_cmd "cat /etc/astra_version 2>/dev/null || echo 'Версия Astra недоступна'" \
    "Проверяю версию — важна для соответствия конкретному ЗБ"
  
  run_cmd "ls -la /usr/share/doc/*/copyright 2>/dev/null | head -5 || true" \
    "Информация о лицензировании компонентов — часть ЗБ"
}

block_6_evaluation_levels(){
  title
  echo "$(bold '6) Уровни оценки доверия (EAL)')"
  hr
  echo "Уровни оценки:"
  echo "  - EAL1: Функционально протестированный"
  echo "  - EAL2: Структурно протестированный"
  echo "  - EAL3: Методически протестированный и проверенный"
  echo "  - EAL4: Методически разработанный, протестированный и проверенный"
  echo "  - EAL5: Полуформально разработанный и протестированный"
  echo "  - EAL6: Полуформально верифицированный проект и протестированный"
  echo "  - EAL7: Формально верифицированный проект и протестированный"
  hr
  
  echo "Astra Linux SE обычно имеет оценку EAL4 или выше"
  echo "(формальная верификация отдельных компонентов может достигать EAL6-7)"
  hr
  
  run_cmd "cat /etc/os-release | grep -i version" "Версия системы — важна для определения уровня оценки"
  
  run_cmd "dpkg -l | grep -i 'parsec\|security' | wc -l" \
    "Количество компонентов безопасности — влияет на сложность оценки"
}

block_7_application_astra(){
  title
  echo "$(bold '7) Применение ГОСТ Р 15408 к Astra Linux SE')"
  hr
  
  echo "Функциональные требования, реализованные в Astra:"
  hr
  
  run_cmd "cat /sys/module/parsec/parameters/* 2>/dev/null | head -20 || echo 'PARSEC недоступен'" \
    "FDP_IFF: Мандатный контроль доступа (реализован через PARSEC)"
  
  run_cmd "systemctl status auditd --no-pager 2>/dev/null | head -10 || echo 'auditd недоступен'" \
    "FAU: Аудит безопасности (auditd)"
  
  run_cmd "id" "FIA: Идентификация и аутентификация"
  
  run_cmd "lsmod | grep -i parsec || echo 'PARSEC не загружен'" \
    "FPT: Защита функций безопасности (на уровне ядра)"
  
  run_cmd "cat /proc/cmdline" "FTP: Доверенный путь загрузки (через параметры ядра)"
}

block_8_summary(){
  title
  echo "$(bold 'Итоговая сводка по ГОСТ Р 15408')"
  hr
  cat <<'EOF'
Ключевые моменты:

1. Структура ГОСТ Р 15408:
   - Часть 1: Общая модель
   - Часть 2: Функциональные компоненты (11 классов)
   - Часть 3: Компоненты доверия (8 классов)

2. Основные функциональные классы:
   - FDP: Защита данных пользователя
   - FIA: Идентификация и аутентификация
   - FAU: Аудит безопасности
   - FMT: Управление безопасностью

3. Уровни оценки (EAL):
   - EAL1-EAL4: Стандартные уровни
   - EAL5-EAL7: Высокие уровни с формальной верификацией

4. Применение к Astra Linux SE:
   - Реализация мандатного контроля (FDP_IFF)
   - Полный аудит (FAU)
   - Защита на уровне ядра (FPT)
   - Сертификация ФСТЭК России

5. Преемственность:
   - Соответствие ISO/IEC 15408
   - Совместимость с Common Criteria
   - Учёт российских требований
EOF
  hr
  pause
}

menu(){
  title
  echo "Выбери блок для демонстрации:"
  echo
  echo "  0) Введение в ГОСТ Р 15408"
  echo "  1) Функциональные компоненты безопасности"
  echo "  2) Мандатный контроль доступа (FDP_IFF)"
  echo "  3) Аудит безопасности (FAU)"
  echo "  4) Компоненты доверия"
  echo "  5) Профили защиты и заявления"
  echo "  6) Уровни оценки доверия (EAL)"
  echo "  7) Применение к Astra Linux SE"
  echo "  8) Итоговая сводка"
  echo "  a) Пройти всё по порядку (0→8)"
  echo "  q) Выход"
  echo
  read -r -p "$(dim 'Твой выбор: ')" ch
  case "$ch" in
    0) block_0_intro ;;
    1) block_1_functional_components ;;
    2) block_2_mandatory_access_fdp ;;
    3) block_3_audit_fau ;;
    4) block_4_assurance_components ;;
    5) block_5_security_targets ;;
    6) block_6_evaluation_levels ;;
    7) block_7_application_astra ;;
    8) block_8_summary ;;
    a|A)
      block_0_intro
      block_1_functional_components
      block_2_mandatory_access_fdp
      block_3_audit_fau
      block_4_assurance_components
      block_5_security_targets
      block_6_evaluation_levels
      block_7_application_astra
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

