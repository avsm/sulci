%{
open Printf

let var_table = Hashtbl.create 16

let fact x =
   if x > 174.0 then failwith "Многовато... :("
   else if x -. floor x <> 0.0 then 
      failwith "Не, я не умею вычислять факториал нецелых чисел :("
   else
      let rec f y acc =
	 if y <= 0.0 then acc
	 else f (y-. 1.) (y *. acc)
      in
	 f x 1.

%}

%token <float> NUM
%token LPAREN RPAREN EQ FACT
%token PLUS MINUS MUL DIVIDE CARET NEG
%token MAX_FLOAT PI
%token EOL
%token <string> VAR
%token <float -> float> FUNC

%left PLUS MINUS
%left MUL DIVIDE
%left NEG
%right CARET

%start line
%type <string> line

%% 
line:
   | expr EOL              { sprintf "%.10g" $1 }
;
expr:
   | NUM                      { $1 }
   | VAR                      { try Hashtbl.find var_table $1
				with Not_found -> 0.0 }
   | VAR EQ expr              { Hashtbl.replace var_table $1 $3;
				$3 }
   | FUNC LPAREN expr RPAREN  { $1 $3 }
   | expr PLUS expr           { $1 +. $3 }
   | expr MINUS expr          { $1 -. $3 }
   | expr MUL expr            { $1 *. $3 }
   | expr DIVIDE expr         { if $3 <> 0.0 then $1 /. $3
				else failwith "Делим на нолик, да? :/" }
   | expr CARET expr          { $1 ** $3 }
   | MINUS expr %prec NEG     { -. $2 }
   | MAX_FLOAT             { max_float }
   | PI                    { 4. *. (atan (1./.2.) +. atan (1./.3.)) }
   | LPAREN expr RPAREN    { $2 }
   | expr FACT             { fact $1 }
;
%%
