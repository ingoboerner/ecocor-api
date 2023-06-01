xquery version "3.1";

import module namespace config = "http://ecocor.org/ns/exist/config"
  at "../modules/config.xqm";
import module namespace ectei = "http://ecocor.org/ns/exist/tei"
  at "../modules/tei.xqm";
import module namespace load = "http://ecocor.org/ns/exist/load"
  at "../modules/load.xqm";

declare variable $local:corpusname external;

let $corpus := ectei:get-corpus($local:corpusname)

return (
  util:log-system-out("Loading data for corpus: " || $local:corpusname),
  util:log-system-out($corpus),
  load:load-corpus($corpus)
)
