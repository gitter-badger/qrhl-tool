theory Squash_Sampling
  imports Programs Relational_Hoare
begin

lemma squash_sampling: 
  fixes Q R d e
  defines "\<And>z. e' z \<equiv> subst_expression (substitute_vars Q (const_expression z)) e"
  defines "de \<equiv> map_expression2' (\<lambda>d e. bind_distr d (\<lambda>z. map_distr (\<lambda>y. (z,y)) (e z))) d e'"
  shows "denotation (block [sample Q d, sample R e]) =
         denotation (sample (variable_concat Q R) de)"
  by (cheat squash_sampling)

lemma squash_sampling_assign: 
  fixes Q R d e
  defines "\<And>z. e' z \<equiv> subst_expression (substitute_vars Q (const_expression z)) e"
  defines "de \<equiv> map_expression2' (\<lambda>d e. map_distr (\<lambda>d. (d,e d)) d) d e'"
  shows "denotation (block [sample Q d, assign R e]) =
         denotation (sample (variable_concat Q R) de)"
  by (cheat squash_sampling_assign)

lemma squash_assign_sampling: 
  fixes Q R d e
  defines "\<And>z. e' z \<equiv> subst_expression (substitute_vars Q (const_expression z)) e"
  defines "de \<equiv> map_expression2' (\<lambda>d e. bind_distr (point_distr d) (\<lambda>z. map_distr (\<lambda>y. (z,y)) (e z))) d e'"
  shows "denotation (block [assign Q d, sample R e]) =
         denotation (sample (variable_concat Q R) de)"
  by (cheat squash_sampling_assign)

lemma squash_assign: 
  fixes Q R d e
  defines "\<And>z. e' z \<equiv> subst_expression (substitute_vars Q (const_expression z)) e"
  defines "de \<equiv> map_expression2' (\<lambda>d e. (d,e d)) d e'"
  shows "denotation (block [assign Q d, assign R e]) =
         denotation (assign (variable_concat Q R) de)"
  by (cheat squash_assign)

(* lemma assign_sample:
  shows "denotation (assign Q e) = denotation (sample Q (map_expression (\<lambda>x. uniform {x}) e))"
  by (cheat assign_sample) *)

lemma squash_sampling_left_ss_tac:
  assumes left0: "left0 @ [sample Q d, sample R e] = left"
  assumes e': "\<And>z. e' z = subst_expression (substitute_vars Q (const_expression z)) e"
  assumes de: "de = map_expression2' (\<lambda>d e. bind_distr d (\<lambda>z. map_distr (\<lambda>y. (z,y)) (e z))) d e'"
  assumes left': "left' = left0 @ [sample (variable_concat Q R) de]"
  assumes qrhl: "qrhl A left' right B"
  shows "qrhl A left right B"
proof -
  have "denotation (block [sample Q d, sample R e]) = denotation (sample (variable_concat Q R) de)"
    unfolding de e' by (rule squash_sampling)
  then have "denotation (block left) = denotation (block left')"
    unfolding left' left0[symmetric] denotation_block by auto
  with qrhl show ?thesis
    using qrhl_denotation_replace by blast 
qed


lemma squash_sampling_left_as_tac:
  assumes left0: "left0 @ [assign Q d, sample R e] = left"
  assumes e': "\<And>z. e' z = subst_expression (substitute_vars Q (const_expression z)) e"
  assumes de: "de = map_expression2' (\<lambda>d e. bind_distr (point_distr d) (\<lambda>z. map_distr (\<lambda>y. (z,y)) (e z))) d e'"
  assumes left': "left' = left0 @ [sample (variable_concat Q R) de]"
  assumes qrhl: "qrhl A left' right B"
  shows "qrhl A left right B"
proof -
  have "denotation (block [assign Q d, sample R e]) = denotation (sample (variable_concat Q R) de)"
    unfolding de e' by (rule squash_assign_sampling)
  then have "denotation (block left) = denotation (block left')"
    unfolding left' left0[symmetric] denotation_block by auto
  with qrhl show ?thesis
    using qrhl_denotation_replace by blast 
qed

lemma squash_sampling_left_sa_tac:
  assumes left0: "left0 @ [sample Q d, assign R e] = left"
  assumes e': "\<And>z. e' z = subst_expression (substitute_vars Q (const_expression z)) e"
  assumes de: "de = map_expression2' (\<lambda>d e. map_distr (\<lambda>d. (d,e d)) d) d e'"
  assumes left': "left' = left0 @ [sample (variable_concat Q R) de]"
  assumes qrhl: "qrhl A left' right B"
  shows "qrhl A left right B"
proof -
  have "denotation (block [sample Q d, assign R e]) = denotation (sample (variable_concat Q R) de)"
    unfolding de e' by (rule squash_sampling_assign)
  then have "denotation (block left) = denotation (block left')"
    unfolding left' left0[symmetric] denotation_block by auto
  with qrhl show ?thesis
    using qrhl_denotation_replace by blast 
qed
  
lemma squash_sampling_left_aa_tac:
  assumes left0: "left0 @ [assign Q d, assign R e] = left"
  assumes e': "\<And>z. e' z = subst_expression (substitute_vars Q (const_expression z)) e"
  assumes de: "de = map_expression2' (\<lambda>d e. (d,e d)) d e'"
  assumes left': "left' = left0 @ [assign (variable_concat Q R) de]"
  assumes qrhl: "qrhl A left' right B"
  shows "qrhl A left right B"
proof -
  have "denotation (block [assign Q d, assign R e]) = denotation (assign (variable_concat Q R) de)"
    unfolding de e' by (rule squash_assign)
  then have "denotation (block left) = denotation (block left')"
    unfolding left' left0[symmetric] denotation_block by auto
  with qrhl show ?thesis
    using qrhl_denotation_replace by blast 
qed

lemma squash_sampling_right_ss_tac:
  assumes right0: "right0 @ [sample Q d, sample R e] = right"
  assumes e': "\<And>z. e' z = subst_expression (substitute_vars Q (const_expression z)) e"
  assumes de: "de = map_expression2' (\<lambda>d e. bind_distr d (\<lambda>z. map_distr (\<lambda>y. (z,y)) (e z))) d e'"
  assumes right': "right' = right0 @ [sample (variable_concat Q R) de]"
  assumes qrhl: "qrhl A left right' B"
  shows "qrhl A left right B"
proof -
  have "denotation (block [sample Q d, sample R e]) = denotation (sample (variable_concat Q R) de)"
    unfolding de e' by (rule squash_sampling)
  then have "denotation (block right) = denotation (block right')"
    unfolding right' right0[symmetric] denotation_block by auto
  with qrhl show ?thesis
    using qrhl_denotation_replace by blast 
qed

lemma squash_sampling_right_as_tac:
  assumes right0: "right0 @ [assign Q d, sample R e] = right"
  assumes e': "\<And>z. e' z = subst_expression (substitute_vars Q (const_expression z)) e"
  assumes de: "de = map_expression2' (\<lambda>d e. bind_distr (point_distr d) (\<lambda>z. map_distr (\<lambda>y. (z,y)) (e z))) d e'"
  assumes right': "right' = right0 @ [sample (variable_concat Q R) de]"
  assumes qrhl: "qrhl A left right' B"
  shows "qrhl A left right B"
proof -
  have "denotation (block [assign Q d, sample R e]) = denotation (sample (variable_concat Q R) de)"
    unfolding de e' by (rule squash_assign_sampling)
  then have "denotation (block right) = denotation (block right')"
    unfolding right' right0[symmetric] denotation_block by auto
  with qrhl show ?thesis
    using qrhl_denotation_replace by blast 
qed

lemma squash_sampling_right_sa_tac:
  assumes right0: "right0 @ [sample Q d, assign R e] = right"
  assumes e': "\<And>z. e' z = subst_expression (substitute_vars Q (const_expression z)) e"
  assumes de: "de = map_expression2' (\<lambda>d e. map_distr (\<lambda>d. (d,e d)) d) d e'"
  assumes right': "right' = right0 @ [sample (variable_concat Q R) de]"
  assumes qrhl: "qrhl A left right' B"
  shows "qrhl A left right B"
proof -
  have "denotation (block [sample Q d, assign R e]) = denotation (sample (variable_concat Q R) de)"
    unfolding de e' by (rule squash_sampling_assign)
  then have "denotation (block right) = denotation (block right')"
    unfolding right' right0[symmetric] denotation_block by auto
  with qrhl show ?thesis
    using qrhl_denotation_replace by blast 
qed

lemma squash_sampling_right_aa_tac:
  assumes right0: "right0 @ [assign Q d, assign R e] = right"
  assumes e': "\<And>z. e' z = subst_expression (substitute_vars Q (const_expression z)) e"
  assumes de: "de = map_expression2' (\<lambda>d e. (d,e d)) d e'"
  assumes right': "right' = right0 @ [assign (variable_concat Q R) de]"
  assumes qrhl: "qrhl A left right' B"
  shows "qrhl A left right B"
proof -
  have "denotation (block [assign Q d, assign R e]) = denotation (assign (variable_concat Q R) de)"
    unfolding de e' by (rule squash_assign)
  then have "denotation (block right) = denotation (block right')"
    unfolding right' right0[symmetric] denotation_block by auto
  with qrhl show ?thesis
    using qrhl_denotation_replace by blast 
qed


ML \<open>
structure Squash_Sampling = struct

fun squash_sampling_tac left ctxt =
  resolve_tac ctxt (if left then 
      @{thms squash_sampling_left_ss_tac squash_sampling_left_sa_tac squash_sampling_left_as_tac squash_sampling_left_aa_tac} 
    else 
      @{thms squash_sampling_right_ss_tac squash_sampling_right_sa_tac squash_sampling_right_as_tac squash_sampling_right_aa_tac})
  THEN' Misc.match_list_tac ctxt
  THEN' Expressions.subst_expression_tac ctxt
  THEN' Expressions.map_expression_tac ctxt
  THEN' Misc.append_list_tac ctxt
end\<close>

(* TODO remove *)
variables classical x :: bit and classical y :: bit and classical z ::bit begin
schematic_goal xxx: "qrhl A
 [sample \<lbrakk>var_z\<rbrakk> Expr[uniform UNIV], sample \<lbrakk>var_x\<rbrakk> Expr[uniform {1,z}], sample \<lbrakk>var_y\<rbrakk> Expr[uniform {x,z}]]
 [assign \<lbrakk>\<rbrakk> Expr[()]] Expr[Cla[x1=y2]]"
  apply (tactic \<open>Squash_Sampling.squash_sampling_tac true \<^context> 1\<close>)
  apply (tactic \<open>Squash_Sampling.squash_sampling_tac true \<^context> 1\<close>)
  apply simp
  oops

schematic_goal xxx: "qrhl A
 [assign \<lbrakk>var_z\<rbrakk> Expr[3], sample \<lbrakk>var_z\<rbrakk> Expr[uniform UNIV], assign \<lbrakk>var_x\<rbrakk> Expr[1], assign \<lbrakk>var_y\<rbrakk> Expr[x]]
 [assign \<lbrakk>\<rbrakk> Expr[()]] Expr[Cla[x1=y2]]"
  apply (tactic \<open>Squash_Sampling.squash_sampling_tac true \<^context> 1\<close>)
  apply simp
  apply (tactic \<open>Squash_Sampling.squash_sampling_tac true \<^context> 1\<close>)
  apply simp
  apply (tactic \<open>Squash_Sampling.squash_sampling_tac true \<^context> 1\<close>)
  apply simp
  oops

schematic_goal xxx: "qrhl A
 [assign \<lbrakk>\<rbrakk> Expr[()]] 
 [assign \<lbrakk>var_z\<rbrakk> Expr[3], sample \<lbrakk>var_z\<rbrakk> Expr[uniform UNIV], assign \<lbrakk>var_x\<rbrakk> Expr[1], assign \<lbrakk>var_y\<rbrakk> Expr[x]]
Expr[Cla[x1=y2]]"
  apply (tactic \<open>Squash_Sampling.squash_sampling_tac false \<^context> 1\<close>)
  apply simp
  apply (tactic \<open>Squash_Sampling.squash_sampling_tac false \<^context> 1\<close>)
  apply simp
  apply (tactic \<open>Squash_Sampling.squash_sampling_tac false \<^context> 1\<close>)
  apply simp
  oops

end

end
