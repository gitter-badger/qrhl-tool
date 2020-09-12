structure Control_Isabelle : sig
  val handleLines : unit -> unit
  datatype data = D_String of string | D_Int of int | D_Tree of data list
  exception E_Function of exn -> exn
  exception E_Int of int
  exception E_String of string
  exception E_Data of data
  exception E_Pair of exn * exn
  val store : int -> exn -> unit
  (* For diagnostics. Linear time *)
  val numObjects : unit -> int
end
=
struct
datatype data = D_String of string | D_Int of int | D_Tree of data list

exception E_Function of exn -> exn
(*exception E_StoreFunction of tree -> exn*)
(*exception E_RetrieveFunction of exn -> tree*)
exception E_Data of data
exception E_Int of int
exception E_Unit
exception E_String of string
exception E_Pair of exn * exn

val inStream = BinIO.openIn inputPipeName
val outStream = BinIO.openOut outputPipeName

(* TODO remove *)
val garbageLog = TextIO.openOut "/tmp/garbage.log"
(* fun debugLog str = (TextIO.output (garbageLog, str); TextIO.flushOut garbageLog) *)

val objectsMax = Unsynchronized.ref 0
val objects : exn Inttab.table Unsynchronized.ref = Unsynchronized.ref Inttab.empty

fun numObjects () : int = Inttab.fold (fn _ => fn i => i+1) (!objects) 0

fun sendByte b = BinIO.output1 (outStream, b)
fun readByte () = case BinIO.input1 inStream of
  NONE => error "unexpected end of input"
  | SOME b => b

fun sendInt32 i = let
  val word = Word32.fromInt i
  val _ = sendByte (Word8.fromLargeWord (Word32.toLargeWord (Word32.>> (word, 0w24))))
  val _ = sendByte (Word8.fromLargeWord (Word32.toLargeWord (Word32.>> (word, 0w16))))
  val _ = sendByte (Word8.fromLargeWord (Word32.toLargeWord (Word32.>> (word, 0w8))))
  val _ = sendByte (Word8.fromLargeWord (Word32.toLargeWord (word)))
  in () end

fun readInt32 () : int = let
  val b = readByte () |> Word8.toLargeWord |> Word32.fromLargeWord
  val word = Word32.<< (b, 0w24)
  val b = readByte () |> Word8.toLargeWord |> Word32.fromLargeWord
  val word = Word32.orb (word, Word32.<< (b, 0w16))
  val b = readByte () |> Word8.toLargeWord |> Word32.fromLargeWord
  val word = Word32.orb (word, Word32.<< (b, 0w8))
  val b = readByte () |> Word8.toLargeWord |> Word32.fromLargeWord
  val word = Word32.orb (word, b)
  in Word32.toInt word end

fun sendInt64 i = let
  val word = Word64.fromInt i
  val _ = sendByte (Word8.fromLargeWord (Word64.toLargeWord (Word64.>> (word, 0w56))))
  val _ = sendByte (Word8.fromLargeWord (Word64.toLargeWord (Word64.>> (word, 0w48))))
  val _ = sendByte (Word8.fromLargeWord (Word64.toLargeWord (Word64.>> (word, 0w40))))
  val _ = sendByte (Word8.fromLargeWord (Word64.toLargeWord (Word64.>> (word, 0w32))))
  val _ = sendByte (Word8.fromLargeWord (Word64.toLargeWord (Word64.>> (word, 0w24))))
  val _ = sendByte (Word8.fromLargeWord (Word64.toLargeWord (Word64.>> (word, 0w16))))
  val _ = sendByte (Word8.fromLargeWord (Word64.toLargeWord (Word64.>> (word, 0w8))))
  val _ = sendByte (Word8.fromLargeWord (Word64.toLargeWord (word)))
  in () end

fun readInt64 () : int = let
  val b = readByte () |> Word8.toLargeWord |> Word64.fromLargeWord
  val word = Word64.<< (b, 0w56)
  val b = readByte () |> Word8.toLargeWord |> Word64.fromLargeWord
  val word = Word64.orb (word, Word64.<< (b, 0w48))
  val b = readByte () |> Word8.toLargeWord |> Word64.fromLargeWord
  val word = Word64.orb (word, Word64.<< (b, 0w40))
  val b = readByte () |> Word8.toLargeWord |> Word64.fromLargeWord
  val word = Word64.orb (word, Word64.<< (b, 0w64))
  val b = readByte () |> Word8.toLargeWord |> Word64.fromLargeWord
  val word = Word64.orb (word, Word64.<< (b, 0w24))
  val b = readByte () |> Word8.toLargeWord |> Word64.fromLargeWord
  val word = Word64.orb (word, Word64.<< (b, 0w16))
  val b = readByte () |> Word8.toLargeWord |> Word64.fromLargeWord
  val word = Word64.orb (word, Word64.<< (b, 0w8))
  val b = readByte () |> Word8.toLargeWord |> Word64.fromLargeWord
  val word = Word64.orb (word, b)
  in Word64.toInt word end

fun sendString str = let
  val len = size str
  val _ = sendInt32 len
  val _ = BinIO.output (outStream, Byte.stringToBytes str)
  in () end

fun readString () = let
  val len = readInt32 ()
  val bytes = BinIO.inputN (inStream, len)
  val str = Byte.bytesToString bytes
  val _ = TextIO.output (garbageLog, "Read " ^ string_of_int len ^ " bytes as string: " ^ str ^ "\n")
  val _ = TextIO.flushOut garbageLog
  in str end

fun sendData (D_Int i) = (sendByte 0w1; sendInt64 i)
  | sendData (D_String str) = (sendByte 0w2; sendString str)
  | sendData (D_Tree list) = let
      val _ = sendByte 0w3
      val _ = sendInt64 (length list)
      val _ = List.app sendData list
    in () end
      
fun readData () : data = case readByte () of
    0w1 => readInt64 () |> D_Int
  | 0w2 => readString () |> D_String
  | 0w3 => let
      val len = readInt64 ()
      fun readNRev 0 sofar = sofar
        | readNRev n sofar = readNRev (n-1) (readData () :: sofar)
      val list = readNRev len [] |> rev
    in D_Tree list end

(* Deprecated *)
fun sendReplyStr seq str = let
  val _ = sendInt64 seq
  val _ = sendByte 0w1
  val _ = sendData (D_String str)
  val _ = BinIO.flushOut outStream
  in () end

fun sendReplyN seq ints = let
  val _ = sendInt64 seq
  val _ = sendByte 0w1
  val _ = sendData (D_Tree (map D_Int ints))
  val _ = BinIO.flushOut outStream
  in () end

fun sendReply1 seq int = let
  val _ = sendInt64 seq
  val _ = sendByte 0w1
  val _ = sendData (D_Int int)
  val _ = BinIO.flushOut outStream
  in () end



fun executeML ml = let
  (* val _ = TextIO.print ("Compiling "^ ml^"\n") *)
  (* val flags = ML_Compiler.verbose true ML_Compiler.flags *)
  val flags = ML_Compiler.flags
  val _ = ML_Compiler.eval flags Position.none (ML_Lex.tokenize ml)
  (* val _ = TextIO.flushOut TextIO.stdOut (* Doesn't seem to work *) *)
  in () end

fun addToObjects exn = let
  val idx = !objectsMax
  val _ = objects := Inttab.update_new (idx, exn) (!objects)
  val _ = objectsMax := idx + 1
  in idx end

fun store seq exn = sendReply1 seq (addToObjects exn)

fun storeMany seq exns = sendReplyN seq (map addToObjects exns)

fun storeMLValue seq ml =
  executeML ("let open Control_Isabelle val result = ("^ml^") in store "^string_of_int seq^" result end")

fun exn_str exn = Runtime.pretty_exn exn |> Pretty.unformatted_string_of

fun retrieveInt seq id = case Inttab.lookup (!objects) id of
  NONE => error ("no object " ^ string_of_int id)
  | SOME (E_Int i) => sendReply1 seq i
  | SOME exn => error ("expected E_Int, got: " ^ exn_str exn)

fun retrieveString seq id = case Inttab.lookup (!objects) id of
  NONE => error ("no object " ^ string_of_int id)
  | SOME (E_String str) => sendReplyStr seq str
  | SOME exn => error ("expected E_String, got: " ^ exn_str exn)

fun applyFunc seq f x = case (Inttab.lookup (!objects) f, Inttab.lookup (!objects) x) of
  (NONE,_) => error ("no object " ^ string_of_int f)
  | (_,NONE) => error ("no object " ^ string_of_int x)
  | (SOME (E_Function f), SOME x) => store seq (f x)
  | (SOME exn, _) => error ("object " ^ string_of_int f ^ " is not an E_Function but: " ^ exn_str exn)



fun mkPair seq a b = case (Inttab.lookup (!objects) a, Inttab.lookup (!objects) b) of
  (NONE,_) => error ("no object " ^ string_of_int a)
  | (_,NONE) => error ("no object " ^ string_of_int b)
  | (SOME x, SOME y) => store seq (E_Pair (x,y))

fun splitPair seq id = case (Inttab.lookup (!objects) id) of
  NONE => error ("no object " ^ string_of_int id)
  | SOME (E_Pair (x,y)) => storeMany seq [x,y]
  | SOME exn => error ("object " ^ string_of_int id ^ " is not an E_Pair but: " ^ exn_str exn)

fun removeObjects (D_Tree ids) = let
  val _ = objects := fold (fn D_Int id => Inttab.delete id) ids (!objects)
  val _ = List.app (fn D_Int id => TextIO.output (garbageLog, string_of_int id ^ " ")) ids
  val _ = TextIO.output (garbageLog, "\n")
  in () end 

fun int_of_string str = case Int.fromString str of
  NONE => error ("Failed to parse '" ^ str ^ "' as an int")
  | SOME i => i

(* Without error handling *)
fun handleLine' seq =
  case readByte () of
    (* 1b|string - executes ML code xxx *)
    0w1 => (executeML (readString ()); sendReplyN seq [])

    (* 2b|string - stores string in objects, response 'seq ID' *)
  | 0w2 => store seq (E_String (readString ()))

    (* 3b|int64 - stores int64 as object, response 'seq object#' *)
  | 0w3 => store seq (E_Int (readInt64 ()))

    (* 4b|string - Compiles string as ML code of type exn, stores result as object #seq *)
  | 0w4 => storeMLValue seq (readString ())

    (* 5b|int64 - Interprets int64 as object# and returns the object, assuming it's (E_Int i), response 'seq i' *)
  | 0w5 => retrieveInt seq (readInt64 ())

    (* 6b|int64 - Interprets int64 as object# and returns the object, assuming it's (E_String s), response 'seq s' *)
  | 0w6 => retrieveString seq (readInt64 ())

    (* 7b|int64|int64 - Parses f,x as object#, f of type E_Function, computes f x, stores the result, response 'seq ID' *)
  | 0w7 => let 
        val f = readInt64 ()
        val x = readInt64 ()
      in applyFunc seq f x end

    (* 8b|data ... - data must be list of ints, removes objects with these IDs from objects *)
  | 0w8 => removeObjects (readData ())

    (* 9b|int64|int64 - takes objects i j, creates new object with content E_Pair (i,j), returns 'seq object' *)
  | 0w9 => let 
      val a = readInt64 ()
      val b = readInt64 ()
    in mkPair seq a b end

    (* 10b|int64 - takes object int64, parses as E_Pair (a,b), stores a,b as objects, returns "seq a b" *)
  | 0w10 => splitPair seq (readInt64 ())

  | cmd => error ("Unknown command " ^ string_of_int (Word8.toInt cmd))

fun reportException seq exn = let
  val msg = Runtime.exn_message exn
  val _ = sendInt64 seq
  val _ = sendByte 0w2
  val _ = sendString msg
  val _ = BinIO.flushOut outStream
  in () end

fun handleLine seq =
  handleLine' seq
  handle exn => reportException seq exn

fun handleLines' seq = (handleLine seq; handleLines' (seq+1))

fun handleLines () = handleLines' 0

val _ = TextIO.StreamIO.setBufferMode (TextIO.getOutstream TextIO.stdOut, IO.LINE_BUF)

end
