#!/bin/bash

# bash strict mode
# NOT using -e, this failes with entr and check for statuscode 2
set -uo pipefail
IFS=$'\n\t'

scanandocr() {
for P in $(find "${DIR}" -name '*PLZOCR.pdf' -not -name '.*' -print); do
  IN="$(basename $P)"
  newfn="${IN/PLZOCR/INPROGRESS}"
  outfn="${IN/PLZOCR/OCR}"
  failedfn="${IN/PLZOCR/FAILED}"

  echo "scanandocr: found ${IN} -> ${newfn}"

  mv "${IN}" "${newfn}"
  docker run --rm -v "$(pwd):/home/docker" jbarlow83/ocrmypdf --output-type pdfa -l deu+eng "/home/docker/${newfn}" "/home/docker/${outfn}"
  if [ -f "${outfn}" ]; then
    rm -f "${newfn}"
    echo "scanandocr: success. ${outfn}"
  else
    mv "${newfn}" "${failedfn}"
    echo "scanandocr: failed. ${failedfn}"
  fi
done
}

uploadsnailmail() {
for P in $(find "${DIR}" -name '*SNAILMAIL.pdf' -not -name '.*' -print); do
  IN="$(basename $P)"
  newfn="${IN/_SNAILMAIL/}"
  failedfn="${IN/SNAILMAIL/FAILED}"

  echo "uploadsnailmail: found ${IN} -> ${newfn}"

  mv "${IN}" "${newfn}"
  # upload to owncloud
  curl -s -T "${newfn}" -u "${OCFOLDERKEY}:${OCPASSWD}" -H 'X-Requested-With: XMLHttpRequest' "${OCBASEURL}/public.php/webdav/${newfn}" | tee /tmp/upload.log
  if [ $? -ne 0 ] || grep -q error /tmp/upload.log; then
    mv "${newfn}" "${failedfn}"
    echo "uploadsnailmail: failed. ${failedfn}"
  else
    rm -f "${newfn}"
    echo "uploadsnailmail: success. deleted ${newfn}"
  fi
  rm /tmp/upload.log

  # post to slack
  TEXT="Neuer Scan: ${OCBASEURL}/remote.php/webdav/${OCFOLDER}/${newfn}"
  JSON="{\"text\":\"${TEXT}\"}"
  curl -X POST -H 'Content-type: application/json' --data "${JSON}" ${SLACKHOOKURL}
  echo "" # newline after slack response
  echo "uploadsnailmail: notified ${TEXT}"
done
}

run() {
echo "Starting OCR for directory ${DIR}"
while sleep 1; do
  # using entr to detect changes in the directory DIR
  echo "${DIR}" | entr -n -d /bin/echo
  A=$?
  echo $A
  if [ $A -eq 2 ]; then
    echo "waiting for full upload"
    sleep 2
    scanandocr
    uploadsnailmail
  fi
done
}


# start. for debugging purposes you can run the script with the first argument set to a known function
if [ $# -ge 1 ] && [ -n "$1" ]; then
  $1
else
  # run default function
  run
fi
