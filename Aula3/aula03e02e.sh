#!/bin/bash
# Conditional block if
if (( $1 > 5 && $1 < 10 )) ; then
echo "Maior que 5 e menor que 10."
else
echo "Nao está entre 5 e 10."
fi
