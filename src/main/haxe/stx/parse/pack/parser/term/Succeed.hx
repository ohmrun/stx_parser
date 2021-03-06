package stx.parse.pack.parser.term;

class Succeed<P,R> extends Sync<P,R>{
  var value : R;
  public function new(value:R,?id){
    super(id);
    this.value = value;
  }
  @:noUsing static public function pure<P,R>(r:R):Parser<P,R>{
    return Parser.Succeed(r).asParser();
  }
  override function do_parse(ipt:Input<P>):ParseResult<P,R>{
    return ipt.ok(this.value);
  }
}