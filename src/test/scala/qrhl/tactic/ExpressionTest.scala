package qrhl.tactic

import org.scalatest.FunSuite
import qrhl.isabelle.Isabelle
import qrhl.logic.Expression
import qrhl.toplevel.ToplevelTest

class ExpressionTest extends FunSuite {
  test("encodeAsExpression") {
    val tl = ToplevelTest.makeToplevel()
    tl.execCmd("classical var x : int")
    val state = tl.state
    val e = state.parseExpression(Isabelle.predicateT,"Cla[ x=(1::int) ]")
    val t = e.encodeAsExpression(tl.state.isabelle)
    println(e)
    println(t)
    assert(state.isabelle.checkType(t) == Isabelle.expressionT(Isabelle.predicateT))
  }

  test("encodeAsExpression roundtrip") {
    val tl = ToplevelTest.makeToplevel()
    tl.execCmd("classical var x : int")
    val state = tl.state
    val e = state.parseExpression(Isabelle.predicateT,"Cla[ x=(1::int) ]")
    println(e)
    val t = e.encodeAsExpression(tl.state.isabelle)
    println(Isabelle.pretty(t))
    val e2 = Expression.decodeFromExpression(tl.state.isabelle, t)
    println(e2)

    assert(e.isabelleTerm==e2.isabelleTerm)
    assert(e.typ==e2.typ)
    assert(e==e2)

  }

  test("encodeAsExpression roundtrip 2") {
    val tl = ToplevelTest.makeToplevel()
    tl.execCmd("classical var x : int")
    val state = tl.state
    val e = state.parseExpression(Isabelle.predicateT,"Cla[ x1=x2 ]")
    println(e)
    val t = e.encodeAsExpression(tl.state.isabelle)
    println(Isabelle.pretty(t))
    val e2 = Expression.decodeFromExpression(tl.state.isabelle, t)
    println(e2)

    assert(e.isabelleTerm==e2.isabelleTerm)
    assert(e.typ==e2.typ)
    assert(e==e2)

  }

  test("encodeAsExpression roundtrip 3") {
    val tl = ToplevelTest.makeToplevel()
    tl.execCmd("classical var x : int")
    tl.execCmd("classical var c : int")
    val state = tl.state
    val e = state.parseExpression(Isabelle.predicateT,"Cla[ x1=x2 ∧ c1=c2 ]")
    println(e)
    val t = e.encodeAsExpression(tl.state.isabelle)
    println(Isabelle.pretty(t))
    val e2 = Expression.decodeFromExpression(tl.state.isabelle, t)
    println(e2)

    assert(e.isabelleTerm==e2.isabelleTerm)
    assert(e.typ==e2.typ)
    assert(e==e2)

  }
}
