theory QRHL_Core
  imports Complex_Main "HOL-Library.Adhoc_Overloading" Bounded_Operators.Bounded_Operators Discrete_Distributions 
    Universe Misc_Missing Prog_Variables
  keywords "declare_variable_type" :: thy_decl
begin

hide_const (open) span

section \<open>Miscellaneous\<close>


(* definition [code]: "(sqrt2::complex) = sqrt 2"
lemma sqrt22[simp]: "sqrt2 * sqrt2 = 2" 
 by (simp add: of_real_def scaleR_2 sqrt2_def)
lemma sqrt2_neq0[simp]: "sqrt2 \<noteq> 0" unfolding sqrt2_def by simp
lemma [simp]: "cnj sqrt2 = sqrt2" unfolding sqrt2_def by simp *)



(* TODO move into theory Predicates.thy *)
section \<open>Quantum predicates\<close>
    
type_synonym predicate = "mem2 subspace"

subsection \<open>Classical predicates\<close>
  
definition classical_subspace :: "bool \<Rightarrow> predicate"  ("\<CC>\<ll>\<aa>[_]")
  where "\<CC>\<ll>\<aa>[b] = (if b then top else bot)"
syntax classical_subspace :: "bool \<Rightarrow> predicate"  ("Cla[_]")

lemma classical_true[simp]: "Cla[True] = top" unfolding classical_subspace_def by simp
lemma classical_false[simp]: "Cla[False] = bot" unfolding classical_subspace_def by simp
lemma classical_mono[simp]: "(Cla[a] \<le> Cla[b]) = (a \<longrightarrow> b)" 
  apply (cases a, auto, cases b, auto)
  using bot.extremum_uniqueI top_not_bot by blast 
lemma classical_simp1[simp]: 
  shows "(Cla[b] \<le> A) = (b \<longrightarrow> A = top)"
  using top.extremum_unique by fastforce
lemma classical_inf[simp]: "Cla[x] \<sqinter> Cla[y] = Cla[x \<and> y]"
  by (simp add: classical_subspace_def)
lemma classical_sup[simp]: "Cla[x] \<squnion> Cla[y] = Cla[x \<or> y]"
  by (simp add: classical_subspace_def)
lemma classical_simp2[simp]:
  shows "(Cla[a] \<sqinter> B \<le> C) = (a \<longrightarrow> B \<le> C)"
  apply (cases a) by auto
lemma classical_sort[simp]:
  assumes "NO_MATCH Cla[x] A" 
  shows "A \<sqinter> Cla[b] = Cla[b] \<sqinter> A"
  by (simp add: classical_subspace_def)

lemma Cla_split[split]: "P (Cla[Q]) = ((Q \<longrightarrow> P top) \<and> (\<not> Q \<longrightarrow> P bot))"
  by (cases Q, auto) 
lemma classical_ortho[simp]: "ortho Cla[b] = Cla[\<not> b]"
  by auto

lemma applyOp_Cla[simp]:
  assumes "unitary A"
  shows "A \<cdot> Cla[b] = Cla[b]"
  apply (cases b) using assms by auto

lemma Cla_plus[simp]: "Cla[x] + Cla[y] = Cla[x\<or>y]" unfolding sup_subspace_def[symmetric] by auto
lemma BINF_Cla[simp]: "(INF z:Z. Cla[x z]) = Cla[\<forall>z\<in>Z. x z]" 
proof (rule Inf_eqI)
  show "\<And>i. i \<in> (\<lambda>z. \<CC>\<ll>\<aa>[x z]) ` Z \<Longrightarrow> \<CC>\<ll>\<aa>[\<forall>z\<in>Z. x z] \<le> i" by auto
  fix y assume assm: "\<And>i. i \<in> (\<lambda>z. \<CC>\<ll>\<aa>[x z]) ` Z \<Longrightarrow> y \<le> i"
  show "y \<le> \<CC>\<ll>\<aa>[\<forall>z\<in>Z. x z]"
  proof (cases "\<forall>z\<in>Z. x z")
    case True thus ?thesis by auto
  next case False
    then obtain z where "\<not> x z" and "z\<in>Z" by auto
    hence "Cla[x z] = bot" by simp
    hence "bot \<in> (\<lambda>z. \<CC>\<ll>\<aa>[x z]) ` Z"
      using \<open>z \<in> Z\<close> by force
    hence "y \<le> bot" by (rule assm)
    thus ?thesis
      by (simp add: False)
  qed
qed

lemma free_INF[simp]: "(INF x:X. A) = Cla[X={}] + A"
  apply (cases "X={}") by auto

lemma [simp]: "eigenspace b 0 = Cla[b=0]"
  unfolding eigenspace_def apply auto
  apply (rewrite at "kernel \<hole>" DEADID.rel_mono_strong[where y="(-b) \<cdot> idOp"])
  by (auto simp: subspace_zero_bot uminus_bounded_def)


subsection "Distinct quantum variables"

consts predicate_local_raw :: "predicate \<Rightarrow> variable_raw set \<Rightarrow> bool"
lemma predicate_local_raw_top: "predicate_local_raw top {}" 
  by (cheat predicate_local_raw_top)
lemma predicate_local_raw_bot: "predicate_local_raw bot {}" 
  by (cheat predicate_local_raw_bot)
lemma predicate_local_raw_inter: "predicate_local_raw A Q \<Longrightarrow> predicate_local_raw B Q \<Longrightarrow> predicate_local_raw (A\<sqinter>B) Q" 
  by (cheat predicate_local_raw_inter)
lemma predicate_local_raw_plus: "predicate_local_raw A Q \<Longrightarrow> predicate_local_raw B Q \<Longrightarrow> predicate_local_raw (A+B) Q" 
  by (cheat predicate_local_raw_plus)
lemma predicate_local_raw_ortho: "predicate_local_raw A Q \<Longrightarrow> predicate_local_raw (ortho A) Q" 
  by (cheat predicate_local_raw_ortho)
lemma predicate_local_raw_mono: "Q \<subseteq> Q' \<Longrightarrow> predicate_local_raw A Q \<Longrightarrow> predicate_local_raw A Q'"
  by (cheat predicate_local_raw_mono)
consts operator_local_raw :: "(mem2,mem2)bounded \<Rightarrow> variable_raw set \<Rightarrow> bool"
lemma predicate_local_raw_apply_op: "operator_local_raw U Q \<Longrightarrow> predicate_local_raw A Q \<Longrightarrow> predicate_local_raw (U\<cdot>A) Q" 
  by (cheat predicate_local_raw_apply_op)
lemma operator_local_raw_mono: "Q \<subseteq> Q' \<Longrightarrow> operator_local_raw A Q \<Longrightarrow> operator_local_raw A Q'" 
  by (cheat operator_local_raw_mono)

lift_definition colocal_pred_qvars :: "predicate \<Rightarrow> 'a::universe variables \<Rightarrow> bool"
  is "\<lambda>A (vs,_). \<exists>vs'. set (flatten_tree vs) \<inter> vs' = {} \<and> predicate_local_raw A vs'" .

lift_definition colocal_op_qvars :: "(mem2,mem2) bounded \<Rightarrow> 'a::universe variables \<Rightarrow> bool"
  is "\<lambda>A (vs,_). \<exists>vs'. set (flatten_tree vs) \<inter> vs' = {} \<and> operator_local_raw A vs'" .

lift_definition colocal_op_pred :: "(mem2,mem2) bounded \<Rightarrow> predicate \<Rightarrow> bool"
  is "\<lambda>A B. \<exists>vs1 vs2. vs1 \<inter> vs2 = {} \<and> operator_local_raw A vs1 \<and> predicate_local_raw B vs2" .

consts colocal :: "'a \<Rightarrow> 'b \<Rightarrow> bool"
adhoc_overloading colocal colocal_pred_qvars colocal_op_pred colocal_op_qvars (* colocal_qvars_qvars *)

lemma colocal_top[simp]: "distinct_qvars Q \<Longrightarrow> colocal_pred_qvars top Q"
  using [[transfer_del_const cr_subspace]]
  unfolding distinct_qvars_def apply transfer by (auto intro: predicate_local_raw_top exI[of _ "{}"])
lemma colocal_bot[simp]: "distinct_qvars Q \<Longrightarrow> colocal bot Q"
  using [[transfer_del_const cr_subspace]]
  unfolding distinct_qvars_def apply transfer by (auto intro: predicate_local_raw_bot exI[of _ "{}"])

lemma colocal_inf[simp]: assumes "colocal A Q" and "colocal B Q" shows "colocal (A \<sqinter> B) Q"
proof -
  obtain vsQ Qe where Q: "Rep_variables Q = (vsQ,Qe)" apply atomize_elim by simp
  from assms
  obtain vsA vsB where "set (flatten_tree vsQ) \<inter> vsA = {}" and "predicate_local_raw A vsA"
    and "set (flatten_tree vsQ) \<inter> vsB = {}" and "predicate_local_raw B vsB"
    apply atomize_elim unfolding colocal_pred_qvars.rep_eq unfolding Q by auto
  then show ?thesis
    unfolding colocal_pred_qvars.rep_eq Q apply simp
    apply (rule exI[of _ "vsA \<union> vsB"])
    by (auto intro: predicate_local_raw_mono intro!: predicate_local_raw_inter )
qed

lemma colocal_plus[simp]: 
  fixes A :: "_ subspace"
  assumes "colocal A Q" and "colocal B Q" shows "colocal (A + B) Q" 
proof -
  obtain vsQ Qe where Q: "Rep_variables Q = (vsQ,Qe)" apply atomize_elim by simp
  from assms
  obtain vsA vsB where "set (flatten_tree vsQ) \<inter> vsA = {}" and "predicate_local_raw A vsA"
    and "set (flatten_tree vsQ) \<inter> vsB = {}" and "predicate_local_raw B vsB"
    apply atomize_elim unfolding colocal_pred_qvars.rep_eq unfolding Q by auto
  then show ?thesis
    unfolding colocal_pred_qvars.rep_eq Q apply simp
    apply (rule exI[of _ "vsA \<union> vsB"])
    by (auto intro: predicate_local_raw_mono intro!: predicate_local_raw_plus)
qed

lemma colocal_sup[simp]: "colocal A Q \<Longrightarrow> colocal B Q \<Longrightarrow> colocal (A \<squnion> B) Q"
  unfolding subspace_sup_plus by simp
lemma colocal_Cla[simp]: "distinct_qvars Q \<Longrightarrow> colocal (Cla[b]) Q"
  by (cases b; simp)

lemma colocal_pred_qvars_mult[simp]:
  assumes "colocal_op_qvars U Q" and "colocal_pred_qvars S Q" shows "colocal_pred_qvars (U\<cdot>S) Q"
proof -
  obtain vsQ Qe where Q: "Rep_variables Q = (vsQ,Qe)" apply atomize_elim by simp
  from assms
  obtain vsU vsS where "set (flatten_tree vsQ) \<inter> vsU = {}" and "operator_local_raw U vsU"
    and "set (flatten_tree vsQ) \<inter> vsS = {}" and "predicate_local_raw S vsS"
    apply atomize_elim unfolding colocal_pred_qvars.rep_eq colocal_op_qvars.rep_eq unfolding Q by auto
  then show ?thesis
    unfolding colocal_pred_qvars.rep_eq Q apply simp
    apply (rule exI[of _ "vsU \<union> vsS"])
    by (auto intro: predicate_local_raw_mono operator_local_raw_mono intro!: predicate_local_raw_apply_op)
qed

lemma colocal_ortho[simp]: "colocal (ortho S) Q = colocal S Q"
proof -
  have "colocal (ortho S) Q" if "colocal S Q" for S
  proof -
    obtain vsQ Qe where Q: "Rep_variables Q = (vsQ,Qe)" apply atomize_elim by simp
    from that
    obtain vsS where "set (flatten_tree vsQ) \<inter> vsS = {}" and "predicate_local_raw S vsS"
      apply atomize_elim unfolding colocal_pred_qvars.rep_eq unfolding Q by auto
    then show ?thesis
      unfolding colocal_pred_qvars.rep_eq Q apply simp
      apply (rule exI[of _ vsS])
      by (auto intro: intro!: predicate_local_raw_ortho)
  qed
  from this this[where S="ortho S"]
  show ?thesis 
    by auto
qed

subsection \<open>Lifting\<close>

consts
    liftOp :: "('a,'a) bounded \<Rightarrow> 'a::universe variables \<Rightarrow> (mem2,mem2) bounded"
    liftSpace :: "'a subspace \<Rightarrow> 'a::universe variables \<Rightarrow> predicate"


consts lift :: "'a \<Rightarrow> 'b \<Rightarrow> 'c" ("_\<guillemotright>_"  [91,91] 90)
syntax lift :: "'a \<Rightarrow> 'b \<Rightarrow> 'c" ("_>>_"  [91,91] 90)
adhoc_overloading
  lift liftOp liftSpace

lemma adjoint_lift[simp]: "adjoint (liftOp U Q) = liftOp (adjoint U) Q" 
  by (cheat TODO10)

lemma imageOp_lift[simp]: "applyOpSpace (liftOp U Q) top = liftSpace (applyOpSpace U top) Q"
  by (cheat TODO10)
lemma applyOpSpace_lift[simp]: "applyOpSpace (liftOp U Q) (liftSpace S Q) = liftSpace (applyOpSpace U S) Q"
  by (cheat TODO10)
lemma top_lift[simp]: "liftSpace top Q = top"
  by (cheat TODO10)
lemma bot_lift[simp]: "liftSpace bot Q = bot"
  by (cheat TODO10)
lemma unitary_lift[simp]: "unitary (liftOp U Q) = unitary U"
  by (cheat TODO10)
(* for U :: "('a::universe,'a) bounded" *)

lemma lift_inf[simp]: "S\<guillemotright>Q \<sqinter> T\<guillemotright>Q = (S \<sqinter> T)\<guillemotright>Q" for S::"'a::universe subspace"
  by (cheat TODO11)
lemma lift_leq[simp]: "(S\<guillemotright>Q \<le> T\<guillemotright>Q) = (S \<le> T)" for S::"'a::universe subspace"
  by (cheat TODO11)
lemma lift_eqSp[simp]: "(S\<guillemotright>Q = T\<guillemotright>Q) = (S = T)" for S T :: "'a::universe subspace" 
  by (cheat TODO11)
lemma lift_eqOp[simp]: "distinct_qvars Q \<Longrightarrow> (S\<guillemotright>Q = T\<guillemotright>Q) = (S = T)" for S T :: "('a::universe,'a) bounded" 
  by (cheat TODO11)
lemma lift_timesScalarOp[simp]: "distinct_qvars Q \<Longrightarrow> a \<cdot> (A\<guillemotright>Q) = (a \<cdot> A)\<guillemotright>Q" for a::complex and A::"('a::universe,'a)bounded"
  by (cheat TODO11)
lemma lift_plus[simp]: "distinct_qvars Q \<Longrightarrow> S\<guillemotright>Q + T\<guillemotright>Q = (S + T)\<guillemotright>Q" for S T :: "'a::universe subspace"  
  by (cheat TODO11)
lemma lift_plusOp[simp]: "distinct_qvars Q \<Longrightarrow> S\<guillemotright>Q + T\<guillemotright>Q = (S + T)\<guillemotright>Q" for S T :: "('a::universe,'a) bounded"  
  by (cheat TODO11)
lemma lift_uminusOp[simp]: "distinct_qvars Q \<Longrightarrow> - (T\<guillemotright>Q) = (- T)\<guillemotright>Q" for T :: "('a::universe,'a) bounded"  
  unfolding uminus_bounded_def by simp
lemma lift_minusOp[simp]: "distinct_qvars Q \<Longrightarrow> S\<guillemotright>Q - T\<guillemotright>Q = (S - T)\<guillemotright>Q" for S T :: "('a::universe,'a) bounded"  
  unfolding minus_bounded_def by simp
lemma lift_timesOp[simp]: "distinct_qvars Q \<Longrightarrow> S\<guillemotright>Q \<cdot> T\<guillemotright>Q = (S \<cdot> T)\<guillemotright>Q" for S T :: "('a::universe,'a) bounded"  
  by (cheat TODO11)
lemma lift_ortho[simp]: "distinct_qvars Q \<Longrightarrow> ortho (S\<guillemotright>Q) = (ortho S)\<guillemotright>Q" for Q :: "'a::universe variables"
  by (cheat TODO11)
lemma lift_tensorOp: "distinct_qvars (variable_concat Q R) \<Longrightarrow> (S\<guillemotright>Q) \<cdot> (T\<guillemotright>R) = (S \<otimes> T)\<guillemotright>variable_concat Q R" for Q :: "'a::universe variables" and R :: "'b::universe variables" and S T :: "(_,_) bounded" 
  by (cheat TODO11)
lemma lift_tensorSpace: "distinct_qvars (variable_concat Q R) \<Longrightarrow> (S\<guillemotright>Q) = (S \<otimes> top)\<guillemotright>variable_concat Q R" for Q :: "'a::universe variables" and R :: "'b::universe variables" and S :: "_ subspace" 
  by (cheat TODO11)
lemma lift_idOp[simp]: "idOp\<guillemotright>Q = idOp" for Q :: "'a::universe variables"
  by (cheat TODO11)
lemma INF_lift: "distinct_qvars Q \<Longrightarrow> (INF x. S x\<guillemotright>Q) = (INF x. S x)\<guillemotright>Q" for Q::"'a::universe variables" and S::"'b \<Rightarrow> 'a subspace"
  by (cheat TODO11)
lemma Cla_inf_lift: "distinct_qvars Q \<Longrightarrow> Cla[b] \<sqinter> (S\<guillemotright>Q) = (if b then S else bot)\<guillemotright>Q" by auto
lemma Cla_plus_lift: "distinct_qvars Q \<Longrightarrow> Cla[b] + (S\<guillemotright>Q) = (if b then top else S)\<guillemotright>Q" by auto
lemma Proj_lift[simp]: "distinct_qvars Q \<Longrightarrow> Proj (S\<guillemotright>Q) = (Proj S)\<guillemotright>Q"
  for Q::"'a::universe variables"
  by (cheat TODO11)
lemma kernel_lift[simp]: "distinct_qvars Q \<Longrightarrow> kernel (A\<guillemotright>Q) = (kernel A)\<guillemotright>Q" for Q::"'a::universe variables"
  by (cheat TODO11)
lemma eigenspace_lift[simp]: "distinct_qvars Q \<Longrightarrow> eigenspace a (A\<guillemotright>Q) = (eigenspace a A)\<guillemotright>Q" for Q::"'a::universe variables"
  unfolding eigenspace_def apply (subst lift_idOp[symmetric, of Q]) by (simp del: lift_idOp)

lemma top_leq_lift: "top \<le> S\<guillemotright>Q \<longleftrightarrow> top \<le> S" 
  apply (subst top_lift[symmetric]) apply (subst lift_leq) by simp
lemma top_geq_lift: "top \<ge> S\<guillemotright>Q \<longleftrightarrow> top \<ge> S" 
  apply (subst top_lift[symmetric]) apply (subst lift_leq) by simp
lemma bot_leq_lift: "bot \<le> S\<guillemotright>Q \<longleftrightarrow> bot \<le> S" 
  apply (subst bot_lift[symmetric]) apply (subst lift_leq) by simp
lemma bot_geq_lift: "bot \<ge> S\<guillemotright>Q \<longleftrightarrow> bot \<ge> S" 
  apply (subst bot_lift[symmetric]) apply (subst lift_leq) by simp
lemma top_eq_lift: "top = S\<guillemotright>Q \<longleftrightarrow> top = S" 
  apply (subst top_lift[symmetric]) apply (subst lift_eqSp) by simp
lemma bot_eq_lift: "bot = S\<guillemotright>Q \<longleftrightarrow> bot = S" 
  apply (subst bot_lift[symmetric]) apply (subst lift_eqSp) by simp
lemma top_eq_lift2: "S\<guillemotright>Q = top \<longleftrightarrow> S = top" 
  apply (subst top_lift[symmetric]) apply (subst lift_eqSp) by simp
lemma bot_eq_lift2: "S\<guillemotright>Q = bot \<longleftrightarrow> S = bot" 
  apply (subst bot_lift[symmetric]) apply (subst lift_eqSp) by simp


lemma remove_qvar_unit_op:
  "(remove_qvar_unit_op \<cdot> A \<cdot> remove_qvar_unit_op*)\<guillemotright>Q = A\<guillemotright>(variable_concat Q \<lbrakk>\<rbrakk>)"
for A::"(_,_)bounded" and Q::"'a::universe variables"
  by (cheat TODO12)


lemma colocal_op_pred_lift1[simp]:
 "colocal S Q \<Longrightarrow> colocal (U\<guillemotright>Q) S"
for Q :: "'a::universe variables" and U :: "('a,'a) bounded" and S :: predicate
  by (cheat TODO12)

lemma colocal_op_qvars_lift1[simp]:
  "distinct_qvars (variable_concat Q R) \<Longrightarrow> colocal (U\<guillemotright>Q) R"
for Q :: "'a::universe variables" and R :: "'b::universe variables" and U :: "('a,'a) bounded"  
  by (cheat TODO12)

lemma colocal_pred_qvars_lift1[simp]:
  "distinct_qvars (variable_concat Q R) \<Longrightarrow> colocal_pred_qvars (S\<guillemotright>Q) R"
for Q :: "'a::universe variables" and R :: "'b::universe variables"
  by (cheat TODO12)

lemma lift_extendR:
  assumes "distinct_qvars (variable_concat Q R)"
  shows "U\<guillemotright>Q = (U\<otimes>idOp)\<guillemotright>(variable_concat Q R)"
  by (metis assms lift_idOp lift_tensorOp times_idOp1)

lemma lift_extendL:
  assumes "distinct_qvars (variable_concat Q R)"
  shows "U\<guillemotright>Q = (idOp\<otimes>U)\<guillemotright>(variable_concat R Q)"
  by (metis assms distinct_qvars_swap lift_idOp lift_tensorOp times_idOp2)

lemma move_plus_meas_rule:
  fixes Q::"'a::universe variables"
  assumes "distinct_qvars Q"
  assumes "(Proj C)\<guillemotright>Q \<cdot> A \<le> B"
  shows "A \<le> (B\<sqinter>C\<guillemotright>Q) + (ortho C)\<guillemotright>Q"
  apply (rule move_plus) 
  using Proj_leq[of "C\<guillemotright>Q"] assms by simp


subsection "Rewriting quantum variable lifting"


(* Means that operator A can be used to transform an expression \<dots>\<guillemotright>Q into \<dots>\<guillemotright>R *)
definition "qvar_trafo A Q R = (distinct_qvars Q \<and> distinct_qvars R \<and> (\<forall>C::(_,_)bounded. C\<guillemotright>Q = (A\<cdot>C\<cdot>A*)\<guillemotright>R))" for A::"('a::universe,'b::universe) bounded"

lemma qvar_trafo_id[simp]: "distinct_qvars Q \<Longrightarrow> qvar_trafo idOp Q Q" unfolding qvar_trafo_def by auto

(* Auxiliary lemma, will be removed after generalizing to qvar_trafo_unitary *)
lemma qvar_trafo_coiso: assumes "qvar_trafo A Q R" shows "A \<cdot> A* = idOp"
proof -
  have colocalQ: "distinct_qvars Q" and colocalR: "distinct_qvars R" using assms unfolding qvar_trafo_def by auto
  have "idOp\<guillemotright>Q = (A \<cdot> idOp \<cdot> A*)\<guillemotright>R"
    using assms unfolding qvar_trafo_def by auto 
  hence "idOp\<guillemotright>R = (A \<cdot> A*)\<guillemotright>R" by auto
  hence "idOp = A \<cdot> A*" apply (subst lift_eqOp[symmetric])
    using colocalR by auto
  then show ?thesis ..
qed

lemma qvar_trafo_adj[simp]: assumes "qvar_trafo A Q R" shows "qvar_trafo (A*) R Q"
proof (unfold qvar_trafo_def, auto)
  show colocalQ: "distinct_qvars Q" and colocalR: "distinct_qvars R" using assms unfolding qvar_trafo_def by auto
  show "C\<guillemotright>R = (A* \<cdot> C \<cdot> A)\<guillemotright>Q" for C::"(_,_)bounded"
  proof -
    have "(A* \<cdot> C \<cdot> A)\<guillemotright>Q = (A \<cdot> (A* \<cdot> C \<cdot> A) \<cdot> A*)\<guillemotright>R"
      using assms unfolding qvar_trafo_def by auto 
    also have "\<dots> = ((A \<cdot> A*) \<cdot> C \<cdot> (A \<cdot> A*)*)\<guillemotright>R"
      by (simp add: timesOp_assoc)
    also have "\<dots> = C\<guillemotright>R" apply (subst qvar_trafo_coiso[OF assms])+ by auto 
    finally show ?thesis ..
  qed
qed

lemma qvar_trafo_unitary:
  assumes "qvar_trafo A Q R"
  shows "unitary A"
proof -
  have "qvar_trafo (A*) R Q"
    using assms by (rule qvar_trafo_adj)
  hence "(A*) \<cdot> (A*)* = idOp" by (rule qvar_trafo_coiso)
  hence "A* \<cdot> A = idOp" by simp
  also have "A \<cdot> A* = idOp"
    using assms by (rule qvar_trafo_coiso)
  ultimately show ?thesis unfolding unitary_def by simp
qed

hide_fact qvar_trafo_coiso (* Subsumed by qvar_trafo_unitary *)

lemma assoc_op_lift: "(assoc_op \<cdot> A \<cdot> assoc_op*)\<guillemotright>(variable_concat (variable_concat Q R) T)
     = A\<guillemotright>(variable_concat Q (variable_concat R T))" for A::"('a::universe*'b::universe*'c::universe,_)bounded" 
  by (cheat TODO12)
lemma comm_op_lift: "(comm_op \<cdot> A \<cdot> comm_op*)\<guillemotright>(variable_concat Q R)
     = A\<guillemotright>(variable_concat R Q)" for A::"('a::universe*'b::universe,_)bounded" 
  by (cheat TODO12)
lemma lift_tensor_id: "distinct_qvars (variable_concat Q R) \<Longrightarrow> distinct_qvars (variable_concat Q R) \<Longrightarrow>
   (\<And>D::(_,_) bounded. (A \<cdot> D \<cdot> A*)\<guillemotright>Q = D\<guillemotright>Q') \<Longrightarrow> (\<And>D::(_,_) bounded. (A' \<cdot> D \<cdot> A'*)\<guillemotright>R = D\<guillemotright>R') \<Longrightarrow> 
  ((A\<otimes>A') \<cdot> C \<cdot> (A\<otimes>A')*)\<guillemotright>variable_concat Q R = C\<guillemotright>variable_concat Q' R'"
  for A :: "('a::universe,'b::universe) bounded" and A' :: "('c::universe,'d::universe) bounded" and C::"(_,_) bounded" and Q R :: "_ variables"
  by (cheat lift_tensor_id)


lemma qvar_trafo_assoc_op[simp]:
  assumes "distinct_qvars (variable_concat Q (variable_concat R T))"
  shows "qvar_trafo assoc_op (variable_concat Q (variable_concat R T))  (variable_concat (variable_concat Q R) T)"
proof (unfold qvar_trafo_def, auto)
  show "distinct_qvars (variable_concat Q (variable_concat R T))" and "distinct_qvars (variable_concat (variable_concat Q R) T)"
    using assms by (auto intro: distinct_qvars_swap simp: distinct_qvars_split1 distinct_qvars_split2)
  show "C\<guillemotright>variable_concat Q (variable_concat R T) = (assoc_op \<cdot> C \<cdot> assoc_op*)\<guillemotright>variable_concat (variable_concat Q R) T" for C::"(_,_)bounded"
    by (rule assoc_op_lift[symmetric])
qed


lemma qvar_trafo_comm_op[simp]:
  assumes "distinct_qvars (variable_concat Q R)"
  shows "qvar_trafo comm_op (variable_concat Q R) (variable_concat R Q)"
proof (unfold qvar_trafo_def, auto simp del: adj_comm_op)
  show "distinct_qvars (variable_concat Q R)" and "distinct_qvars (variable_concat R Q)"
    using assms by (auto intro: distinct_qvars_swap)
  show "C\<guillemotright>variable_concat Q R = (comm_op \<cdot> C \<cdot> comm_op*)\<guillemotright>variable_concat R Q" for C::"(_,_)bounded"
    by (rule comm_op_lift[symmetric])
qed

lemma qvar_trafo_bounded:
  fixes C::"(_,_) bounded"
  assumes "qvar_trafo A Q R"
  shows "C\<guillemotright>Q = (A\<cdot>C\<cdot>A*)\<guillemotright>R"
  using assms unfolding qvar_trafo_def by auto

lemma qvar_trafo_subspace:
  fixes S::"'a::universe subspace"
  assumes "qvar_trafo A Q R"
  shows "S\<guillemotright>Q = (A\<cdot>S)\<guillemotright>R"
proof -
  define C where "C = Proj S"
  have "S\<guillemotright>Q = (Proj S \<cdot> top)\<guillemotright>Q" by simp
  also have "\<dots> = (Proj S)\<guillemotright>Q \<cdot> top" by simp
  also have "\<dots> = (A \<cdot> Proj S \<cdot> A*)\<guillemotright>R \<cdot> top"
    apply (subst qvar_trafo_bounded) using assms by auto
  also have "\<dots> = (Proj (A\<cdot>S))\<guillemotright>R \<cdot> top" apply (subst Proj_times) by simp
  also have "\<dots> = (Proj (A\<cdot>S) \<cdot> top)\<guillemotright>R" by auto
  also have "\<dots> = (A\<cdot>S)\<guillemotright>R" by auto
  ultimately show ?thesis by simp
qed

lemma qvar_trafo_mult:
  assumes "qvar_trafo A Q R"
    and "qvar_trafo B R S"
  shows "qvar_trafo (B\<cdot>A) Q S"
proof (unfold qvar_trafo_def, auto)
  show colocalQ: "distinct_qvars Q" and colocalS: "distinct_qvars S" using assms unfolding qvar_trafo_def by auto
  show "C\<guillemotright>Q = (B \<cdot> A \<cdot> C \<cdot> (A* \<cdot> B*))\<guillemotright>S" for C::"(_,_) bounded"
  proof -
    have "C\<guillemotright>Q = (A \<cdot> C \<cdot> A*)\<guillemotright>R" apply (rule qvar_trafo_bounded) using assms by simp
    also have "\<dots> = (B \<cdot> (A \<cdot> C \<cdot> A*) \<cdot> B*)\<guillemotright>S" apply (rule qvar_trafo_bounded) using assms by simp
    also have "\<dots> = (B \<cdot> A \<cdot> C \<cdot> (A* \<cdot> B*))\<guillemotright>S" using timesOp_assoc by metis
    finally show ?thesis .
  qed
qed

lemma qvar_trafo_tensor:
  assumes "distinct_qvars (variable_concat Q Q')"
    and "distinct_qvars (variable_concat R R')"
    and "qvar_trafo A Q R"
    and "qvar_trafo A' Q' R'"
  shows "qvar_trafo (A\<otimes>A') (variable_concat Q Q') (variable_concat R R')"
proof (unfold qvar_trafo_def, (rule conjI[rotated])+, rule allI)
  show "distinct_qvars (variable_concat Q Q')" and "distinct_qvars (variable_concat R R')"
    using assms unfolding qvar_trafo_def by auto
  show "C\<guillemotright>variable_concat Q Q' = ((A \<otimes> A') \<cdot> C \<cdot> (A \<otimes> A')*)\<guillemotright>variable_concat R R'" for C::"(_,_)bounded"
    apply (rule lift_tensor_id[symmetric])
    using assms unfolding qvar_trafo_def by auto
qed


(* A hint to the simplifier with the meaning:
    - A is a term of the form x>>Q
    - R is an explicit distinct varterm containing all variables in Q
    - Q is an explicit distinct varterm
    - The whole term should be rewritten into x'>>R for some x'
  Rewriting the term is done by the simproc variable_rewriting_simproc declared below.
*)
definition "reorder_variables_hint A R = A"
lemma [cong]: "A=A' \<Longrightarrow> reorder_variables_hint A R = reorder_variables_hint A' R" by simp

lemma reorder_variables_hint_remove_aux: "reorder_variables_hint x R \<equiv> x" \<comment> \<open>Auxiliary lemma used by reorder_variables_hint_conv\<close>
  unfolding reorder_variables_hint_def by simp

(* Tells the simplifier the following:
    - A is of the form x\<guillemotright>Q
    - Q,R are both explicit distinct variable terms
    - the term should be rewritten into x'\<guillemotright>(variable_concat Q' R) for some Q', x'
*)
definition "extend_lift_as_var_concat_hint A R = A"
lemma [cong]: "A=A' \<Longrightarrow> extend_lift_as_var_concat_hint A R = extend_lift_as_var_concat_hint A' R" by simp
lemma extend_lift_as_var_concat_hint_remove_aux: "extend_lift_as_var_concat_hint A R \<equiv> A"
  by (simp add: extend_lift_as_var_concat_hint_def)


(* A hint to the simplifier with the meaning:
     - x is a term of the form x'>>Q (where x' is of type subspace or bounded)
     - qvar_trafo A Q R holds (i.e., should be produced as a precondition when rewriting)
     - the whole term should be rewritten into y'>>R for some y' 
  Rewriting the term is done by the simplifier rules declared below.
*)
definition "variable_renaming_hint x (A::('a,'b) bounded) (R::'b::universe variables) = x"
lemma [cong]: "x=x' \<Longrightarrow> variable_renaming_hint x A R = variable_renaming_hint x' A R" by simp

(* A copy of qvars_trafo that is protected from unintentional rewriting *)
definition "qvar_trafo_protected = qvar_trafo"
lemma [cong]: "qvar_trafo_protected A Q R = qvar_trafo_protected A Q R" ..

lemma variable_renaming_hint_subspace[simp]:
  fixes S::"_ subspace"
  assumes "qvar_trafo_protected A Q R"
  shows "variable_renaming_hint (S\<guillemotright>Q) A R = (A\<cdot>S)\<guillemotright>R"
  using assms unfolding variable_renaming_hint_def qvar_trafo_protected_def by (rule qvar_trafo_subspace)

lemma variable_renaming_hint_bounded[simp]:
  fixes S::"(_,_) bounded"
  assumes "qvar_trafo_protected A Q R"
  shows "variable_renaming_hint (S\<guillemotright>Q) A R = (A\<cdot>S\<cdot>A*)\<guillemotright>R"
  using assms unfolding variable_renaming_hint_def qvar_trafo_protected_def by (rule qvar_trafo_bounded)


lemma extend_space_lift_aux: \<comment> \<open>Auxiliary lemma for extend_lift_conv\<close>
  fixes Q :: "'q::universe variables" and R :: "'r::universe variables"
    and S :: "'q subspace"
  assumes "distinct_qvars (variable_concat Q R)"
  shows "S\<guillemotright>Q \<equiv> (S\<otimes>top)\<guillemotright>(variable_concat Q R)"
  apply (rule eq_reflection)
  using assms by (rule lift_tensorSpace)


lemma extend_bounded_lift_aux: \<comment> \<open>Auxiliary lemma for extend_lift_conv\<close>
  fixes Q :: "'q::universe variables" and R :: "'r::universe variables"
    and S :: "('q,'q) bounded"
  assumes "distinct_qvars (variable_concat Q R)"
  shows "S\<guillemotright>Q \<equiv> (S\<otimes>idOp)\<guillemotright>(variable_concat Q R)"
  apply (rule eq_reflection)
  using assms lift_extendR by blast

lemma trafo_lift_space_aux: \<comment> \<open>Auxiliary lemma for sort_lift_conv\<close>
  fixes S::"_ subspace"
  assumes "qvar_trafo_protected A Q R"
  shows "S\<guillemotright>Q \<equiv> (A\<cdot>S)\<guillemotright>R"
  apply (rule eq_reflection)
  using assms unfolding qvar_trafo_protected_def by (rule qvar_trafo_subspace)

lemma trafo_lift_bounded_aux: \<comment> \<open>Auxiliary lemma for sort_lift_conv\<close>
  fixes S::"(_,_) bounded"
  assumes "qvar_trafo_protected A Q R"
  shows "S\<guillemotright>Q \<equiv> (A\<cdot>S\<cdot>A*)\<guillemotright>R"
  apply (rule eq_reflection)
  using assms unfolding qvar_trafo_protected_def by (rule qvar_trafo_bounded)

lemma trafo_lift_space_bw_aux: \<comment> \<open>Auxiliary lemma for reorder_lift_conv\<close>
  fixes S::"_ subspace"
  assumes "qvar_trafo_protected A Q R"
  shows "S\<guillemotright>R \<equiv> (A*\<cdot>S)\<guillemotright>Q"
  apply (rule eq_reflection)
  using qvar_trafo_adj[OF assms[unfolded qvar_trafo_protected_def]]
  using qvar_trafo_subspace by blast

lemma trafo_lift_bounded_bw_aux: \<comment> \<open>Auxiliary lemma for reorder_lift_conv\<close>
  fixes S::"(_,_) bounded"
  assumes "qvar_trafo_protected A Q R"
  shows "S\<guillemotright>R \<equiv> (A*\<cdot>S\<cdot>A)\<guillemotright>Q"
  apply (rule eq_reflection)
  using qvar_trafo_bounded[OF qvar_trafo_adj[OF assms[unfolded qvar_trafo_protected_def]]]
  by simp
  




(* A hint to the simplifier with the meaning:
     - x is a term of the form x'>>Q (where x' is of type subspace or bounded)
     - colocal Q R holds (i.e., should be produced as a precondition when rewriting)
     - the whole term should be rewritten into y'>>variable_concat Q R for some y'
  Rewriting the term is done by the variable_rewriting simproc.
 *)
(* TODO: we might not need this if we reimplement the various conversions *)
definition "variable_extension_hint x (R::_ variables) = x"


lemma variable_extension_hint_subspace[simp]:
  fixes S::"_ subspace"
  assumes "distinct_qvars (variable_concat Q R)"
  shows "variable_extension_hint (S\<guillemotright>Q) R = (S\<otimes>top)\<guillemotright>variable_concat Q R"
  unfolding variable_extension_hint_def 
  using assms by (rule lift_tensorSpace)

lemma variable_extension_hint_bounded[simp]:
  fixes S::"(_,_) bounded"
  assumes "distinct_qvars (variable_concat Q R)"
  shows "variable_extension_hint (S\<guillemotright>Q) R = (S\<otimes>idOp)\<guillemotright>variable_concat Q R"
  unfolding variable_extension_hint_def 
  using assms
  by (metis lift_idOp lift_tensorOp times_idOp1)


(* Hint for the simplifier, meaning that:
    - x is of the form x'\<guillemotright>Q
    - colocal Q [], colocal R [] holds
    - the whole expression should be rewritten to x'\<guillemotright>Q\<otimes>R' such that Q\<otimes>R' has the same variables as Q\<otimes>R (duplicates removed)
  Rewriting the term is done by the simplifier rules declared below.
*)
definition "join_variables_hint x (R::'a::universe variables) = x"

lemma add_join_variables_hint: 
  fixes Q :: "'a::universe variables" and R :: "'b::universe variables" 
    and S :: "'a subspace" and T :: "'b subspace"
    and A :: "('a,'a) bounded" and B :: "('b,'b) bounded"
  shows "NO_MATCH (a,a) (Q,R) \<Longrightarrow> S\<guillemotright>Q \<sqinter> T\<guillemotright>R = join_variables_hint (S\<guillemotright>Q) R \<sqinter> join_variables_hint (T\<guillemotright>R) Q"
    and "NO_MATCH (a,a) (Q,R) \<Longrightarrow> S\<guillemotright>Q + T\<guillemotright>R = join_variables_hint (S\<guillemotright>Q) R + join_variables_hint (T\<guillemotright>R) Q"
    and "NO_MATCH (a,a) (Q,R) \<Longrightarrow> A\<guillemotright>Q \<cdot> T\<guillemotright>R = join_variables_hint (A\<guillemotright>Q) R \<cdot> join_variables_hint (T\<guillemotright>R) Q"
    and "NO_MATCH (a,a) (Q,R) \<Longrightarrow> (S\<guillemotright>Q \<le> T\<guillemotright>R) = (join_variables_hint (S\<guillemotright>Q) R \<le> join_variables_hint (T\<guillemotright>R) Q)"
    and "NO_MATCH (a,a) (Q,R) \<Longrightarrow> (S\<guillemotright>Q = T\<guillemotright>R) = (join_variables_hint (S\<guillemotright>Q) R = join_variables_hint (T\<guillemotright>R) Q)"
    and "NO_MATCH (a,a) (Q,R) \<Longrightarrow> (A\<guillemotright>Q = B\<guillemotright>R) = (join_variables_hint (A\<guillemotright>Q) R = join_variables_hint (B\<guillemotright>R) Q)"
    and "NO_MATCH (a,a) (Q,R) \<Longrightarrow> (A\<guillemotright>Q + B\<guillemotright>R) = (join_variables_hint (A\<guillemotright>Q) R + join_variables_hint (B\<guillemotright>R) Q)"
    and "NO_MATCH (a,a) (Q,R) \<Longrightarrow> (A\<guillemotright>Q - B\<guillemotright>R) = (join_variables_hint (A\<guillemotright>Q) R - join_variables_hint (B\<guillemotright>R) Q)"
    and "NO_MATCH (a,a) (Q,R) \<Longrightarrow> (A\<guillemotright>Q \<cdot> B\<guillemotright>R) = (join_variables_hint (A\<guillemotright>Q) R \<cdot> join_variables_hint (B\<guillemotright>R) Q)"
  unfolding join_variables_hint_def by simp_all



(* Hint for the simplifier, meaning that:
    - x is of the form x'>>Q
    - colocal Q \<lbrakk>\<rbrakk> holds
    - the whole expression should be rewritten to y'>>Q' where Q' is a sorted variable list
  Rewriting the term is done by the variable_rewriting simproc.
 *)
definition "sort_variables_hint x = x"

lemma join_variables_hint_subspace_conv_aux:
  "join_variables_hint (S\<guillemotright>Q) R \<equiv> sort_variables_hint (variable_extension_hint (S\<guillemotright>Q) R')" for S::"_ subspace"
  unfolding join_variables_hint_def variable_extension_hint_def sort_variables_hint_def by simp

lemma join_variables_hint_bounded_conv_aux:
  "join_variables_hint (S\<guillemotright>Q) R \<equiv> sort_variables_hint (variable_extension_hint (S\<guillemotright>Q) R')" for S::"(_,_) bounded"
  unfolding join_variables_hint_def variable_extension_hint_def sort_variables_hint_def by simp

lemma sort_variables_hint_subspace_conv_aux:
  "sort_variables_hint (S\<guillemotright>Q) \<equiv> variable_renaming_hint (S\<guillemotright>Q) A R'" for S::"_ subspace"
  unfolding variable_renaming_hint_def sort_variables_hint_def by simp

lemma sort_variables_hint_bounded_conv_aux:
  "sort_variables_hint (S\<guillemotright>Q) \<equiv> variable_renaming_hint (S\<guillemotright>Q) A R'" for S::"(_,_) bounded"
  unfolding variable_renaming_hint_def sort_variables_hint_def by simp

lemma sort_variables_hint_remove_aux: "sort_variables_hint x \<equiv> x" 
  unfolding sort_variables_hint_def by simp


(* For convenience in ML code *)
definition [simp]: "comm_op_pfx = assoc_op* \<cdot> (comm_op\<otimes>idOp) \<cdot> assoc_op"
definition [simp]: "id_tensor A = idOp\<otimes>A"
definition [simp]: "assoc_op_adj = assoc_op*"
definition [simp]: "remove_qvar_unit_op2 = remove_qvar_unit_op \<cdot> comm_op"
definition [simp]: "qvar_trafo_mult (Q::'b::universe variables) (B::('b,'c)bounded) (A::('a,'b)bounded) = timesOp B A"


lemma qvar_trafo_protected_mult[simp]: 
  "qvar_trafo_protected A Q R \<Longrightarrow> qvar_trafo_protected B R S \<Longrightarrow> qvar_trafo_protected (qvar_trafo_mult R B A) Q S"
  unfolding qvar_trafo_protected_def apply simp by (rule qvar_trafo_mult)

lemma qvar_trafo_protected_adj_assoc_op[simp]:
  "distinct_qvars (variable_concat Q (variable_concat R T)) \<Longrightarrow>
    qvar_trafo_protected assoc_op_adj (variable_concat (variable_concat Q R) T)
                                      (variable_concat Q (variable_concat R T))"
  unfolding qvar_trafo_protected_def by simp 

lemma qvar_trafo_protected_assoc_op[simp]:
  "distinct_qvars (variable_concat Q (variable_concat R T)) \<Longrightarrow>
    qvar_trafo_protected assoc_op (variable_concat Q (variable_concat R T))
                                  (variable_concat (variable_concat Q R) T)"
  unfolding qvar_trafo_protected_def by simp 

lemma qvar_trafo_protected_comm_op_pfx[simp]:
  assumes [simp]: "distinct_qvars (variable_concat Q (variable_concat R T))"
  shows "qvar_trafo_protected comm_op_pfx
         (variable_concat Q (variable_concat R T))
         (variable_concat R (variable_concat Q T))"
proof -
  have [simp]: "distinct_qvars (variable_concat Q R)" 
   and [simp]: "distinct_qvars (variable_concat (variable_concat R Q) T)"
   and [simp]: "distinct_qvars (variable_concat (variable_concat Q R) T)"
   and [simp]: "distinct_qvars (variable_concat R (variable_concat Q T)) "
   and [simp]: "distinct_qvars T" 
    using assms by (auto simp: distinct_qvars_split1 distinct_qvars_split2 intro: distinct_qvars_swap distinct_qvarsL)
  show ?thesis
  unfolding qvar_trafo_protected_def comm_op_pfx_def
  apply (rule qvar_trafo_mult[where R="variable_concat (variable_concat Q R) T"])
   apply simp
  apply (rule qvar_trafo_mult[where R="variable_concat (variable_concat R Q) T"])
   apply (rule qvar_trafo_tensor)
  by simp_all
qed

lemma qvar_trafo_protected_remove_qvar_unit_op[simp]:
  assumes "distinct_qvars Q"
  shows "qvar_trafo_protected (remove_qvar_unit_op) (variable_concat Q \<lbrakk>\<rbrakk>) Q"
  unfolding qvar_trafo_protected_def qvar_trafo_def
  by (auto simp: assms remove_qvar_unit_op)

lemma qvar_trafo_protected_remove_qvar_unit_op2[simp]:
  assumes [simp]: "distinct_qvars Q"
  shows "qvar_trafo_protected (remove_qvar_unit_op2) (variable_concat \<lbrakk>\<rbrakk> Q) Q"
  unfolding qvar_trafo_protected_def remove_qvar_unit_op2_def
  apply (rule qvar_trafo_mult)
   apply (rule qvar_trafo_comm_op)
   apply simp
  unfolding qvar_trafo_def
  by (auto simp: remove_qvar_unit_op)


lemma qvar_trafo_protecterd_id_tensor[simp]:
  assumes [simp]: "distinct_qvars (variable_concat Q R)" and [simp]: "distinct_qvars (variable_concat Q R')"
    and "qvar_trafo_protected A R R'"
  shows "qvar_trafo_protected (id_tensor A) (variable_concat Q R) (variable_concat Q R')"
  unfolding qvar_trafo_protected_def id_tensor_def
  apply (rule qvar_trafo_tensor)
     apply simp_all[2]
   apply (rule qvar_trafo_id)
  using assms(2) apply (rule distinct_qvarsL) 
  using assms(3) unfolding qvar_trafo_protected_def by assumption

lemma qvar_trafo_protecterd_comm_op[simp]:
  assumes [simp]: "distinct_qvars (variable_concat Q R)"
  shows "qvar_trafo_protected comm_op (variable_concat Q R) (variable_concat R Q)"
  unfolding qvar_trafo_protected_def by simp                                                  
 
section \<open>Measurements\<close>

typedecl ('a,'b) measurement
consts mproj :: "('a,'b) measurement \<Rightarrow> 'a \<Rightarrow> ('b,'b) bounded"
       mtotal :: "('a,'b) measurement \<Rightarrow> bool"
lemma isProjector_mproj[simp]: "isProjector (mproj M i)"
  by (cheat TODO13)

consts computational_basis :: "('a, 'a) measurement"
lemma mproj_computational_basis[simp]: "mproj computational_basis x = proj (ket x)"
  by (cheat TODO13)
lemma mtotal_computational_basis [simp]: "mtotal computational_basis"
  by (cheat TODO13)


section \<open>Quantum predicates (ctd.)\<close>

subsection \<open>Subspace division\<close>

consts space_div :: "predicate \<Rightarrow> 'a vector \<Rightarrow> 'a::universe variables \<Rightarrow> predicate"
                    ("_ \<div> _\<guillemotright>_" [89,89,89] 90)
lemma leq_space_div[simp]: "colocal A Q \<Longrightarrow> (A \<le> B \<div> \<psi>\<guillemotright>Q) = (A \<sqinter> span {\<psi>}\<guillemotright>Q \<le> B)"
  by (cheat TODO14)

definition space_div_unlifted :: "('a*'b) subspace \<Rightarrow> 'b vector \<Rightarrow> 'a subspace" where
  [code del]: "space_div_unlifted S \<psi> = Abs_subspace {\<phi>. \<phi>\<otimes>\<psi> \<in> subspace_as_set S}"

lemma space_div_space_div_unlifted: "space_div (S\<guillemotright>(variable_concat Q R)) \<psi> R = (space_div_unlifted S \<psi>)\<guillemotright>Q"
  by (cheat space_div_space_div_unlifted)

lemma top_div[simp]: "top \<div> \<psi>\<guillemotright>Q = top" 
  by (cheat top_div)
lemma bot_div[simp]: "bot \<div> \<psi>\<guillemotright>Q = bot" 
  by (cheat bot_div)
lemma Cla_div[simp]: "Cla[e] \<div> \<psi>\<guillemotright>Q = Cla[e]" by simp

lemma space_div_add_extend_lift_as_var_concat_hint:
  fixes S :: "_ subspace"
  shows "NO_MATCH ((variable_concat a b),b) (Q,R) \<Longrightarrow> (space_div (S\<guillemotright>Q) \<psi> R) = (space_div (extend_lift_as_var_concat_hint (S\<guillemotright>Q) R)) \<psi> R"
  unfolding extend_lift_as_var_concat_hint_def by simp

subsection \<open>Quantum equality\<close>

definition quantum_equality_full :: "('a,'c) bounded \<Rightarrow> 'a::universe variables \<Rightarrow> ('b,'c) bounded \<Rightarrow> 'b::universe variables \<Rightarrow> predicate" where
  [code del]: "quantum_equality_full U Q V R = 
                 (eigenspace 1 (comm_op \<cdot> (V*\<cdot>U)\<otimes>(U*\<cdot>V))) \<guillemotright> variable_concat Q R"
  for Q :: "'a::universe variables" and R :: "'b::universe variables"
  and U V :: "(_,'c) bounded"

abbreviation "quantum_equality" :: "'a::universe variables \<Rightarrow> 'a::universe variables \<Rightarrow> predicate" (infix "\<equiv>\<qq>" 100)
  where "quantum_equality X Y \<equiv> quantum_equality_full idOp X idOp Y"
syntax quantum_equality :: "'a::universe variables \<Rightarrow> 'a::universe variables \<Rightarrow> predicate" (infix "==q" 100)
syntax "_quantum_equality" :: "variable_list_args \<Rightarrow> variable_list_args \<Rightarrow> predicate" ("Qeq'[_=_']")
translations
  "_quantum_equality a b" \<rightharpoonup> "CONST quantum_equality (_variables a) (_variables b)"

lemma quantum_equality_sym:
  assumes "distinct_qvars (variable_concat Q R)"
  shows "quantum_equality_full U Q V R = quantum_equality_full V R U Q"
proof -
  have dist: "distinct_qvars (variable_concat R Q)"
    using assms by (rule distinct_qvars_swap)
  have a: "comm_op \<cdot> ((V* \<cdot> U) \<otimes> (U* \<cdot> V)) \<cdot> comm_op* = (U* \<cdot> V) \<otimes> (V* \<cdot> U)" by simp
  have op_eq: "((comm_op \<cdot> (V* \<cdot> U) \<otimes> (U* \<cdot> V))\<guillemotright>variable_concat Q R) =
               ((comm_op \<cdot> (U* \<cdot> V) \<otimes> (V* \<cdot> U))\<guillemotright>variable_concat R Q)"
    apply (subst comm_op_lift[symmetric])
    using a by (simp add: assoc_right)
  show ?thesis
    apply (subst quantum_equality_full_def)
    apply (subst quantum_equality_full_def)
    apply (subst eigenspace_lift[symmetric, OF assms])
    apply (subst eigenspace_lift[symmetric, OF dist])
    using op_eq by simp
qed

lemma colocal_quantum_equality_full[simp]:
  "distinct_qvars (variable_concat Q1 (variable_concat Q2 Q3)) \<Longrightarrow> colocal (quantum_equality_full U1 Q1 U2 Q2) Q3"
for Q1::"'a::universe variables" and Q2::"'b::universe variables" and Q3::"'c::universe variables"
and U1 U2::"(_,'d)bounded" 
  by (cheat TODO14)

lemma colocal_quantum_eq[simp]: "distinct_qvars (variable_concat (variable_concat Q1 Q2) R) \<Longrightarrow> colocal (Q1 \<equiv>\<qq> Q2) R"
 for Q1 Q2 :: "'c::universe variables" and R :: "'a::universe variables"
  by (cheat TODO14)

lemma applyOpSpace_colocal[simp]:
  "colocal U S \<Longrightarrow> U\<noteq>0 \<Longrightarrow> U \<cdot> S = S" for U :: "(mem2,mem2) bounded" and S :: predicate
  by (cheat TODO14)

lemma qeq_collect:
 "quantum_equality_full U Q1 V Q2 = quantum_equality_full (V*\<cdot>U) Q1 idOp Q2"
 for U :: "('a::universe,'b::universe) bounded" and V :: "('c::universe,'b) bounded"
  unfolding quantum_equality_full_def by auto

lemma qeq_collect_guarded[simp]:
  fixes U :: "('a::universe,'b::universe) bounded" and V :: "('c::universe,'b) bounded"
  assumes "NO_MATCH idOp V"
  shows "quantum_equality_full U Q1 V Q2 = quantum_equality_full (V*\<cdot>U) Q1 idOp Q2"
  by (fact qeq_collect)

(* Proof in paper *)
lemma Qeq_mult1[simp]:
  "unitary U \<Longrightarrow> U\<guillemotright>Q1 \<cdot> quantum_equality_full U1 Q1 U2 Q2 = quantum_equality_full (U1\<cdot>U*) Q1 U2 Q2"
 for U::"('a::universe,'a) bounded" and U2 :: "('b::universe,'c::universe) bounded"  
  by (cheat TODO14)

(* Proof in paper *)
lemma Qeq_mult2[simp]:
  "unitary U \<Longrightarrow> U\<guillemotright>Q2 \<cdot> quantum_equality_full U1 Q1 U2 Q2 = quantum_equality_full U1 Q1 (U2\<cdot>U*) Q2"
 for U::"('a::universe,'a::universe) bounded" and U1 :: "('b::universe,'c::universe) bounded"  
  by (cheat TODO14)

(* Proof in paper *)
lemma quantum_eq_unique[simp]: "distinct_qvars (variable_concat Q R) \<Longrightarrow>
  isometry U \<Longrightarrow> isometry (adjoint V) \<Longrightarrow> 
  quantum_equality_full U Q V R \<sqinter> span{\<psi>}\<guillemotright>Q
  = liftSpace (span{\<psi>}) Q \<sqinter> liftSpace (span{V* \<cdot> U \<cdot> \<psi>}) R"
  for Q::"'a::universe variables" and R::"'b::universe variables"
    and U::"('a,'c) bounded" and V::"('b,'c) bounded"
    and \<psi>::"'a vector"
  by (cheat TODO14)

(* Proof in paper *)
lemma
  quantum_eq_add_state: 
    "distinct_qvars (variable_concat Q (variable_concat R T)) \<Longrightarrow> norm \<psi> = 1 \<Longrightarrow>
    quantum_equality_full U Q V R \<sqinter> span {\<psi>}\<guillemotright>T
             = quantum_equality_full (U \<otimes> idOp) (variable_concat Q T) (addState \<psi> \<cdot> V) R"
    for U :: "('a::universe,'c) bounded" and V :: "('b::universe,'c) bounded" and \<psi> :: "'d::universe vector"
    and Q :: "'a::universe variables"    and R :: "'b::universe variables"    and T :: "'d variables"
  by (cheat TODO14)

section \<open>Common quantum objects\<close>

definition [code del]: "CNOT = classical_operator (Some o (\<lambda>(x::bit,y). (x,y+x)))"
lemma unitaryCNOT[simp]: "unitary CNOT"
  unfolding CNOT_def apply (rule unitary_classical_operator)
  apply (rule o_bij[where g="\<lambda>(x,y). (x,y+x)"]; rule ext)
  unfolding o_def id_def by auto

lemma adjoint_CNOT[simp]: "CNOT* = CNOT"
proof -
  let ?f = "\<lambda>(x::bit,y). (x,y+x)"
  have[simp]: "?f o ?f = id"
    unfolding o_def id_def by auto
  have[simp]: "bij ?f"
    apply (rule o_bij[where g="?f"]; rule ext) by auto
  have[simp]: "inj ?f"
    apply (rule bij_is_inj) by simp
  have[simp]: "surj ?f"
    apply (rule bij_is_surj) by simp
  have inv_f[simp]: "Hilbert_Choice.inv ?f = ?f"
    apply (rule inv_unique_comp) by auto
  have [simp]: "inv_option (Some \<circ> ?f) = Some \<circ> ?f"
    apply (subst inv_option_Some) by simp_all
  show ?thesis
    unfolding CNOT_def
    apply (subst classical_operator_adjoint)
    by auto
qed

lemma CNOT_CNOT[simp]: "CNOT \<cdot> CNOT = idOp"
  using unitaryCNOT unfolding unitary_def adjoint_CNOT by simp

definition [code del]: "pauliX = classical_operator (Some o (\<lambda>x::bit. x+1))"
lemma unitaryX[simp]: "unitary pauliX"
  unfolding pauliX_def apply (rule unitary_classical_operator)
  apply (rule o_bij[where g="\<lambda>x. x+1"]; rule ext)
  unfolding o_def id_def by auto

lemma adjoint_X[simp]: "pauliX* = pauliX"
proof -
  let ?f = "\<lambda>x::bit. x+1"
  have[simp]: "?f o ?f = id"
    unfolding o_def id_def by auto
  have[simp]: "bij ?f"
    apply (rule o_bij[where g="?f"]; rule ext) by auto
  have[simp]: "inj ?f"
    apply (rule bij_is_inj) by simp
  have[simp]: "surj ?f"
    apply (rule bij_is_surj) by simp
  have inv_f[simp]: "Hilbert_Choice.inv ?f = ?f"
    apply (rule inv_unique_comp) by auto
  have [simp]: "inv_option (Some \<circ> ?f) = Some \<circ> ?f"
    apply (subst inv_option_Some) by simp_all
  show ?thesis
    unfolding pauliX_def
    apply (subst classical_operator_adjoint)
    by auto
qed


lemma X_X[simp]: "pauliX \<cdot> pauliX = idOp"
  using unitaryX unfolding unitary_def adjoint_CNOT by simp

consts hadamard :: "(bit,bit) bounded"
lemma unitaryH[simp]: "unitary hadamard"
  by (cheat TODO14)
lemma adjoint_H[simp]: "hadamard* = hadamard"
  by (cheat TODO15)

lemma H_H[simp]: "hadamard \<cdot> hadamard = idOp"
  using unitaryH unfolding unitary_def by simp

(* definition "hadamard' = sqrt2 \<cdot> hadamard"
lemma H_H': "hadamard = (1/sqrt2) \<cdot> hadamard'" unfolding hadamard'_def by simp
lemma [simp]: "isometry (1 / sqrt2 \<cdot> hadamard')"
  unfolding hadamard'_def by simp *)


definition [code del]: "pauliZ = hadamard \<cdot> pauliX \<cdot> hadamard"
lemma unitaryZ[simp]: "unitary pauliZ"
  unfolding pauliZ_def by simp

lemma adjoint_Z[simp]: "pauliZ* = pauliZ"
  unfolding pauliZ_def apply simp apply (subst timesOp_assoc) by simp

lemma Z_Z[simp]: "pauliZ \<cdot> pauliZ = idOp"
  using unitaryZ unfolding unitary_def by simp

consts pauliY :: "(bit,bit) bounded"
lemma unitaryY[simp]: "unitary pauliY"
  by (cheat TODO15)
lemma Y_Y[simp]: "pauliY \<cdot> pauliY = idOp"
  by (cheat TODO15)
lemma adjoint_Y[simp]: "pauliY* = pauliY"
  by (cheat TODO15)

consts EPR :: "(bit*bit) vector" 
lemma EPR_normalized[simp]: "norm EPR = 1"
  by (cheat TODO15)

(* definition[code del]: "EPR' = timesScalarVec sqrt2 EPR"

lemma EPR_EPR': "EPR = timesScalarVec (1/sqrt2) EPR'"
  unfolding EPR'_def by simp

lemma norm_EPR'[simp]: "cmod (1/sqrt2) * norm EPR' = 1"
  unfolding EPR'_def using EPR_normalized apply auto
  by (metis divide_cancel_right nonzero_mult_div_cancel_right norm_divide norm_eq_zero norm_one sqrt2_neq0) *)

definition "Uoracle f = classical_operator (Some o (\<lambda>(x,y::_::group_add). (x, y + (f x))))"

lemma unitary_Uoracle[simp]: "unitary (Uoracle f)"
  unfolding Uoracle_def
  apply (rule unitary_classical_operator, rule bijI)
   apply (simp add: inj_on_def)
  apply (auto simp: image_def)
  by (metis diff_add_cancel)

lemma Uoracle_adjoint: "(Uoracle f)* = classical_operator (Some o (\<lambda>(x,y::_::group_add). (x, y - (f x))))" 
      (is "_ = classical_operator (Some o ?pi)")
proof -
  define \<pi> where "\<pi> = ?pi"
  have [simp]: "surj \<pi>"
    apply (auto simp: \<pi>_def image_def)
    by (metis add_diff_cancel)

  define \<pi>2 where "\<pi>2 = (\<lambda>(x,y). (x, y + (f x)))"
  have "\<pi>2 o \<pi> = id"
    unfolding \<pi>_def \<pi>2_def by auto
  with \<open>surj \<pi>\<close> have [simp]: "surj \<pi>2"
    by (metis fun.set_map surj_id)
  have "\<pi> o \<pi>2 = id"
    unfolding \<pi>_def \<pi>2_def by auto
  then have [simp]: "inj \<pi>2"
    using \<open>\<pi>2 \<circ> \<pi> = id\<close> inj_iff inv_unique_comp by blast

  have "Hilbert_Choice.inv \<pi>2 = \<pi>"
    using inv_unique_comp
    using \<open>\<pi> \<circ> \<pi>2 = id\<close> \<open>\<pi>2 \<circ> \<pi> = id\<close> by blast

  then have "inv_option (Some o \<pi>2) = Some o \<pi>"
    by (subst inv_option_Some, simp_all)

  then have "(classical_operator (Some \<circ> \<pi>2))* = classical_operator (Some o \<pi>)"
    apply (subst classical_operator_adjoint)
    by simp_all

  then show ?thesis
    unfolding \<pi>_def \<pi>2_def Uoracle_def by auto
qed

lemma Uoracle_selfadjoint[simp]: "(Uoracle f)* = Uoracle f" for f :: "_ \<Rightarrow> _::xor_group"
  unfolding Uoracle_adjoint unfolding Uoracle_def by simp

lemma Uoracle_selfinverse[simp]: "Uoracle f \<cdot> Uoracle f = idOp" for f :: "_ \<Rightarrow> _::xor_group"
  apply (subst Uoracle_selfadjoint[symmetric]) apply (rule adjUU) by simp
                                                                    
section \<open>Misc\<close>

lemma bij_add_const[simp]: "bij (\<lambda>x. x+(y::_::ab_group_add))" 
  apply (rule bijI') apply simp
  apply (rename_tac z) apply (rule_tac x="z-y" in exI)
  by auto


declare imp_conjL[simp]


section "ML Code"

ML_file \<open>qrhl.ML\<close>

section "Simprocs"

simproc_setup "variable_rewriting" 
  ("join_variables_hint a b" | "sort_variables_hint a" | 
   "reorder_variables_hint a b" | "extend_lift_as_var_concat_hint A R") = 
  QRHL.variable_rewriting_simproc


end
