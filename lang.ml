(*                                                                          *)
(* (c) 2004, Anastasia Gornostaeva. <ermine@ermine.pp.ru>                   *)
(*                                                                          *)

open Common
open Xml
open Hooks

let ext = ".htbl"
let deflang = "ru"

module LangMap = Map.Make(Id)
let langmsgs =  ref (LangMap.empty:(string, string) Hashtbl.t LangMap.t)

let _ =
   let dir = 
      try trim (get_attr_s Config.config ~path:["lang"] "dir")
      with Not_found -> "" in
   let htbl = Marshal.from_channel 
      (open_in_bin (Filename.concat dir (deflang ^ ext))) in
      langmsgs := LangMap.add deflang htbl !langmsgs

let find_htbl lang =
   try
      LangMap.find lang !langmsgs
   with Not_found ->
      try
	 let dir = 
	    try trim (get_attr_s Config.config ~path:["lang"] "dir")
	    with Not_found -> "" in
	 let htbl =  Marshal.from_channel 
	    (open_in_bin (Filename.concat dir (lang ^ ext))) in
	    langmsgs := LangMap.add lang htbl !langmsgs;
	    htbl
      with _ ->
	 LangMap.find deflang !langmsgs

let process str args =
   let rec cycle part arges =
      if arges = [] then part
      else
	 try
	    let mark = String.index part '%' in
	       if part.[mark+1] = 's' then
		  (String.sub part 0 mark) ^ (List.hd arges) ^ 
		     cycle (string_after part (mark+2)) (List.tl arges)
	       else
		  String.sub part 0 (mark+2) ^
		     (cycle (string_after part (mark+2)) arges)
	 with Not_found ->
	    part
      in
	 cycle str args

let get_lang xml =
   match safe_get_attr_s xml "type" with
      | "groupchat" ->
	   let room = Xmpp.get_bare_jid (get_attr_s xml "from") in
	      (try
		  let room_env = GroupchatMap.find room !groupchats in
		     room_env.lang
	       with Not_found ->
		  deflang)
      | _ ->
	   try get_attr_s xml "xml:lang" with Not_found -> deflang

let get_msg ?xml ?(lang="") msgid args =
   let lang = 
      match xml with
	 | Some x -> get_lang x
	 | None -> if lang = "" then deflang else lang
   in
   let htbl = find_htbl lang in
   let str =  try Hashtbl.find htbl msgid with _ ->
      try
	 let hashtbl = LangMap.find deflang !langmsgs in
	    Hashtbl.find hashtbl msgid
      with Not_found ->
	 Printf.printf "lang not found: [%s]\n" msgid;
	 flush Pervasives.stdout;
	 "[not found in lang pack"
   in
      process str args

let update lang =
   try
      let dir = 
	 try trim (get_attr_s Config.config ~path:["lang"] "dir")
	 with Not_found -> "" in
      let htbl = Marshal.from_channel 
	 (open_in_bin (Filename.concat dir (lang ^ ext))) in
	 langmsgs := LangMap.add deflang htbl !langmsgs;
	 "Updated"
   with exn ->
      Printexc.to_string exn
