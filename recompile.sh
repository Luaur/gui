#!/bin/bash
echo "Memulai kompilasi latar belakang..."

# Pastikan path dan library sesuai dengan instalasi Termux Anda
clang++ bot_termux.cpp -o bot_termux -ldpp -std=c++17

if [ $? -eq 0 ]; then
    echo "Kompilasi sukses. Merestart bot..."
    killall bot_termux
    ./bot_termux &
else
    echo "Kompilasi gagal!"
fi
