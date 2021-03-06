package qrhl.tactic

import qrhl._

case class ClearTac(number:Int) extends Tactic {
  if (number<=0) throw UserException(s"clear tactic must have argument >= 1, not $number")

  override def apply(state: State, goal: Subgoal): List[Subgoal] = goal match {
    case QRHLSubgoal(left,right,pre,post,assms) =>
      if (number>assms.length) throw UserException(s"Only ${assms.length} assumption${if (assms.length==1) "" else "s"}, cannot remove ${number}. assumption")
      val (before,_::after) = assms.splitAt(number-1)
      List(QRHLSubgoal(left,right,pre,post,before ++ after))
    case AmbientSubgoal(expr) =>
      List(AmbientSubgoal(expr.stripAssumption(number-1)))
  }
}
