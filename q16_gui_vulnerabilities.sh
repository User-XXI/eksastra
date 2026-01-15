#!/usr/bin/env bash
set -euo pipefail

# Вопрос 16: Типовое описание уязвимостей ОС, связанных с графической подсистемой

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
  echo "$(bold 'Вопрос 16: Уязвимости графической подсистемы')"
  hr
}

block_0_intro(){
  title
  echo "$(bold '0) Типовые уязвимости графической подсистемы')"
  hr
  echo "Уязвимости графической подсистемы:"
  echo "  1. Перехват ввода (кейлоггинг) через графические драйверы"
  echo "  2. Утечка данных через буфер обмена"
  echo "  3. Перехват окон и экрана (скриншотирование)"
  echo "  4. Доступ к процессам графических приложений"
  echo "  5. Изоляция графических сессий"
  hr
  pause
}

block_1_display_server(){
  title
  echo "$(bold '1) Графический сервер (X11/Wayland)')"
  hr
  
  run_cmd "echo \$DISPLAY" "Переменная DISPLAY (идентификатор графической сессии)"
  
  run_cmd "ps aux | grep -iE 'xorg|wayland|X11' | grep -v grep | head -5 || echo 'Графический сервер не найден'" \
    "Процесс графического сервера"
  
  run_cmd "systemctl --user list-units 2>/dev/null | grep -iE 'display|wayland|x11' | head -5 || echo 'Пользовательские службы недоступны'" \
    "Службы графической подсистемы"
  
  echo "$(bold 'Уязвимости X11:')"
  echo "  - X11 не имеет изоляции между приложениями"
  echo "  - Любое приложение может перехватывать ввод/вывод других"
  echo "  - Нет контроля доступа к графическим ресурсам"
  hr
}

block_2_keylogging(){
  title
  echo "$(bold '2) Перехват ввода (кейлоггинг)')"
  hr
  
  echo "$(bold 'Уязвимости перехвата ввода:')"
  echo "  - В X11 любое приложение может получить доступ к клавиатуре"
  echo "  - Перехват всех нажатий клавиш"
  echo "  - Возможность получения паролей и конфиденциальной информации"
  hr
  
  run_cmd "xinput list 2>/dev/null | head -10 || echo 'xinput недоступен (возможно, нет X11)'" \
    "Список устройств ввода"
  
  run_cmd "ps aux | grep -iE 'keyboard|input|xinput' | grep -v grep | head -5 || echo 'Процессы ввода не найдены'" \
    "Процессы, связанные с вводом"
  
  echo "$(bold 'Защита в Astra Linux SE:')"
  echo "  - Изоляция графических сессий"
  echo "  - Контроль доступа к устройствам ввода"
  echo "  - Аудит доступа к графическим ресурсам"
  hr
}

block_3_clipboard_leak(){
  title
  echo "$(bold '3) Утечка данных через буфер обмена')"
  hr
  
  echo "$(bold 'Уязвимости буфера обмена:')"
  echo "  - В X11 буфер обмена доступен всем приложениям"
  echo "  - Возможность чтения данных из буфера обмена"
  echo "  - Утечка конфиденциальной информации"
  hr
  
  run_cmd "xclip -o 2>/dev/null | head -5 || xsel -p 2>/dev/null | head -5 || echo 'Буфер обмена недоступен или пуст'" \
    "Текущее содержимое буфера обмена"
  
  run_cmd "ps aux | grep -iE 'clipboard|xclip|xsel' | grep -v grep | head -5 || echo 'Процессы буфера обмена не найдены'" \
    "Процессы, работающие с буфером обмена"
  
  echo "$(bold 'Защита:')"
  echo "  - Изоляция буфера обмена между сессиями"
  echo "  - Контроль доступа к буферу обмена"
  echo "  - Очистка буфера при переключении сессий"
  hr
}

block_4_screen_capture(){
  title
  echo "$(bold '4) Перехват окон и экрана')"
  hr
  
  echo "$(bold 'Уязвимости перехвата экрана:')"
  echo "  - В X11 любое приложение может делать скриншоты"
  echo "  - Перехват содержимого окон других приложений"
  echo "  - Утечка визуальной информации"
  hr
  
  run_cmd "command -v import >/dev/null && echo 'ImageMagick import найден' || echo 'import не найден'" \
    "Утилиты для захвата экрана"
  
  run_cmd "command -v scrot >/dev/null && echo 'scrot найден' || echo 'scrot не найден'" \
    "Альтернативные утилиты захвата"
  
  echo "$(bold 'Защита в Astra Linux SE:')"
  echo "  - Контроль доступа к графическим ресурсам"
  echo "  - Изоляция графических сессий"
  echo "  - Аудит операций захвата экрана"
  hr
}

block_5_process_isolation(){
  title
  echo "$(bold '5) Изоляция процессов графических приложений')"
  hr
  
  run_cmd "ps aux | grep -E '$(whoami)' | grep -iE 'gui|gtk|qt|x11' | head -10 || echo 'Графические процессы не найдены'" \
    "Графические процессы текущего пользователя"
  
  run_cmd "ps aux | grep -iE 'xorg|wayland' | grep -v grep | head -5 || echo 'Серверы отображения не найдены'" \
    "Процессы графических серверов"
  
  echo "$(bold 'Уязвимости изоляции:')"
  echo "  - Процессы графических приложений могут взаимодействовать друг с другом"
  echo "  - Нет контроля доступа между графическими приложениями"
  echo "  - Возможность модификации графических процессов"
  hr
  
  run_cmd "getfattr -n security.ILEV -m security.ILEV /usr/bin/* 2>/dev/null | grep -iE 'gtk|qt|x11' | head -5 || echo 'ILEV метки на графических приложениях не найдены'" \
    "Проверка уровней целостности графических приложений"
}

block_6_protection_astra(){
  title
  echo "$(bold '6) Защита от уязвимостей в Astra Linux SE')"
  hr
  
  echo "$(bold 'Механизмы защиты в Astra:')"
  echo "  1. Изоляция графических объектов (управление доступом)"
  echo "  2. Контроль доступа к графическим ресурсам"
  echo "  3. Мандатный контроль доступа для графических приложений"
  echo "  4. Аудит всех операций графической подсистемы"
  hr
  
  run_cmd "getfattr -n security.PDPL -m security.PDPL /usr/bin/* 2>/dev/null | grep -iE 'x11|wayland' | head -5 || echo 'PDPL метки на графических компонентах не найдены'" \
    "Мандатные метки на компонентах графической подсистемы"
  
  if have auditctl; then
    run_cmd "sudo auditctl -l 2>/dev/null | grep -iE 'display|x11|wayland' | head -10 || echo 'Правила аудита графики не найдены'" \
      "Правила аудита графической подсистемы"
  fi
  
  run_cmd "systemctl --user list-units 2>/dev/null | head -10 || echo 'Пользовательские службы недоступны'" \
    "Изоляция пользовательских служб (графические сессии)"
}

block_7_summary(){
  title
  echo "$(bold 'Итог: уязвимости графической подсистемы')"
  hr
  cat <<'EOF'
Типовые уязвимости графической подсистемы:

1. Перехват ввода (кейлоггинг):
   - В X11 любое приложение может получить доступ к клавиатуре
   - Перехват всех нажатий клавиш
   - Утечка паролей и конфиденциальной информации

2. Утечка данных через буфер обмена:
   - Буфер обмена доступен всем приложениям в X11
   - Возможность чтения данных из буфера
   - Утечка конфиденциальной информации

3. Перехват окон и экрана:
   - Любое приложение может делать скриншоты
   - Перехват содержимого окон других приложений
   - Утечка визуальной информации

4. Изоляция процессов:
   - Графические процессы могут взаимодействовать
   - Нет контроля доступа между приложениями
   - Возможность модификации процессов

5. Защита в Astra Linux SE:
   - Изоляция графических объектов
   - Контроль доступа к графическим ресурсам
   - Мандатный контроль доступа
   - Аудит всех операций графики
EOF
  hr
  pause
}

menu(){
  title
  echo "  0) Введение"
  echo "  1) Графический сервер"
  echo "  2) Перехват ввода"
  echo "  3) Утечка через буфер обмена"
  echo "  4) Перехват экрана"
  echo "  5) Изоляция процессов"
  echo "  6) Защита в Astra"
  echo "  7) Итог"
  echo "  a) Всё по порядку"
  echo "  q) Выход"
  read -r -p "$(dim 'Выбор: ')" ch
  case "$ch" in
    0) block_0_intro ;;
    1) block_1_display_server ;;
    2) block_2_keylogging ;;
    3) block_3_clipboard_leak ;;
    4) block_4_screen_capture ;;
    5) block_5_process_isolation ;;
    6) block_6_protection_astra ;;
    7) block_7_summary ;;
    a|A)
      block_0_intro
      block_1_display_server
      block_2_keylogging
      block_3_clipboard_leak
      block_4_screen_capture
      block_5_process_isolation
      block_6_protection_astra
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

