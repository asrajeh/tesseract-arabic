#!/bin/bash
# A script to train Tesseract OCR on TRACOM dataset
# Written by Abdullah Alrajeh, Jan 2021

TRACOM_Lines=/mnt/storage/TRACOM_Lines
# git clone https://github.com/tesseract-ocr/langdata_lstm.git
langdata_lstm=/mnt/storage/langdata_lstm

if [ ! -d $TRACOM_Lines ] || [ ! -d $langdata_lstm ]; then
  echo TRAINING DATA NOT AVAILABLE
  exit 1
fi

if [ ! -d tesstrain ]; then
  git clone https://github.com/tesseract-ocr/tesstrain.git
fi

cd tesstrain
MODEL_NAME=ara

# data preperation
if [ ! -d data/$MODEL_NAME ]; then

mkdir data/$MODEL_NAME
cp $langdata_lstm/ara/ara.config data/$MODEL_NAME/$MODEL_NAME.config
cp $langdata_lstm/ara/ara.numbers data/$MODEL_NAME/$MODEL_NAME.numbers
cp $langdata_lstm/ara/ara.punc data/$MODEL_NAME/$MODEL_NAME.punc
cp $langdata_lstm/ara/ara.wordlist data/$MODEL_NAME/$MODEL_NAME.wordlist
mkdir data/$MODEL_NAME-ground-truth

for type in 00 01 02 03; do
  TRACOM=$TRACOM_Lines/TRACOM_${type}
  cp $TRACOM/Lines_${type}/*/*.tif data/$MODEL_NAME-ground-truth

  for d in $TRACOM/GT_${type}/*/; do
    for f in $d/*.txt; do
      filename=$(basename $f)
      filename="${filename%.*}"
      if [ $type -ne '00' ]; then
        filename="${filename:1}"
        filename="${filename::-3}"
      fi
      n=1
      while read l; do
        # Note that text has been reversed since Arabic images are RTL
        echo $l | rev > data/$MODEL_NAME-ground-truth/$filename-$(printf "%02d" $n).gt.txt
        n=$((n+1))
      done < <(iconv -f WINDOWS-1256 -t UTF-8 $f | sed 's/\r//g' | awk '{print $0}' | sed '/^$/d')
    done
  done
done

fi

make training MODEL_NAME=$MODEL_NAME LANG_TYPE=RTL MAX_ITERATIONS=100000

# How to use
# tesseract --tessdata-dir tesstrain/data -l $MODEL_NAME image_input out
