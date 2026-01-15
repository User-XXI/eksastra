#!/usr/bin/env bash
set -euo pipefail

# Вопрос 1: Основные международные стандарты и руководящие документы 
# в области моделей безопасности и мандатного доступа
# (Оранжевая книга, Красная книга)

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
  echo "$(bold 'Вопрос 1: Международные стандарты безопасности (Оранжевая/Красная книга)')"
  echo "$(dim 'Демонстрация знаний об исторических и современных стандартах безопасности')"
  hr
}

block_0_intro(){
  title
  echo "$(bold '0) Введение в стандарты безопасности')"
  hr
  echo "Оранжевая книга (TCSEC, 1985):"
  echo "  - Классификация систем защиты: D, C1-C2, B1-B3, A1"
  echo "  - Мандатный контроль доступа (MAC) с класса B1"
  echo "  - Аудит безопасности и монитор ссылок"
  echo ""
  echo "Красная книга (TNI, 1987):"
  echo "  - Расширение Оранжевой книги на сети"
  echo "  - Требования к межсетевым экранам и защищённым коммуникациям"
  hr
  pause
}

block_1_astra_compliance(){
  title
  echo "$(bold '1) Соответствие Astra Linux SE стандартам')"
  hr
  run_cmd "cat /etc/os-release" "Проверяю версию дистрибутива — важно для понимания уровня защиты"
  
  run_cmd "dpkg -l | grep -iE 'certificate|certification|fstec|gost' | head -20 || true" \
    "Ищу пакеты, связанные с сертификацией и соответствием стандартам"
  
  run_cmd "cat /etc/astra_version 2>/dev/null || echo 'Файл версии не найден'" \
    "Проверяю специфичную версию Astra (важна для соответствия сертификатам)"
  
  run_cmd "find /usr/share/doc -name '*certificate*' -o -name '*standard*' -o -name '*gost*' 2>/dev/null | head -10 || true" \
    "Ищу документацию по сертификации и стандартам в системе"
}

block_2_mandatory_access(){
  title
  echo "$(bold '2) Реализация мандатного доступа (соответствие TCSEC B1+)')"
  hr
  echo "TCSEC класс B1 требует:"
  echo "  - Мандатный контроль доступа (MAC)"
  echo "  - Маркировка объектов уровнями безопасности"
  echo "  - Невозможность обхода политики даже для администратора"
  hr
  
  run_cmd "cat /sys/module/parsec/parameters/max_ilev 2>/dev/null || echo 'PARSEC недоступен'" \
    "PARSEC в Astra SE реализует мандатный контроль — проверяю наличие"
  
  run_cmd "getfattr -n security.PDPL -m security.PDPL /etc/passwd 2>/dev/null | head -5 || echo 'Мандатные метки не найдены'" \
    "Демонстрирую наличие мандатных меток (маркировка объектов уровнями)"
  
  run_cmd "lsmod | grep -i parsec || echo 'Модуль PARSEC не загружен'" \
    "Подтверждаю, что подсистема мандатного контроля активна на уровне ядра"
}

block_3_reference_monitor(){
  title
  echo "$(bold '3) Монитор ссылок (Reference Monitor) — ключевое требование TCSEC')"
  hr
  echo "Монитор ссылок должен быть:"
  echo "  - Полным (полный контроль всех обращений)"
  echo "  - Изолированным (защищён от модификации)"
  echo "  - Верифицируемым (можно доказать корректность)"
  hr
  
  run_cmd "cat /sys/module/parsec/parameters/* 2>/dev/null | head -20 || echo 'Параметры недоступны'" \
    "PARSEC как монитор ссылок — показываю параметры контроля"
  
  run_cmd "dmesg | grep -i 'parsec\|lsm\|security' | tail -20 || true" \
    "Проверяю инициализацию подсистемы безопасности в ядре"
  
  run_cmd "systemctl status auditd --no-pager 2>/dev/null | head -15 || echo 'auditd недоступен'" \
    "Аудит — обязательное требование TCSEC для контроля всех операций"
}

block_4_access_control_models(){
  title
  echo "$(bold '4) Модели контроля доступа (историческая перспектива)')"
  hr
  echo "Основные модели:"
  echo "  1. Дискреционный контроль (DAC) — Оранжевая книга C1-C2"
  echo "  2. Мандатный контроль (MAC) — Оранжевая книга B1+"
  echo "  3. Ролевой контроль (RBAC) — позднее развитие"
  echo "  4. Контроль целостности (Biba, Clark-Wilson) — для надёжности"
  hr
  
  run_cmd "id" "Текущий пользователь и группы (дискреционный контроль — базовый уровень)"
  
  run_cmd "ls -la /etc/passwd" "Права доступа к системным файлам (DAC на практике)"
  
  run_cmd "getfattr -n security.ILEV -m security.ILEV /bin/bash 2>/dev/null | head -3 || echo 'Уровни целостности не настроены'" \
    "Демонстрирую контроль целостности (модель Biba/Clark-Wilson в PARSEC)"
  
  run_cmd "sudo -l 2>/dev/null | head -10 || echo 'Нет sudo прав или не настроен'" \
    "Ролевой доступ — пример RBAC через sudo"
}

block_5_network_security_red_book(){
  title
  echo "$(bold '5) Сетевые стандарты безопасности (Красная книга)')"
  hr
  echo "Красная книга (TNI) расширяет требования на сети:"
  echo "  - Защита сетевых коммуникаций"
  echo "  - Межсетевые экраны и изоляция"
  echo "  - Контроль доступа к сетевым ресурсам"
  hr
  
  run_cmd "ss -tulpn | head -15 || netstat -tulpn | head -15 || echo 'Сетевые утилиты недоступны'" \
    "Проверяю сетевые соединения — поверхность атаки (важно для сетевой безопасности)"
  
  run_cmd "iptables -L -n 2>/dev/null | head -20 || echo 'iptables недоступен'" \
    "Межсетевой экран — базовая реализация сетевой защиты"
  
  run_cmd "systemctl list-units | grep -iE 'firewall|iptables|ufw' || true" \
    "Службы сетевой защиты — соответствие требованиям сетевой безопасности"
}

block_6_modern_standards(){
  title
  echo "$(bold '6) Современные стандарты (развитие идей Оранжевой/Красной книги)')"
  hr
  echo "Современное развитие:"
  echo "  - Common Criteria (ISO/IEC 15408) — международный стандарт"
  echo "  - ГОСТ Р 15408 — российский аналог"
  echo "  - NIST SP 800-53 — руководство по безопасности"
  echo "  - ISO 27001 — система управления информационной безопасностью"
  hr
  
  run_cmd "cat /etc/os-release | grep -i 'name\|version'" "Текущая ОС для сопоставления с требованиями стандартов"
  
  run_cmd "dpkg -l | grep -i 'security\|protection\|parsec' | head -15 || true" \
    "Компоненты безопасности в системе — соответствие современным требованиям"
  
  run_cmd "cat /proc/version" "Информация о ядре — важна для сертификации"
}

block_7_summary(){
  title
  echo "$(bold 'Итоговая сводка по стандартам')"
  hr
  cat <<'EOF'
Ключевые моменты:

1. Оранжевая книга (TCSEC, 1985):
   - Классы безопасности D, C, B, A
   - Мандатный контроль с класса B1
   - Монитор ссылок обязателен

2. Красная книга (TNI, 1987):
   - Расширение на сети
   - Защита сетевых коммуникаций
   - Межсетевые экраны

3. Astra Linux SE:
   - Реализует мандатный контроль (PARSEC)
   - Соответствует требованиям B1+
   - Сертифицирована ФСТЭК России
   - Поддерживает сетевую безопасность

4. Современные стандарты:
   - Common Criteria (ISO/IEC 15408)
   - ГОСТ Р 15408 (российский аналог)
   - Обеспечивают преемственность с классикой
EOF
  hr
  pause
}

menu(){
  title
  echo "Выбери блок для демонстрации:"
  echo
  echo "  0) Введение в стандарты"
  echo "  1) Соответствие Astra Linux SE стандартам"
  echo "  2) Реализация мандатного доступа (TCSEC B1+)"
  echo "  3) Монитор ссылок (Reference Monitor)"
  echo "  4) Модели контроля доступа"
  echo "  5) Сетевые стандарты (Красная книга)"
  echo "  6) Современные стандарты"
  echo "  7) Итоговая сводка"
  echo "  a) Пройти всё по порядку (0→7)"
  echo "  q) Выход"
  echo
  read -r -p "$(dim 'Твой выбор: ')" ch
  case "$ch" in
    0) block_0_intro ;;
    1) block_1_astra_compliance ;;
    2) block_2_mandatory_access ;;
    3) block_3_reference_monitor ;;
    4) block_4_access_control_models ;;
    5) block_5_network_security_red_book ;;
    6) block_6_modern_standards ;;
    7) block_7_summary ;;
    a|A)
      block_0_intro
      block_1_astra_compliance
      block_2_mandatory_access
      block_3_reference_monitor
      block_4_access_control_models
      block_5_network_security_red_book
      block_6_modern_standards
      block_7_summary
      ;;
    q|Q) exit 0 ;;
    *) echo "$(ylw 'Не понял. Давай ещё раз.')"; pause ;;
  esac
}

while true; do
  menu
  pause
done

