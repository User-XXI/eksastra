#!/usr/bin/env bash
set -euo pipefail

# Вопрос 17: Реализация принципа изоляции объектов графической подсистемы в ОССН

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
  echo "$(bold 'Вопрос 17: Изоляция объектов графической подсистемы')"
  hr
}

block_0_intro(){
  title
  echo "$(bold '0) Принцип изоляции графических объектов')"
  hr
  echo "Изоляция графических объектов в Astra Linux SE:"
  echo "  1. Изоляция графических сессий пользователей"
  echo "  2. Контроль доступа к графическим ресурсам"
  echo "  3. Мандатный контроль доступа для графических приложений"
  echo "  4. Изоляция буфера обмена между сессиями"
  echo "  5. Контроль доступа к устройствам ввода/вывода"
  hr
  pause
}

block_1_session_isolation(){
  title
  echo "$(bold '1) Изоляция графических сессий')"
  hr
  
  run_cmd "who" "Активные графические сессии пользователей"
  
  run_cmd "echo \$DISPLAY" "Идентификатор текущей графической сессии"
  
  run_cmd "ps aux | grep -iE 'xorg|wayland' | grep -v grep | head -5 || echo 'Графические серверы не найдены'" \
    "Процессы графических серверов (по одному на сессию)"
  
  run_cmd "systemctl --user list-units 2>/dev/null | head -10 || echo 'Пользовательские службы недоступны'" \
    "Изоляция пользовательских служб (каждый пользователь имеет свою сессию)"
  
  echo "$(bold 'Изоляция сессий:')"
  echo "  - Каждый пользователь имеет отдельную графическую сессию"
  echo "  - Сессии не имеют доступа к ресурсам друг друга"
  echo "  - Аудит доступа к графическим ресурсам"
  hr
}

block_2_mandatory_access_gui(){
  title
  echo "$(bold '2) Мандатный контроль доступа для графических объектов')"
  hr
  
  run_cmd "getfattr -n security.PDPL -m security.PDPL /usr/bin/* 2>/dev/null | grep -iE 'x11|wayland|gtk|qt' | head -10 || echo 'PDPL метки на графических компонентах не найдены'" \
    "Мандатные метки на компонентах графической подсистемы"
  
  run_cmd "getfattr -n security.ILEV -m security.ILEV /usr/bin/* 2>/dev/null | grep -iE 'x11|wayland|gtk|qt' | head -10 || echo 'ILEV метки не найдены'" \
    "Уровни целостности графических приложений"
  
  echo "$(bold 'Мандатный контроль:')"
  echo "  - Графические приложения имеют мандатные метки"
  echo "  - Доступ к графическим объектам контролируется МРД"
  echo "  - Невозможность обхода политики даже для графических приложений"
  hr
}

block_3_clipboard_isolation(){
  title
  echo "$(bold '3) Изоляция буфера обмена')"
  hr
  
  run_cmd "xclip -o 2>/dev/null | head -5 || xsel -p 2>/dev/null | head -5 || echo 'Буфер обмена недоступен или пуст'" \
    "Текущее содержимое буфера обмена"
  
  echo "$(bold 'Изоляция буфера обмена:')"
  echo "  - Буфер обмена изолирован между графическими сессиями"
  echo "  - При переключении сессий буфер очищается"
  echo "  - Контроль доступа к буферу обмена через МРД"
  hr
  
  run_cmd "ps aux | grep -iE 'clipboard|xclip|xsel' | grep -v grep | head -5 || echo 'Процессы буфера обмена не найдены'" \
    "Процессы, работающие с буфером обмена"
}

block_4_input_output_control(){
  title
  echo "$(bold '4) Контроль доступа к устройствам ввода/вывода')"
  hr
  
  run_cmd "xinput list 2>/dev/null | head -10 || echo 'xinput недоступен (возможно, нет X11)'" \
    "Список устройств ввода в графической сессии"
  
  run_cmd "ls -la /dev/input/* 2>/dev/null | head -10 || echo 'Устройства ввода недоступны'" \
    "Устройства ввода на уровне системы"
  
  echo "$(bold 'Контроль доступа:')"
  echo "  - Контроль доступа к устройствам ввода (клавиатура, мышь)"
  echo "  - Контроль доступа к устройствам вывода (дисплей)"
  echo "  - Изоляция устройств между сессиями"
  hr
  
  run_cmd "getfacl /dev/input/* 2>/dev/null | head -10 || echo 'ACL на устройствах ввода не настроены'" \
    "Права доступа к устройствам ввода"
}

block_5_window_isolation(){
  title
  echo "$(bold '5) Изоляция окон графических приложений')"
  hr
  
  run_cmd "ps aux | grep -E '^$(whoami)' | grep -iE 'gui|gtk|qt' | head -10 || echo 'Графические процессы не найдены'" \
    "Графические процессы текущего пользователя"
  
  echo "$(bold 'Изоляция окон:')"
  echo "  - Каждое графическое приложение имеет изолированную область отображения"
  echo "  - Контроль доступа к окнам других приложений"
  echo "  - Защита от перехвата содержимого окон"
  hr
  
  if have auditctl; then
    run_cmd "sudo auditctl -l 2>/dev/null | grep -iE 'window|display|x11' | head -10 || echo 'Правила аудита окон не найдены'" \
      "Правила аудита доступа к окнам"
  fi
}

block_6_parsec_gui(){
  title
  echo "$(bold '6) Реализация изоляции через PARSEC')"
  hr
  
  run_cmd "cat /sys/module/parsec/parameters/* 2>/dev/null | grep -iE 'gui|display|x11' | head -5 || echo 'Параметры графики в PARSEC не найдены'" \
    "Параметры PARSEC, связанные с графической подсистемой"
  
  run_cmd "dmesg | grep -iE 'parsec|security' | grep -iE 'display|x11|gui' | tail -10 || echo 'Сообщения не найдены'" \
    "Сообщения ядра о контроле графической подсистемы"
  
  echo "$(bold 'PARSEC и графика:')"
  echo "  - PARSEC контролирует доступ к графическим ресурсам"
  echo "  - Проверка на каждое обращение к графическим объектам"
  echo "  - Аудит всех операций графической подсистемы"
  hr
}

block_7_audit_gui(){
  title
  echo "$(bold '7) Аудит изоляции графических объектов')"
  hr
  
  if have auditctl; then
    run_cmd "sudo auditctl -l 2>/dev/null | grep -iE 'display|x11|wayland|gui' | head -10 || echo 'Правила аудита графики не найдены'" \
      "Правила аудита графической подсистемы"
    
    run_cmd "sudo ausearch -m file_access 2>/dev/null | grep -iE 'display|x11' | tail -10 || echo 'События доступа не найдены'" \
      "События доступа к графическим ресурсам"
  fi
  
  run_cmd "journalctl -k -n 50 --no-pager 2>/dev/null | grep -iE 'parsec|security' | grep -iE 'display|gui' | head -10 || echo 'События не найдены'" \
    "События изоляции в журнале ядра"
  
  echo "$(bold 'Аудит изоляции:')"
  echo "  - Фиксация всех попыток доступа к графическим объектам"
  echo "  - Логирование нарушений изоляции"
  echo "  - Отслеживание переключений между сессиями"
  hr
}

block_8_summary(){
  title
  echo "$(bold 'Итог: изоляция графических объектов')"
  hr
  cat <<'EOF'
Реализация изоляции графических объектов в ОССН:

1. Изоляция графических сессий:
   - Отдельная сессия для каждого пользователя
   - Сессии не имеют доступа друг к другу
   - Аудит доступа к графическим ресурсам

2. Мандатный контроль доступа:
   - Графические приложения имеют мандатные метки
   - Доступ контролируется МРД
   - Невозможность обхода политики

3. Изоляция буфера обмена:
   - Буфер изолирован между сессиями
   - Очистка при переключении сессий
   - Контроль доступа через МРД

4. Контроль устройств ввода/вывода:
   - Контроль доступа к клавиатуре, мыши, дисплею
   - Изоляция устройств между сессиями
   - Аудит доступа к устройствам

5. Изоляция окон:
   - Изолированные области отображения
   - Контроль доступа к окнам
   - Защита от перехвата содержимого

6. Реализация через PARSEC:
   - Контроль доступа к графическим ресурсам
   - Проверка на каждое обращение
   - Аудит всех операций

7. Аудит изоляции:
   - Фиксация попыток доступа
   - Логирование нарушений
   - Отслеживание переключений
EOF
  hr
  pause
}

menu(){
  title
  echo "  0) Введение"
  echo "  1) Изоляция сессий"
  echo "  2) Мандатный контроль GUI"
  echo "  3) Изоляция буфера обмена"
  echo "  4) Контроль устройств ввода/вывода"
  echo "  5) Изоляция окон"
  echo "  6) Реализация через PARSEC"
  echo "  7) Аудит изоляции"
  echo "  8) Итог"
  echo "  a) Всё по порядку"
  echo "  q) Выход"
  read -r -p "$(dim 'Выбор: ')" ch
  case "$ch" in
    0) block_0_intro ;;
    1) block_1_session_isolation ;;
    2) block_2_mandatory_access_gui ;;
    3) block_3_clipboard_isolation ;;
    4) block_4_input_output_control ;;
    5) block_5_window_isolation ;;
    6) block_6_parsec_gui ;;
    7) block_7_audit_gui ;;
    8) block_8_summary ;;
    a|A)
      block_0_intro
      block_1_session_isolation
      block_2_mandatory_access_gui
      block_3_clipboard_isolation
      block_4_input_output_control
      block_5_window_isolation
      block_6_parsec_gui
      block_7_audit_gui
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

