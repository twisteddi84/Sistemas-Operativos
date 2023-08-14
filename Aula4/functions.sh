#!/bin/bash
function imprime_msg()
{
echo "A minha primeira funcao"
return 0
}
function imprime_data()
{
    echo $(date)
}
function imprime_nome()
{
    echo $(hostname)
    echo $USER
}