package qrhl.toplevel

import java.io.{BufferedReader, StringReader}

import info.hupel.isabelle.Operation.ProverException
import org.jline.reader.LineReaderBuilder
import org.jline.terminal.TerminalBuilder
import qrhl.isabelle.Isabelle
import qrhl.{State, UserException}

import scala.io.StdIn
import scala.util.matching.Regex


class Toplevel {
  private val commandEnd: Regex = """\.\s*$""".r

  /** Reads one command from the input. The last line of the command must end with ".".
    * @param readLine command for reading lines from the input, invoked with the prompt to show
    * @return the command (without the "."), null on EOF
    * */
  private def readCommand(readLine : String => String): String = {
    val str = new StringBuilder()
    var first = true
    while (true) {
      //      val line = StdIn.readLine("qrhl> ")
      val line =
        try {
//          lineReader.readLine(if (first) "\nqrhl> " else "\n...> ")
          readLine(if (first) "\nqrhl> " else "\n...> ")
        } catch {
          case _: org.jline.reader.EndOfFileException =>
            null;
          case _: org.jline.reader.UserInterruptException =>
            println("Aborted.")
            sys.exit(1)
        }

      if (line==null) {
        val str2 = str.toString()
        if (str2.trim == "") return null
        return str2
      }

      str.append(line).append('\n')

      if (commandEnd.findFirstIn(line).isDefined)
        return commandEnd.replaceAllIn(str.toString, "")
      first = false
    }

    "" // unreachable
  }

  private def parseCommand(state:State, str:String): Command = {
    implicit val parserContext = state.parserContext
    Parser.parseAll(Parser.command,str) match {
      case Parser.Success(cmd2,_) => cmd2
      case res @ Parser.NoSuccess(msg, _) =>
        throw UserException(msg)
    }
  }

  private var states : List[State] = List(State.empty)

  /** Executes a single command. */
  def execCmd(cmd:Command) : Unit = {
    cmd match {
      case UndoCommand(n) =>
        assert(n < states.length)
        states = states.drop(n)
        println(states.head)
      case _ =>
        val newState = cmd.act(states.head)
        println(newState)
        states = newState :: states
    }
  }

  /** Returns the current state of the toplevel */
  def state: State = states.head

  /** Executes a single command. The command must be given without a final ".". */
  def execCmd(cmd:String) : Unit = {
    val cmd2 = parseCommand(states.head, cmd)
    execCmd(cmd2)
  }

  /** Runs a sequence of commands. Each command must be delimited by "." at the end of a line. */
  def run(script: String): Unit = {
    val reader = new BufferedReader(new StringReader(script))
    def readLine(prompt:String) = {
      val line = reader.readLine()
      println("> "+line)
      line
    }
    run(readLine _)
  }

  /** Runs a sequence of commands. Each command must be delimited by "." at the end of a line.
    * @param readLine command for reading lines from the input, invoked with the prompt to show
    */
  def run(readLine : String => String): Unit = {
    while (true) {
        val cmdStr = readCommand(readLine)
        if (cmdStr==null) { println("EOF"); return; }
        execCmd(cmdStr)
    }
  }

  /** Runs a sequence of commands. Each command must be delimited by "." at the end of a line.
    * Errors (such as UserException's and assertions) are caught and printed as error messages,
    * and the commands producing the errors are ignored.
    * @param readLine command for reading lines from the input, invoked with the prompt to show
    */
  def runWithErrorHandler(readLine : String => String): Unit = {
    while (true) {
      try {
        val cmdStr = readCommand(readLine)
        if (cmdStr==null) { println("EOF"); return; }
        execCmd(cmdStr)
      } catch {
        case UserException(msg) =>
          println("[ERROR] "+msg)
        case e: ProverException =>
          val msg = Isabelle.symbolsToUnicode(e.fullMessage)
          println("[ERROR] (in Isabelle) "+msg)
        case e : AssertionError =>
          println("[ERROR]")
          e.printStackTrace()
      }
    }
  }
}

object Toplevel {
  /** Runs the interactive toplevel from the terminal (with interactive readline). */
  def runFromTerminal() : Toplevel = {
    val terminal = TerminalBuilder.terminal()
    val lineReader = LineReaderBuilder.builder().terminal(terminal).build()
    val toplevel = new Toplevel()
    toplevel.runWithErrorHandler(lineReader.readLine)
    toplevel
  }

  def main(args: Array[String]): Unit = {
    try
      runFromTerminal()
    catch {
      case e:Throwable => // we need to catch and print, otherwise the sys.exit below gobbles up the exception
        e.printStackTrace()
        sys.exit(1)
    } finally
      sys.exit(0) // otherwise the Isabelle process blocks termination
  }
}
