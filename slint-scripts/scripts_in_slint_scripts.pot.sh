sed -n "/# File:/p" slint_scripts.pot|sed "s/# File: //;s/,.*//" |sort|uniq >scripts_in_slint_scripts.txt
