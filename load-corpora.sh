#!/bin/sh

API_BASE=http://localhost:8090/exist/restxq/ecocor
GH_CONTENT_URI=https://raw.githubusercontent.com/dracor-org

for lang in en de; do
  echo Creating corpus $lang
  curl $GH_CONTENT_URI/eco_$lang/main/corpus.xml | \
    curl -X POST \
      -u admin: \
      -d@- \
      -H 'Content-type: text/xml' \
      $API_BASE/corpora
  echo Loading $lang
  curl -X POST -u admin: $API_BASE/corpora/$lang
done
