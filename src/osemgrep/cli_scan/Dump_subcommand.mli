(* There is currently no 'semgrep dump' subcommand. Dumps are run via
 * 'semgrep scan --dump-ast ...' but internally it's quite similar to
 * a subcommand.
 *)

type conf = { target : target_kind; json : bool }

and target_kind =
  | Pattern of string * Lang.t
  | File of Common.filename * Lang.t
  | Config of Semgrep_dashdash_config.config_str
[@@deriving show]

val run : conf -> Exit_code.t
