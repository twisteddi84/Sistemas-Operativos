#!/bin/bash
function comparar()
{
if (($1 == $2)); then
echo "Números iguais"
else
    if (($1 > $2)); then
    echo "$1 maior que $2"
    else
    echo "$1 menor que $2"
    fi
fi
}