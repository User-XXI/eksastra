#!/usr/bin/env bash
set -euo pipefail

# Вопрос 8: Практические примеры реализации мандатного управления в ОССН
# (на нескольких файлах, каталогах и пользователях)

DEMO_MUTATE="${DEMO_MUTATE:-1}"  # По умолчанию 1, т.к. это практический вопрос
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
  echo "$(bold 'Вопрос 8: Практические примеры реализации МРД')"
  echo "$(dim 'Работа с файлами, каталогами и пользователями')"
  hr
}

block_0_intro(){
  title
  echo "$(bold '0) Подготовка к практической демонстрации')"
  hr
  echo "Демонстрирую:"
  echo "  1. Создание файлов и каталогов с разными метками"
  echo "  2. Установка мандатных меток через pdpl-file"
  echo "  3. Проверка меток через getfattr"
  echo "  4. Попытка доступа с разными уровнями"
  hr
  
  run_cmd "whoami" "Текущий пользователь"
  run_cmd "id" "Права и группы"
  
  if [[ "$DEMO_MUTATE" != "1" ]]; then
    echo "$(ylw 'ВНИМАНИЕ: DEMO_MUTATE=0, практика ограничена. Установи DEMO_MUTATE=1 для полной демонстрации')"
    pause
  fi
}

block_1_create_structure(){
  title
  echo "$(bold '1) Создание тестовой структуры (файлы и каталоги)')"
  hr
  
  if [[ "$DEMO_MUTATE" == "1" ]]; then
    DEMO_DIR="/tmp/mrd_practical_$$"
    run_cmd "mkdir -p \"$DEMO_DIR\"/{level1,level2,level3}" \
      "Создаю структуру каталогов для демонстрации"
    
    run_cmd "echo 'Top secret data' > \"$DEMO_DIR\"/top_secret.txt" \
      "Создаю файл с конфиденциальными данными"
    run_cmd "echo 'Public data' > \"$DEMO_DIR\"/public.txt" \
      "Создаю файл с публичными данными"
    run_cmd "echo 'Internal data' > \"$DEMO_DIR\"/level1/internal.txt" \
      "Создаю файл во вложенном каталоге"
    
    run_cmd "ls -laR \"$DEMO_DIR\" 2>/dev/null | head -20" \
      "Показываю созданную структуру"
  else
    echo "$(ylw 'Пропускаю создание структуры (DEMO_MUTATE=0)')"
  fi
}

block_2_set_labels(){
  title
  echo "$(bold '2) Установка мандатных меток на файлы и каталоги')"
  hr
  
  if [[ "$DEMO_MUTATE" == "1" ]] && have pdpl-file; then
    DEMO_DIR="/tmp/mrd_practical_$$"
    
    run_cmd "sudo pdpl-file 3:0:-1:CCNR \"$DEMO_DIR\"/top_secret.txt 2>/dev/null || echo 'Не удалось установить метку (возможны ограничения политики)'" \
      "Устанавливаю высокий уровень безопасности на конфиденциальный файл"
    
    run_cmd "sudo pdpl-file 1:0:-1:CCNR \"$DEMO_DIR\"/public.txt 2>/dev/null || echo 'Не удалось установить метку'" \
      "Устанавливаю низкий уровень на публичный файл"
    
    run_cmd "sudo pdpl-file 2:0:-1:CCNR \"$DEMO_DIR\"/level1 2>/dev/null || echo 'Не удалось установить метку'" \
      "Устанавливаю метку на каталог"
    
    run_cmd "getfattr -d -m 'security\\.' \"$DEMO_DIR\"/* \"$DEMO_DIR\"/level1 2>/dev/null | head -30 || echo 'Метки не найдены'" \
      "Проверяю установленные метки на всех объектах"
  else
    echo "$(ylw 'pdpl-file недоступен или DEMO_MUTATE=0. Показываю существующие метки в системе:')"
    run_cmd "getfattr -n security.PDPL -m security.PDPL /etc/passwd 2>/dev/null | head -5 || echo 'Метки не найдены'"
  fi
}

block_3_compare_labels(){
  title
  echo "$(bold '3) Сравнение меток разных объектов')"
  hr
  
  if [[ "$DEMO_MUTATE" == "1" ]]; then
    DEMO_DIR="/tmp/mrd_practical_$$"
    run_cmd "for f in \"$DEMO_DIR\"/top_secret.txt \"$DEMO_DIR\"/public.txt \"$DEMO_DIR\"/level1; do echo \"=== \$f ===\"; getfattr -n security.PDPL -m security.PDPL \"\$f\" 2>/dev/null || echo 'Метка не найдена'; done" \
      "Сравниваю метки разных объектов"
  else
    run_cmd "getfattr -n security.PDPL -m security.PDPL /etc/passwd /etc/shadow /bin/bash 2>/dev/null | head -15 || echo 'Метки не найдены'" \
      "Сравниваю метки системных объектов"
  fi
}

block_4_user_access(){
  title
  echo "$(bold '4) Работа с пользователями и их уровнями')"
  hr
  
  run_cmd "id" "Текущий пользователь и его группы"
  run_cmd "getent passwd | head -5" "Список пользователей системы"
  run_cmd "groups" "Группы текущего пользователя"
  
  echo "$(bold 'Примечание:') Уровни пользователей управляются администратором через политику безопасности"
  hr
  
  run_cmd "ps aux | grep -E '^$(whoami)' | head -5 || true" \
    "Процессы текущего пользователя (субъекты с уровнем)"
}

block_5_access_attempts(){
  title
  echo "$(bold '5) Попытки доступа и проверка политики')"
  hr
  
  if [[ "$DEMO_MUTATE" == "1" ]]; then
    DEMO_DIR="/tmp/mrd_practical_$$"
    
    run_cmd "cat \"$DEMO_DIR\"/public.txt 2>/dev/null || echo 'Доступ запрещён или файл не существует'" \
      "Попытка чтения публичного файла"
    
    run_cmd "cat \"$DEMO_DIR\"/top_secret.txt 2>/dev/null || echo 'Доступ запрещён (уровень недостаточен)'" \
      "Попытка чтения конфиденциального файла (может быть заблокировано МРД)"
    
    if have auditctl; then
      run_cmd "sudo ausearch -m file_access 2>/dev/null | tail -10 || echo 'Логи аудита недоступны'" \
        "Проверяю логи аудита попыток доступа"
    fi
  else
    echo "$(ylw 'Пропускаю попытки доступа (DEMO_MUTATE=0)')"
  fi
}

block_6_summary(){
  title
  echo "$(bold 'Итог: практические примеры МРД')"
  hr
  cat <<'EOF'
Практическая демонстрация показала:

1. Создание структуры:
   - Файлы и каталоги с разными назначениями
   - Вложенная структура

2. Установка меток:
   - pdpl-file для назначения мандатных меток
   - Разные уровни для разных объектов
   - Проверка через getfattr

3. Работа с пользователями:
   - Уровни пользователей
   - Процессы как субъекты доступа

4. Контроль доступа:
   - Политика МРД проверяет каждое обращение
   - Аудит фиксирует попытки доступа

5. Практический вывод:
   - МРД работает на всех уровнях
   - Невозможно обойти политику
   - Все действия фиксируются в аудите
EOF
  hr
  
  if [[ "$DEMO_MUTATE" == "1" ]]; then
    DEMO_DIR="/tmp/mrd_practical_$$"
    run_cmd "rm -rf \"$DEMO_DIR\" 2>/dev/null; echo 'Тестовая структура удалена'" \
      "Очистка тестовых объектов"
  fi
  
  pause
}

menu(){
  title
  echo "  0) Подготовка"
  echo "  1) Создание структуры"
  echo "  2) Установка меток"
  echo "  3) Сравнение меток"
  echo "  4) Работа с пользователями"
  echo "  5) Попытки доступа"
  echo "  6) Итог"
  echo "  a) Всё по порядку"
  echo "  q) Выход"
  read -r -p "$(dim 'Выбор: ')" ch
  case "$ch" in
    0) block_0_intro ;;
    1) block_1_create_structure ;;
    2) block_2_set_labels ;;
    3) block_3_compare_labels ;;
    4) block_4_user_access ;;
    5) block_5_access_attempts ;;
    6) block_6_summary ;;
    a|A)
      block_0_intro
      block_1_create_structure
      block_2_set_labels
      block_3_compare_labels
      block_4_user_access
      block_5_access_attempts
      block_6_summary
      ;;
    q|Q) exit 0 ;;
    *) echo "$(ylw 'Не понял')"; pause ;;
  esac
}

while true; do
  menu
  pause
done

