# Сканирование на Canon MF4010 в современной macOS

[![CI](https://github.com/zvdenis/canon-mf4010-macos/actions/workflows/ci.yml/badge.svg)](https://github.com/zvdenis/canon-mf4010-macos/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/zvdenis/canon-mf4010-macos?sort=semver)](https://github.com/zvdenis/canon-mf4010-macos/releases)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**Одна команда возвращает Canon imageCLASS MF4010 к жизни в macOS 12+ — включая
Apple Silicon.**

Драйвер сканера Canon ScanGear для этого МФУ — 32-битный код, который не
запускается на современных macOS. Поэтому Image Capture и Preview не видят
сканер, хотя печать через драйвер UFR II работает. Проект использует бэкенд
SANE `pixma`, добавляет команду `scan` с разумными настройками по умолчанию и
приложение для Spotlight, а также обходит ошибку `scanimage`, из-за которой
сканы выглядят белыми.

![Как это работает](docs/diagram.png)

```sh
# только командная строка
brew install zvdenis/tap/canon-mf4010

# CLI + приложение для Spotlight
curl -fsSL https://raw.githubusercontent.com/zvdenis/canon-mf4010-macos/main/install.sh | bash
```

Положите страницу лицевой стороной вниз на стекло и выполните `scan` (или
нажмите ⌘Space, введите `Scan` и Enter).

**English:** [README.md](README.md)

## Зачем это нужно

MF4010 — это принтер, планшетный сканер и копир конца 2000-х. Печать в macOS
работает, а сканирование — нет: нужен **ScanGear MF**, 32-битный драйвер без
сборки под Apple Silicon. Железо при этом исправно и отдаёт стандартный
интерфейс сканера по USB.

Бэкенд SANE `pixma` умеет работать с MF4010, но даёт только консольную утилиту
с десятком опций и, на macOS, PDF-файлы, которые открываются белой страницей.
Этот проект — недостающая прослойка.

## Что вы получаете

- **`scan`** — одна команда, по умолчанию A4, 300 dpi, оттенки серого, PDF.
- **Scan.app** — ⌘Space → `Scan` → Enter, результат открывается в Preview.
- **`install.sh` / `uninstall.sh`** — без sudo и без расширений ядра.
- **Формула Homebrew** — `brew install zvdenis/tap/canon-mf4010`.

## Требования

- macOS 12 или новее (проверено на 26.6.2, Apple M5; на Intel должно работать)
- [Homebrew](https://brew.sh)
- Принтер, подключённый по USB (сетевого порта у этой модели нет)

## Установка

### Homebrew (только CLI)

```sh
brew install zvdenis/tap/canon-mf4010
```

Приложение для Spotlight можно добавить после:

```sh
cp -R "$(brew --prefix)/opt/canon-mf4010/Scan.app" /Applications/
```

Если Homebrew откажется загружать формулу из стороннего тапа («untrusted
tap»), один раз выполните `brew trust zvdenis/tap`.

### Одной командой (CLI + приложение)

```sh
curl -fsSL https://raw.githubusercontent.com/zvdenis/canon-mf4010-macos/main/install.sh | bash
```

Установщик при необходимости поставит SANE через Homebrew, положит `scan` в
`PATH` и соберёт `Scan.app` в `/Applications` (или в `~/Applications`, если нет
прав администратора).

### Из клона репозитория

```sh
git clone https://github.com/zvdenis/canon-mf4010-macos.git
cd canon-mf4010-macos
./install.sh
```

Опции установщика: `--prefix DIR`, `--app-dir DIR`, `--no-app`, `--no-brew`.

## Использование

### Spotlight и Finder

⌘Space → `Scan` → Enter. Сканируется одна страница, файл сохраняется в
`~/Documents/Scans` и открывается в Preview. Страницу нужно положить на стекло
**заранее** — сканирование начинается сразу.

Если сканер спит или отключён, приложение покажет диалог с ошибкой. Подробности
пишутся в `/tmp/scan-app.log`.

### Командная строка

```sh
scan                    # 300 dpi, серый, PDF -> ~/Documents/Scans
scan -c                 # цвет
scan -c -r 150          # быстрый цветной черновик
scan -l -n Receipt      # ч/б, своё имя файла
scan -p 3               # 3 страницы, с подсказкой между листами
scan --png -o ~/Desktop/page.png
scan --list             # список найденных сканеров
scan --version
```

| Опция | Значение |
|---|---|
| `-c`, `--color` | Цветной скан (по умолчанию — серый) |
| `-l`, `--lineart` | Чисто чёрно-белый, лучше для текста |
| `-r 75/150/300/600` | Разрешение (по умолчанию 300 dpi) |
| `-p N` | N страниц с запросом замены листа |
| `-o FILE` | Точный путь к файлу |
| `-n NAME` | Основа имени файла |
| `--png`, `--jpg`, `--tiff` | Формат (по умолчанию PDF) |
| `--no-open` | Не открывать результат |
| `SCAN_DIR=...` | Другая папка для сканов |

Имена файлов: `Scan-ГГГГ-ММ-ДД-ЧЧММСС.pdf`. Сканируется всё стекло A4 — датчика
размера страницы у MF4010 нет, при необходимости обрежьте afterwards.

## Как это работает

```
Spotlight ──► Scan.app ──► scan ──► scanimage ──► SANE pixma ──► MF4010 (USB)
                                   │
                                   └──► PNG ──► sips (ImageIO) ──► PDF ──► Preview
```

- `scanimage` общается со сканером через бэкенд SANE `pixma`
  (`pixma:04A926B4_<серийный номер>`); устройство определяется автоматически,
  серийный номер в репозитории не хранится.
- `scan` сканирует в PNG и собирает PDF через `sips` (macOS ImageIO) — так
  получается корректная таблица кросс-ссылок.
- `Scan.app` — маленький AppleScript-апплет, который запускает `scan` и
  показывает ошибку в диалоге.

Проверено на Canon imageCLASS MF4010 Series (USB), macOS 26.6.2 (25G83),
Apple M5, SANE 1.4.0 и Canon UFR II 10.19.25 для печати.

Другие модели из `man sane-pixma` (MF4018, MF4120, MF4150 и т. д.) с большой
вероятностью тоже заработают, но проверена только MF4010.

## Ошибка с белыми страницами

`scanimage --format=pdf` в SANE 1.4.0 пишет PDF, у которого таблица
кросс-ссылок заполнена нулями, а `startxref` равен `0`. Изображение внутри
файла целое и корректное, но CoreGraphics (Preview, Quick Look, PDFKit)
отказывается его рисовать и пишет в лог:

```
CoreGraphics PDF has logged an error
```

Страница выглядит белой. Другие просмотрщики молча чинят файл, поэтому проблема
кажется «плавающей». `scan` вообще не использует этот писатель: сканирует в
PNG без потерь и собирает PDF средствами macOS.

Подробный отчёт для разработчиков SANE — в
[docs/upstream-report.md](docs/upstream-report.md). Если ошибку исправят в SANE,
заплатка станет ненужной для всех, а не только для MF4010.

## Решение проблем

| Симптом | Что делать |
|---|---|
| `scan: no Canon scanner found` | Принтер выключен или спит — нажмите кнопку на нём, проверьте кабель USB, выполните `scan --list`. MF4010 иногда пропадает с USB при простое; кнопка возвращает его. |
| Белая страница в Preview | Убедитесь, что лист лежит лицевой стороной вниз на стекле. PDF, созданные до 0.1.0, были повреждены — пересканируйте. |
| Сканирование зависает | Переподключите USB, подождите ~10 с, повторите. Печать и сканирование делят один USB-канал. |
| Полосы или серый фон | Протрите стекло; калибровка со стороны драйвера Canon через SANE недоступна. |
| Приложение «молчит» | Смотрите `/tmp/scan-app.log`; запустите `scan` в Терминале. |

## FAQ

**Подойдёт для других моделей Canon?**
Проверена только MF4010. Модели из списка `sane-pixma` (MF4018, MF4120,
MF4150, ...) используют тот же протокол и, скорее всего, заработают — напишите
о результате в issue.

**Почему не VueScan?**
VueScan поддерживает MF4010 и отлично работает, но стоит денег: $49.95 за
Basic (только JPEG, без PDF) или $99.95 за Standard с PDF и OCR. Если нужен
GUI, OCR и сканирование плёнки — берите его. Этот проект закрывает массовый
случай: бесплатно, MIT, скриптуется и ставится одной командой.

**А ExactScan?**
В его списке совместимости есть Canon P-, DR-, G- и X-серии, но MF4010 нет.

**Можно сканировать в PDF с OCR?**
Встроенного OCR нет. Сохраните PDF и прогоните через `ocrmypdf` (есть в
Homebrew) либо используйте VueScan/ExactScan.

**ADF, дуплекс, сеть?**
У MF4010 этого нет. Многостраничность — `scan -p N` с заменой листов вручную.

## Удаление

```sh
# версия из Homebrew
brew uninstall canon-mf4010

# версия из install.sh
./uninstall.sh

# приложение
rm -rf /Applications/Scan.app
```

Сканы в `~/Documents/Scans` не удаляются. Драйвер при желании убирается
командой `brew uninstall sane-backends`.

## Лицензия

MIT — см. [LICENSE](LICENSE). Проект не связан с Canon; SANE распространяется
под GPL-2.0.
