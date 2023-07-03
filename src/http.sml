datatype 'a result = OK of 'a | ERROR of string

type request = {method: string, path: string, version: string}

type response = {status: int, headers: (string * string) list, body: string}

fun decode firstLine =
  case String.tokens (fn c => c = #" ") firstLine of
    method :: path :: version :: _ =>
      OK {method = method, path = path, version = version}
  | _ => ERROR "Invalid request"

fun statusString code =
  case code of
    200 => "200 OK"
  | 301 => "301 Moved Permanently"
  | 400 => "400 Bad Request"
  | 404 => "404 Not Found"
  | _ => "500"

fun response status contentType body =
  { status = status
  , headers =
      [ ("Server", "SML HTTP Server Hack")
      , ("Content-Type", contentType)
      , ("Content-Length", Int.toString (String.size body))
      ]
  , body = body
  }

fun setHeader k v resp =
  let val {status, headers, body} = resp
  in {status = status, headers = (k, v) :: headers, body = body}
  end

fun encode {status, headers, body} =
  let
    fun encodeHeader (k, v) =
      k ^ ": " ^ v ^ "\r\n"
  in
    "HTTP/1.1 " ^ (statusString status) ^ "\r\n"
    ^ String.concat (map encodeHeader headers) ^ "\r\n" ^ body
  end

fun firstLine str =
  let
    fun isntLineBreak c = c <> #"\r" andalso c <> #"\n"
  in
    Substring.string (Substring.takel isntLineBreak (Substring.full str))
  end

(* Each request is handled by a forked child process running this code *)
fun handleHTTP sock handler =
  let
    val maxHeaderSize = 8192
    val bytes = Socket.recvVec (sock, maxHeaderSize)
    val str = Byte.bytesToString bytes
    val reqLine = firstLine str
  in
    print (reqLine ^ "\n");
    let
      val resp =
        case decode reqLine of
          OK req => handler req
        | ERROR msg =>
            ( print ("Invalid request: " ^ msg ^ "\n")
            ; response 400 "text/plain" "Bad request, dude"
            )
      val encoded = encode resp
      val bytes = Byte.stringToBytes encoded
      val size = Word8Vector.length bytes
    in
      print
        (statusString (#status resp) ^ " (" ^ (Int.toString size) ^ " bytes)\n");
      Socket.sendVec (sock, Word8VectorSlice.full bytes)
    end
  end

(* The server entry point enters this loop waiting for connections *)
fun serveHTTP server_sock handler =
  let
    val _ = print "Waiting for connection...\n"
    val (client_sock, _) = Socket.accept server_sock
  in
    print "Accepted connection, forking handler.\n";
    case Posix.Process.fork () of
      NONE =>
        ( handleHTTP client_sock handler
        ; Socket.close client_sock
        ; Posix.Process.exit (Word8.fromInt 0)
        )
    | SOME _ => serveHTTP server_sock handler
  end
