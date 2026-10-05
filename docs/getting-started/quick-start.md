# Быстрый старт

Соберём простую программу, которая выводит «Hello, World!» в терминал, и запустим её в эмуляторе.

## 1. Написать исходник

Создай файл `hello.asm`:

```asm
.ORG 0x00060000
.TEXT

main:
        LDI.DW SP, 0x00080000       ; указатель стека
        LDI.DW IX, msg              ; адрес строки
        CALL print_string
        HALT

print_string:
        LOD.B XL1, [IX]             ; читаем байт
        CMP.B XL1, 0                ; конец строки?
        JMP.EQ ps_done
        STR.B XL1, [0x00020018]     ; TERM_OUT
        INC IX
        JMA print_string
ps_done:
        RET

.DATA
msg:    .db "Hello, World!", 0x0A, 0
```

## 2. Собрать

Простейший вариант - сразу в плоский бинарник:

```bash
python CASM148.py hello.asm -o hello.bin
```

На выходе появятся два файла:

- `hello.bin` - сырой бинарник (загружается в эмулятор или Logisim).
- `hello.hex` - Logisim hex формата `v2.0 raw`.

Ассемблер выведет что-то вроде:

```text
26 bytes collected. Labels: {'MAIN': 327680, 'PRINT_STRING': 327690, 'PS_DONE': 327706}
Segments: text=32, data=14, bss=0
Written: hello.bin and hello.hex
```

## 3. Запустить в эмуляторе

Эмулятор находится в `emulator\dist\emulator.exe` (Сборках пока что только под Windows), запустите его, в вкладке FILE выбираем пункт Open Disk Image... и выбираем наш `hello.bin`.

В окне эмулятора должен появиться терминал с надписью:

```text
Hello, World!
```

## 4. Что произошло под капотом

1. Программа загружена по адресу `0x00060000` - это начало региона `USER RAM`.
2. `main` установил указатель стека, загрузил адрес строки в `IX` и вызвал `print_string`.
3. `print_string` в цикле читает байт из памяти, проверяет на ноль и пишет в регистр `TERM_OUT` (`0x00020018`).
4. Видеокарта по этому адресу выводит символ в терминал.
5. Когда встречается `\0`, программа завершается через `HALT`.

## 5. Собрать по-взрослому (опционально)

Ту же программу можно собрать в объектный файл и слинковать:

```bash
python CASM148.py -c hello.asm -o hello.o
python LINK148.py hello.o -o hello.bin --entry main
```

Этот способ нужен, когда программа состоит из нескольких модулей и статических библиотек.