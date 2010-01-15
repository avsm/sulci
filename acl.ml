(*
 * (c) 2004-2010 Anastasia Gornostaeva. <ermine@ermine.pp.ru>
 *)

open JID
open Hooks
  
let acls : ((jid * string) list) ref = ref []

let check_access jid classname =
  if classname = "" then
    true
  else
    List.exists
      (fun (jid', name) ->
         (name = classname &&
             jid'.lnode = jid.lnode && jid'.ldomain = jid.ldomain)
        ) !acls

  
