(*                                                                          *)
(* (c) 2004, Anastasia Gornostaeva. <ermine@ermine.pp.ru>                   *)
(*                                                                          *)

open Xml
open Common
open Http_client
open Pcre

(* http://weather.noaa.gov/pub/data/observations/metar/decoded/ULLI.TXT *)

let split_lines lines =
   let map = List.find_all 
		(function line ->
		    if Str.string_match (Str.regexp ".+: .+") line 0 then
		       true else false)
		lines in
      List.map (function m ->
		   let m1 = Str.bounded_split (Str.regexp ": ") m 2 in
		      (List.hd m1, List.nth m1 1)
	       ) map

let get_weather code =
   let content = 
      Http_client.request "weather.noaa.gov"
	 (Get ("/pub/data/observations/metar/decoded/" ^ code ^ ".TXT"))
	 [] in
      
   let lines = Str.split (Str.regexp "\n") content in

   let line1 = List.hd lines in
   let place = 
      if Str.string_match (Str.regexp "\\(.+\\) (....).+") line1 0 then
	 Str.matched_group 1 line1 else line1 in
   let line2 = List.nth lines 1 in
   let time = 
      if Str.string_match (Str.regexp ".+/ \\(.+\\)$") line2 0 then
	 Str.matched_group 1 line2 else line2 in
   let map = split_lines lines in
   let weather = 
      try List.assoc "Weather" map with _ ->
	 List.assoc "Sky conditions" map
   in
   let f, c = 
      let z = List.assoc "Temperature" map in
	 if Str.string_match (Str.regexp "\\(.+\\) F (\\(.+\\) C)") z 0 then
	    Str.matched_group 1 z, Str.matched_group 2 z
	 else
	    "", "" in
   let hum = List.assoc "Relative Humidity" map in
   let wind = 
      try
	 let w = List.assoc "Wind" map in
	    if Str.string_match (Str.regexp "\\(.+\\):0") w 0 then
	       Str.matched_group 1 w
	    else w
      with _ -> "n/a"
   in
   let vis =
      try
	 let v = List.assoc "Visibility" map in
	    if Str.string_match (Str.regexp "\\(.+\\):0") v 0 then
	       Str.matched_group 1 v
	    else v
      with _ -> "n/a"
   in

      Printf.sprintf 
	 "%s - %s / %s, %sC/%sF, humidity %s wind: %s visibility: %s"
	 place time weather c f hum wind vis

let r = Pcre.regexp "[a-zA-Z]{4}"

let weather text xml out =
   if pmatch ~rex:r text then
      let proc () =
	 let response = 
	    try get_weather (String.uppercase text) with _ -> 
	       "Undefined error" in
	    out (make_msg xml response)
      in
	 ignore (Thread.create proc ())
   else
      out (make_msg xml "гы! Попробуй еще разок, сина!")

let _ =
   Hooks.register_handle (Hooks.Command ("wz", weather))
