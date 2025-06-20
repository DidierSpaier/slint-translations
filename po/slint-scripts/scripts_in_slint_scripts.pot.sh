sed -n "/# File:/p" slint-scripts.pot|sed "s/# File: //;s/,.*//" |sort|uniq >scripts_in_slint_scripts_prev.txt
