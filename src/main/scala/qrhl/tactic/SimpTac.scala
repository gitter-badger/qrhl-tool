package qrhl.tactic

import org.log4s
import qrhl._
import qrhl.toplevel.Parser

import scala.collection.immutable.Nil

case class SimpTac(facts:List[String], everywhere:Boolean, force:Boolean) extends Tactic {
  override def apply(state: State, goal: Subgoal): List[Subgoal] = {
        val newGoal = goal.simplify(state.isabelle, facts, everywhere)
        if (TrueTac.isTrivial(newGoal)) Nil
        else if (force) throw UserException("Simp failed to fully solve subgoal.")
        else List(newGoal)
    }

  override def toString: String = s"simplify${if (force) " !" else ""} ${facts.mkString(" ")}"
}

object SimpTac {
  private val logger = log4s.getLogger
}
