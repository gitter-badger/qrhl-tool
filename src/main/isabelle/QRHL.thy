theory QRHL
  imports Complex_Main "HOL-Library.Adhoc_Overloading" (* "~~/src/Tools/Adhoc_Overloading" *)
begin
  
section \<open>Miscellaneous\<close>
  
syntax "Lattices.sup_class.sup" :: "'a \<Rightarrow> 'a \<Rightarrow> 'a" (infixl "\<squnion>" 65)
syntax "Lattices.inf_class.inf" :: "'a \<Rightarrow> 'a \<Rightarrow> 'a" (infixl "\<sqinter>" 70)

typedef 'a distr = "{f::'a\<Rightarrow>real. (\<forall>x. f x \<ge> 0) \<and> (\<forall> M. sum f M \<le> 1)}" 
  morphisms prob Abs_distr
  apply (rule exI[of _ "\<lambda>x. 0"]) by auto
instantiation distr :: (type)zero begin
definition "0 = Abs_distr (\<lambda>_. 0)"
instance .. 
end
 
  
definition "supp \<mu> = {x. prob \<mu> x > 0}" 
definition uniform :: "'a set \<Rightarrow> 'a distr" where
  "uniform M = Abs_distr (\<lambda>m. if m\<in>M then 1/card M else 0)"
axiomatization where supp_uniform [simp]: "M \<noteq> {} \<Longrightarrow> finite M \<Longrightarrow> supp (uniform M) = M" for M :: "'a set"
axiomatization weight :: "'a distr \<Rightarrow> real" where
  weight_pos[simp]: "weight \<mu> \<ge> 0" 
and weight_leq1[simp]: "weight \<mu> \<le> 1"
and weight_uniform[simp]: "M \<noteq> {} \<Longrightarrow> finite M \<Longrightarrow> weight (uniform M) = 1"

axiomatization "map_distr" :: "('a\<Rightarrow>'b) \<Rightarrow> 'a distr \<Rightarrow> 'b distr" where
  weight_map_distr[simp]: "weight (map_distr f \<mu>) = weight \<mu>"
  and supp_map_distr[simp]: "supp (map_distr f \<mu>) = f ` (supp \<mu>)"
  
axiomatization where  
  compose_map_distr[simp]: "map_distr g (map_distr f \<mu>) = map_distr (\<lambda>x. g (f x)) \<mu>"
and  map_distr_id[simp]: "map_distr (\<lambda>x. x) \<mu> = \<mu>"
and map_distr_uniform_eq[simp]: "(map_distr f (uniform A) = uniform B) = (bij_betw f A B \<or> (infinite A \<and> infinite B))"
  for f::"'a\<Rightarrow>'b" and g::"'b\<Rightarrow>'c"

typedef bit = "UNIV::bool set"..
setup_lifting type_definition_bit
instantiation bit :: field begin
lift_definition times_bit :: "bit \<Rightarrow> bit \<Rightarrow> bit" is "op&".
lift_definition plus_bit :: "bit \<Rightarrow> bit \<Rightarrow> bit" is "op\<noteq>".
lift_definition zero_bit :: bit is "False".
lift_definition one_bit :: bit is "True".
definition[simp]: "uminus_bit (x::bit) = x"
definition[simp]: "minus_bit = (op+ :: bit\<Rightarrow>_\<Rightarrow>_)"
definition[simp]: "inverse_bit (x::bit) = x"
definition[simp]: "divide_bit = (op* :: bit\<Rightarrow>_\<Rightarrow>_)"
instance by intro_classes (transfer; auto)+
end
instantiation bit :: finite begin
instance by (intro_classes, transfer, simp)
end

lemma bit_cases: "(x=0 \<Longrightarrow> P) \<Longrightarrow> (x=1 \<Longrightarrow> P) \<Longrightarrow> P" for x :: bit
  by (metis (full_types) Rep_bit_inverse one_bit.abs_eq zero_bit.abs_eq)
lemma bit_two[simp]: "(2::bit) = 0"
  by (metis add_cancel_left_right bit_cases one_add_one) 
lemma bit_eq_x[simp]: "((a=x) = (b=x)) = (a=b)" for a b x :: bit
  apply transfer by auto
lemma bit_neq[simp]: "(a \<noteq> b) = (a = b+1)" for a b :: bit
  apply (cases a rule:bit_cases; cases b rule:bit_cases) by auto

(*instantiation "fun" :: (type,zero)zero begin
definition[simp]: "zero_fun (x::'a) = (0::'b)"
instance .. 
end*)

typedecl program
typedecl program_state

  
section \<open>Subspaces\<close>
  
typedef 'a state = "{x::'a\<Rightarrow>complex. \<exists>b. \<forall>F. finite F \<longrightarrow> sum (\<lambda>i. (norm(x i))^2) F \<le> b }"
  by (rule exI[of _ "\<lambda>_.0"], auto)
setup_lifting type_definition_state

lift_definition ket :: "'a \<Rightarrow> 'a state" ("|_\<rangle>") is "\<lambda>x y. if x=y then 1 else 0"
proof (rule exI[of _ 1], rule allI, rule impI)
  fix a::'a and F::"'a set" assume "finite F"
  have "(\<Sum>i\<in>F. (cmod (if a = i then 1 else 0))\<^sup>2) = 0" if "a\<notin>F"
    apply (subst sum.cong[where B=F and h="\<lambda>_. 0"]) using that by auto
  moreover have "(\<Sum>i\<in>F. (cmod (if a = i then 1 else 0))\<^sup>2) = 1" if "a\<in>F"
  proof -
    obtain F0 where "a\<notin>F0" and F_F0: "F=insert a F0"
      by (meson \<open>a \<in> F\<close> mk_disjoint_insert) 
    show "(\<Sum>i\<in>F. (cmod (if a = i then 1 else 0))\<^sup>2) = 1"
      unfolding F_F0
      apply (subst sum.insert_remove)
       using F_F0 `finite F` apply auto
      apply (subst sum.cong[where B=F0 and h="\<lambda>_. 0"])
        apply (simp add: \<open>a \<notin> F0\<close>)
       using \<open>a \<notin> F0\<close> apply auto[1]
      by simp
  qed
  ultimately show "(\<Sum>i\<in>F. (cmod (if a = i then 1 else 0))\<^sup>2) \<le> 1"
    by linarith
qed

instantiation state :: (type)real_vector begin
lift_definition zero_state :: "'a state" is "\<lambda>_.0" by auto
lift_definition uminus_state :: "'a state \<Rightarrow> 'a state" is uminus by auto
lift_definition plus_state :: "'a state \<Rightarrow> 'a state \<Rightarrow> 'a state" is "\<lambda>f g x. f x + g x"
proof -
  fix f g :: "'a \<Rightarrow> complex"  fix fun1 fun2 :: "'a \<Rightarrow> complex"
    
  assume "\<exists>bf. \<forall>F. finite F \<longrightarrow> (\<Sum>i\<in>F. ((cmod (f i))^2)) \<le> bf"
  then obtain bf where bf: "\<forall>F. finite F \<longrightarrow> (\<Sum>i\<in>F. (cmod (f i)^2)) \<le> bf" ..
  assume "\<exists>bg. \<forall>F. finite F \<longrightarrow> (\<Sum>i\<in>F. ((cmod (g i))^2)) \<le> bg"
  then obtain bg where bg: "\<forall>F. finite F \<longrightarrow> (\<Sum>i\<in>F. (cmod (g i)^2)) \<le> bg" ..

  have cmod: "cmod (a+b)^2 \<le> 2 * ((cmod a)^2 + (cmod b)^2)" for a b
    by (smt cmod_def cmod_power2 norm_triangle_ineq power2_sum sqrt_le_D sum_squares_bound)
         
  define b where "b = 2 * (bf+bg)"
      
  have "\<forall>F. finite F \<longrightarrow> (\<Sum>i\<in>F. (cmod (f i + g i))\<^sup>2) \<le> b"
  proof (rule allI, rule impI)
    fix F :: "'a set" assume "finite F"
    have h1: "(\<Sum>i\<in>F. (cmod (f i + g i))\<^sup>2) \<le> 2 * ((\<Sum>i\<in>F. (cmod (f i))\<^sup>2) + (\<Sum>i\<in>F. (cmod (g i))\<^sup>2))"
      apply (subst sum.distrib[symmetric])
      apply (subst sum_distrib_left)
      apply (rule sum_mono)
      by (rule cmod)
    moreover have h2: "(\<Sum>i\<in>F. (cmod (f i))\<^sup>2) \<le> bf"
      using \<open>finite F\<close> bf by blast
    moreover have h3: "(\<Sum>i\<in>F. (cmod (g i))\<^sup>2) \<le> bg" 
      using \<open>finite F\<close> bg by blast
    ultimately show "(\<Sum>i\<in>F. (cmod (f i + g i))\<^sup>2) \<le> b" unfolding b_def 
      by auto
    qed
  then show "\<exists>b. \<forall>F. finite F \<longrightarrow> (\<Sum>i\<in>F. (cmod (f i + g i))\<^sup>2) \<le> b" by auto
qed
definition "a - b = a + (-b)" for a b :: "'a state"
lift_definition scaleR_state :: "real \<Rightarrow> 'a state \<Rightarrow> 'a state" is "\<lambda>r f x. r *\<^sub>R f x"
proof -
  fix f :: "'a \<Rightarrow> complex" and r :: real
  assume "\<exists>b. \<forall>F. finite F \<longrightarrow> (\<Sum>i\<in>F. (cmod (f i))\<^sup>2) \<le> b"
  then obtain b where b: "\<And>F. finite F \<Longrightarrow> (\<Sum>i\<in>F. (cmod (f i))\<^sup>2) \<le> b" by auto
  have aux: "(r*x)^2 = r^2 * x^2" for r x :: real unfolding power2_eq_square by auto
  have "(\<Sum>i\<in>F. (cmod (r *\<^sub>R f i))\<^sup>2) \<le> \<bar>r\<bar>\<^sup>2 * b" if "finite F" for F
    apply (subst norm_scaleR)
    apply (subst aux)
    apply (subst sum_distrib_left[symmetric])
    apply (subst mult_left_mono)
    by (auto simp: b that)
  then show "\<exists>b. \<forall>F. finite F \<longrightarrow> (\<Sum>i\<in>F. (cmod (r *\<^sub>R f i))\<^sup>2) \<le> b"
    by auto
qed
instance apply intro_classes
          apply (transfer; rule ext; simp)
         apply (transfer; rule ext; simp)
        apply (transfer; rule ext; simp)
       apply (transfer; rule ext; simp)
      apply (unfold minus_state_def; transfer; rule ext; simp)
     apply (transfer; rule ext; simp add: scaleR_add_right)
    apply (transfer; rule ext; simp add: scaleR_add_left)
   apply (transfer; rule ext; simp)
  by (transfer; rule ext; simp)
end

  (* TODO: states should be normalized! *)

typedecl 'a subspace
  
instantiation subspace :: (type)zero begin instance .. end (* The subspace {0} *)
instantiation subspace :: (type)top begin instance .. end (* The full space *)
instantiation subspace :: (type)inf begin instance .. end (* Intersection *)
instantiation subspace :: (type)Inf begin instance .. end (* Intersection *)
instantiation subspace :: (type)plus begin instance .. end (* Sum of spaces *)
instantiation subspace :: (type)Sup begin instance .. end (* Sum of spaces *)
  
consts tmp_subspace_less_eq :: "'a subspace \<Rightarrow> 'a subspace \<Rightarrow> bool"
instantiation subspace :: (type)ord begin  
definition "(a \<le> b) = tmp_subspace_less_eq a b" (* \<le> means inclusion *)
definition "(a < b) = (a \<le> b \<and> \<not> (b \<le> a))" for a :: "'a subspace"
instance .. end
hide_fact less_eq_subspace_def
hide_const tmp_subspace_less_eq
  
axiomatization ortho :: "'a subspace \<Rightarrow> 'a subspace" (* Orthogonal complement *)
  
axiomatization where
    subspace_zero_not_top[simp]: "(0::'a subspace) \<noteq> top"
and tmp_reflex: "x \<le> x" (* Names with tmp_ will be hidden later *)
and tmp_transitive: "x \<le> y \<Longrightarrow> y \<le> z \<Longrightarrow> x \<le> z"
and tmp_antisym: "x \<le> y \<Longrightarrow> y \<le> x \<Longrightarrow> x = y"
and tmp_top: "x \<le> top"
and tmp_pos: "x \<ge> 0" (* zero_le *)
and tmp_inf1: "inf x y \<le> x"
and tmp_inf2: "inf x y \<le> y"
and tmp_inf: "x \<le> y \<Longrightarrow> x \<le> z \<Longrightarrow> x \<le> inf y z"
and tmp_assoc: "x + y + z = x + (y + z)" 
and tmp_comm: "x + y = y + x"
and tmp_mono: "x \<le> y \<Longrightarrow> z + x \<le> z + y"
and tmp_zero_neutral: "0 + x = x"
and subspace_plus_sup: "y \<le> x \<Longrightarrow> z \<le> x \<Longrightarrow> y + z \<le> x"
and tmp_Inf1: "x \<in> A \<Longrightarrow> Inf A \<le> x"
and tmp_Inf2: "(\<And>x. x \<in> A \<Longrightarrow> z \<le> x) \<Longrightarrow> z \<le> Inf A"
and tmp_Sup1: "x \<in> A \<Longrightarrow> Sup A \<ge> x"
and tmp_Sup2: "(\<And>x. x \<in> A \<Longrightarrow> z \<ge> x) \<Longrightarrow> z \<ge> Sup A"
and tmp_Inf3: "Inf {} = (top::'a subspace)" 
and subspace_empty_Sup: "Sup {} = (0::'a subspace)"
for x y z :: "'a subspace"

instantiation subspace :: (type)order begin
instance apply intro_classes
    by (fact less_subspace_def, fact tmp_reflex, fact tmp_transitive, fact tmp_antisym)
end
hide_fact tmp_reflex tmp_transitive tmp_antisym

instantiation subspace :: (type)order_top begin
instance apply intro_classes by (fact tmp_top)
end
hide_fact tmp_top

instantiation subspace :: (type)order_bot begin
definition "(bot::'a subspace) = 0"
instance apply intro_classes unfolding bot_subspace_def by (fact tmp_pos)
end

instantiation subspace :: (type)ab_semigroup_add begin
instance apply intro_classes by (fact tmp_assoc, fact tmp_comm)
end
hide_fact tmp_assoc tmp_comm
  
instantiation subspace :: (type)ordered_ab_semigroup_add begin
instance apply intro_classes by (fact tmp_mono)
end
hide_fact tmp_mono
 
instantiation subspace :: (type)comm_monoid_add begin
instance apply intro_classes by (fact tmp_zero_neutral)
end
hide_fact tmp_zero_neutral
     
  
instantiation subspace :: (type)semilattice_sup begin
definition "sup a b = a+b" for a::"'a subspace"
instance apply intro_classes
  using add_left_mono sup_subspace_def tmp_pos apply fastforce
  using add_right_mono sup_subspace_def tmp_pos apply fastforce
  by (simp add: subspace_plus_sup sup_subspace_def)
end

instantiation subspace :: (type)canonically_ordered_monoid_add begin
instance apply intro_classes
  by (metis add.commute add.right_neutral add_left_mono antisym_conv subspace_plus_sup tmp_pos)
end
hide_fact tmp_pos
  
instantiation subspace :: (type)semilattice_inf begin
instance apply intro_classes by (fact tmp_inf1, fact tmp_inf2, fact tmp_inf)
end
hide_fact tmp_inf1 tmp_inf2 tmp_inf

instantiation subspace :: (type)lattice begin
instance ..
end

instantiation subspace :: (type)complete_lattice begin
instance apply intro_classes
       apply (fact tmp_Inf1, fact tmp_Inf2, fact tmp_Sup1, fact tmp_Sup2, fact tmp_Inf3)
    unfolding bot_subspace_def by (fact subspace_empty_Sup)
end
hide_fact tmp_Inf1 tmp_Inf2 tmp_Sup1 tmp_Sup2 tmp_Inf3
  
  
lemma top_not_bot[simp]: "(top::'a subspace) \<noteq> bot" 
  using subspace_zero_not_top bot_subspace_def by metis

lemma bot_plus[simp]: "bot + x = x" for x :: "'a subspace" unfolding sup_subspace_def[symmetric] by simp
lemma plus_bot[simp]: "x + bot = x" for x :: "'a subspace" unfolding sup_subspace_def[symmetric] by simp
lemma top_plus[simp]: "top + x = top" for x :: "'a subspace" unfolding sup_subspace_def[symmetric] by simp
lemma plus_top[simp]: "x + top = top" for x :: "'a subspace" unfolding sup_subspace_def[symmetric] by simp
    
axiomatization subspace_as_set :: "'a subspace \<Rightarrow> 'a state set"
    
definition "span A = Inf {S. A \<subseteq> subspace_as_set S}"
  
  
subsection \<open>Isometries\<close>
    
      
typedecl ('a,'b) isometry
type_synonym 'a isometry2 = "('a,'a) isometry"
  
axiomatization 
  adjoint :: "('a,'b) isometry \<Rightarrow> ('b,'a) isometry" ("_*" [99] 100) (* TODO: not an isometry! *)
and timesIso :: "('b,'c) isometry \<Rightarrow> ('a,'b) isometry \<Rightarrow> ('a,'c) isometry" 
and applyIso :: "('a,'b) isometry \<Rightarrow> 'a state \<Rightarrow> 'b state"
and applyIsoSpace :: "('a,'b) isometry \<Rightarrow> 'a subspace \<Rightarrow> 'b subspace"
and imageIso :: "('a,'b) isometry \<Rightarrow> 'b subspace" 
where
 applyIso_0[simp]: "applyIsoSpace U 0 = 0"
and applyIso_bot[simp]: "applyIsoSpace U bot = bot"
and applyIso_top[simp]: "applyIsoSpace U top = imageIso U"

  
consts cdot :: "'a \<Rightarrow> 'b \<Rightarrow> 'c" (infixl "\<cdot>" 70)
adhoc_overloading
  cdot timesIso applyIso applyIsoSpace
  
axiomatization 
    idIso :: "'a isometry2"
where
    apply_idIso[simp]: "applyIso idIso \<psi> = \<psi>"
and apply_idIso_space[simp]: "applyIsoSpace idIso S = S"
and times_idIso[simp]: "U \<cdot> idIso = U"
  for \<psi> :: "'a state" and S :: "'a subspace" and U :: "('a,'b) isometry"
  
axiomatization identity :: "'a isometry2" where
    apply_id[simp]: "identity \<cdot> \<psi> = \<psi>"
and times_id[simp]: "identity \<cdot> U = U" 
and apply_space_id[simp]: "identity \<cdot> S = S" 
for \<psi> :: "'a state" and U :: "('b,'a) isometry" and S :: "'a subspace"

definition "unitary U = (U \<cdot> (U*) = identity)"  
  
axiomatization where 
    unitary_adjoint[simp]: "unitary U \<Longrightarrow> U* = U" 
and unitary_image[simp]: "unitary U \<Longrightarrow> imageIso U = top"
for U :: "'a isometry2"

section \<open>Projectors\<close>

typedecl 'a projector
axiomatization proj :: "'a state \<Rightarrow> 'a projector"
  and imProj :: "'a projector \<Rightarrow> 'a subspace"
  
section \<open>Measurements\<close>
  
typedecl ('a,'b) measurement
axiomatization mproj :: "('a,'b) measurement \<Rightarrow> 'a \<Rightarrow> 'b projector"
  and mtotal :: "('a,'b) measurement \<Rightarrow> bool"
  
axiomatization computational_basis :: "('a, 'a) measurement" where
  mproj_computational_basis[simp]: "mproj computational_basis x = proj (ket x)"
  
section \<open>Quantum variables\<close>

typedecl 'a qvariable (* a variable, refers to a location in a memory *)
axiomatization variable_name :: "'a qvariable \<Rightarrow> string"
typedecl 'a qvariables (* represents a tuple of variables, of joint type 'a *)

axiomatization
    qvariable_names :: "'a qvariables \<Rightarrow> string list"
(* and qvariable_cons :: "'a qvariable \<Rightarrow> 'b qvariables \<Rightarrow> ('a \<times> 'b) qvariables" *)
and qvariable_concat :: "'a qvariables \<Rightarrow> 'b qvariables \<Rightarrow> ('a * 'b) qvariables"
and qvariable_singleton :: "'a qvariable \<Rightarrow> 'a qvariables"
and qvariable_unit :: "unit qvariables"

nonterminal qvariable_list_args
syntax
  "qvariable_unit"      :: "qvariable_list_args \<Rightarrow> 'a"        ("(1'[[']])")
  "qvariable_unit"      :: "qvariable_list_args \<Rightarrow> 'a"        ("(1'\<lbrakk>'\<rbrakk>)")
  "_qvariables"      :: "qvariable_list_args \<Rightarrow> 'a"        ("(1'[[_']])")
  "_qvariables"      :: "qvariable_list_args \<Rightarrow> 'a"        ("(1'\<lbrakk>_'\<rbrakk>)")
  "_qvariable_list_arg"  :: "'a \<Rightarrow> qvariable_list_args"                   ("_")
  "_qvariable_list_args" :: "'a \<Rightarrow> qvariable_list_args \<Rightarrow> qvariable_list_args"     ("_,/ _")

translations
  "_qvariables (_qvariable_list_args x y)" \<rightleftharpoons> "CONST qvariable_concat (CONST qvariable_singleton x) (_qvariables y)"
  "_qvariables (_qvariable_list_arg x)" \<rightleftharpoons> "CONST qvariable_singleton x"
  "_qvariables (_qvariable_list_args x y)" \<leftharpoondown> "CONST qvariable_concat (_qvariables (_qvariable_list_arg x)) (_qvariables y)"
  

axiomatization where
  qvariable_names_cons[simp]: "qvariable_names (qvariable_concat X Y) = qvariable_names X @ qvariable_names Y"
  and qvariable_singleton_name[simp]: "qvariable_names (qvariable_singleton x) = [variable_name x]"
  and qvariable_unit_name[simp]: "qvariable_names qvariable_unit = []"
  for X::"'a qvariables" and Y::"'b qvariables" and x::"'c qvariable"

definition "qvariables_distinct X == distinct (qvariable_names X)"



  
section \<open>Assertions\<close>
    
typedecl mem2
type_synonym assertion = "mem2 subspace"

subsection \<open>Classical assertions\<close>
  
definition classical_subspace :: "bool \<Rightarrow> assertion"  ("\<CC>\<ll>\<aa>[_]")
  where "\<CC>\<ll>\<aa>[b] = (if b then top else bot)"
syntax classical_subspace :: "bool \<Rightarrow> assertion"  ("Cla[_]")
    
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
(* lemma INF_Cla[simp]: "(INF z. Cla[x z]) = Cla[\<forall>z. x z]" 
  by simp *)

lemma free_INF[simp]: "(INF x:X. A) = Cla[X={}] + A"
  apply (cases "X={}") by auto
  
axiomatization colocal_ass_qvars :: "assertion \<Rightarrow> 'a qvariables \<Rightarrow> bool"
  and colocal_qvars_qvars :: "'a qvariables \<Rightarrow> 'b qvariables \<Rightarrow> bool"
  and colocal_qvar_qvars :: "'a qvariable \<Rightarrow> 'b qvariables \<Rightarrow> bool"

consts colocal :: "'a \<Rightarrow> 'b \<Rightarrow> bool"
adhoc_overloading colocal colocal_ass_qvars colocal_qvars_qvars colocal_qvar_qvars
  
axiomatization where 
  colocal_qvariable_names[simp]: "set (qvariable_names Q) \<inter> set (qvariable_names R) = {} \<Longrightarrow> colocal Q R" 
  for Q :: "'a qvariables" and R :: "'b qvariables"


subsection \<open>Quantum equality\<close>

axiomatization quantum_equality_full :: "('a,'c) isometry \<Rightarrow> 'a qvariables \<Rightarrow> ('b,'c) isometry \<Rightarrow> 'b qvariables \<Rightarrow> assertion"
abbreviation "quantum_equality" :: "'a qvariables \<Rightarrow> 'a qvariables \<Rightarrow> assertion" (infix "\<equiv>\<qq>" 100)
  where "quantum_equality X Y \<equiv> quantum_equality_full idIso X idIso Y"
syntax quantum_equality :: "'a qvariables \<Rightarrow> 'a qvariables \<Rightarrow> assertion" (infix "==q" 100)
syntax "_quantum_equality" :: "qvariable_list_args \<Rightarrow> qvariable_list_args \<Rightarrow> assertion" ("Qeq'[_=_']")
translations
  "_quantum_equality a b" \<rightharpoonup> "CONST quantum_equality (_qvariables a) (_qvariables b)"

axiomatization where colocal_quantum_eq[simp]: "colocal Q1 R \<Longrightarrow> colocal Q2 R \<Longrightarrow> colocal (Q1 \<equiv>\<qq> Q2) R"
 for Q1 Q2 :: "'c qvariables" and R :: "'a qvariables"

subsection \<open>Subspace division\<close>

(* term "space_div (\<lbrakk>B1\<rbrakk> \<equiv>\<qq> \<lbrakk>A2\<rbrakk>) EPR \<lbrakk>A1, B1\<rbrakk>" *)

subsection \<open>Lifting\<close>
  
axiomatization
    liftIso :: "'a isometry2 \<Rightarrow> 'a qvariables \<Rightarrow> mem2 isometry2"
and liftProj :: "'a projector \<Rightarrow> 'a qvariables \<Rightarrow> mem2 projector"
and liftSpace :: "'a subspace \<Rightarrow> 'a qvariables \<Rightarrow> assertion"

consts lift :: "'a \<Rightarrow> 'b \<Rightarrow> 'c" ("_\<^sub>@_"  [91,91] 90 )
adhoc_overloading
  lift liftIso liftSpace
  
axiomatization where 
    adjoint_lift[simp]: "adjoint (liftIso U Q) = liftIso (adjoint U) Q" 
and imageIso_lift[simp]: "imageIso (liftIso U Q) = liftSpace (imageIso U) Q"
and top_lift[simp]: "liftSpace top Q = top"
and bot_lift[simp]: "liftSpace bot Q = bot"
and unitary_lift[simp]: "unitary (liftIso U Q) = unitary U"
for U :: "'a isometry2"
  
axiomatization space_div :: "assertion \<Rightarrow> 'a state \<Rightarrow> 'a qvariables \<Rightarrow> assertion" ("_ \<div> _@_" [89,89,89] 90)
  where leq_space_div[simp]: "colocal A Q \<Longrightarrow> (A \<le> B \<div> \<psi>@Q) = (A \<sqinter> span {\<psi>}\<^sub>@Q \<le> B)"


  
section \<open>Common quantum objects\<close>

axiomatization EPR :: "(bit*bit) state"

axiomatization CNOT :: "(bit*bit) isometry2" where
  unitaryCNOT[simp]: "unitary CNOT"
axiomatization H :: "bit isometry2" 
  and X :: "bit isometry2"
  and Y :: "bit isometry2"
  and Z :: "bit isometry2"
  where
  unitaryH[simp]: "unitary H"
and unitaryX[simp]: "unitary X"
and unitaryY[simp]: "unitary Y"
and unitaryZ[simp]: "unitary Z"

ML_file \<open>qrhl.ML\<close>
  
section \<open>Experiments\<close>
  
axiomatization where mtotal_computational_basis [simp]: "mtotal computational_basis"
axiomatization where imProj_proj [simp]: "imProj (proj \<psi>) = span {\<psi>}" for \<psi> :: "'a state"
axiomatization where imProj_liftProj [simp]: "imProj (liftProj P Q) = liftSpace (imProj P) Q" for P :: "'a projector" and Q
axiomatization where quantum_eq_unique [simp]: "quantum_equality Q R \<sqinter> liftSpace (span{\<psi>}) Q = liftSpace (span{\<psi>}) Q \<sqinter> liftSpace (span{\<psi>}) R"
  for Q R :: "'a qvariables" and \<psi> :: "'a state"

axiomatization probability :: "string \<Rightarrow> program \<Rightarrow> program_state \<Rightarrow> real" 
syntax "_probability" :: "ident \<Rightarrow> program \<Rightarrow> program_state \<Rightarrow> real" ("Pr[_:_'(_')]")
parse_translation \<open>[("_probability", fn ctx => fn [Const(v,_),p,rho] =>
  @{const probability} $ HOLogic.mk_string v $ p $ rho)]\<close>
    
print_translation \<open>[(@{const_syntax probability}, fn ctx => fn [str,p,rho] =>
  Const(@{syntax_const "_probability"},dummyT) $ Const(QRHL.dest_string_syntax str,dummyT) $ p $ rho)]\<close>
  
end
