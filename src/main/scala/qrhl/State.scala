package qrhl

import info.hupel.isabelle.hol.HOLogic
import info.hupel.isabelle.ml
import info.hupel.isabelle.pure.{Type, Typ => ITyp, Context => IContext}
import qrhl.isabelle.Isabelle
import qrhl.logic._
import qrhl.toplevel.ParserContext

sealed trait Subgoal {
  def checkVariablesDeclared(environment: Environment): Unit
}

final case class QRHLSubgoal(left:Block, right:Block, pre:Expression, post:Expression) extends Subgoal {
  override def toString: String = s"Pre:   $pre\nLeft:  ${left.toStringNoParens}\nRight: ${right.toStringNoParens}\nPost:  $post"

  override def checkVariablesDeclared(environment: Environment): Unit = {
    for (x <- pre.variables)
      if (!environment.variableExistsForAssertion(x))
        throw UserException(s"Undeclared variable $x in precondition")
    for (x <- post.variables)
      if (!environment.variableExistsForAssertion(x))
        throw UserException(s"Undeclared variable $x in postcondition")
    for (x <- left.variablesDirect)
      if (!environment.variableExistsForProg(x))
        throw UserException(s"Undeclared variable $x in left program")
    for (x <- right.variablesDirect)
      if (!environment.variableExistsForProg(x))
        throw UserException(s"Undeclared variable $x in left program")
  }
}
final case class AmbientSubgoal(goal: Expression) extends Subgoal {
  override def toString: String = goal.toString

  override def checkVariablesDeclared(environment: Environment): Unit =
    for (x <- goal.variables)
      if (!environment.variableExists(x))
        throw UserException(s"Undeclared variable $x")
}

trait Tactic {
  def apply(state: State, goal : Subgoal) : List[Subgoal]
}

case class UserException(msg:String) extends RuntimeException(msg)

class State private (val environment: Environment,
                     val goal: List[Subgoal],
                     val isabelle: Option[Isabelle.Context],
                     val boolT: Typ,
                     val assertionT: Typ,
                     val programT: Typ) {
  def declareProgram(name: String, program: Block): State = {
    for (x <- program.variablesDirect)
      if (!environment.variableExistsForProg(x))
        throw UserException(s"Undeclared variable $x in program")

    if (isabelle.isEmpty) throw UserException("Missing isabelle command.")
    val isa = isabelle.get.declareVariable(name, programT.isabelleTyp)

    copy(environment = environment.declareProgram(name, program))
  }

  def declareAdversary(name: String, cvars: Seq[CVariable], qvars: Seq[QVariable]): State = {
    copy(environment = environment.declareAdversary(name, cvars, qvars))
  }


  def applyTactic(tactic:Tactic) : State = goal match {
    case Nil =>
      throw UserException("No pending proof")
    case (subgoal::subgoals) =>
      copy(goal=tactic.apply(this,subgoal)++subgoals)

  }

  private def copy(environment:Environment=environment,
                   goal:List[Subgoal]=goal,
                  isabelle:Option[Isabelle.Context]=isabelle,
                  boolT:Typ=boolT,
                  assertionT:Typ=assertionT,
                   programT:Typ=programT) : State =
    new State(environment=environment, goal=goal, isabelle=isabelle, boolT=boolT, assertionT=assertionT, programT=programT)

  def openGoal(goal:Subgoal) : State = this.goal match {
    case Nil =>
      goal.checkVariablesDeclared(environment)
      copy(goal=List(goal))
    case _ => throw UserException("There is still a pending proof.")
  }

  override def toString: String = goal match {
    case Nil => "No current goal."
    case _ =>
      s"${goal.size} subgoals:\n\n" + goal.mkString("\n\n")
  }

  lazy val parserContext = ParserContext(isabelle=isabelle, environment=environment, boolT = boolT, assertionT = assertionT)

  def loadIsabelle(path:String, theory:Option[String]) : State = {
    assert(isabelle.isEmpty)
    val isa = new Isabelle(path)
    loadIsabelle(isa,theory)
  }

  def loadIsabelle(isabelle: Isabelle, theory:Option[String]) : State = {
    val isa = theory match {
      case None => isabelle.getContext(State.defaultIsabelleTheory)
      case Some(thy) => isabelle.getContextFile(thy)
    }
    copy(isabelle = Some(isa), boolT = Typ.bool(isa), assertionT=Typ(isa,"QRHL.assertion"), programT=Typ(isa,"QRHL.program"))
  }

  private def addQVariableNameAssumption(isabelle: Isabelle.Context, name: String, typ: ITyp) : Isabelle.Context = {
    val mlExpr = ml.Expr.uncheckedLiteral[String => ITyp => IContext => IContext]("QRHL.addQVariableNameAssumption")
    isabelle.map(mlExpr(name)(implicitly)(typ))
  }

  def declareVariable(name: String, typ: Typ, quantum: Boolean = false): State = {
    val newEnv = environment.declareVariable(name, typ, quantum = quantum)
    if (isabelle.isEmpty) throw UserException("Missing isabelle command.")
    val isa = isabelle.get
    val typ1 = typ.isabelleTyp
    val typ2 = if (quantum) Type("QRHL.qvariable",List(typ1)) else typ1
    var newIsa = isa.declareVariable(name, typ2)
      .declareVariable(Variable.index1(name), typ2)
      .declareVariable(Variable.index2(name), typ2)
    if (quantum) {
      newIsa = addQVariableNameAssumption(newIsa, Variable.index1(name), typ1)
      newIsa = addQVariableNameAssumption(newIsa, Variable.index2(name), typ1)
    }
    copy(environment = newEnv, isabelle = Some(newIsa))
  }

  def declareAmbientVariable(name: String, typ: Typ): State = {
    val newEnv = environment.declareAmbientVariable(name, typ)
    if (isabelle.isEmpty) throw UserException("Missing isabelle command.")
    val isa = isabelle.get.declareVariable(name, typ.isabelleTyp)
    copy(environment = newEnv, isabelle = Some(isa))
  }
}

object State {
  val empty = new State(environment=Environment.empty,goal=Nil,isabelle=None,
    boolT=null, assertionT=null, programT=null)
  private[State] val defaultIsabelleTheory = "QRHL_Protocol"
}