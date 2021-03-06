package qrhl.tactic


import qrhl._
import qrhl.isabellex.{IsabelleX, RichTerm}
import IsabelleX.{globalIsabelle => GIsabelle}

object TrueTac extends Tactic {
  override def apply(state: State, goal: Subgoal): List[Subgoal] =
    if (isTrivial(goal)) Nil
    else throw UserException("""Tactic true expects a subgoal that is simply "true", or a QRHL subgoal with one assumption being "False" or the precondition being "bot" or "0"""")

  def isTrivial(goal: Subgoal): Boolean = goal match{
    case AmbientSubgoal(exp : RichTerm) => exp.isabelleTerm==GIsabelle.True_const
    case g : QRHLSubgoal =>
      g.assumptions.exists(_.isabelleTerm==GIsabelle.False_const) ||
      g.pre.isabelleTerm==GIsabelle.predicate_bot ||
      g.pre.isabelleTerm==GIsabelle.predicate_0
  }

  override def toString: String = "true"
}
