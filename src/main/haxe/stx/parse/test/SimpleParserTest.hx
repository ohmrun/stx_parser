package stx.parse.test;

import stx.parse.pack.parser.term.Identifier;

class SimpleParserTest extends haxe.unit.TestCase{
  public function testIdentifier(){
    var reader = "if".reader();
    var parser = new Identifier("if").asParser();
    var result = parser.forward(reader).fudge();
    this.assertEquals("if",result.value().defv(""));
  }
  public function testOr(){
    var reader = "if".reader();
    var parser = "id".id().or("if".id()).asParser();
    var result = parser.forward(reader).fudge();
    this.assertEquals("if",result.value().defv(""));
  }
  public function testOrs(){
    var reader = "if".reader();
    var parser = ["id".id(),"if".id()].ors().asParser();
    var result = parser.forward(reader).fudge();
    this.assertEquals("if",result.value().defv(""));
  }
  public function testMany(){
    var reader = "ifif".reader();
    var parser = "if".id().many().asParser();
    var result = parser.forward(reader).fudge();
    this.assertEquals("ifif",result.value().defv([]).join(""));
  }
  public function testOneMany(){
    var reader = "ifif".reader();
    var parser = "if".id().one_many().asParser();
    var result = parser.forward(reader).fudge();
    this.assertEquals("ifif",result.value().defv([]).join(""));
  }
  public function testAndThen(){
    var reader = "if".reader();
    var parser = 'if'.id().and_then(
      (_) -> Parser.Succeed('${_}fo')
    ).asParser();
    var result = parser.forward(reader).fudge();
    this.assertEquals("iffo",result.value().defv(""));
  }
  public function testThen(){
    var reader = "if".reader();
    var parser = 'if'.id().then(
      (_) -> '${_}fo'
    ).asParser();
    var result = parser.forward(reader).fudge();
    this.assertEquals("iffo",result.value().defv(""));
  }
  public function testRegex(){
    var reader = "ifY".reader();
    var parser = "^i[a-z][A-Z]".regex();
    var result = parser.forward(reader).fudge();
    this.assertEquals("ifY",result.value().defv(""));
  }
  public function testAnon(){
    var reader = "a".reader();
    var parser   = Parser.SyncAnon(
      (input) -> input.head().fold(
        v 	-> input.tail().ok(v),
        () 	-> input.tail().nil()
      )
    );
    var result = parser.forward(reader).fudge();
    this.assertEquals("a",result.value().defv(""));
  }
}