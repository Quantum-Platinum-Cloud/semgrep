(* TODO: This module should be renamed to Tok.ml and maybe split with a Loc.ml
 * and maybe a Parsing_error.ml ?
 *)

(*****************************************************************************)
(* Tokens *)
(*****************************************************************************)

(* ('token_location' < 'token_origin' < 'token_mutable') * token_kind *)

(* to report errors, regular position information *)
type token_location = {
  str : string; (* the content of the "token" *)
  charpos : int; (* byte position, 0-based *)
  line : int; (* 1-based *)
  column : int; (* 0-based *)
  file : Common.filename;
}
(* see also type filepos = { l: int; c: int; } in Common.mli *)

(* to deal with expanded tokens, e.g. preprocessor like cpp for C *)
type token_origin =
  | OriginTok of token_location
  | FakeTokStr of string * (token_location * int) option (* next to *)
  | ExpandedTok of token_location * token_location * int
  | Ab (* abstract token, see Parse_info.ml comment *)

(* to allow source to source transformation via token "annotations",
 * see the documentation for spatch.
 *)
type token_mutable = {
  token : token_origin;
  (* for spatch *)
  mutable transfo : transformation;
}

and transformation =
  | NoTransfo
  | Remove
  | AddBefore of add
  | AddAfter of add
  | Replace of add
  | AddArgsBefore of string list

and add = AddStr of string | AddNewlineAndIdent

(* Shortcut.
 * Technically speaking this is not a token, because we do not have
 * the kind of the token (e.g., PLUS | IDENT | IF | ...).
 * It's just a lexeme, but the word lexeme is not as known as token.
 *)
type t = token_mutable [@@deriving eq]

(* deprecated *)
type info_ = t

(* for ppx_deriving *)
val pp_full_token_info : bool ref
val pp : Format.formatter -> t -> unit
val pp_token_location : Format.formatter -> token_location -> unit
val equal_token_location : token_location -> token_location -> bool
val show_token_location : token_location -> string

(* mostly for the fuzzy AST builder *)
type token_kind =
  | LPar
  | RPar
  | LBrace
  | RBrace
  | LBracket
  | RBracket
  | LAngle
  | RAngle
  | Esthet of esthet
  | Eof
  | Other

and esthet = Comment | Newline | Space

(*****************************************************************************)
(* Errors during parsing *)
(*****************************************************************************)

(* TODO? move to Error_code.mli instead *)

(* note that those exceptions can be converted in Error_code.error with
 * Error_code.try_with_exn_to_error()
 *)
(* see also Parsing.Parse_error and Failure "empty token" raised by Lexing *)
exception Lexical_error of string * t

(* better than Parsing.Parse_error, which does not have location information *)
exception Parsing_error of t

(* when convert from CST to AST *)
exception Ast_builder_error of string * t

(* other stuff *)
exception Other_error of string * t
exception NoTokenLocation of string

val lexical_error : string -> Lexing.lexbuf -> unit

(*
   Register printers for the exceptions defined in this module.

   This makes 'Printexc.to_string' print the exceptions in a more complete
   fashion than the default printer, which only prints ints and strings
   and doesn't descend any deeper.
*)
val register_exception_printer : unit -> unit

(*****************************************************************************)
(* Info accessors and builders *)
(*****************************************************************************)

val tokinfo : Lexing.lexbuf -> t
val mk_info_of_loc : token_location -> t

(* Fake tokens: safe vs unsafe
 * ---------------------------
 * "Safe" fake tokens require an existing location to attach to, and so
 * token_location_of_info will work on these fake tokens. "Unsafe" fake tokens
 * do not carry any location info, so calling token_location_of_info on these
 * will raise a NoTokenLocation exception.
 *
 * Always prefer "safe" functions (no "unsafe_" prefix), which only introduce
 * "safe" fake tokens. The unsafe_* functions introduce "unsafe" fake tokens,
 * please use them only as a last resort. *)

val fake_token_location : token_location

(* NOTE: These functions introduce unsafe fake tokens, prefer safe functions
 * below, use these only as a last resort! *)
val unsafe_fake_info : string -> t
val unsafe_fake_bracket : 'a -> t * 'a * t
val unsafe_sc : t
val fake_info_loc : token_location -> string -> t
val fake_info : t -> string -> t
val abstract_info : t
val fake_bracket_loc : token_location -> 'a -> t * 'a * t
val fake_bracket : t -> 'a -> t * 'a * t
val unbracket : t * 'a * t -> 'a
val sc_loc : token_location -> t
val sc : t -> t
val is_fake : t -> bool
val first_loc_of_file : Common.filename -> token_location

(* Extract the lexeme (token) as a string *)
val str_of_info : t -> string

(* Extract position information *)
val line_of_info : t -> int
val col_of_info : t -> int
val pos_of_info : t -> int
val file_of_info : t -> Common.filename

(* Format the location file/line/column into a string *)
val string_of_info : t -> string
val is_origintok : t -> bool
val token_location_of_info : t -> (token_location, string) result

(* @raise NoTokenLocation if given an unsafe fake token (without location info) *)
val unsafe_token_location_of_info : t -> token_location
val get_original_token_location : token_origin -> token_location
val compare_pos : t -> t -> int
val min_max_ii_by_pos : t list -> t * t

(* TODO? could also be in Lexer helpers section *)
(* can deprecate? *)
val tokinfo_str_pos : string -> int -> t
val rewrap_str : string -> t -> t
val tok_add_s : string -> t -> t

(* used mainly by tree-sitter based parsers in semgrep *)
val combine_infos : t -> t list -> t

(* this function assumes the full content of the token is on the same
 * line, otherwise the line/col of the result might be wrong *)
val split_info_at_pos : int -> t -> t * t

(*****************************************************************************)
(* Parsing stats *)
(*****************************************************************************)
(* now in Parsing_stat.ml *)

(*****************************************************************************)
(* Lexer helpers *)
(*****************************************************************************)
(* now in Parsing_helpers.ml *)
