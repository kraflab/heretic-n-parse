#! /bin/bash
for file in *.txt; do
  cp $file temp
  current_encoding=`file -i temp | grep -o "=.*" | sed 's/=//'`
  iconv -f $current_encoding -t UTF-8 temp -o $file
done
rm temp
