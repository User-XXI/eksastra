#!/usr/bin/env bash
set -euo pipefail

# Вопрос 10: Работа с атрибутами мандатного управления доступом в среде ОССН

DEMO_MUTATE="${DEMO_MUTATE:-1}"
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
  echo "$(bold 'Вопрос 10: Работа с атрибутами мандатного управления доступом')"
  hr
}

block_0_intro(){
  title
  echo "$(bold '0) Типы мандатных атрибутов')"
  hr
  echo "Основные атрибуты МРД:"
  echo "  1. security.PDPL — полная метка мандатного доступа"
  echo "  2. security.CLEV — уровень конфиденциальности"
  echo "  3. security.ILEV — уровень целостности"
  echo "  4. security.CATEG — категории"
  hr
  pause
}

block_1_view_attributes(){
  title
  echo "$(bold '1) Просмотр мандатных атрибутов')"
  hr
  
  run_cmd "getfattr --version 2>/dev/null || echo 'getfattr недоступен'" \
    "Проверка наличия утилиты для работы с расширенными атрибутами"
  
  run_cmd "getfattr -n security.PDPL -m security.PDPL /etc/passwd 2>/dev/null | head -5 || echo 'PDPL атрибут не найден'" \
    "Просмотр PDPL метки на системном файле"
  
  run_cmd "getfattr -d -m 'security\\.' /etc/passwd 2>/dev/null | head -10 || echo 'Security атрибуты не найдены'" \
    "Просмотр всех security.* атрибутов"
  
  run_cmd "getfattr -n security.ILEV -m security.ILEV /bin/bash 2>/dev/null | head -3 || echo 'ILEV не найден'" \
    "Уровень целостности исполняемого файла"
  
  run_cmd "getfattr -n security.CLEV -m security.CLEV /etc/shadow 2>/dev/null | head -3 || echo 'CLEV не найден'" \
    "Уровень конфиденциальности защищённого файла"
}

block_2_set_attributes(){
  title
  echo "$(bold '2) Установка мандатных атрибутов')"
  hr
  
  if have pdpl-file; then
    run_cmd "pdpl-file -h 2>/dev/null | head -40" \
      "Справка по утилите pdpl-file для установки меток"
    
    if [[ "$DEMO_MUTATE" == "1" ]]; then
      DEMO_DIR="/tmp/mac_attrs_$$"
      run_cmd "mkdir -p \"$DEMO_DIR\" && echo 'test' > \"$DEMO_DIR\"/file1" \
        "Создаю тестовый файл"
      
      run_cmd "sudo pdpl-file 3:0:-1:CCNR \"$DEMO_DIR\"/file1 2>/dev/null || echo 'Не удалось установить метку (возможны ограничения политики)'" \
        "Установка PDPL метки через pdpl-file"
      
      run_cmd "getfattr -d -m 'security\\.' \"$DEMO_DIR\"/file1 2>/dev/null || echo 'Метки не найдены'" \
        "Проверка установленной метки"
      
      run_cmd "rm -rf \"$DEMO_DIR\"" "Очистка"
    fi
  else
    echo "$(ylw 'pdpl-file недоступен. Показываю альтернативные методы:')"
    run_cmd "setfattr --help 2>/dev/null | head -20 || echo 'setfattr недоступен'" \
      "Прямая установка через setfattr (низкоуровневая)"
  fi
}

block_3_copy_preserve(){
  title
  echo "$(bold '3) Сохранение атрибутов при копировании')"
  hr
  
  if [[ "$DEMO_MUTATE" == "1" ]]; then
    DEMO_DIR="/tmp/mac_copy_$$"
    run_cmd "mkdir -p \"$DEMO_DIR\" && echo 'source' > \"$DEMO_DIR\"/src" \
      "Создаю исходный файл"
    
    if have pdpl-file; then
      run_cmd "sudo pdpl-file 2:0:-1:CCNR \"$DEMO_DIR\"/src 2>/dev/null || true" \
        "Устанавливаю метку на исходный файл"
    fi
    
    run_cmd "cp \"$DEMO_DIR\"/src \"$DEMO_DIR\"/dst1" \
      "Копирование без сохранения атрибутов"
    
    run_cmd "cp -a \"$DEMO_DIR\"/src \"$DEMO_DIR\"/dst2" \
      "Копирование с сохранением атрибутов (-a)"
    
    run_cmd "for f in \"$DEMO_DIR\"/{src,dst1,dst2}; do echo \"=== \$f ===\"; getfattr -d -m 'security\\.' \"\$f\" 2>/dev/null || echo 'Нет меток'; done" \
      "Сравнение меток исходного и скопированных файлов"
    
    run_cmd "rm -rf \"$DEMO_DIR\"" "Очистка"
  else
    echo "$(ylw 'Пропускаю практику (DEMO_MUTATE=0)')"
  fi
}

block_4_inheritance(){
  title
  echo "$(bold '4) Наследование атрибутов')"
  hr
  
  echo "Правила наследования:"
  echo "  - Новые файлы могут наследовать метки от родительского каталога"
  echo "  - Зависит от политики PARSEC"
  hr
  
  run_cmd "cat /sys/module/parsec/parameters/*inherit* 2>/dev/null || echo 'Параметры наследования не найдены'" \
    "Параметры наследования в PARSEC"
  
  if [[ "$DEMO_MUTATE" == "1" ]]; then
    DEMO_DIR="/tmp/mac_inherit_$$"
    run_cmd "mkdir -p \"$DEMO_DIR\" && (have pdpl-file && sudo pdpl-file 2:0:-1:CCNR \"$DEMO_DIR\" 2>/dev/null || true)" \
      "Создаю каталог с меткой"
    
    run_cmd "echo 'new file' > \"$DEMO_DIR\"/newfile" \
      "Создаю файл в каталоге с меткой"
    
    run_cmd "getfattr -d -m 'security\\.' \"$DEMO_DIR\" \"$DEMO_DIR\"/newfile 2>/dev/null || echo 'Метки не найдены'" \
      "Проверка наследования метки новым файлом"
    
    run_cmd "rm -rf \"$DEMO_DIR\"" "Очистка"
  fi
}

block_5_bulk_operations(){
  title
  echo "$(bold '5) Массовые операции с атрибутами')"
  hr
  
  run_cmd "find /etc -maxdepth 1 -type f -exec getfattr -n security.PDPL -m security.PDPL {} \; 2>/dev/null | head -20 || echo 'Метки не найдены'" \
    "Поиск файлов с PDPL метками в /etc"
  
  run_cmd "find /usr/bin -maxdepth 1 -type f -exec getfattr -n security.ILEV -m security.ILEV {} \; 2>/dev/null | head -20 || echo 'ILEV метки не найдены'" \
    "Поиск исполняемых файлов с уровнями целостности"
  
  echo "$(bold 'Для массовой установки можно использовать:')"
  echo "  - Циклы find + pdpl-file"
  echo "  - Скрипты с проверкой политики"
  hr
}

block_6_verification(){
  title
  echo "$(bold '6) Проверка корректности атрибутов')"
  hr
  
  if [[ "$DEMO_MUTATE" == "1" ]]; then
    DEMO_DIR="/tmp/mac_verify_$$"
    run_cmd "mkdir -p \"$DEMO_DIR\" && echo 'data' > \"$DEMO_DIR\"/f1" \
      "Создаю тестовый файл"
    
    if have pdpl-file; then
      run_cmd "sudo pdpl-file 2:0:-1:CCNR \"$DEMO_DIR\"/f1 2>/dev/null || true" \
        "Устанавливаю метку"
      
      run_cmd "getfattr -d -m 'security\\.' \"$DEMO_DIR\"/f1 2>/dev/null" \
        "Проверка установленной метки"
      
      run_cmd "stat \"$DEMO_DIR\"/f1 | grep -i 'file\|size'" \
        "Дополнительная информация о файле"
    fi
    
    run_cmd "rm -rf \"$DEMO_DIR\"" "Очистка"
  fi
  
  run_cmd "getfattr -n security.PDPL -m security.PDPL /etc/passwd 2>/dev/null || echo 'Метка не установлена (это нормально, если политика не требует)'" \
    "Проверка меток на системных файлах"
}

block_7_summary(){
  title
  echo "$(bold 'Итог: работа с мандатными атрибутами')"
  hr
  cat <<'EOF'
Работа с атрибутами МРД включает:

1. Просмотр атрибутов:
   - getfattr для чтения security.* атрибутов
   - PDPL, CLEV, ILEV — основные типы меток

2. Установка атрибутов:
   - pdpl-file — основной инструмент
   - Требует прав администратора
   - Подчиняется политике безопасности

3. Сохранение при операциях:
   - cp -a сохраняет атрибуты
   - Наследование от родительских каталогов
   - Зависит от настроек PARSEC

4. Массовые операции:
   - find + pdpl-file для обработки множества файлов
   - Проверка корректности через getfattr

5. Важно:
   - Атрибуты влияют на доступ
   - Изменение требует понимания политики
   - Все операции аудируются
EOF
  hr
  pause
}

menu(){
  title
  echo "  0) Введение"
  echo "  1) Просмотр атрибутов"
  echo "  2) Установка атрибутов"
  echo "  3) Сохранение при копировании"
  echo "  4) Наследование атрибутов"
  echo "  5) Массовые операции"
  echo "  6) Проверка корректности"
  echo "  7) Итог"
  echo "  a) Всё по порядку"
  echo "  q) Выход"
  read -r -p "$(dim 'Выбор: ')" ch
  case "$ch" in
    0) block_0_intro ;;
    1) block_1_view_attributes ;;
    2) block_2_set_attributes ;;
    3) block_3_copy_preserve ;;
    4) block_4_inheritance ;;
    5) block_5_bulk_operations ;;
    6) block_6_verification ;;
    7) block_7_summary ;;
    a|A)
      block_0_intro
      block_1_view_attributes
      block_2_set_attributes
      block_3_copy_preserve
      block_4_inheritance
      block_5_bulk_operations
      block_6_verification
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

