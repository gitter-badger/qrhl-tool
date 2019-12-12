package qrhl.tactic

import info.hupel.isabelle.pure.Term
import org.log4s
import qrhl.{AmbientSubgoal, QRHLSubgoal, State, Subgoal, Tactic, UserException}
import qrhl.isabelle.Isabelle.{Inf, QuantumEqualityFull, predicateT, predicate_inf, predicate_top}
import qrhl.isabelle.{Isabelle, RichTerm}
import qrhl.logic.{Block, Local, QVariable}

case object LocalJointTac extends Tactic {
  /** Assumes that s1,s2 have same length and matching types */
  private def extendQeq(us1: Term, s1: Term, us2: Term, s2: Term, qvarsL: List[QVariable], qvarsR: List[QVariable]) = {
    import Isabelle.{variable_concat, variable_singleton, quantum_equality_full, idOp, ell2T}
    var us1_ = us1
    var us2_ = us2
    var s1_ = s1
    var s2_ = s2

    for ((q1,q2) <- qvarsL.zip(qvarsR).reverse) {
      s1_ = variable_concat(variable_singleton(q1.index1.variableTerm),s1_)
      s2_ = variable_concat(variable_singleton(q2.index2.variableTerm),s2_)
      us1_ = Isabelle.tensorOp(idOp(ell2T(q1.valueTyp)), us1_)
      us2_ = Isabelle.tensorOp(idOp(ell2T(q2.valueTyp)), us2_)
    }

    quantum_equality_full(us1_, s1_, us2_, s2_)
  }

  def apply(state: State, goal: Subgoal): List[Subgoal] = goal match {
    case AmbientSubgoal(goal) =>
      throw UserException("Expected qRHL goal")
    case QRHLSubgoal(leftProg, rightProg, pre, post, assumptions) =>
      val env = state.environment
      val context = state.isabelle

      // Decomposing left/right program
      val (cvarsL, qvarsL, bodyL) = leftProg match {
        case Block(Local(cvars, qvars, body)) => (cvars, qvars, body)
        case _ => throw UserException(s"Expected left program to be of the form { local ...; ... }")
      }

      val (cvarsR, qvarsR, bodyR) = rightProg match {
        case Block(Local(cvars, qvars, body)) => (cvars, qvars, body)
        case _ => throw UserException(s"Expected right program to be of the form { local ...; ... }")
      }


      def decomposePredicate(which: String, pred: RichTerm) = {
        pred.isabelleTerm match {
          case Inf(main,QuantumEqualityFull(u1,v1,u2,v2)) => (main,u1,v1,u2,v2)
          case QuantumEqualityFull(u1,v1,u2,v2) => (predicate_top,u1,v1,u2,v2)
          case _ => throw UserException(s"""Expected $which to be of the form "A ⊓ Q" where Q is a quantum equality""")
        }
      }

      val (a, us1, s1, us2, s2) = decomposePredicate("precondition", pre)
      val (b, ur1, r1, ur2, r2) = decomposePredicate("postcondition", post)

      // TODO remove
      def p(t:Term) = Isabelle.pretty(t)
      logger.debug(s"A:   ${p(a)}")
      logger.debug(s"US:  ${p(us1)}")
      logger.debug(s"S:   ${p(s1)}")
      logger.debug(s"US': ${p(us2)}")
      logger.debug(s"S':  ${p(s2)}")
      logger.debug(s"B:   ${p(b)}")
      logger.debug(s"UR:  ${p(ur1)}")
      logger.debug(s"R:   ${p(r1)}")
      logger.debug(s"UR': ${p(ur2)}")
      logger.debug(s"R':  ${p(r2)}")

      println(s"*** Unsound (incomplete) tactic local applied.")


      // TODO check qvars1, qvars2 has same length and same types

      val newPre = predicate_inf $ a $ extendQeq(us1,s1,us2,s2,qvarsL,qvarsR)
      // TODO: unitarity condition
      val unitarity = Isabelle.classical_subspace $ Isabelle.conj(Isabelle.unitary(ur1), Isabelle.unitary(ur2))
      val newPost = Isabelle.inf(b, unitarity, extendQeq(ur1,r1,ur2,r2,qvarsL,qvarsR))

      logger.debug(s"Pre: ${p(newPre)}")
      logger.debug(s"Post: ${p(newPost)}")

      val newQrhl = QRHLSubgoal(bodyL, bodyR, RichTerm(predicateT, newPre), RichTerm(predicateT, newPost), assumptions)

      // TODO check premises of rule

      // TODO create subgoal for fv-q-conditions

      //      // Checking whether pre/postcondition contains local classical variables
      //      val cvars12 = (cvarsL map { _.index1 }) ++ (cvarsR map { _.index2 })
      //      val preConflict = pre.caVariables(env).classical.intersect(cvars12.toSet)
      //      if (preConflict.nonEmpty)
      //        throw UserException(s"Precondition must not contain the classical variable(s) ${cvars12 map { _.name } mkString ", "}")
      //      val postConflict = post.caVariables(env).classical.intersect(cvars12.toSet)
      //      if (postConflict.nonEmpty)
      //        throw UserException(s"Postcondition must not contain the classical variable(s) ${cvars12 map { _.name } mkString ", "}")

      List(newQrhl)
  }

  private val logger = log4s.getLogger
}
