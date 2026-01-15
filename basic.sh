#!/usr/bin/env bash
set -euo pipefail

# Я этот скрипт держу как “экзаменационное демо” под Astra SE:
# - выбираю пункты руками (никакой гонки)
# - видно какие команды я “ввожу”
# - после каждой команды пауза, чтобы успеть объяснить
# - по умолчанию ничего не меняю в системе

DEMO_MUTATE="${DEMO_MUTATE:-0}"     # 0 = только смотрим, 1 = разрешаю безопасный тест в /tmp
AUTO_ENTER="${AUTO_ENTER:-0}"       # 0 = паузы между командами, 1 = без пауз
USE_SUDO="${USE_SUDO:-auto}"        # auto|always|never

bold() { printf "\033[1m%s\033[0m" "$*"; }
dim()  { printf "\033[2m%s\033[0m" "$*"; }
cyan() { printf "\033[36m%s\033[0m" "$*"; }
grn()  { printf "\033[32m%s\033[0m" "$*"; }
ylw()  { printf "\033[33m%s\033[0m" "$*"; }
red()  { printf "\033[31m%s\033[0m" "$*"; }

pause() {
  [[ "$AUTO_ENTER" == "1" ]] && return 0
  echo
  read -r -p "$(dim 'Нажми Enter, и я поеду дальше... ')" _
}

hr() { printf "%s\n" "$(dim '---------------------------------------------------------------------')"; }

have() { command -v "$1" >/dev/null 2>&1; }

need_sudo() {
  case "$USE_SUDO" in
    always) return 0 ;;
    never)  return 1 ;;
    auto)
      if [[ "$(id -u)" -ne 0 ]] && have sudo; then return 0; else return 1; fi
      ;;
  esac
}

# run_cmd "команда" "зачем эта команда"
run_cmd() {
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

title() {
  clear || true
  echo "$(bold 'Astra Linux SE / ОССН — интерактивное демо')"
  echo "$(dim 'Я выбираю пункты, команды видно как вводимые, двигаюсь пошагово.')"
  echo
  echo "Режимы: DEMO_MUTATE=$(bold "$DEMO_MUTATE"), AUTO_ENTER=$(bold "$AUTO_ENTER"), USE_SUDO=$(bold "$USE_SUDO")"
  hr
}

block_info() {
  title
  echo "$(bold 'Паспорт системы.') Сейчас покажу, что это именно Astra, какая версия и ядро."
  hr
  run_cmd "cat /etc/os-release" "Подтверждаю дистрибутив/версию (важно для вопросов про ОССН и профили защиты)."
  run_cmd "uname -a" "Показываю ядро и сборку (часто спрашивают, какое ядро/архитектура)."
  run_cmd "lscpu | sed -n '1,28p'" "Коротко показываю CPU/архитектуру — просто чтобы было понятно окружение."
  run_cmd "lsblk" "Смотрю диски/разделы — удобно потом говорить про защиту данных и точки монтирования."
  run_cmd "uptime" "Проверяю, что система живая и давно работает (иногда полезно в контексте служб)."
}

block_repos_packages() {
  title
  echo "$(bold 'Репозитории и пакеты.') Это про управляемость и “что реально стоит в системе”."
  hr
  run_cmd "grep -R \"^deb \" -n /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null || true" \
    "Показываю, откуда ставится софт (в твоём случае frozen репозитории Astra 1.7.x)."
  run_cmd "apt list --upgradable 2>/dev/null || true" \
    "Проверяю, есть ли обновления — это прямой аргумент про сопровождение и актуальность."
  run_cmd "dpkg -l | egrep -i 'parsec|linux-astra|ald|krb5|sssd|auditd|fly-admin|fly-|astra' | head -n 220 || true" \
    "Подтверждаю наличие характерных компонентов Astra (PARSEC/ALD/Kerberos/audit/Fly)."
}

block_kss_monitor() {
  title
  echo "$(bold 'КСЗ/монитор безопасности.') Тут я показываю, что защита не “на словах”."
  hr

  if have astra-security-monitor; then
    echo "$(grn 'Нашёл astra-security-monitor — это прям удобно для демонстрации.')"
    hr
    run_cmd "astra-security-monitor || true" "Смотрю состояние функций безопасности через штатный монитор."
  else
    echo "$(ylw 'astra-security-monitor не нашёл. Тогда покажу признаки через модули/логи.')"
    hr
    run_cmd "lsmod | egrep -i 'parsec|lsm|apparmor|selinux' || true" \
      "Проверяю, что загружено из подсистем безопасности (в Астре обычно интересует PARSEC)."
    run_cmd "dmesg | egrep -i 'parsec|lsm|audit' | tail -n 70 || true" \
      "Смотрю сообщения ядра: часто видно инициализацию/режимы."
  fi

  run_cmd "cat /proc/cmdline" \
    "Смотрю параметры загрузки ядра — иногда там фиксируют важные настройки (в т.ч. связанные с PARSEC)."
}

block_parsec() {
  title
  echo "$(bold 'PARSEC.') Сейчас покажу параметры — это одна из ключевых “фишек” Astra SE."
  hr

  run_cmd "lsmod | egrep -i 'parsec|lsm|apparmor|selinux' || true" \
    "Проверяю, что модуль PARSEC реально присутствует/загружен."

  if [[ -d /sys/module/parsec/parameters ]]; then
    echo "$(grn 'PARSEC параметры доступны. Показываю max_ilev и остальные настройки.')"
    hr
    run_cmd "ls -la /sys/module/parsec/parameters" \
      "Это список параметров PARSEC (по сути, видимые настройки подсистемы защиты)."

    run_cmd "cat /sys/module/parsec/parameters/max_ilev 2>/dev/null || true" \
      "max_ilev — “потолок” целостности системы (важный маркер в Astra SE)."

    # ВАЖНО: тут $f должен раскрываться внутри bash -lc, а не в нашем скрипте (set -u!)
    run_cmd 'for f in /sys/module/parsec/parameters/*; do echo "--- $f"; cat "$f" 2>/dev/null || true; done | sed -n "1,220p"' \
      "Делаю снимок всех параметров PARSEC. Тут важно: я вывожу и имя, и значение."
  else
    echo "$(red 'Нет /sys/module/parsec/parameters. Значит PARSEC не загружен или профиль другой.')"
    hr
    run_cmd "ls -la /sys/module | egrep -i 'parsec' || true" \
      "Проверяю вообще наличие модуля в /sys/module."
  fi
}

block_mac_xattr() {
  title
  echo "$(bold 'Мандатные атрибуты (xattr security.*).') Это то, что отличает Astra от обычного Linux."
  hr

  run_cmd "getfattr --version 2>/dev/null || true" \
    "Проверяю, что инструменты работы с extended attributes есть."

  run_cmd "command -v pdpl-file >/dev/null && pdpl-file -h | sed -n '1,80p' || echo 'pdpl-file: не найден'" \
    "pdpl-file — утилита работы с мандатными метками (если она установлена)."

  run_cmd "getfattr -n security.PDPL -m security.PDPL / 2>/dev/null | head -n 10 || true" \
    "Пробую найти PDPL-метки на корне (может быть пусто — это нормально)."

  if [[ "$DEMO_MUTATE" == "1" ]]; then
    echo
    echo "$(ylw 'DEMO_MUTATE=1: делаю безопасный тест в /tmp (ничего системного не трогаю).')"
    hr
    run_cmd "DEMO_DIR=/tmp/astra_mac_demo_$$; mkdir -p \"\$DEMO_DIR\"; echo 'demo' > \"\$DEMO_DIR/f\"; ls -la \"\$DEMO_DIR\"" \
      "Создаю тестовый каталог и файл — только для демонстрации."

    if have pdpl-file; then
      run_cmd "DEMO_DIR=/tmp/astra_mac_demo_$$; pdpl-file 3:0:-1:CCNR \"\$DEMO_DIR\" 2>/dev/null || true; pdpl-file 3:0:-1:CCNR \"\$DEMO_DIR/f\" 2>/dev/null || true" \
        "Пробую назначить мандатную метку (если политика/права позволяют)."

      run_cmd "DEMO_DIR=/tmp/astra_mac_demo_$$; getfattr -d -m 'security\\.' \"\$DEMO_DIR\" \"\$DEMO_DIR/f\" 2>/dev/null || true" \
        "Читаю security.* атрибуты — вот тут обычно видно, что метка реально записалась."
    else
      run_cmd "DEMO_DIR=/tmp/astra_mac_demo_$$; getfattr -d -m- \"\$DEMO_DIR/f\" 2>/dev/null || true" \
        "Без pdpl-file просто показываю, что xattr у обычного файла обычно пустой."
    fi

    run_cmd "DEMO_DIR=/tmp/astra_mac_demo_$$; rm -rf \"\$DEMO_DIR\"; echo \"removed \$DEMO_DIR\"" \
      "Убираю за собой тестовый каталог."
  else
    echo
    echo "$(dim 'Сейчас DEMO_MUTATE=0 — я ничего не создаю. Если хочешь тест:')"
    echo "$(cyan 'DEMO_MUTATE=1 bash astra_demo_menu.sh')"
  fi
}

block_audit() {
  title
  echo "$(bold 'Аудит.') Это про фиксацию событий безопасности."
  hr
  run_cmd "systemctl status auditd --no-pager 2>/dev/null | sed -n '1,120p' || true" \
    "Смотрю, жив ли auditd и как он запущен."
  if have auditctl; then
    run_cmd "auditctl -s || true" "Проверяю статус подсистемы аудита."
    run_cmd "auditctl -l 2>/dev/null | head -n 140 || true" "Смотрю правила аудита (если заданы)."
  else
    echo "$(ylw 'auditctl не найден — возможно, пакет не установлен.')"
  fi
  run_cmd "journalctl -p warning..alert -n 40 --no-pager || true" \
    "Быстро просматриваю важные предупреждения/ошибки системы."
}

block_domain_kerberos() {
  title
  echo "$(bold 'Домен / Kerberos / ALD.') Это типовая область применения ОССН в организации."
  hr
  run_cmd "systemctl list-unit-files | egrep -i 'ald|sssd|ldap|slapd|krb5|kdc|samba|winbind' || true" \
    "Проверяю, какие доменные/аутентификационные службы вообще установлены/доступны."
  run_cmd "timedatectl 2>/dev/null || true" \
    "Проверяю время/таймзону — для Kerberos это критично."
  run_cmd "systemctl status chronyd --no-pager 2>/dev/null | sed -n '1,90p' || true" \
    "Проверяю синхронизацию времени (chrony)."
  run_cmd "command -v klist >/dev/null && klist 2>/dev/null || echo 'klist: нет билетов или пакет не установлен'" \
    "Проверяю, есть ли kerberos-билеты (SSO)."
  run_cmd "test -f /etc/krb5.conf && sed -n '1,140p' /etc/krb5.conf || true" \
    "Показываю конфиг Kerberos клиента (realm/kdc и т.д.)."
}

block_network() {
  title
  echo "$(bold 'Сетевой периметр.') Тут я показываю поверхность атаки: что слушает порты."
  hr
  run_cmd "ss -tulpn | sed -n '1,180p' || true" \
    "Смотрю слушающие порты и процессы — быстро видно лишние сервисы."
  run_cmd "iptables -S 2>/dev/null | head -n 120 || true" \
    "Показываю правила firewall (если используются iptables)."
  run_cmd "ufw status 2>/dev/null || true" \
    "Если включён ufw — показываю статус."
}

block_astra_summary() {
  title
  echo "$(bold 'Резюме, что я показал по “особенностям Astra SE”:')"
  hr
  echo "1) PARSEC и max_ilev (системный потолок целостности)"
  run_cmd "cat /sys/module/parsec/parameters/max_ilev 2>/dev/null || echo 'max_ilev недоступен'" \
    "Быстрый маркер, что PARSEC реально есть и целостность на месте."
  echo
  echo "2) Мандатные метки через xattr security.*"
  run_cmd "getfattr -n security.PDPL -m security.PDPL / 2>/dev/null | head -n 5 || true" \
    "Показываю, что система умеет хранить мандатные атрибуты."
  echo
  echo "3) Корпоративный контур (ALD/SSSD/Kerberos) + синхронизация времени"
  run_cmd "dpkg -l | egrep -i 'ald|sssd|krb5' | head -n 60 || true" \
    "Показываю, что нужные пакеты/механизмы есть (если они установлены)."
  echo
  echo "4) Аудит — фиксируем события безопасности"
  run_cmd "systemctl is-active auditd 2>/dev/null || true" \
    "Проверяю, активен ли auditd."
  echo
  echo "$(grn 'Всё. На этом можно уверенно рассказывать архитектуру/назначение/применение ОССН.')"
}

settings() {
  title
  echo "$(bold 'Настройки (я их могу щёлкать прямо перед демонстрацией):')"
  echo
  echo "1) DEMO_MUTATE сейчас = $(bold "$DEMO_MUTATE")   (1 = разрешить тест в /tmp)"
  echo "2) AUTO_ENTER сейчас  = $(bold "$AUTO_ENTER")  (1 = без пауз между командами)"
  echo "3) USE_SUDO сейчас    = $(bold "$USE_SUDO")    (auto/always/never)"
  echo "4) Назад"
  echo
  read -r -p "$(dim 'Выбор: ')" s
  case "$s" in
    1) DEMO_MUTATE=$((1-DEMO_MUTATE)) ;;
    2) AUTO_ENTER=$((1-AUTO_ENTER)) ;;
    3)
      echo "Введи значение: auto / always / never"
      read -r -p "$(dim 'USE_SUDO = ')" v
      case "$v" in auto|always|never) USE_SUDO="$v" ;; *) echo "$(ylw 'Оставляю как было.')";; esac
      ;;
    4) return 0 ;;
  esac
}

menu() {
  title
  echo "Выбери, что показать:"
  echo
  echo "  1) Паспорт системы (ОС/ядро/железо)"
  echo "  2) Репозитории и пакеты (Fly/ALD/PARSEC/audit/krb)"
  echo "  3) КСЗ / монитор безопасности"
  echo "  4) PARSEC и параметры (max_ilev и т.д.)"
  echo "  5) Мандатные атрибуты / xattr security.* (тест в /tmp при DEMO_MUTATE=1)"
  echo "  6) Аудит (auditd/auditctl/journal)"
  echo "  7) Домен / ALD / Kerberos"
  echo "  8) Сетевой периметр (порты/firewall)"
  echo "  9) Короткое резюме “особенности Astra SE”"
  echo
  echo "  a) Пройти всё по порядку (1→9)"
  echo "  s) Настройки"
  echo "  q) Выход"
  echo
  read -r -p "$(dim 'Твой выбор: ')" ch
  case "$ch" in
    1) block_info ;;
    2) block_repos_packages ;;
    3) block_kss_monitor ;;
    4) block_parsec ;;
    5) block_mac_xattr ;;
    6) block_audit ;;
    7) block_domain_kerberos ;;
    8) block_network ;;
    9) block_astra_summary ;;
    a|A)
      block_info; pause
      block_repos_packages; pause
      block_kss_monitor; pause
      block_parsec; pause
      block_mac_xattr; pause
      block_audit; pause
      block_domain_kerberos; pause
      block_network; pause
      block_astra_summary
      ;;
    s|S) settings ;;
    q|Q) exit 0 ;;
    *) echo "$(ylw 'Не понял выбор. Давай ещё раз.')"; pause ;;
  esac
}

while true; do
  menu
  pause
done
