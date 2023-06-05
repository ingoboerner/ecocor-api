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

(:~
 : Calculate citeDepth
 :
 : Helper function to get citeDepth of a document
 : TODO: have to check, if this makes sense for EcoCor becuse it was originally developed for dramatic texts (act-scene..)
 :
 :   :)
declare function local:get-citeDepth($tei as element(tei:TEI))
as xs:integer {
    if ( $tei//tei:body/tei:div/tei:div/tei:div ) then 4
    else if ( $tei//tei:body/tei:div/tei:div ) then 3
    else if ( $tei//tei:body/tei:div ) then 2
    else if ( $tei//tei:body ) then 1
    else 0
};

(:
 : --------------------
 : Document Endpoint
 : --------------------
 :
 : see https://distributed-text-services.github.io/specifications/Documents-Endpoint.html
 : could be /api/dts/documents (the specification uses "document", but mixes singular an plural; entry point will return "documents" in plural form, but this might change)
 :
 : MUST return "application/tei+xml"
 : will implement only GET
 :
 : Params:
 : $id	(Required) Identifier for a document. Where possible this should be a URI
 : $ref	Passage identifier (used together with id; can’t be used with start and end)
 : $start (For range) Start of a range of passages (can’t be used with ref)
 : $end (For range) End of a range of passages (requires start and no ref)
 : $format (Optional) Specifies a data format for response/request body other than the default
 :
 : Params used in POST, PUT, DELETE requests are not availiable

 :)

(:~
 : DTS Document Endpoint
 :
 : Get a document according to the specification: https://distributed-text-services.github.io/specifications/Documents-Endpoint.html
 :
 : @param $id Identifier for a document
 : @param $ref Passage identifier (used together with id; can’t be used with start and end)
 : @param $start (For range) Start of a range of passages (can’t be used with ref)
 : @param $end (For range) End of a range of passages (requires start and no ref)
 : @param $format (Optional) Specifies a data format for response/request body other than the default
 :
 : @result TEI
 :)
declare
  %rest:GET
  %rest:path("ecocor/dts/documents")
  %rest:query-param("id", "{$id}")
  %rest:query-param("ref", "{$ref}")
  %rest:query-param("start", "{$start}")
  %rest:query-param("end", "{$end}")
  %rest:query-param("format", "{$format}")
  %rest:produces("application/tei+xml")
  %output:media-type("application/xml")
  %output:method("xml")
function ecdts:documents($id, $ref, $start, $end, $format) {
    (: check, if valid request :)

    (: In GET requests one may either provide a ref parameter or a pair of start and end parameters. A request cannot combine ref with the other two. If, say, a ref and a start are both provided this should cause the request to fail. :)
    if ( $ref and ( $start or $end ) ) then
        (
        <rest:response>
            <http:response status="400"/>
        </rest:response>,
        <error statusCode="400" xmlns="https://w3id.org/dts/api#">
            <title>Bad Request</title>
            <description>GET requests may either have a 'ref' parameter or a pair of 'start' and 'end' parameters. A request cannot combine 'ref' with the other two.</description>
        </error>
        )
    else if ( ($start and not($end) ) or ( $end and not($start) ) ) then
        (: requesting a range, should check, if start and end is present :)
        (
        <rest:response>
            <http:response status="400"/>
        </rest:response>,
        <error statusCode="400" xmlns="https://w3id.org/dts/api#">
            <title>Bad Request</title>
            <description>If a range is requested, parameters 'start' and 'end' are mandatory.</description>
        </error>
        )
    else if ( $format ) then
        (: requesting other format than TEI is not implemented :)
        (
        <rest:response>
            <http:response status="501"/>
        </rest:response>,
        <error statusCode="501" xmlns="https://w3id.org/dts/api#">
            <title>Not implemented</title>
            <description>Requesting other format than 'application/tei+xml' is not supported.</description>
        </error>
        )
        (: handled common errors, should check, if document with a certain $id exists :)

    else
        (: valid request :)
        let $tei := collection($config:data-root)/id($id)

        return
            (: check, if document exists! :)
            if ( $tei/name() eq "TEI" ) then
                (: here are valid requests handled :)

                if ( $ref ) then
                    (: requested a fragment :)
                    (: local:get-fragment-of-doc($tei, $ref) :)
                    (
                        <rest:response>
                            <http:response status="501"/>
                        </rest:response>,
                        <error statusCode="501" xmlns="https://w3id.org/dts/api#">
                            <title>Not implemented</title>
                            <description>Requesting a fragment of the document is not implemented.</description>
                        </error>
                    )


                else if ( $start and $end ) then
                    (: requested a range; could be implemented, but not sure, if I will manage in time :)
                    (
                    <rest:response>
                        <http:response status="501"/>
                        </rest:response>,
                    <error statusCode="501" xmlns="https://w3id.org/dts/api#">
                        <title>Not implemented</title>
                        <description>Requesting a range is not supported.</description>
                    </error>
                    )

                else
                (: requested full document :)
                    local:get-full-doc($tei)

            else
                if ( not($id) or $id eq "" ) then
                    (: return the URI template/self description :)
                    local:collections-self-describe()
                else
                (: document does not exist, return the error :)
                (
        <rest:response>
            <http:response status="404"/>
        </rest:response>,
        <error statusCode="404" xmlns="https://w3id.org/dts/api#">
            <title>Not Found</title>
            <description>Document with the id '{$id}' does not exist!</description>
        </error>
        )

};

(: The URI template, that would be the self description of the endpoint – unclear, how this should be implemented :)
(: should include a link to a machine readable documentation :)
declare function local:collections-self-describe() {
    (
        <rest:response>
            <http:response status="400"/>
        </rest:response>,
        <error statusCode="400" xmlns="https://w3id.org/dts/api#">
            <title>Bad Request</title>
            <description>Should at least use the required parameter 'id'. Automatic self description is not availiable.</description>
        </error>
        )
};

(:
 : Return full document requested via the documents endpoint :)
declare function local:get-full-doc($tei as element(tei:TEI)) {
    let $id := $tei/@xml:id/string()
    (: requested complete document, just return the TEI File:)
                (: must include the link header as well :)
                (: see https://distributed-text-services.github.io/specifications/Documents-Endpoint.html#get-responses :)
                (: see https://datatracker.ietf.org/doc/html/rfc5988 :)
                (: </navigation?id={$id}>; rel="contents", </collections?id={$id}>; rel="collection" :)
                
                let $links := '<' || $ecdts:navigation-base || '?id=' || $id || '>; rel="contents", <' || $ecdts:collections-base  ||'?id=' || $id || '>; rel="collection"' 
                (: let $links := () :)

                let $link-header :=  <http:header name='Link' value='{$links}'/>

                return
                (
                <rest:response>
                    <http:response status="200">
                       {$link-header}
                    </http:response>
                </rest:response>,
                $tei
                )
};