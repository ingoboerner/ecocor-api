xquery version "3.1";

(:~
 : Module providing function to load files from zip archives.
 :)
module namespace entities = "http://ecocor.org/ns/exist/entities";

import module namespace config = "http://ecocor.org/ns/exist/config" at "config.xqm";
import module namespace ectei = "http://ecocor.org/ns/exist/tei" at "tei.xqm";
import module namespace ecutil = "http://ecocor.org/ns/exist/util" at "util.xqm";

declare namespace trigger = "http://exist-db.org/xquery/trigger";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace tei = "http://www.tei-c.org/ns/1.0";


(:~
 : Create segments input for extractor service
 :
 : @param $tei TEI document
:)
declare function entities:segment($tei as element(tei:TEI)) as map() {
  map {
    "language": normalize-space($tei/@xml:lang),
    "segments": array {
      (: FIXME: remove limit :)
      for $p in ectei:get-text-paras($tei)
      return map {
        "segment_id": normalize-space($p/@xml:id),
        "text": normalize-space($p)
      }
    }
  }
};

(:~
 : Get entities from extractor service for single text
 :
 : @param $tei TEI document
:)
declare function entities:extract($tei as element(tei:TEI)) {
  let $segments := entities:segment($tei)
  let $endpoint := $config:extractor-server || '/extractor'
  let $endpoint := $config:extractor-server || '/extractor' || '?' || $tei/base-uri()
  let $payload := serialize(
    $segments,
    <output:serialization-parameters>
      <output:method>json</output:method>
    </output:serialization-parameters>
  )

  (: Since the metrics service cannot properly handle chunked transfer encoding
   : we disable it using the undocumented @chunked attribute.
   : see https://github.com/expath/expath-http-client-java/issues/9 :)
  let $request :=
    <hc:request method="post" chunked="false">
      <hc:body media-type="application/json" method="text"/>
    </hc:request>
  let $response := hc:send-request($request, ($endpoint), $payload)
  let $status := string($response[1]/@status)
  let $entities := if ($status = "200") then
    $response[2] => util:base64-decode() => parse-json()
  else (
    util:log-system-out(
      "extractor service FAILED with status '"|| $status ||"' for " || $tei/base-uri()
    ),
    map{}
  )

  return $entities
};

(:~
 : Get entities from extractor service for single text
 :
 : @param $url Database URL to TEI document
:)
declare function entities:extract-for-url($url as xs:string) {
  let $tei := doc($url)/tei:TEI
  return entities:extract($tei)
};

(:~
 : Translate extractor service output to XML
 :
 : @param $entities Map
:)
declare function entities:to-xml($entities as map()) {
  <entities updated="{current-dateTime()}">
    {
      for $ent in $entities?entity_list?* return
      <entity>
        <name>{$ent?name}</name>
        <wikidata>{$ent?wikidata_ids}</wikidata>
        <category>{$ent?category}</category>
        <segments>
        {
          for $id in map:keys($ent?segment_frequencies) return
          <segment>
            <id>{$id}</id>
            <count>{map:get($ent?segment_frequencies, $id)}</count>
          </segment>
        }
        </segments>
      </entity>
    }
  </entities>
};

(:~
 : Update entities for single text
 :
 : @param $url URL of the TEI document
:)
declare function entities:update($url as xs:string) {
  let $entities := entities:extract-for-url($url)
  let $paths := ecutil:filepaths($url)
  let $collection := $paths?collections?entities
  let $resource := $paths?filename
  return (
    util:log-system-out('Entities update: ' || $collection || '/' || $resource),
    xmldb:store($collection, $resource, entities:to-xml($entities))
  )
};

(:~
 : Update entities for all texts in the database
:)
declare function entities:update() as xs:string* {
  let $l := util:log-system-out("Updating entities files")
  for $tei in collection($config:data-root)//tei:TEI
  let $url := $tei/base-uri()
  return (util:log-system-out($url), entities:update($url))
};
