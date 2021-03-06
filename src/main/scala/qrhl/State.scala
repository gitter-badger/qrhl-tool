package qrhl

import java.io.FileNotFoundException
import java.nio.file.attribute.FileTime
import java.nio.file.{Files, NoSuchFileException, Path, Paths}
import java.util

import org.log4s
import isabellex.{IsabelleX, RichTerm}
import qrhl.logic._
import qrhl.toplevel.{Command, Parser, ParserContext, Toplevel}
import de.unruh.isabelle.control
import control.{Isabelle, IsabelleException}

import scala.annotation.tailrec
import scala.collection.mutable.ListBuffer
import scala.util.control.Breaks
import qrhl.State.logger

import scala.collection.mutable
import hashedcomputation.Context.default
import hashedcomputation.Hashed
import org.apache.commons.codec.binary.Hex
import qrhl.isabellex.IsabelleX.globalIsabelle.show_oracles
import IsabelleX.{ContextX, globalIsabelle => GIsabelle}
import de.unruh.isabelle.mlvalue.MLValue.Converter
import GIsabelle.Ops
import de.unruh.isabelle.mlvalue.MLValue
import de.unruh.isabelle.pure.{Term, Thm, Typ}

import scala.concurrent.{ExecutionContext, Future}

// Implicits
import de.unruh.isabelle.mlvalue.Implicits._
import de.unruh.isabelle.pure.Implicits._
import qrhl.isabellex.MLValueConverters.Implicits._
import scala.concurrent.ExecutionContext.Implicits._
import GIsabelle.isabelleControl

sealed trait Subgoal {
  def simplify(isabelle: IsabelleX.ContextX, facts: List[String], everywhere:Boolean): Subgoal

  /** Checks whether all isabelle terms in this goal are well-typed.
    * Should always succeed, unless there are bugs somewhere. */
  def checkWelltyped(context: IsabelleX.ContextX): Unit

  /** This goal as a boolean term. (A valid Isabelle representation of this goal.) */
  def toTerm(context:IsabelleX.ContextX): RichTerm

  def checkVariablesDeclared(environment: Environment): Unit

  def containsAmbientVar(x: String) : Boolean

  @tailrec
  final def addAssumptions(assms: List[RichTerm]): Subgoal = assms match {
    case Nil => this
    case a::as => addAssumption(a).addAssumptions(as)
  }

  def addAssumption(assm: RichTerm): Subgoal
}

object Subgoal {
  private val logger = log4s.getLogger

  def printOracles(thms : Thm*): Unit = {
    for (thm <- thms)
      show_oracles(thm)
  }
}

object QRHLSubgoal {
  private val logger = log4s.getLogger
}

final case class QRHLSubgoal(left:Block, right:Block, pre:RichTerm, post:RichTerm, assumptions:List[RichTerm]) extends Subgoal {
  override def toString: String = {
    val assms = if (assumptions.isEmpty) "" else
      s"Assumptions:\n${assumptions.map(a => s"* $a\n").mkString}\n"
    s"${assms}Pre:   $pre\n\n${left.toStringMultiline("Left:  ")}\n\n${right.toStringMultiline("Right: ")}\n\nPost:  $post"
  }

  override def checkVariablesDeclared(environment: Environment): Unit = {
    for (x <- pre.variables)
      if (!environment.variableExistsForPredicate(x))
        throw UserException(s"Undeclared variable $x in precondition")
    for (x <- post.variables)
      if (!environment.variableExistsForPredicate(x))
        throw UserException(s"Undeclared variable $x in postcondition")
    for (x <- left.variablesDirect)
      if (!environment.variableExistsForProg(x))
        throw UserException(s"Undeclared variable $x in left program")
    for (x <- right.variablesDirect)
      if (!environment.variableExistsForProg(x))
        throw UserException(s"Undeclared variable $x in left program")
    for (a <- assumptions; x <- a.variables)
      if (!environment.variableExists(x))
        throw UserException(s"Undeclared variable $x in assumptions")
  }

  override def toTerm(context: IsabelleX.ContextX): RichTerm = {
    val mlVal = MLValue((context.context,left.statements,right.statements,pre.isabelleTerm,post.isabelleTerm,assumptions.map(_.isabelleTerm)))
    val term = Ops.qrhl_subgoal_to_term_op(mlVal).retrieveNow
    RichTerm(term)
  }

  /** Not including ambient vars in nested programs (via Call) */
  override def containsAmbientVar(x: String): Boolean = {
    pre.variables.contains(x) || post.variables.contains(x) ||
      left.variablesDirect.contains(x) || right.variablesDirect.contains(x) ||
      assumptions.exists(_.variables.contains(x))
  }

  override def addAssumption(assm: RichTerm): QRHLSubgoal = {
    assert(assm.typ==GIsabelle.boolT)
    QRHLSubgoal(left,right,pre,post,assm::assumptions)
  }

  /** Checks whether all isabelle terms in this goal are well-typed.
    * Should always succeed, unless there are bugs somewhere. */
  override def checkWelltyped(context:IsabelleX.ContextX): Unit = {
    for (a <- assumptions) a.checkWelltyped(context, GIsabelle.boolT)
    left.checkWelltyped(context)
    right.checkWelltyped(context)
    pre.checkWelltyped(context, GIsabelle.predicateT)
    post.checkWelltyped(context, GIsabelle.predicateT)
  }

  override def simplify(isabelle: IsabelleX.ContextX, facts: List[String], everywhere:Boolean): QRHLSubgoal = {
//    if (assumptions.nonEmpty) QRHLSubgoal.logger.warn("Not using assumptions for simplification")
    val thms = new ListBuffer[Thm]()
    val assms2 = assumptions.map(_.simplify(isabelle,facts,thms))
    val assms3: List[RichTerm] = assms2.filter(_.isabelleTerm!=GIsabelle.True_const)
    val pre2 = pre.simplify(isabelle,facts,thms)
    val post2 = post.simplify(isabelle,facts,thms)
    val left2 = if (everywhere) left.simplify(isabelle,facts,thms) else left
    val right2 = if (everywhere) right.simplify(isabelle,facts,thms) else right

    Subgoal.printOracles(thms.toSeq : _*)
    QRHLSubgoal(left2, right2, pre2, post2, assms2)
  }
}

final case class AmbientSubgoal(goal: RichTerm) extends Subgoal {
  override def toString: String = goal.toString

  override def checkVariablesDeclared(environment: Environment): Unit =
    for (x <- goal.variables)
      if (!environment.variableExists(x))
        throw UserException(s"Undeclared variable $x")

  /** This goal as a boolean expression. */
  override def toTerm(context: IsabelleX.ContextX): RichTerm = goal

  override def containsAmbientVar(x: String): Boolean = goal.variables.contains(x)

  override def addAssumption(assm: RichTerm): AmbientSubgoal = {
    assert(assm.typ == GIsabelle.boolT)
    AmbientSubgoal(assm.implies(goal))
  }

  /** Checks whether all isabelle terms in this goal are well-typed.
    * Should always succeed, unless there are bugs somewhere. */
  override def checkWelltyped(context: IsabelleX.ContextX): Unit = goal.checkWelltyped(context, GIsabelle.boolT)

  override def simplify(isabelle: IsabelleX.ContextX, facts: List[String], everywhere:Boolean): AmbientSubgoal = {
    val (term, thm) = goal.simplify(isabelle, facts)
    Subgoal.printOracles(thm)
    AmbientSubgoal(term)
  }
}

object AmbientSubgoal {
  def apply(goal: Term, assms: Seq[Term]): AmbientSubgoal =
    new AmbientSubgoal(RichTerm(GIsabelle.boolT, assms.foldRight(goal) { (assm,goal) => GIsabelle.implies(assm,goal) }))
  def apply(goal: RichTerm, assms: Seq[RichTerm]): AmbientSubgoal =
    AmbientSubgoal(goal.isabelleTerm, assms.map(_.isabelleTerm))
}

trait Tactic {
  def apply(state: State, goal : Subgoal) : List[Subgoal]
}

class UserException private (private val msg:String, private var _position:String=null) extends RuntimeException(msg) {
  def setPosition(position:String): Unit = {
    if (_position==null)
      _position = position
  }
  def position : String = _position
  def positionMessage : String = s"$position: $msg"
}
object UserException {
  private val logger = log4s.getLogger

  def apply(msg: String) = new UserException(msg)
  def apply(e: IsabelleException, position: String): UserException = {
//    logger.debug(s"Failing operation: operation ${e.operation} with input ${e.input}")
    val e2 = UserException("(in Isabelle) "+IsabelleX.symbols.symbolsToUnicode(e.getMessage))
    e2.setPosition(position)
    e2
  }
}

/** A path together with a last-modification time and content hash. */
class FileTimeStamp(val file:Path) {
  import FileTimeStamp.logger

  private var time = FileTimeStamp.getLastModifiedTime(file)
  private val hash = Utils.hashFile(file)
  /** Returns whether the file (content) has changed since the FileTimeStamp was created.
   * Uses the last modification time as a shortcut – the assumption is that
   * the content will be unmodified if the time is */
  def changed : Boolean =
    if (time==FileTimeStamp.getLastModifiedTime(file))
      false
    else {
      val newHash = Utils.hashFile(file)
      if (util.Arrays.equals(hash,newHash)) {
        time = FileTimeStamp.getLastModifiedTime(file)
        false
      } else {
        logger.debug(s"File change detected: ${Hex.encodeHexString(hash)} -> ${Hex.encodeHexString(newHash)}")
        true
      }
    }

  override def toString: String = s"$file@$time@${Hex.encodeHexString(hash).substring(0,8)}"
}
object FileTimeStamp {
  private val logger = log4s.getLogger
  def getLastModifiedTime(file:Path): FileTime = try
    Files.getLastModifiedTime(file)
  catch {
    case _ : NoSuchFileException => FileTime.fromMillis(-1)
  }
}

class CheatMode private (
                    private val cheatAtAll : Boolean, // whether any cheating should happen at all
                    private val cheatInProof : Boolean, // cheating till the end of the current proof
                    private val cheatInFile : Boolean, // cheating till the end of current file
                    private val inInclude : Boolean // in included file
                    ) {
//  assert(includeLevel >= 0)
//  def endInclude = new CheatMode(cheatAtAll=cheatAtAll, cheatInProof=cheatInProof, cheatInFile=false, includeLevel=includeLevel-1)
  def endProof = new CheatMode(cheatAtAll=cheatAtAll, cheatInProof=false, cheatInFile=cheatInFile, inInclude=inInclude)
  def cheating: Boolean = cheatAtAll && (cheatInFile || cheatInProof || inInclude)
  def startCheatInProof = new CheatMode(cheatAtAll=cheatAtAll, cheatInProof=true, cheatInFile=cheatInFile, inInclude=inInclude)
  def startCheatInFile = new CheatMode(cheatAtAll=cheatAtAll, cheatInProof=cheatInProof, cheatInFile=true, inInclude=inInclude)
  def startInclude = new CheatMode(cheatAtAll=cheatAtAll, cheatInProof=cheatInProof, cheatInFile=cheatInFile, inInclude=true)
  def stopCheatInFile(inProof:Boolean) = new CheatMode(cheatAtAll=cheatAtAll,
    cheatInProof=cheatInProof || (inProof && cheatInFile),
    cheatInFile=false, inInclude=inInclude)
}

object CheatMode {
  def make(cheatAtAll:Boolean): CheatMode = new CheatMode(cheatAtAll=cheatAtAll,false,false,false)
}

class State private (val environment: Environment,
                     val goal: List[Subgoal],
                     val currentLemma: Option[(String,RichTerm)],
                     private val _isabelle: Option[IsabelleX.ContextX],
                     private val _isabelleTheory: List[Path],
                     val dependencies: List[FileTimeStamp],
                     val currentDirectory: Path,
                     val cheatMode : CheatMode,
                     val includedFiles : Set[Path]) {
  def include(hash: default.Hash, file: Path): default.Hashed[State] = {
    val fullpath =
      try {
        currentDirectory.resolve(file).toRealPath()
      } catch {
        case e:NoSuchFileException => throw UserException(s"File not found: $file (relative to $currentDirectory)")
      }

    logger.debug(s"Including $fullpath")
    if (includedFiles.contains(fullpath)) {
      println(s"Already included $file. Skipping.")
      Hashed(this,hash)
    } else {
      val state1 = copy(includedFiles = includedFiles + fullpath, cheatMode=cheatMode.startInclude)
      val hash1 = default.hash(43246596, hash, fullpath.toString)
      val toplevel = Toplevel.makeToplevelFromState(Hashed(state1,hash1))
      toplevel.run(fullpath)
      val Hashed(state2,hash2) = toplevel.state
      val state3 = state2.copy(
        dependencies=new FileTimeStamp(fullpath)::state2.dependencies,
        cheatMode = cheatMode, // restore original cheatMode
        currentDirectory = currentDirectory) // restore original currentDirectory

      // We can drop the file-hash from hash3, but then we get spurious warnings about changed files
      val hash3 = default.hash(187408913, hash2, Utils.hashFile(fullpath))
      Hashed(state3, hash3)
    }
  }

  def cheatInFile: State = copy(cheatMode=cheatMode.startCheatInFile)
  def cheatInProof: State = copy(cheatMode=cheatMode.startCheatInProof)
  def stopCheating: State = copy(cheatMode=cheatMode.stopCheatInFile(currentLemma.isDefined))

  def isabelle: IsabelleX.ContextX = _isabelle match {
    case Some(isa) => isa
    case None => throw UserException(Parser.noIsabelleError)
  }
  def hasIsabelle: Boolean = _isabelle.isDefined

  def qed: State = {
    assert(currentLemma.isDefined)
    assert(goal.isEmpty)

    val (name,prop) = currentLemma.get
    val isa = if (name!="") _isabelle.map(_.addAssumption(name,prop.isabelleTerm)) else _isabelle
    copy(isabelle=isa, currentLemma=None, cheatMode=cheatMode.endProof)
  }

  private def containsDuplicates[A](seq: Seq[A]): Boolean = {
    val seen = new mutable.HashSet[A]()
    for (e <- seq) {
      if (seen.contains(e)) return true
      seen += e
    }
    false
  }

  def declareProgram(name: String, oracles: List[String], program: Block): State = {
    if (containsDuplicates(oracles))
      throw UserException("Oracles "+oracles.mkString(",")+" must not contain duplicates")

    for (x <- program.variablesDirect)
      if (!environment.variableExistsForProg(x))
        throw UserException(s"Undeclared variable $x in program")

    if (_isabelle.isEmpty) throw UserException("Missing isabelle command.")
    if (this.environment.variableExists(name))
      throw UserException(s"Name $name already used for a variable or program.")

    val decl = ConcreteProgramDecl(environment,name,oracles,program)
    val env1 = environment.declareProgram(decl)
    val isa = decl.declareInIsabelle(_isabelle.get)

//    val isa1 = _isabelle.get.declareVariable(name, if (oracles.isEmpty) Isabelle.programT else Isabelle.oracle_programT)

//    val isa2 = decl.getSimplifierRules.foldLeft(isa1) { (isa,rule) => isa.addAssumption("", rule.isabelleTerm, simplifier = true) }

    logger.debug(s"Program variables: ${env1.programs(name).variablesRecursive}")

    copy(environment = env1, isabelle=Some(isa))
  }

  def declareAdversary(name: String, free: Seq[Variable], inner: Seq[Variable], written: Seq[Variable], covered: Seq[Variable], overwritten: Seq[Variable], numOracles : Int): State = {
//    val isa1 = _isabelle.get.declareVariable(name,
//      if (numOracles==0) Isabelle.programT else Isabelle.oracle_programT)
    val decl = AbstractProgramDecl(name, free=free.toList,inner=inner.toList,written=written.toList,covered=covered.toList,overwritten=overwritten.toList, numOracles=numOracles)
    val isa = decl.declareInIsabelle(_isabelle.get)
//    val isa2 = decl.getSimplifierRules.foldLeft(isa1) { (isa,rule) => isa.addAssumption("", rule.isabelleTerm, simplifier = true) }
    val env1 = environment.declareProgram(decl)

    logger.debug(s"Program variables: ${env1.programs(name).variablesRecursive}")

    copy(environment = env1, isabelle=Some(isa))
  }


  def applyTactic(tactic:Tactic) : State =
    if (cheatMode.cheating)
      copy(goal=Nil)
    else
      goal match {
        case Nil =>
          throw UserException("No pending proof")
        case subgoal::subgoals =>
          copy(goal=tactic.apply(this,subgoal)++subgoals)
      }

  private def copy(environment:Environment=environment,
                   goal:List[Subgoal]=goal,
                   isabelle:Option[IsabelleX.ContextX]=_isabelle,
                   dependencies:List[FileTimeStamp]=dependencies,
                   currentLemma:Option[(String,RichTerm)]=currentLemma,
                   currentDirectory:Path=currentDirectory,
                   cheatMode:CheatMode=cheatMode,
                   isabelleTheory:List[Path]=_isabelleTheory,
                   includedFiles:Set[Path]=includedFiles) : State =
    new State(environment=environment, goal=goal, _isabelle=isabelle, cheatMode=cheatMode,
      currentLemma=currentLemma, dependencies=dependencies, currentDirectory=currentDirectory,
      includedFiles=includedFiles, _isabelleTheory=isabelleTheory)

  def changeDirectory(dir:Path): State = {
    assert(dir!=null)
    if (dir==currentDirectory) return this
    if (!Files.isDirectory(dir)) throw UserException(s"Non-existent directory: $dir")
//    if (hasIsabelle) throw UserException("Cannot change directory after loading Isabelle")
    copy(currentDirectory=dir)
  }

  def openGoal(name:String, goal:Subgoal) : State = this.currentLemma match {
    case None =>
      goal.checkVariablesDeclared(environment)
      copy(goal=List(goal), currentLemma=Some((name,goal.toTerm(_isabelle.get))))
    case _ => throw UserException("There is still a pending proof.")
  }

  override def toString: String = if (cheatMode.cheating)
    "In cheat mode."
  else goal match {
    case Nil => "No current goal."
    case List(goal1) => s"Goal:\n\n" + goal1
    case List(goal1,rest @ _*) =>
      s"${goal.size} subgoals:\n\n" + goal1 + "\n\n----------------------------------------------------\n\n" + rest.mkString("\n\n")
  }

  lazy val parserContext: ParserContext = ParserContext(isabelle=_isabelle, environment=environment)

  def parseCommand(str:String): Command = {
    implicit val parserContext: ParserContext = this.parserContext
    Parser.parseAll(Parser.command,str) match {
      case Parser.Success(cmd2,_) => cmd2
      case res @ Parser.NoSuccess(msg, _) =>
        throw UserException(msg)
    }
  }

  def parseExpression(typ:Typ, str:String): RichTerm = {
    implicit val parserContext: ParserContext = this.parserContext
    Parser.parseAll(Parser.expression(typ),str) match {
      case Parser.Success(cmd2,_) => cmd2
      case res @ Parser.NoSuccess(msg, _) =>
        throw UserException(msg)
    }
  }

  def parseBlock(str:String): Block = {
    implicit val parserContext: ParserContext = this.parserContext
    Parser.parseAll(Parser.block,str) match {
      case Parser.Success(cmd2,_) => cmd2
      case res @ Parser.NoSuccess(msg, _) =>
        throw UserException(msg)
    }
  }

  def loadIsabelle(theory:Seq[String]) : State = {
    val theoryPath = theory.toList map { thy => currentDirectory.resolve(thy+".thy") }

    if (_isabelle.isDefined)
      if (theoryPath != _isabelleTheory)
        throw UserException(s"Isabelle loaded twice with different theories: ${if (_isabelleTheory.isEmpty) "none" else _isabelleTheory.mkString(", ")} vs. ${if (theoryPath.isEmpty) "none" else theoryPath.mkString(", ")}")
      else
        return this

    val isabelle = IsabelleX.globalIsabelle
    logger.debug(s"Paths of theories to load: $theoryPath")
    val (ctxt,deps) = isabelle.getQRHLContextWithFiles(theoryPath : _*)
    logger.debug(s"Dependencies of theory ${theory.mkString(", ")}: ${deps.mkString(", ")}")
    val stamps = deps.map(new FileTimeStamp(_))
    val newState = copy(isabelle = Some(ctxt), dependencies=stamps:::dependencies, isabelleTheory=theoryPath)
    // We declare a quantum variable aux :: infinite by default (for use in equal-tac, for example)
    newState.declareVariable("aux", GIsabelle.infiniteT, quantum = true)
  }

  def filesChanged : List[Path] = {
    dependencies.filter(_.changed).map(_.file)
  }

  private def declare_quantum_variable(isabelle: IsabelleX.ContextX, name: String, typ: Typ) : IsabelleX.ContextX = {
    val ctxt = Ops.declare_quantum_variable(MLValue((name, typ, isabelle.context))).retrieveNow
    new ContextX(isabelle.isabelle, ctxt)
//    isabelle.map(id => isabelle.isabelle.invoke(State.declare_quantum_variable, (name,typ,id)))
  }

  private def declare_classical_variable(isabelle: IsabelleX.ContextX, name: String, typ: Typ) : IsabelleX.ContextX = {
    val ctxt = Ops.declare_classical_variable(MLValue((name, typ, isabelle.context))).retrieveNow
    new ContextX(isabelle.isabelle, ctxt)
//    isabelle.map(id => isabelle.isabelle.invoke(State.declare_classical_variable, (name,typ,id)))
  }

  def declareVariable(name: String, typ: Typ, quantum: Boolean = false): State = {
    val newEnv = environment.declareVariable(name, typ, quantum = quantum)
      .declareAmbientVariable("var_"+name, typ)
      .declareAmbientVariable("var_"+Variable.index1(name), typ)
      .declareAmbientVariable("var_"+Variable.index2(name), typ)
    if (_isabelle.isEmpty) throw UserException("Missing isabelle command.")
    val isa = _isabelle.get
//    val typ1 = typ.isabelleTyp
//    val typ2 = if (quantum) Type("QRHL_Core.variable",List(typ1)) else typ1
    val newIsa =
      if (quantum)
        declare_quantum_variable(isa, name, typ)
      else
        declare_classical_variable(isa, name, typ)

    copy(environment = newEnv, isabelle = Some(newIsa))
  }

  def declareAmbientVariable(name: String, typ: Typ): State = {
    val newEnv = environment.declareAmbientVariable(name, typ)
    if (_isabelle.isEmpty) throw UserException("Missing isabelle command.")
    val isa = _isabelle.get.declareVariable(name, typ)
    copy(environment = newEnv, isabelle = Some(isa))
  }
}

object State {
  def empty(cheating:Boolean) = new State(environment=Environment.empty, goal=Nil,
    _isabelle=None, _isabelleTheory=null,
    dependencies=Nil, currentLemma=None, currentDirectory=Paths.get(""),
    cheatMode=CheatMode.make(cheating), includedFiles=Set.empty)
//  private[State] val defaultIsabelleTheory = "QRHL"

  private val logger = log4s.getLogger

}
