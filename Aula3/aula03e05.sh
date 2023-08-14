#!/bin/bash
# For all the files in a folder, show their properties
if [[ $# > 1 ]]; then
echo "Muitos argumentos"
elif [[ -d $1 ]]; then
for f in $1/*; do
mv "$f" "$1/new_$(basename $f)"
done
else
echo "Nao é diretorio"
fi
