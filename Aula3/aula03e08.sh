#!/bin/bash
# select structure to create menus
PS3="Chupamos:"
select arg in $@; do
if (("$#" < "$REPLY")); then
break
else
echo "You picked $arg ($REPLY)."
fi
done