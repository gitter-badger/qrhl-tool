theory Weakest_Precondition
  imports Cert_Codegen Encoding Tactics
begin


(* TODO move non wp-stuff *)
ML \<open>
fun get_variable_name ctxt v = let
  val ct = Const(\<^const_name>\<open>variable_name\<close>, fastype_of v --> HOLogic.stringT) $ v |> Thm.cterm_of ctxt
  val thm = Raw_Simplifier.rewrite_cterm (false,false,false) (K (K NONE)) ctxt ct
  val rhs = Thm.rhs_of thm |> Thm.term_of
  val _ = HOLogic.dest_string rhs         
  in
    (rhs, fn () => thm RS @{thm meta_eq_to_obj_eq})
  end
val get_variable_name_spec : Cert_Codegen.specf = {name="get_variable_name", inputs=["v"], outputs=["n"],
                                      pattern=\<^prop>\<open>variable_name v = n\<close> |> Cert_Codegen.free_to_var}
\<close>
setup \<open>Cert_Codegen.add_spec get_variable_name_spec\<close>


lemma index_var1_aux:
  assumes "variable_name v = vname"
  assumes "variable_name v1 = v1name"
  assumes "vname @ ''1'' = v1name'"
  assumes "assert_equals v1name v1name'"
  shows "index_var True v = v1"
  using assms unfolding assert_equals_def using index_var1I by smt

lemma index_var2_aux:
  assumes "variable_name v = vname"
  assumes "variable_name v2 = v2name"
  assumes "vname @ ''2'' = v2name'"
  assumes "assert_equals v2name v2name'"
  shows "index_var False v = v2"
  using assms unfolding assert_equals_def using index_var2I by smt


ML \<open>
fun index_var_func ctxt left (v as Free(n,T)) = let
  val left' = if left = \<^const>\<open>True\<close> then true else if left = \<^const>\<open>False\<close> then false else raise TERM("index_var_func",[left])
  fun lr x y = if left' then x else y
  val v1 = Free(n^lr "1" "2",T)
  val (vname,vname_cert) = get_variable_name ctxt v
  val (v1name,v1name_cert) = get_variable_name ctxt v1
  val (v1name',v1name'_cert) = Cert_Codegen.string_concat_func ctxt vname (lr \<^term>\<open>''1''\<close> \<^term>\<open>''2''\<close>)
  val ((),eq_cert) = Cert_Codegen.assert_equals_func ctxt v1name v1name'
  fun cert () = (lr @{thm index_var1_aux} @{thm index_var2_aux}) OF [vname_cert(), v1name_cert(), v1name'_cert(), eq_cert()]
  in (v1,cert) end
  | index_var_func _ _ v = raise TERM("index_var_func",[v])
;;
val index_var_func_spec = {name="index_var_func", inputs=["left","v"], outputs=["v1"], pattern=\<^prop>\<open>index_var left v = v1\<close> |> Cert_Codegen.free_to_var} : Cert_Codegen.specf
\<close>
setup \<open>Cert_Codegen.add_spec index_var_func_spec\<close>

lemma index_vars_unit_func:
  assumes "X \<equiv> variable_unit"
  assumes "variable_unit \<equiv> X'"
  shows "index_vars left X = X'"
  using assms index_vars_unit by metis

lemma index_vars_singleton_func:
  assumes "X \<equiv> variable_singleton x"
  assumes "index_var left x = x1"
  assumes "variable_singleton x1 \<equiv> X'"
  shows "index_vars left X = X'"
  using assms index_vars_singleton by metis

lemma index_vars_concat_func:
  assumes "X \<equiv> variable_concat Y Z"
  assumes "index_vars left Y = Y1"
  assumes "index_vars left Z = Z1"
  assumes "variable_concat Y1 Z1 \<equiv> X'"
  shows "index_vars left X = X'"
  using assms index_vars_concat by metis

ML \<open>
val index_vars_func_spec : Cert_Codegen.specfx = {name="index_vars", inputs=["left","X"], outputs=["X'"],
  thms= ["index_vars_unit_func","index_vars_singleton_func","index_vars_concat_func"],
  pattern=Thm.concl_of @{thm index_vars_singleton_func}, fallback="fn (left,X) => raise TERM(\"index_vars_concat_func\",[left,X])"}
\<close>
setup \<open>Cert_Codegen.thms_to_funs [index_vars_func_spec] "Autogen_Index_Vars" "index_vars.ML"\<close>


lemma index_expression_func:
  assumes "e \<equiv> expression Q E"
  assumes "index_vars left Q = Q1"
  assumes "expression Q1 E \<equiv> e'"
  shows "index_expression left e = e'"
  using assms index_expression_def by metis

ML \<open>
val index_expression_func_spec : Cert_Codegen.specfx = {name="index_expression_func", inputs=["left","e"], outputs=["e'"],
    pattern=Thm.concl_of @{thm index_expression_func}, thms=["index_expression_func"], 
    fallback="fn (left,e) => raise TERM(\"index_expression_func\",[left,e])"}
\<close>
setup \<open>Cert_Codegen.thms_to_funs [index_expression_func_spec] "Autogen_Index_Expression" "index_expression.ML"\<close>




lemma wp_skip_func:
  assumes "c == []" and "d == []" and "B == A"
  shows "qrhl A c d B"
  unfolding assms by (rule wp_skip)

lemma wp1_assign_func:
  fixes x e c d A B
  assumes "c == [assign x e]" and "d == []"
  assumes "index_var True x = x1"
  assumes "index_expression True e = e1"
  assumes "subst_expression (substitute1 x1 e1) B = A"
  shows "qrhl A c d B"
  using assms wp1_assign by metis

lemma wp2_assign_func:
  fixes x e c d A B
  assumes "d == [assign x e]" and "c == []"
  assumes "index_var False x = x1"
  assumes "index_expression False e = e1"
  assumes "subst_expression (substitute1 x1 e1) B = A"
  shows "qrhl A c d B"
  using assms wp2_assign by metis

definition "cleanup_expression_concat Q1 Q2 = expression (variable_concat Q1 Q2)"

lemma cleanup_expression_concat_unit:
  assumes "Q1 \<equiv> \<lbrakk>\<rbrakk>"
  (* TODO: beta reduce f ((),q) if possible *)
  assumes "expression Q2 (\<lambda>q. f ((),q)) \<equiv> e"
  shows "cleanup_expression_concat Q1 Q2 f = e"
  unfolding cleanup_expression_concat_def using assms apply auto
  sorry

lemma cleanup_expression_concat_cons:
  assumes "Q1 \<equiv> variable_concat \<lbrakk>q\<rbrakk> Q1'"
  (* TODO: beta reduce f ((),q) if possible *)
  assumes "expression (variable_concat Q1' (variable_concat \<lbrakk>q\<rbrakk> Q2)) (\<lambda>(x1',(x,x2)). f ((x,x1'),x2)) \<equiv> e"
  shows "cleanup_expression_concat Q1 Q2 f = e"
  unfolding cleanup_expression_concat_def using assms apply auto
  sorry

lemma cleanup_expression_concat_single:
  assumes "Q1 \<equiv> \<lbrakk>q\<rbrakk>"
  assumes "expression (variable_concat Q1 Q2) f  \<equiv> e"
  shows "cleanup_expression_concat Q1 Q2 f = e"
  unfolding cleanup_expression_concat_def using assms by auto

ML \<open>
val cleanup_expression_concat_spec : Cert_Codegen.specfx = {
  name="cleanup_expression_concat",
  pattern=\<^prop>\<open>cleanup_expression_concat Q1 Q2 f = e\<close> |> Cert_Codegen.free_to_var,
  inputs=["Q1","Q2","f"], outputs=["e"],
  thms=["cleanup_expression_concat_unit","cleanup_expression_concat_cons","cleanup_expression_concat_single"],
  fallback="fn (Q1,Q2,f) => raise TERM(\"cleanup_expression_concat\",[Q1,Q2,f])"
}\<close>
setup \<open>Cert_Codegen.thms_to_funs [cleanup_expression_concat_spec] "Autogen_Cleanup_Expression_Concat" "cleanup_expression_concat.ML"\<close>

lemma map_expression2'_func:
  assumes "e1 == expression Q1 E1"
  assumes "\<And>z. e2 z == expression (Q2z z) (E2 z)"
  assumes "constant_function Q2z Q2"
  assumes "cleanup_expression_concat Q1 Q2 (\<lambda>(x1,x2). f (E1 x1) (\<lambda>z. E2 z x2)) = e'"
  shows "map_expression2' f e1 e2 = e'"
  unfolding assms(1,2) assms(4)[symmetric]
  using assms(3) unfolding constant_function_def cleanup_expression_concat_def
  by simp

ML \<open>
val map_expression2'_func_spec : Cert_Codegen.specfx = {
  name="map_expression2'",
  pattern=\<^prop>\<open>map_expression2' f e1 e2 = e'\<close> |> Cert_Codegen.free_to_var,
  inputs=["f","e1","e2"], outputs=["e'"],
  thms=["map_expression2'_func"],
  fallback="fn (f,e1,e2) => raise TERM(\"map_expression2'\",[f,e1,e2])"
}
\<close>
setup \<open>Cert_Codegen.thms_to_funs [map_expression2'_func_spec] "Autogen_Map_Expression" "map_expression.ML"\<close>

variables classical x :: int and classical y :: int begin
ML \<open>
\<^cterm>\<open>case_prod (%x y. u)\<close>;
\<^term>\<open>%((x,y),(u,w)). xxx\<close>;
\<^cterm>\<open>%(a,b). case_prod (%x y. u) a * case_prod (%x y. u) b\<close>;
\<close>

ML \<open>
Autogen_Map_Expression.map_expression2' \<^context> \<^term>\<open>%(a::int) b. a*b a\<close>
\<^term>\<open>Expr[x+y :: int]\<close>
\<^term>\<open>%z. Expr[x+y+z :: int]\<close>
|> fst |> Thm.cterm_of \<^context>
\<close>
end

lemma subst_expression_func_unit:
  assumes "s == substitute1 x f"
  assumes "e == expression variable_unit E"
  assumes "expression variable_unit E == e'"
  shows "subst_expression s e = e'"
  using assms Encoding.subst_expression_unit_aux by metis

lemma subst_expression_func_singleton_same:
  assumes "s == substitute1 x (expression R F)"
  assumes "e == expression \<lbrakk>x\<rbrakk> E"
  assumes "expression R (\<lambda>r. E (F r)) == e'"
  shows "subst_expression s e = e'"
  using assms Encoding.subst_expression_singleton_same_aux by metis

lemma subst_expression_func_singleton_notsame:
  assumes "s == substitute1 x f"
  assumes "e == expression \<lbrakk>y\<rbrakk> E"
  assumes "variable_name x = xn"
  assumes "variable_name y = yn"
  assumes neq: "assert_string_neq xn yn"
  assumes "e == e'"
  shows "subst_expression s e = e'"
  using neq unfolding assms(1,2) assms(3,4,6)[symmetric] assert_string_neq_def
  using Encoding.subst_expression_singleton_notsame_aux by metis

lemma subst_expression_func_concat_id:
  assumes "s == substitute1 x f"
  assumes "e == expression (variable_concat Q1 Q2) (\<lambda>x. x)"
  assumes "subst_expression (substitute1 x f) (expression Q1 (\<lambda>x. x)) = expression Q1' e1"
  assumes "subst_expression (substitute1 x f) (expression Q2 (\<lambda>x. x)) = expression Q2' e2"
  assumes "cleanup_expression_concat Q1' Q2' (\<lambda>(x1,x2). (e1 x1, e2 x2)) = e'"
  shows "subst_expression s e = e'"
  using assms Encoding.subst_expression_concat_id_aux unfolding cleanup_expression_concat_def by metis

lemma subst_expression_func_id_comp:
  assumes "s == substitute1 x f"
  assumes "e == expression Q E"
  assumes "NO_MATCH (\<lambda>x::unit. x) E"
  assumes "subst_expression (substitute1 x f) (expression Q (\<lambda>x. x)) = expression Q' g"
  assumes "expression Q' (\<lambda>x. E (g x)) == e'"
  shows "subst_expression s e = e'"
  using assms(4) unfolding assms(1-2) assms(5)[symmetric]
  using Encoding.subst_expression_id_comp_aux by metis

ML \<open>
val subst_expression_func_spec : Cert_Codegen.specfx = {
  name="subst_expression_func",
  inputs=["s","e"], outputs=["e'"], pattern= @{thm subst_expression_func_id_comp} |> Thm.concl_of,
  thms= ["subst_expression_func_unit","subst_expression_func_concat_id",
               "subst_expression_func_singleton_same","subst_expression_func_singleton_notsame",
               "subst_expression_func_concat_id", "subst_expression_func_id_comp"],
  fallback="fn (s,e) => raise TERM(\"subst_expression_func\",[s,e])"}
\<close>
setup \<open>Cert_Codegen.thms_to_funs [subst_expression_func_spec] "Autogen_Subst_Expression" "subst_expression.ML"\<close>


lemma wp1_sample_func:
  fixes A B c d x e
  assumes "d == []" and "c == [sample x e]" 
  assumes "index_var True x = x1"
  assumes "index_expression True e = e1"
(* TODO: all-quants probably don't work! *)
  assumes "\<And>z. subst_expression (substitute1 x1 (const_expression z)) B = B' z"
(* TODO: implement map_expression2' *)
  assumes "map_expression2' (\<lambda>e' B'. Cla[weight e' = 1] \<sqinter> (INF z:supp e'. B' z)) e1 B' = A"
  shows "qrhl A c d B"
  unfolding assms(1-2) assms(3-6)[symmetric] by (rule wp1_sample)

lemma wp2_sample_func:
(*TODO*)
  fixes A B c d x e
  assumes "c == []" and "d == [sample x e]" 
  defines "e' \<equiv> index_expression False e"
  defines "B' z \<equiv> subst_expression (substitute1 (index_var False x) (const_expression z)) B"
  assumes "map_expression2' (\<lambda>e' B'. Cla[weight e' = 1] \<sqinter> (INF z:supp e'. B' z)) e' B' == A"
  shows "qrhl A c d B"
  unfolding assms(1-4) assms(5)[symmetric] by (rule wp2_sample)

lemma wp1_qapply_func:
(*TODO*)
  fixes A B Q e
  assumes "d == []" and "c == [qapply Q e]"
  defines "Q\<^sub>1 \<equiv> index_vars True Q"
  assumes "map_expression2 (\<lambda>e\<^sub>1 B. Cla[isometry e\<^sub>1] \<sqinter> (adjoint (e\<^sub>1\<guillemotright>Q\<^sub>1) \<cdot> (B \<sqinter> (e\<^sub>1\<guillemotright>Q\<^sub>1 \<cdot> top)))) (index_expression True e) B \<equiv> A"
  shows "qrhl A c d B"
  unfolding assms(1-3) assms(4)[symmetric] by (rule wp1_qapply)

lemma wp2_qapply_func:
(*TODO*)
  fixes A B Q e
  assumes "c == []" and "d == [qapply Q e]"
  defines "Q\<^sub>1 \<equiv> index_vars False Q"
  assumes "map_expression2 (\<lambda>e\<^sub>1 B. Cla[isometry e\<^sub>1] \<sqinter> (adjoint (e\<^sub>1\<guillemotright>Q\<^sub>1) \<cdot> (B \<sqinter> (e\<^sub>1\<guillemotright>Q\<^sub>1 \<cdot> top)))) (index_expression False e) B \<equiv> A"
  shows "qrhl A c d B"
  unfolding assms(1-3) assms(4)[symmetric] by (rule wp2_qapply)

lemma wp1_measure_func:
(*TODO*)
  fixes A B x Q e
  assumes "d == []" and "c == [measurement x Q e]"
  defines "e\<^sub>1 \<equiv> index_expression True e"
  defines "B' z \<equiv> subst_expression (substitute1 (index_var True x) (const_expression z)) B"
  defines "\<And>e\<^sub>1 z. ebar e\<^sub>1 z \<equiv> ((mproj e\<^sub>1 z)\<guillemotright>(index_vars True Q)) \<cdot> top"
  assumes "map_expression2' (\<lambda>e\<^sub>1 B'. Cla[mtotal e\<^sub>1] \<sqinter> 
           (INF z. ((B' z \<sqinter> ebar e\<^sub>1 z) + ortho (ebar e\<^sub>1 z)))) e\<^sub>1 B' == A"
  shows "qrhl A c d B"
  unfolding assms(1-5) assms(6)[symmetric] by (rule wp1_measure)

lemma wp2_measure_func:
(*TODO*)
  fixes A B x Q e
  assumes "c == []" and "d == [measurement x Q e]"
  defines "e\<^sub>1 \<equiv> index_expression False e"
  defines "B' z \<equiv> subst_expression (substitute1 (index_var False x) (const_expression z)) B"
  defines "\<And>e\<^sub>1 z. ebar e\<^sub>1 z \<equiv> ((mproj e\<^sub>1 z)\<guillemotright>(index_vars False Q)) \<cdot> top"
  assumes "map_expression2' (\<lambda>e\<^sub>1 B'. Cla[mtotal e\<^sub>1] \<sqinter> 
           (INF z. ((B' z \<sqinter> ebar e\<^sub>1 z) + ortho (ebar e\<^sub>1 z)))) e\<^sub>1 B' == A"
  shows "qrhl A c d B"
  unfolding assms(1-5) assms(6)[symmetric] by (rule wp2_measure)

lemma wp1_qinit_func:
(*TODO*)
  fixes A B e Q
  assumes "d==[]" and "c == [qinit Q e]"
  assumes "map_expression2 (\<lambda>e\<^sub>1 B. Cla[norm e\<^sub>1 = 1] \<sqinter> (B \<div> e\<^sub>1 \<guillemotright> (index_vars True Q)))
           (index_expression True e) B == A"
  shows "qrhl A c d B"
  unfolding assms(1-2) assms(3)[symmetric] by (rule wp1_qinit)

lemma wp2_qinit_func:
(*TODO*)
  fixes A B e Q
  assumes "c == []" and "d == [qinit Q e]"
  assumes "map_expression2 (\<lambda>e\<^sub>1 B. Cla[norm e\<^sub>1 = 1] \<sqinter> (B \<div> e\<^sub>1 \<guillemotright> (index_vars False Q)))
           (index_expression False e) B == A"
  shows "qrhl A c d B"
  unfolding assms(1-2) assms(3)[symmetric] by (rule wp2_qinit)

lemma wp1_if_func:
(*TODO*)
  fixes e p1 p2 B
  assumes "d == []" and "c == [ifthenelse e p1 p2]"
  assumes "qrhl wp_true p1 [] B"
  assumes "qrhl wp_false p2 [] B"
  assumes "map_expression3 (\<lambda>e\<^sub>1 wp_true wp_false. (Cla[\<not>e\<^sub>1] + wp_true) \<sqinter> (Cla[e\<^sub>1] + wp_false))
           (index_expression True e) wp_true wp_false == A"
  shows "qrhl A c d B"
  unfolding assms(1-2) assms(5)[symmetric] using assms(3,4) by (rule wp1_if)

lemma wp2_if_func:
(*TODO*)
  fixes e p1 p2 B
  assumes "c == []" and "d == [ifthenelse e p1 p2]"
  assumes "qrhl wp_true [] p1 B"
  assumes "qrhl wp_false [] p2 B"
  assumes "map_expression3 (\<lambda>e\<^sub>1 wp_true wp_false. (Cla[\<not>e\<^sub>1] + wp_true) \<sqinter> (Cla[e\<^sub>1] + wp_false))
           (index_expression False e) wp_true wp_false == A"
  shows "qrhl A c d B"
  unfolding assms(1-2) assms(5)[symmetric] using assms(3,4) by (rule wp2_if)

lemma wp1_block_func:
(*TODO*)
  assumes "d == []" and "c == [block p]"
  assumes "qrhl A p [] B"
  shows "qrhl A c d B"
  unfolding assms(1,2) using assms(3) by (rule wp1_block)

lemma wp2_block_func:
(*TODO*)
  assumes "c == []" and "d == [block p]"
  assumes "qrhl A [] p B"
  shows "qrhl A c d B"
  unfolding assms(1,2) using assms(3) by (rule wp2_block)

lemma wp1_cons_func:
  assumes "d == []" and "c == p#ps"
  assumes "NO_MATCH ([]::unit list) ps"
  assumes "qrhl B' ps [] B" and "qrhl A [p] [] B'"
  shows "qrhl A c d B"
  unfolding assms(1,2) using assms(4,5) by (rule wp1_cons[rotated])

lemma wp2_cons_func:
  assumes "c == []" and "d == p#ps"
  assumes "NO_MATCH ([]::unit list) ps"
  assumes "qrhl B' [] ps B"
    and "qrhl A [] [p] B'"
  shows "qrhl A c d B"
  unfolding assms(1,2) using assms(4,5) by (rule wp2_cons[rotated])




ML \<open>
val spec_wp = 
{name="wp", thms= 
["wp_skip_func","wp1_assign_func","wp2_assign_func", "wp1_sample_func", "wp2_sample_func",
  "wp1_qapply_func", "wp2_qapply_func", "wp1_measure_func", "wp2_measure_func", "wp1_if_func", "wp2_if_func",
  "wp1_block_func", "wp2_block_func", "wp1_cons_func", "wp2_cons_func"],
inputs=["c","d","B"], outputs=["A"], fallback="fn (c,d,B) => raise TERM(\"wp\",[c,d,B])", pattern=Thm.concl_of @{thm wp_skip_func}} : Cert_Codegen.specfx
\<close>

setup \<open>Cert_Codegen.thms_to_funs [spec_wp] "Autogen_WP" "wp.ML"\<close>



end
