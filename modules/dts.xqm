xquery version "3.1";

(:
 : DTS Endpoint
 : This module implements the DTS (Distributed Text Services) API specification – https://distributed-text-services.github.io/specifications/
 : the module was originally developed for the DTS Hackathon https://distributed-text-services.github.io/workshops/events/2021-hackathon/ by Ingo Börner
 : and has been adapted for EcoCor in June 2023.
 :)

(: todo:
 : * Paginated Child Collection; Paginantion not implemented, will return Status code 501
 : * add dublin core metadata; only added language so far
 : * didn't manage to implement all fields in the link header on all levels when requesting a fragment
 : * citeStructure: does it represent the structure, e.g. the types, or is it like a TOC, e.g. list all five acts in a five act play? needs to be refactored
 : * add machine readble endpoint documentation
 : * code of navigation endpoint should be refactored, maybe also code of documents endpoint (fragments)
 : :)



(: ecdts – EcoCor-Implementation of DTS follows EcoCor naming conventions, e.g. ecutil :)
module namespace ecdts = "http://ecocor.org/ns/exist/dts";

import module namespace config = "http://ecocor.org/ns/exist/config" at "config.xqm";
import module namespace ecutil = "http://ecocor.org/ns/exist/util" at "util.xqm";

declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace http = "http://expath.org/ns/http-client";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

(: Namespaces mentioned in the spec:  :)
declare namespace dts = "https://w3id.org/dts/api#";
declare namespace hydra = "https://www.w3.org/ns/hydra/core#";
declare namespace dc = "http://purl.org/dc/terms/";

(: Variables used in responses :)
declare variable $ecdts:api-base := "https://ecocor.org/api"; (: change for production :)
declare variable $ecdts:collections-base := "/api/dts/collections" ;
declare variable $ecdts:documents-base := "/api/dts/documents" ;
declare variable $ecdts:navigation-base := "/api/dts/navigation" ;

declare variable $ecdts:ns-dts := "https://w3id.org/dts/api#";
declare variable $ecdts:ns-hydra := "https://www.w3.org/ns/hydra/core#";
declare variable $ecdts:ns-dc := "http://purl.org/dc/terms/";

(: fixed parts in response, e.g. namespaces :)
declare variable $ecdts:context :=
  map {
      "@vocab": $ecdts:ns-hydra,
      "dc": $ecdts:ns-dc,
      "dts": $ecdts:ns-dts
  };


(:
 : --------------------
 : Entry Point
 : --------------------
 :
 : see https://distributed-text-services.github.io/specifications/Entry.html
 : /api/dts
 :)

(:~
 : DTS Entry Point
 :
 : Main Entry Point to the DTS API. Provides the base path for each of the 3 specified endpoints: collections, navigation and documents.
 :
 : @result JSON object
 :)
declare
  %rest:GET
  %rest:path("ecocor/dts")
  %rest:produces("application/json")
  %output:media-type("application/json")
  %output:method("json")
function ecdts:entry-point() {
  map {
    "@context": "/dts/contexts/EntryPoint.jsonld",
    "@id": "/dts",
    "@type": "EntryPoint",
    "collections": "/dts/collections",
    "documents": "/dts/documents",
    "navigation" : "/dts/navigation"
  }
};
