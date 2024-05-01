//// Simple Parser Combinator

import gleam/int
import gleam/list
import gleam/string

/// A Parser is a function that take an input string an returns a tuple of a parser result and the remaining string.
/// To represent a failed parse and to add the possibility of multiple results the result tuples is wrapped in a list.
/// A parser is considered failed when the resulting list is empty.
pub type Parser(a) =
  fn(String) -> List(#(a, String))

pub type Char =
  String

/// Parses the first character of the input.
pub fn item() -> Parser(Char) {
  fn(str) {
    case string.first(str) {
      Error(_err) -> []
      Ok(c) -> [#(c, string.drop_left(str, up_to: 1))]
    }
  }
}

/// List the given input into a parser, in other words build a parser that will return the given value.
pub fn return(a: a) -> Parser(a) {
  fn(cs) { [#(a, cs)] }
}

/// Applies `f` with the results of parser `p`, effectively transforming the Parser.
pub fn map(p: Parser(a), f: fn(a) -> b) -> Parser(b) {
  fn(str) {
    let res = p(str)
    use res <- list.map(res)
    let #(a, rest) = res
    #(f(a), rest)
  }
}

/// Applies `f` to the result of parser `p`.
pub fn bind(p: Parser(a), f: fn(a) -> Parser(b)) -> Parser(b) {
  fn(str) {
    let res = p(str)
    use res <- list.flat_map(res)
    let #(a, rest) = res
    f(a)(rest)
  }
}

/// Parser that parses nothing.
pub fn zero() -> Parser(a) {
  fn(_str) { [] }
}

/// Runs both parser and appends results.
fn both(p1: Parser(a), p2: Parser(a)) -> Parser(a) {
  fn(str) {
    let p = p1(str)
    let q = p2(str)
    list.append(p, q)
  }
}

/// Returns the result of the first marching parser, effectively behaving like an OR-operator for Parsers.
pub fn or(p1: Parser(a), p2: Parser(a)) -> Parser(a) {
  fn(str) {
    case both(p1, p2)(str) {
      [] -> []
      [fst, ..] -> [fst]
    }
  }
}

/// Succeeds the parser if the parser input satisfies the given predicate.
pub fn satisfies(pred: fn(Char) -> Bool) -> Parser(Char) {
  use c <- bind(item())
  case pred(c) {
    True -> return(c)
    False -> zero()
  }
}

/// As gleam has char type this is an alias for `string`.
pub fn char(c: Char) -> Parser(Char) {
  string(c)
}

/// Parser succeeds when the input matches the given string.
pub fn string(str: String) -> Parser(String) {
  satisfies(fn(i) { i == str })
}

pub fn any_char() -> Parser(Char) {
  use c <- bind(item())
  case c {
    "a"
    | "b"
    | "c"
    | "d"
    | "e"
    | "f"
    | "g"
    | "h"
    | "i"
    | "j"
    | "k"
    | "l"
    | "m"
    | "n"
    | "o"
    | "p"
    | "q"
    | "r"
    | "s"
    | "t"
    | "u"
    | "v"
    | "w"
    | "x"
    | "y"
    | "z" -> return(c)
    "A"
    | "B"
    | "C"
    | "D"
    | "E"
    | "F"
    | "G"
    | "H"
    | "I"
    | "J"
    | "K"
    | "L"
    | "M"
    | "N"
    | "O"
    | "P"
    | "Q"
    | "R"
    | "S"
    | "T"
    | "U"
    | "V"
    | "W"
    | "X"
    | "Y"
    | "Z" -> return(c)
    _ -> zero()
  }
}

pub fn any_char_string() -> Parser(String) {
  use cs <- bind(many1(any_char()))
  string.join(cs, "")
  |> return
}

/// Returns multiples consecutive matches of parser `p`.
/// Requires 1 or more matches of `p`.
pub fn many1(p: Parser(a)) -> Parser(List(a)) {
  use a <- bind(p)
  use a_s <- bind(many(p))
  return([a, ..a_s])
}

/// Returns multiples consecutive matches of parser `p`.
/// Requires 0 or more matches of `p`.
pub fn many(p: Parser(a)) -> Parser(List(a)) {
  or(many1(p), return([]))
}

/// Return matches of parser `p` interspersed by matches of parser `sep`.
/// Requires 1 or more matches of `p`.
pub fn sep_by1(p: Parser(a), sep: Parser(b)) -> Parser(List(a)) {
  use a <- bind(p)
  let sep = bind(sep, fn(_) { p })
  use a_s <- bind(many(sep))
  return([a, ..a_s])
}

/// Return matches of parser `p` interspersed by matches of parser `sep`.
/// Requires 0 or more matches of `p`.
pub fn sep_by(p: Parser(a), sep: Parser(b)) -> Parser(List(a)) {
  or(sep_by1(p, sep), return([]))
}

/// Helper function for chain_l1.
fn rest_chain_l1(p: Parser(a), op: Parser(fn(a, a) -> a), a: a) -> Parser(a) {
  let left = {
    use f <- bind(op)
    use b <- bind(p)
    rest_chain_l1(p, op, f(a, b))
  }
  or(left, return(a))
}

/// Repeats application of parser `p` separated by parser `op`.
/// `op` is assumed to be a left associative operator.
/// Effectively `op` is used to combine the results of `p`.
/// Matches 1 or more of .
pub fn chain_l1(p: Parser(a), op: Parser(fn(a, a) -> a)) {
  use a <- bind(p)
  rest_chain_l1(p, op, a)
}

/// Like `chain_l1`.
/// Matches 0 or more.
pub fn chain_l(p: Parser(a), op: Parser(fn(a, a) -> a), a: a) -> Parser(a) {
  or(chain_l1(p, op), return(a))
}

fn is_whitespace(c: String) -> Bool {
  case c {
    " " | "\t" | "\n" | "\f" -> True
    "\r" -> todo as "fix: turns rest string into code points"
    _ -> False
  }
}

/// Parser matching white space characters
pub fn space() -> Parser(String) {
  use strs <- bind(many(satisfies(is_whitespace)))
  let str = string.join(strs, "")
  return(str)
}

/// Matches both parser but only keep the result of the left parser.
pub fn keep_left(pl: Parser(a), pr: Parser(b)) -> Parser(a) {
  use l <- bind(pl)
  use _ <- bind(pr)
  return(l)
}

/// Matches both parser but only keep the result of the right parser.
pub fn keep_right(pl: Parser(a), pr: Parser(b)) -> Parser(b) {
  use _ <- bind(pl)
  use r <- bind(pr)
  return(r)
}

/// Matches a single digit
pub fn digit() -> Parser(Int) {
  use c <- bind(item())
  case int.base_parse(c, 10) {
    Ok(r) -> return(r)
    Error(_) -> zero()
  }
}

/// Matches integers
pub fn int() -> Parser(Int) {
  let int_p = {
    use c <- bind(item())
    case c {
      "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" -> return(c)
      _ -> zero()
    }
  }
  use str <- bind(many1(int_p))
  let str = string.join(str, "")
  case int.base_parse(str, 10) {
    Ok(r) -> return(r)
    Error(_) -> zero()
  }
}

pub fn token(p: Parser(a)) -> Parser(a) {
  use a <- bind(p)
  use _ <- bind(space())
  return(a)
}

pub fn symbol(s: String) -> Parser(String) {
  token(string(s))
}

pub fn apply(p: Parser(a)) -> Parser(a) {
  use _ <- bind(space())
  p
}
