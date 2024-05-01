import gleam/io
import gleeunit
import gleeunit/should
import shiny_parse as sp

pub fn main() {
  gleeunit.main()
}

pub fn item_test() {
  "abc"
  |> sp.item()
  |> should.equal([#("a", "bc")])

  ""
  |> sp.item()
  |> should.equal([])
}

pub fn return_test() {
  "def"
  |> sp.return("abc")
  |> should.equal([#("abc", "def")])

  ""
  |> sp.return("abc")
  |> should.equal([#("abc", "")])
}

pub fn map_test() {
  let mapped = {
    use a <- sp.map(sp.item())
    case a {
      "a" -> 1
      _ -> 99
    }
  }

  "abc"
  |> mapped
  |> should.equal([#(1, "bc")])

  "bc"
  |> mapped
  |> should.equal([#(99, "c")])

  ""
  |> mapped
  |> should.equal([])
}

pub fn int_test() {
  "1"
  |> sp.int()
  |> should.equal([#(1, "")])

  "12"
  |> sp.int()
  |> should.equal([#(12, "")])
}

pub fn digit_test() {
  "1"
  |> sp.digit()
  |> should.equal([#(1, "")])

  "12"
  |> sp.digit()
  |> should.equal([#(1, "2")])
}

pub fn space_test() {
  " abc"
  |> sp.space()
  |> should.equal([#(" ", "abc")])

  "\tabc"
  |> sp.space()
  |> should.equal([#("\t", "abc")])

  "\nabc"
  |> sp.space()
  |> should.equal([#("\n", "abc")])

  "\fabc"
  |> sp.space()
  |> should.equal([#("\f", "abc")])

  // "\rabc"
  // |> sp.space()
  // |> should.equal([#("\r", "abc")])

  " \t\n\fabc"
  |> sp.space()
  |> should.equal([#(" \t\n\f", "abc")])
}

pub fn sep_by_test() {
  "1,2"
  |> sp.sep_by(sp.digit(), sp.string(","))
  |> should.equal([#([1, 2], "")])

  ""
  |> sp.sep_by(sp.digit(), sp.string(","))
  |> should.equal([#([], "")])

  ",2"
  |> sp.sep_by(sp.digit(), sp.string(","))
  |> should.equal([#([], ",2")])

  "1,,2"
  |> sp.sep_by(sp.digit(), sp.string(","))
  |> should.equal([#([1], ",,2")])
}

pub fn sep_by1_test() {
  "1,2"
  |> sp.sep_by1(sp.digit(), sp.string(","))
  |> should.equal([#([1, 2], "")])

  ""
  |> sp.sep_by1(sp.digit(), sp.string(","))
  |> should.equal([])

  ",2"
  |> sp.sep_by1(sp.digit(), sp.string(","))
  |> should.equal([])

  "1,,2"
  |> sp.sep_by1(sp.digit(), sp.string(","))
  |> should.equal([#([1], ",,2")])
}

pub fn any_char_test() {
  "abc"
  |> sp.any_char()
  |> should.equal([#("a", "bc")])

  "a bc"
  |> sp.any_char()
  |> should.equal([#("a", " bc")])

  "1bc"
  |> sp.any_char()
  |> should.equal([])
}

pub fn any_char_string_test() {
  "abc"
  |> sp.any_char_string()
  |> should.equal([#("abc", "")])

  "a bc"
  |> sp.any_char_string()
  |> should.equal([#("a", " bc")])

  "1bc"
  |> sp.any_char_string()
  |> should.equal([])
}

pub fn chain_l1_test() {
  "a+b"
  |> sp.chain_l1(
    sp.or(sp.char("a"), sp.char("b")),
    sp.char("+")
      |> sp.map(fn(_) { fn(a, b) { a <> b } }),
  )
  |> should.equal([#("ab", "")])
}
