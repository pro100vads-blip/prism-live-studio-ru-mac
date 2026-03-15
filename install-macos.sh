#!/bin/bash
set -e

# ============================================================
# Установщик русской локализации PRISM Live Studio для macOS
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_PATH="/Applications/PRISMLiveStudio.app"
APP_DATA="$APP_PATH/Contents/Resources/data/prism-studio"
APP_LOCALE="$APP_DATA/locale"
APP_CONFIG="$APP_DATA/locale.ini"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[!]${NC} $1"; }
print_err()  { echo -e "${RED}[ОШИБКА]${NC} $1"; }

# --- Удаление ---
if [[ "$1" == "--uninstall" ]]; then
    echo "=========================================="
    echo " Удаление русской локализации PRISM"
    echo "=========================================="
    echo ""

    if [[ ! -d "$APP_PATH" ]]; then
        print_err "PRISM Live Studio не найден в /Applications/"
        exit 1
    fi

    echo "Будут удалены все файлы ru-RU.ini из PRISM Live Studio."
    read -p "Продолжить? (y/n): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Отменено."
        exit 0
    fi

    # Удаление файлов перевода
    count=0
    while IFS= read -r file; do
        sudo rm -f "$file"
        ((count++))
    done < <(find "$APP_LOCALE" -name "ru-RU.ini" 2>/dev/null)

    # Удаление секции [ru-RU] из locale.ini
    if grep -q "\[ru-RU\]" "$APP_CONFIG" 2>/dev/null; then
        sudo sed -i '' '/\[ru-RU\]/,/^$/d' "$APP_CONFIG"
        print_ok "Секция [ru-RU] удалена из locale.ini"
    fi

    print_ok "Удалено файлов: $count"
    echo ""
    echo "Перезапустите PRISM Live Studio для применения изменений."
    exit 0
fi

# --- Установка ---
echo "=========================================="
echo " Русская локализация PRISM Live Studio"
echo "=========================================="
echo ""

# Проверка наличия PRISM
if [[ ! -d "$APP_PATH" ]]; then
    print_err "PRISM Live Studio не найден!"
    echo "  Убедитесь, что приложение установлено в /Applications/PRISMLiveStudio.app"
    exit 1
fi

print_ok "PRISM Live Studio найден"

# Проверка наличия файлов перевода
if [[ ! -d "$SCRIPT_DIR/locale" ]]; then
    print_err "Папка locale/ не найдена рядом со скриптом!"
    exit 1
fi

# Подсчёт файлов
file_count=$(find "$SCRIPT_DIR/locale" -name "ru-RU.ini" | wc -l | tr -d ' ')
print_ok "Найдено файлов перевода: $file_count"

echo ""
echo "Файлы будут скопированы в:"
echo "  $APP_LOCALE"
echo ""
echo "Для записи в папку приложения потребуется пароль администратора (sudo)."
echo ""
read -p "Продолжить установку? (y/n): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Установка отменена."
    exit 0
fi

echo ""

# Бэкап locale.ini
if [[ -f "$APP_CONFIG" ]]; then
    backup_name="locale.ini.backup.$(date +%Y%m%d%H%M%S)"
    sudo cp "$APP_CONFIG" "$APP_DATA/$backup_name"
    print_ok "Создан бэкап: $backup_name"
fi

# Добавление секции [ru-RU] в locale.ini если её нет
if ! grep -q "\[ru-RU\]" "$APP_CONFIG" 2>/dev/null; then
    sudo bash -c "cat >> '$APP_CONFIG'" << 'EOF'

[ru-RU]
# 0x0419
LID=1049
Name=Русский
EOF
    print_ok "Секция [ru-RU] добавлена в locale.ini"
else
    print_warn "Секция [ru-RU] уже есть в locale.ini — пропускаю"
fi

# Копирование корневого ru-RU.ini
sudo cp "$SCRIPT_DIR/locale/ru-RU.ini" "$APP_LOCALE/ru-RU.ini"
print_ok "Скопирован: locale/ru-RU.ini"

# Копирование модулей
copied=0
for module_dir in "$SCRIPT_DIR"/locale/*/; do
    module_name=$(basename "$module_dir")
    src_file="$module_dir/ru-RU.ini"
    dest_dir="$APP_LOCALE/$module_name"

    if [[ -f "$src_file" ]]; then
        sudo mkdir -p "$dest_dir"
        sudo cp "$src_file" "$dest_dir/ru-RU.ini"
        ((copied++))
    fi
done

print_ok "Скопировано модулей: $copied"

echo ""
echo "=========================================="
echo -e "${GREEN} Установка завершена!${NC}"
echo "=========================================="
echo ""
echo "Как активировать русский язык:"
echo "  1. Откройте PRISM Live Studio"
echo "  2. Перейдите в Settings (Настройки)"
echo "  3. Вкладка General (Общие)"
echo "  4. В списке Language выберите «Русский»"
echo "  5. Перезапустите приложение"
echo ""
