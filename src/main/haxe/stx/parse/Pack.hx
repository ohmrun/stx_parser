package stx.parse;

import stx.parse.pack.parser.term.Not;
import stx.parse.pack.parser.term.Head;
import stx.parse.pack.parser.term.LAnon;
import stx.parse.pack.parser.term.Regex;
import stx.parse.pack.parser.term.Or;
import stx.parse.pack.parser.term.Identifier;

#if(test==stx_parse)
typedef Test                  = stx.parse.test.Test;
#end
typedef LiftArrayReader       = stx.parse.lift.LiftArrayReader;
typedef LiftStringReader      = stx.parse.lift.LiftStringReader;
typedef LiftLinkedListReader  = stx.parse.lift.LiftLinkedListReader;


typedef EnumerableApi<C,T>    = stx.parse.pack.Enumerable.EnumerableApi<C,T>;
typedef Enumerable<C,T>       = stx.parse.pack.Enumerable<C,T>;

typedef ParseSuccess<P,T>     = stx.parse.pack.ParseSuccess<P,T>;

typedef ParseErrorInfo        = stx.parse.pack.ParseError.ParseErrorInfo;
typedef ParseError            = stx.parse.pack.ParseError;
typedef ParseFailure<P>       = stx.parse.pack.ParseFailure<P>;

typedef ParseResult<P,T>      = stx.parse.pack.ParseResult<P,T>;
typedef ParseResultLift       = stx.parse.pack.ParseResult.ParseResultLift;

typedef RestWithDef<P,T>      = stx.parse.pack.RestWith.RestWithDef<P,T>;
typedef RestWith<P,T>         = stx.parse.pack.RestWith<P,T>;

typedef Head                  = stx.parse.pack.Head;
typedef Input<P>              = stx.parse.pack.Input<P>;
typedef LR                    = stx.parse.pack.LR;
typedef LRLift                = stx.parse.pack.LR.LRLift;

typedef Memo                  = stx.parse.pack.Memo;
typedef MemoEntry             = stx.parse.pack.Memo.MemoEntry;
typedef MemoKey               = stx.parse.pack.Memo.MemoKey;

typedef ParserApi<P,R>        = stx.parse.pack.Parser.ParserApi<P,R>;
typedef Parser<P,R>           = stx.parse.pack.Parser<P,R>;
typedef ParserLift            = stx.parse.pack.Parser.ParserLift;

typedef ParseSystemFailure    = stx.parse.pack.ParseSystemFailure;

//typedef Parserer<I,O>					= stx.arrowlet.term.Parserer<I,O>;

class Pack{

}
class Parse{
	static public function head<I,O>(fn:I->Option<Couple<O,Option<I>>>):Parser<I,O>{
		return new stx.parse.pack.parser.term.Head(fn).asParser();
	}
  static public function anything<I>():Parser<I,I>{
		return Parser.SyncAnon(
			(input:Input<I>)->{
			return if(input.is_end()){
				input.fail('EOF');
			}else{
				input.head().fold(
					v 	-> input.tail().ok(v),
					() 	-> input.tail().nil()
				);
			}
		}).asParser();
	}
	@:noUsing static public function range(min:Int, max:Int):String->Bool{
		return function(s:String):Bool {
			var x = StringTools.fastCodeAt(s,0);
			return (x >= min) && (x <= max);
		}
	}
	@:noUsing static public function mergeString(a:String,b:String){
		return a + b;
	}
	@:noUsing static public function mergeOption<T>(a:String, b:Option<String>){
		return switch (b){ case Some(v) : a += v ; default : ''; } return a; 
	}
	@:noUsing static public function mergeTAndArray<T>(a:T, b:Array<T>):Array<T>{
		return [a].concat(b);
	}
	@:noUsing static public function mergeOptionAndArray<T>(a:Option<T>, b:Array<T>):Array<T>{
		return a.fold(
			(t) -> [t].concat(b),
			() 	-> b
		);
	}
	static public var truth 			= 'true'.id().or('false'.id());
	static public var integer     = "[\\+\\-]?\\d+".regexParser();
  static public var float 			= "[\\+\\-]?\\d+(\\.\\d+)?".regexParser();
  
	static public function primitive():Parser<String,Primitive>{
		return truth.then((x) -> PBool(x == 'true' ? true : false))
		.or(float.then(Std.parseFloat.fn().then(PFloat)))
		.or(integer.then((str) -> PInt(__.option(Std.parseInt(str)).defv(0))))
		.or(literal.then(PString));
	}
		

	static public var lower				= range(97, 122).predicated();
	static public var upper				= range(65, 90).predicated();
	static public var alpha				= Parser._.or(upper,lower);
	static public var digit				= range(48, 57).predicated();
	static public var alphanum		= alpha.or(digit);
	static public var ascii				= range(0, 255).predicated();
	
	static public var valid				= alpha.or(digit).or('_'.id());
	
	static public var tab					= '	'.id();
	static public var space				= ' '.id();
	
	static public var nl					= '\n'.id();
	static public var gap					= [tab, space].ors();

	//static public var camel 			= lower.and_with(word, mergeString);
	static public var word				= lower.or(upper).one_many().token();//[a-z]*
	static public var quote				= '"'.id().or("'".id());
	static public var escape			= '\\'.id();
	static public var not_escaped	= '\\\\'.id();
	
	static public var x 					= not_escaped.not()._and(escape);
	static public var x_quote 		= x._and(quote);
	
 	static public var whitespace	= range(0, 33).predicated();
	
	static public var literal 		= new stx.parse.term.Literal().asParser();
	
	static public function spaced( p : Parser<String,String> ) {
		return p.and_(gap.many());
	}
	static public function returned(p : Parser<String,String>) {
		return p.and_(whitespace.many());
	}
	// static public function until<I>(p:Parser<I,I>):Parser<I,Array<I>>{
	// 	var prs = function rec(ipt:Input<I>,memo:Array<I>){ 
	// 		return switch(p.parse(ipt)){
	// 			case Success(success) 				  : ipt.ok(Some(memo));
	// 			case Failure(failure)           : anything().and_then(
	// 				(x:I) -> Parser.Anon(rec.bind(_,memo.snoc(x))).asParser()
	// 			).parse(ipt);
	// 		}
	// 	}
	// 	return Parser.Anon(prs.bind(_,[])).asParser();
	// }
	@:noUsing static public function eq<I>(v:I):Parser<I,I>{
		return Parser.SyncAnon((input:Input<I>) -> {
			return v == input.head() ? input.head().fold((v) -> input.tail().ok(v),() -> input.tail().nil()) : input.fail('no $v found',false);
		},'eq').asParser();
	}
	static public function eof<P,R>():Parser<P,R>{
    return new Parser(Parser.SyncAnon(ParserLift.eof,'eof'));
	}
	static public function any<I>():Parser<I,I>{
		return Parse.anything();
	}

  /**
	 * Takes a predicate function for an item of Input and returns it's parser.
   */
   static public function predicated<I>(p:I->Bool) : Parser<I,I> {
		return Parser.SyncAnon(function(input:Input<I>) {
			var res = input.head().map(p).defv(false);
			//trace(x.offset + ":z" + x.content.at(x.offset)  + " " + Std.string(res));
			return
				if ( res && !input.is_end() ) {
          input.drop(1).ok(input.take(1));
				}else {
					input.fail("predicate failed",false);
				}
		},'predicated').asParser();
  }
  static public function filter<I,O>(fn:I->Option<O>): Parser<I,O>{
    return Parser.SyncAnon(
      (i:Input<I>) -> 
        i.head().flat_map(fn).fold(
          (o) -> i.drop(1).ok(o),
          ()  -> i.fail("predicate failed")
        )
    );
  }
}
class LiftParse{
  static public function parse(wildcard:Wildcard){
    return new stx.parse.Module();
  }
  static public inline function ok<P,R>(rest:Input<P>,match:R):ParseResult<P,R>{
    return ParseSuccess.make(rest,Some(match));
	}
	static public inline function nil<P,R>(rest:Input<P>):ParseResult<P,R>{
    return ParseSuccess.make(rest,None);
  }
  static public inline function fail<P,R>(rest:Input<P>,message:String,fatal:Bool=false,?pos:Pos):ParseResult<P,R>{
    return ParseFailure.at_with(rest,message,fatal,pos);
  }
  static public function parsify(regex:hre.RegExp,ipt:Input<String>):hre.Match{
    //trace(ipt.content.data);
    var data : String = (cast ipt).content.data;
    if(data == null){
      data = "";
    }
    data = data.substr(ipt.offset);
    return regex.exec(data);
  }
  static public inline function identifier(str:String,?pos:Pos):Parser<String,String>{
    return new Identifier(str,pos).asParser();
  }
  static public inline function alts<I,O>(arr:Array<Parser<I,O>>){
    return arr.lfold1((next,memo:Parser<I,O>) -> new Or(memo,next).asParser());
  }
  static public inline function regex(s:String):Parser<String,String>{
    return new Regex(s).asParser();
  }
  static public inline function defer<I,O>(f:Void->Parser<I,O>):Parser<I,O>{
    return new LAnon(f).asParser();
  }
  static public function lookahead<I,O>(p:Parser<I,O>):Parser<I,O>{
		return Parser.TaggedAnon((input:Input<I>,cont:Terminal<ParseResult<I,O>,Noise>)->
			Arrowlet.Then(
				p,
				Arrowlet.Sync(
					(res:ParseResult<I,O>) -> res.fold(
						(ok) 	-> input.nil(),
						(no)	-> ParseResult.failure(no)
					) 
				)
			).applyII(input,cont)
		,'lookahead: ${p.tag}').asParser();
	}
	static public function token(p:Parser<String,Array<String>>):Parser<String,String>{
		return p.then(
			(arr) -> __.option(arr).defv([]).join("")
		);
	}
  /**
	 * Returns true if the parser fails and vice versa.
	 */
	static public function not<I,O>(p:Parser<I,O>):Parser<I,O>{
		return new Not(p).asParser();
	}

  public static function id(s:String) {
		return identifier(s);
	}
	static public function inspector<I,O>(__:Wildcard,?pre:Input<I>->Void,?post:ParseResult<I,O>->Void,?pos:Pos):Parser<I,O>->Parser<I,O>{
		return (prs:Parser<I,O>) -> {
			return prs.inspect(
				__.option(pre).defv(
					(v) -> {
						if(v.tag!=null){
							__.log()('${v.tag} "${v.head()}"',pos);
						}
					}
				),
				__.option(post).defv(
					(v) -> {
						__.log()(v.toString(),pos);
					}
				)
			);
		};
	}
	static public inline function tagged<I,T>(p : Parser<I,T>, tag : String):Parser<I,T> {
    p.tag = Some(tag);
    return Parser._.with_error_tag(p, tag);
	}
	@:noUsing static public inline function succeed<I,O>(v:O):Parser<I,O>{
    return new stx.parse.pack.parser.term.Succeed(v).asParser();
  }
}