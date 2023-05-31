xquery version "3.1";

(:~
 : Module providing utility functions for EcoCor API.
 :)
module namespace ecutil = "http://ecocor.org/ns/exist/util";

import module namespace config = "http://ecocor.org/ns/exist/config" at "config.xqm";

declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace json = "http://www.w3.org/2013/XSL/json";

(:~
 : Return document for a play.
 :
 : @param $corpusname
 : @param $workname
 :)
declare function ecutil:get-doc(
  $corpusname as xs:string,
  $workname as xs:string
) as node()* {
  let $doc := doc(
    $config:data-root || "/" || $corpusname || "/" || $workname || ".xml"
  )
  return $doc
};
