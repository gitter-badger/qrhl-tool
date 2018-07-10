theory EPR
  imports QRHL
begin

lemma final_goal:
  assumes [simp]: "declared_qvars \<lbrakk>q1,r1,q2,r2\<rbrakk>"
    shows "span {EPR}\<guillemotright>\<lbrakk>q2, r2\<rbrakk> \<sqinter> span {EPR}\<guillemotright>\<lbrakk>q1, r1\<rbrakk> \<le> hadamard\<guillemotright>\<lbrakk>r2\<rbrakk> \<cdot> (hadamard\<guillemotright>\<lbrakk>q1\<rbrakk> \<cdot> \<lbrakk>q1, r1\<rbrakk> \<equiv>\<qq> \<lbrakk>q2, r2\<rbrakk>)"
  apply (simp add: prepare_for_code)
  by eval

end