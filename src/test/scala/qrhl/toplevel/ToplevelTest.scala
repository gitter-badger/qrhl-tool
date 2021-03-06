package qrhl.toplevel

import java.nio.file.{Path, Paths}

import org.scalatest.funsuite.AnyFunSuite
import qrhl.UserException
import qrhl.isabellex.IsabelleX
import qrhl.toplevel.Toplevel.ReadLine

import scala.util.Random

class ToplevelTest extends AnyFunSuite {
  test("assign statement should throw UserException on undefined variable") {
    val toplevel = Toplevel.makeToplevelWithTheory()
    assertThrows[UserException] {
      toplevel.execCmd("program prog := { x <- (); }")
    }
  }

  test("name collision between program and variable should have proper error message") {
    val toplevel = Toplevel.makeToplevelWithTheory()
    toplevel.execCmd("classical var x : int")
    val exn = intercept[UserException] {
      toplevel.execCmd("program x := { skip; }") }
    assert(exn.getMessage.startsWith("Name x already used for a variable or program"))
  }
}

object ToplevelTest {
  def randomCommandString : String = "<fake> "+Random.nextLong
  //  val isabellePath = "auto"
  //  lazy val isabelle = new Isabelle(isabellePath)
  //  def makeToplevel(): Toplevel = Toplevel.makeToplevel()
//  object dummyReadLine extends ReadLine {
//    override def readline(prompt: String): String = ???
//    override def position: String = "<test case>"
//  }
}
