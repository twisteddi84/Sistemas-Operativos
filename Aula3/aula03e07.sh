#!/bin/bash
# Calculate the sum of a series of numbers.
SCORE="0"
SUM="0"
CONT="0"
MEDIA="0"
while true; do
echo -n "Enter your score [0-10] ('r' to reset) ('q' to quit): "
read SCORE;
if (("$SCORE" < "0")) || (("$SCORE" > "10")); then
echo "Try again: "
elif [[ "$SCORE" == "q" ]]; then
echo "Sum: $SUM."
MEDIA=$((SUM/CONT))
echo "Media: $MEDIA."
break
elif [[ "$SCORE" == "r" ]]; then
SCORE="0"
SUM="0"
CONT="0"
MEDIA="0"
echo "Resetado"
else
SUM=$((SUM + SCORE))
CONT=$((CONT + "1"))
fi
done
echo "Exiting."
