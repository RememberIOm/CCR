Require Import CoqlibCCR.
From compcert Require Import Integers Memory Globalenvs.
From stdpp Require Import numbers.

Local Open Scope Z.

Local Transparent Mem.alloc.
Local Transparent Mem.store.

Local Ltac solve_len := unfold encode_int, bytes_of_int, rev_if_be, inj_bytes in *;
                        change Archi.big_endian with false in *;
                        change Archi.ptr64 with true in *; ss.

Lemma setN_inside x l i c entry
  (IN_RANGE: i ≤ x /\ (x < i + Z.of_nat (length l)))
  (ENTRY: nth_error l (Z.to_nat (x - i)) = Some entry)
:
  Maps.ZMap.get x (Mem.setN l i c) = entry.
Proof.
  assert (Z.to_nat (x - i)%Z < length l)%nat by nia.
  apply nth_error_Some in H. destruct (nth_error _ _) eqn: E in H; clarify.
  clear H. move l at top. revert_until l. induction l; i; ss; try nia.
  destruct (Nat.eq_dec (Z.to_nat (x - i)) 0).
  - rewrite e in *. ss. clarify. assert (x = i) by nia. rewrite H in *.
    rewrite Mem.setN_outside; try nia. apply Maps.ZMap.gss.
  - change (a :: l) with ([a] ++ l) in E. rewrite nth_error_app2 in E; ss; try nia.
    replace (Z.to_nat (x - i) - 1)%nat with (Z.to_nat (x - (i + 1))) in E by nia.
    eapply IHl; et. nia.
Qed.


Lemma alloc_store_zero_condition m m0 m1 start len b
  (ALLOC: Mem.alloc m start (start + len) = (m0, b))
  (STORE_ZEROS: Globalenvs.R_store_zeros m0 b start len (Some m1))
:
  <<FILLED_ZERO: forall ofs, start ≤ ofs < start + len ->
                  Maps.ZMap.get ofs (Maps.PMap.get b m1.(Mem.mem_contents)) = Byte Byte.zero>>.
Proof.
  unfold Mem.alloc in ALLOC. clarify.
  remember (Some m1) as optm in STORE_ZEROS.
  move STORE_ZEROS at top. revert_until STORE_ZEROS.
  induction STORE_ZEROS; red; i; ss; try nia.
  destruct (Coqlib.zlt ofs (p + 1)).
  - assert (Maps.ZMap.get ofs (Maps.PMap.get b (Mem.mem_contents m1)) =
              Maps.ZMap.get ofs (Maps.PMap.get b (Mem.mem_contents m'))).
    { set (p + 1) as p' in *. set (n - 1) as n' in *.
      clear -l STORE_ZEROS Heqoptm. clearbody p' n'. move STORE_ZEROS at top.
      revert_until STORE_ZEROS.
      induction STORE_ZEROS; i; ss; clarify; try nia.
      rewrite IHSTORE_ZEROS; et; try nia. unfold Mem.store in e0.
      des_ifs. ss. rewrite Maps.PMap.gss. rewrite Mem.setN_outside; et. }
    rewrite H0. unfold Mem.store in e0. des_ifs. ss.
    rewrite Maps.PMap.gss. erewrite setN_inside; solve_len; try nia.
    replace (ofs - p) with 0 by nia. et.
  - hexploit IHSTORE_ZEROS; et. i. des. eapply H0. nia.
Qed.
