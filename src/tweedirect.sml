fun sayHello hostname =
  response 200 "text/plain" (concat
    [ "Tweedirect\n"
    , "This is a simple HTTP service redirecting tweet links to embeds.\n"
    , "\n"
    , "Usage:\n"
    , "Given a tweet link:\n"
    , "https://twitter.com/:handle/status/:tweet_id\n"
    , "just replace the host with the host of this service:\n"
    , "https://" ^ hostname ^ "/:handle/status/:tweet_id\n"
    ])

fun embedURL tweet_id =
  "https://platform.twitter.com/embed/Tweet.html?id=" ^ tweet_id

fun redirect url =
  let
    val resp = response 301 "text/plain" (concat
      [ "Redirecting to "
      , url
      , "\n"
      , "If you are not redirected, click the link above.\n"
      ])
  in
    setHeader "Location" url resp
  end

fun router hostname req =
  let
    val method = #method req
    val path = String.tokens (fn c => c = #"/") (#path req)
  in
    case (method, path) of
      ("GET", []) => sayHello hostname
    | ("GET", [_, "status", tweet_id]) => redirect (embedURL tweet_id)
    | _ => response 404 "text/plain" "Not found\n"
  end

fun fail msg =
  (print ("Error: " ^ msg ^ "\n"); OS.Process.exit OS.Process.failure)

fun main () =
  let
    val sock = INetSock.TCP.socket ()
    val portOpt = Option.mapPartial Int.fromString (OS.Process.getEnv "PORT")
    val port =
      case portOpt of
        NONE => 3000
      | SOME x => x
    val hostname =
      case OS.Process.getEnv "TWEEDIRECT_HOST" of
        NONE => fail "required env var TWEEDIRECT_HOST not set"
      | SOME hostname => hostname
  in
    print ("Starting tweedirect on port " ^ (Int.toString port) ^ "\n");
    Socket.Ctl.setREUSEADDR (sock, true);
    Socket.bind (sock, INetSock.any port)
    handle _ => fail "could not bind port";
    Socket.listen (sock, 5)
    handle _ => fail "cannot listen on socket";
    print ("Listening on port " ^ (Int.toString port) ^ "\n");
    serveHTTP sock (router hostname)
  end
