#!/usr/bin/env bash
set -euo pipefail

# Вопрос 4: Архитектура безопасности PARSEC (Astra Linux SE)
# Идея скрипта: я по шагам показываю, что PARSEC реально встроен в ядро,
# где у него "точки управления" (параметры), как он связан с MAC/целостностью,
# и чем это отличается от обычного Linux.
#
# НИЧЕГО НЕ ЛОМАЕТ. По умолчанию только чтение.
# Если хочешь мини-практику с тестовыми файлами в /tmp: DEMO_MUTATE=1

DEMO_MUTATE="${DEMO_MUTATE:-0}"     # 0 = только смотреть, 1 = сделать тест в /tmp
AUTO_ENTER="${AUTO_ENTER:-0}"       # 0 = шаги с Enter, 1 = без пауз
USE_SUDO="${USE_SUDO:-auto}"        # auto|always|never

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
  echo "$(bold 'Astra Linux SE — Демонстрация: Архитектура безопасности PARSEC')"
  echo "$(dim 'Показываю по шагам: ядро → параметры → MAC/целостность → аудит/связки.')"
  echo "Режимы: DEMO_MUTATE=$(bold "$DEMO_MUTATE"), AUTO_ENTER=$(bold "$AUTO_ENTER"), USE_SUDO=$(bold "$USE_SUDO")"
  hr
}

say_arch(){
  echo "$(bold 'Скелет архитектуры PARSEC (как я это объясняю на экзамене):')"
  echo "1) PARSEC сидит в ядре и встраивается в контрольные точки (LSM/хуки)."
  echo "2) У него есть параметры ( /sys/module/parsec/parameters ) — это “панель управления”."
  echo "3) Он дополняет DAC (chmod/ACL) мандатностью (MAC) и целостностью (Integrity)."
  echo "4) Метки/уровни обычно лежат в xattr security.* (PDPL/ILEV/CLEV и т.п.)."
  echo "5) Решение принимается на каждой чувствительной операции (open/exec/rename/…); при необходимости — в аудит."
  hr
  pause
}

block_0_passport(){
  title
  echo "$(bold '0) Старт: подтверждаю, что это Astra SE и какое ядро (чтобы не говорить “в вакууме”).')"
  hr
  run_cmd "cat /etc/os-release" "Фиксирую дистрибутив и версию — это база для разговора про ОССН."
  run_cmd "uname -r" "Версия ядра важна: PARSEC — это именно интеграция на уровне ядра."
}

block_1_kernel_presence(){
  title
  say_arch
  echo "$(bold '1) PARSEC в ядре: модуль/инициализация/LSM')"
  hr
  run_cmd "lsmod | egrep -i 'parsec|lsm|apparmor|selinux' || true" \
    "Проверяю, что PARSEC реально загружен (и какие LSM вообще активны)."

  run_cmd "cat /sys/kernel/security/lsm 2>/dev/null || true" \
    "Смотрю список активных LSM (если ядро это показывает)."

  run_cmd "dmesg | egrep -i 'parsec' | tail -n 80 || true" \
    "В логе ядра часто видно, что PARSEC поднялся и в каком режиме."

  run_cmd "cat /proc/cmdline" \
    "Параметры загрузки: иногда там встречаются настройки, которые влияют на режимы защиты."
}

block_2_parameters_panel(){
  title
  echo "$(bold '2) “Панель управления” PARSEC: параметры в /sys/module/parsec/parameters')"
  hr

  if [[ -d /sys/module/parsec/parameters ]]; then
    echo "$(grn 'Ок, параметры доступны. Это прям наглядно показывает, что подсистема активна.')"
    hr
    run_cmd "ls -la /sys/module/parsec/parameters" \
      "Вывожу список параметров — это то, чем реально можно управлять/проверять режим."

    run_cmd "cat /sys/module/parsec/parameters/max_ilev 2>/dev/null || true" \
      "max_ilev — важный маркер: максимальный уровень целостности системы (потолок)."

    run_cmd 'for f in /sys/module/parsec/parameters/*; do echo "--- $f"; cat "$f" 2>/dev/null || true; done | sed -n "1,260p"' \
      "Снимаю значения всех параметров (показывает режимы: mac/strict_mode/exec_security/и т.д.)."
  else
    echo "$(red 'Папки /sys/module/parsec/parameters нет. Значит PARSEC не загружен/не установлен/другой профиль.')"
    hr
    run_cmd "ls -la /sys/module | egrep -i 'parsec' || true" \
      "Проверяю, есть ли вообще модуль в /sys/module."
  fi
}

block_3_mac_integrity_story(){
  title
  echo "$(bold '3) MAC/целостность: где живут метки и почему это “не просто chmod”')"
  hr

  run_cmd "command -v getfattr >/dev/null && getfattr --version || echo 'getfattr не найден'" \
    "Утилиты xattr нужны, чтобы показать security.* (метки/уровни)."

  run_cmd "command -v pdpl-file >/dev/null && pdpl-file -h | sed -n '1,60p' || echo 'pdpl-file не найден'" \
    "pdpl-file — характерный инструмент для работы с мандатными метками (если установлен)."

  echo
  echo "$(bold 'Смысл, который я проговариваю:')"
  echo "- DAC: владелец/группа/права → можно “разрешить самому себе”."
  echo "- MAC: метки/уровни → даже root/владелец не всегда может “перешагнуть” политику."
  echo "- Integrity: низкоцелостный процесс не должен влиять на высокоцелостные объекты."
  hr

  run_cmd "getfattr -n security.PDPL -m security.PDPL / 2>/dev/null | head -n 10 || true" \
    "Пробую найти PDPL-метки в системе (может быть пусто — зависит от того, где ставили метки)."

  run_cmd "getfattr -n security.ILEV -m security.ILEV / 2>/dev/null | head -n 10 || true" \
    "Пробую найти уровни целостности на объектах (если они используются)."

  run_cmd "getfattr -n security.CLEV -m security.CLEV / 2>/dev/null | head -n 10 || true" \
    "Пробую найти уровни конфиденциальности (если используются)."
}

block_4_safe_practice(){
  title
  echo "$(bold '4) Мини-практика (безопасно): работаю только в /tmp')"
  hr

  if [[ "$DEMO_MUTATE" != "1" ]]; then
    echo "$(ylw 'DEMO_MUTATE=0: я ничего не создаю. Если хочешь практику, запусти так:')"
    echo "$(cyan 'DEMO_MUTATE=1 bash parsec_arch_demo.sh')"
    hr
    pause
    return 0
  fi

  run_cmd "DEMO_DIR=/tmp/parsec_demo_$$; mkdir -p \"\$DEMO_DIR\"; echo 'demo' > \"\$DEMO_DIR/f\"; chmod 640 \"\$DEMO_DIR/f\"; ls -la \"\$DEMO_DIR\"" \
    "Создаю тестовый файл и показываю обычные DAC-права (chmod) — это “низкий слой”."

  run_cmd "DEMO_DIR=/tmp/parsec_demo_$$; getfattr -d -m- \"\$DEMO_DIR/f\" 2>/dev/null || true" \
    "Смотрю xattr у тестового файла (по умолчанию обычно пусто)."

  if have pdpl-file; then
    run_cmd "DEMO_DIR=/tmp/parsec_demo_$$; pdpl-file 3:0:-1:CCNR \"\$DEMO_DIR/f\" 2>/dev/null || true" \
      "Пробую назначить мандатную метку (если политика/права позволяют — увидим security.*)."

    run_cmd "DEMO_DIR=/tmp/parsec_demo_$$; getfattr -d -m 'security\\.' \"\$DEMO_DIR/f\" 2>/dev/null || true" \
      "Проверяю, что security.* реально появились на объекте."
  else
    echo "$(ylw 'pdpl-file нет — значит покажу только то, что xattr технически есть, но метки не назначаю.')"
    hr
  fi

  run_cmd "DEMO_DIR=/tmp/parsec_demo_$$; rm -rf \"\$DEMO_DIR\"; echo \"removed \$DEMO_DIR\"" \
    "Убираю тестовый каталог — чтобы после демо не было мусора."
}

block_5_audit_link(){
  title
  echo "$(bold '5) Связка с аудитом (если auditd включён):')"
  hr

  run_cmd "systemctl status auditd --no-pager 2>/dev/null | sed -n '1,120p' || true" \
    "Смотрю, запущен ли auditd. Архитектурно: контроль + фиксация событий."

  if have auditctl; then
    run_cmd "auditctl -s || true" "Проверяю состояние подсистемы аудита."
    run_cmd "auditctl -l 2>/dev/null | head -n 120 || true" \
      "Смотрю правила: есть ли что-то, что фиксирует безопасность/ядро/доступ."
  else
    echo "$(ylw 'auditctl не найден. Возможно, профиль урезан или пакет не установлен.')"
  fi

  run_cmd "journalctl -k -n 80 --no-pager | egrep -i 'parsec|lsm|audit' || true" \
    "Ищу связанное в kernel-журнале (иногда там видно реакции системы)."
}

block_6_final_words(){
  title
  echo "$(bold 'Итог, как я это формулирую:')"
  hr
  cat <<'EOF'
- PARSEC = принудительная подсистема безопасности уровня ядра (референс-монитор по сути).
- Есть контрольные точки (хуки): любое “чувствительное действие” проходит проверку.
- Политика/режимы видны через /sys/module/parsec/parameters (это прям показатель Astra SE).
- Поверх DAC добавляются MAC/целостность через security.* (метки/уровни объектов).
- При необходимости всё это увязывается с аудитом (auditd/journal) для расследований.
EOF
  hr
  echo "$(grn 'Готово. Это ровно то, что обычно хотят услышать по “архитектуре PARSEC”.')"
  pause
}

menu(){
  title
  echo "Выбери, что показать по PARSEC:"
  echo
  echo "  1) PARSEC в ядре (lsmod/LSM/dmesg/cmdline)"
  echo "  2) Параметры PARSEC ( /sys/module/parsec/parameters , max_ilev и т.д.)"
  echo "  3) MAC/Integrity: где живут метки (security.*) и логика"
  echo "  4) Мини-практика в /tmp (только при DEMO_MUTATE=1)"
  echo "  5) Связка с аудитом (auditd/journal)"
  echo "  a) Пройти всё по порядку (1→6)"
  echo "  s) Настройки (переключатели)"
  echo "  q) Выход"
  echo
  read -r -p "$(dim 'Твой выбор: ')" ch
  case "$ch" in
    1) block_1_kernel_presence ;;
    2) block_2_parameters_panel ;;
    3) block_3_mac_integrity_story ;;
    4) block_4_safe_practice ;;
    5) block_5_audit_link ;;
    a|A)
      block_0_passport
      block_1_kernel_presence
      block_2_parameters_panel
      block_3_mac_integrity_story
      block_4_safe_practice
      block_5_audit_link
      block_6_final_words
      ;;
    s|S) settings ;;
    q|Q) exit 0 ;;
    *) echo "$(ylw 'Не понял. Давай ещё раз.')"; pause ;;
  esac
}

settings(){
  title
  echo "$(bold 'Настройки:')"
  echo
  echo "1) DEMO_MUTATE = $(bold "$DEMO_MUTATE")  (1 = разрешить тест в /tmp)"
  echo "2) AUTO_ENTER  = $(bold "$AUTO_ENTER") (1 = без пауз)"
  echo "3) USE_SUDO    = $(bold "$USE_SUDO")   (auto/always/never)"
  echo "4) Назад"
  echo
  read -r -p "$(dim 'Выбор: ')" s
  case "$s" in
    1) DEMO_MUTATE=$((1-DEMO_MUTATE)) ;;
    2) AUTO_ENTER=$((1-AUTO_ENTER)) ;;
    3)
      echo "Введи: auto / always / never"
      read -r -p "$(dim 'USE_SUDO = ')" v
      case "$v" in auto|always|never) USE_SUDO="$v" ;; *) echo "$(ylw 'Оставляю как было.')";; esac
      ;;
    4) return 0 ;;
  esac
}

# ---- main ----
while true; do
  menu
  pause
done