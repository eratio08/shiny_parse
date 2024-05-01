//// expr ::= expr addop term | term
//// term ::= term mulop factor | factor
//// factor ::= digit | ( expr )
//// digit ::= 0 | 1 | . . . | 9
//// addop ::= + | -
//// mulop ::= * | /

import gleeunit
import gleeunit/should
import shiny_parse.{type Parser, bind, chain_l1, int, or, return, symbol, token}

pub fn main() {
  gleeunit.main()
}

/// addop = do {symb "+"; return (+)} +++ do {symb "-"; return (-)}
fn addop() -> Parser(fn(Int, Int) -> Int) {
  let left = {
    use _ <- bind(symbol("+"))
    return(fn(l, r) { l + r })
  }

  let right = {
    use _ <- bind(symbol("-"))
    return(fn(l, r) { l - r })
  }

  or(left, right)
}

/// mulop = do {symb "*"; return (*)} +++ do {symb "/"; return (div)}
fn mulop() -> Parser(fn(Int, Int) -> Int) {
  let left = {
    use _ <- bind(symbol("*"))
    return(fn(l, r) { l * r })
  }

  let right = {
    use _ <- bind(symbol("/"))
    return(fn(l, r) { l / r })
  }

  or(left, right)
}

/// factor = digit +++ do {symb "("; n <- expr; symb ")"; return n}
fn factor() -> Parser(Int) {
  let left = token(int())
  let right = {
    use _ <- bind(symbol("("))
    use n <- bind(expr())
    use _ <- bind(symbol(")"))
    return(n)
  }
  or(left, right)
}

/// term = factor ‘chainl1‘ mulop
fn term() -> Parser(Int) {
  chain_l1(factor(), mulop())
}

/// expr = term ‘chainl1‘ addop
fn expr() -> Parser(Int) {
  chain_l1(term(), addop())
}

pub fn addop_test() {
  "+"
  |> addop()
  |> fn(res) {
    let assert [#(f, rest)] = res
    should.equal(f(1, 1), 2)
    should.equal(rest, "")
  }

  "-"
  |> addop()
  |> fn(res) {
    let assert [#(f, rest)] = res
    should.equal(f(1, 1), 0)
    should.equal(rest, "")
  }
}

pub fn multop_test() {
  "*"
  |> mulop()
  |> fn(res) {
    let assert [#(f, rest)] = res
    should.equal(f(1, 1), 1)
    should.equal(rest, "")
  }

  "/"
  |> mulop()
  |> fn(res) {
    let assert [#(f, rest)] = res
    should.equal(f(1, 1), 1)
    should.equal(rest, "")
  }
}

pub fn factor_test() {
  "1"
  |> factor()
  |> should.equal([#(1, "")])

  "12"
  |> factor()
  |> should.equal([#(12, "")])

  "(1)"
  |> factor()
  |> should.equal([#(1, "")])
}

pub fn arithmetic_test() {
  "1 + 2 * 3"
  |> expr()
  |> should.equal([#(7, "")])
}
