C = use "common".
P = use "sol/lib/proc".
H = use "sol/lib/http".
ready : String -> String -> (tries : Int | measure tries) -> Int .
ready log prefix tries | tries <= 0 = error "server did not become ready; see {log}".
ready log prefix tries =
  lines = Str.split 10 (readNow log);
  matches = List.filter (Str.startsWith prefix) lines;
  case matches of
    line :: rest -> C.need (Try.parseInt (Str.trim (Str.sub line (Str.len prefix) (Str.len line - Str.len prefix))))
  | [] -> _ = sleepMs 100; ready log prefix (tries - 1).
start argv dir log =
  stage = P.inDir dir (P.spec (["/bin/sh","-c","log=$1; shift; exec \"$@\" > \"$log\" 2>&1","server",log] + argv));
  C.need (Proc.start (PipelineSpec [stage] (PipeBytes (Bytes.empty Unit))
    (PipeCapture 32768) (PipeCapture 32768) 90000 PipeFail)).
request method url headers body =
  bytes = C.need (Utf8.encode body);
  C.need (Http.request (H.withDeadline 5000 H.defaultOptions) (HttpRequest method url headers bytes)).
get url = request "GET" url [] "".
body (HttpResponse status headers bytes) = C.need (Utf8.decode bytes).
status (HttpResponse status headers bytes) = status.
headers (HttpResponse status headers bytes) = headers.
