#!/bin/sh
for i in $(ls *po); do
  ll_TT=${i%.slint.po}
  sed "/^#/{s/# File: /#: /;s/, line:[ ]*/:/}" $i > /tmp/$i
  msggrep -o ${ll_TT}.SeTkeymap.po -N *SeTkeymap /tmp/$i
done
