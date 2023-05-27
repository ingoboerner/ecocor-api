xquery version "3.1";

module namespace api = "http://ecocor.org/ns/exist/api";

import module namespace config = "http://ecocor.org/ns/exist/config" at "config.xqm";

declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace repo = "http://exist-db.org/xquery/repo";
declare namespace expath = "http://expath.org/ns/pkg";
declare namespace json = "http://www.w3.org/2013/XSL/json";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

(:~
 : API info
 :
 : Shows version numbers of the ecocor-api app and the underlying eXist-db.
 :
 : @result JSON object
 :)
declare
  %rest:GET
  %rest:path("/ecocor/info")
  %rest:produces("application/json")
  %output:media-type("application/json")
  %output:method("json")
function api:info() {
  let $expath := config:expath-descriptor()
  let $repo := config:repo-descriptor()
  return map {
    "name": $expath/expath:title/string(),
    "version": $expath/@version/string(),
    "status": $repo/repo:status/string(),
    "existdb": system:get-version(),
    "base": $config:api-base
  }
};

(:~
 : OpenAPI specification
 :
 : @result YAML
 :)
declare
  %rest:GET
  %rest:path("/ecocor/openapi.yaml")
  %rest:produces("application/yaml")
  %output:media-type("application/yaml")
  %output:method("text")
function api:openapi-yaml() {
  let $path := $config:app-root || "/api.yaml"
  let $expath := config:expath-descriptor()
  let $yaml := util:base64-decode(xs:string(util:binary-doc($path)))
  return replace(
    replace($yaml, 'https://ecocor.org/api', $config:api-base),
    'version: [0-9.]+',
    'version: ' || $expath/@version/string()
  )
};
