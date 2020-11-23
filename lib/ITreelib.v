From ITree Require Export ITree Subevent.

From ITree Require Export
     ITree
     ITreeFacts
     Events.MapDefault
     Events.State
     Events.StateFacts
     EqAxiom
.
From ExtLib Require Export
     (* Data.String *)
     (* Structures.Monad *)
     (* Structures.Traversable *)
     (* Structures.Foldable *)
     (* Structures.Reducible *)
     (* OptionMonad *)
     Functor FunctorLaws
     Structures.Maps
     (* Data.List *)
.
Require Import Coqlib.

Export SumNotations.
Export ITreeNotations.
Export Monads.
Export MonadNotation.
Export FunctorNotation.
Export CatNotations.
Open Scope cat_scope.
Open Scope monad_scope.
Open Scope itree_scope.

Set Implicit Arguments.



Global Instance function_Map (K V: Type) (dec: forall k0 k1, {k0=k1} + {k0<>k1}): (Map K V (K -> option V)) :=
  Build_Map
    (fun _ => None)
    (fun k0 v m => fun k1 => if dec k0 k1 then Some v else m k1)
    (fun k0 m => fun k1 => if dec k0 k1 then None else m k1)
    (fun k m => m k)
    (fun m0 m1 => fun k => match (m0 k) with
                           | Some v => Some v
                           | _ => m1 k
                           end)
.



Lemma eq_is_bisim: forall E R (t1 t2 : itree E R), t1 = t2 -> t1 ≅ t2.
Proof. ii. clarify. reflexivity. Qed.
Lemma bisim_is_eq: forall E R (t1 t2 : itree E R), t1 ≅ t2 -> t1 = t2.
Proof. ii. eapply bisimulation_is_eq; eauto. Qed.



Ltac f := first [eapply bisim_is_eq|eapply eq_is_bisim].
Tactic Notation "f" "in" hyp(H) := first [eapply bisim_is_eq in H|eapply eq_is_bisim in H].
Ltac ides itr :=
  let T := fresh "T" in
  destruct (observe itr) eqn:T;
  sym in T; apply simpobs in T; apply bisim_is_eq in T; rewrite T in *; clarify.
Ltac csc := clarify; simpl_depind; clarify.

Notation "tau;; t2" := (Tau t2)
  (at level 200, right associativity) : itree_scope.



(*** COPIED FROM MASTER BRANCH. REMOVE LATER ***)
(*** COPIED FROM MASTER BRANCH. REMOVE LATER ***)
(*** COPIED FROM MASTER BRANCH. REMOVE LATER ***)
Lemma eutt_eq_bind : forall E R U (t1 t2: itree E U) (k1 k2: U -> itree E R), t1 ≈ t2 -> (forall u, k1 u ≈ k2 u) -> ITree.bind t1 k1 ≈ ITree.bind t2 k2.
Proof.
  intros.
  eapply eutt_clo_bind with (UU := Logic.eq); [eauto |].
  intros ? ? ->. apply H0.
Qed.
Ltac f_equiv := first [eapply eutt_eq_bind|eapply eqit_VisF|Morphisms.f_equiv].
(* eapply eqit_bind'| *)

Hint Rewrite @bind_trigger : itree.
Hint Rewrite @tau_eutt : itree.
Hint Rewrite @bind_tau : itree.

(* Tactic Notation "irw" "in" ident(H) := repeat (autorewrite with itree in H; cbn in H). *)
(* Tactic Notation "irw" := repeat (autorewrite with itree; cbn). *)

(*** TODO: IDK why but (1) ?UNUSNED is needed (2) "fold" tactic does not work. WHY????? ***)
Ltac fold_eutt :=
  repeat multimatch goal with
         | [ H: eqit eq true true ?A ?B |- ?UNUSED ] =>
           let name := fresh "tmp" in
           assert(tmp: eutt eq A B) by apply H; clear H; rename tmp into H
         end
.

Lemma bind_ret_map {E R1 R2} (u : itree E R1) (f : R1 -> R2) :
  (r <- u ;; Ret (f r)) = f <$> u.
Proof.
  f.
  rewrite <- (bind_ret_r u) at 2. apply eqit_bind.
  - hnf. intros. apply eqit_Ret. auto.
  - rewrite bind_ret_r. reflexivity.
Qed.

Lemma map_vis {E R1 R2 X} (e: E X) (k: X -> itree E R1) (f: R1 -> R2) :
  (* (f <$> (Vis e k)) ≅ Vis e (fun x => f <$> (k x)). *)
  ITree.map f (Vis e k) = Vis e (fun x => f <$> (k x)).
Proof.
  f.
  cbn.
  unfold ITree.map.
  autorewrite with itree. refl.
Qed.




(*** TODO: move to SIRCommon ***)
Lemma unfold_interp_mrec :
forall (D E : Type -> Type) (ctx : forall T : Type, D T -> itree (D +' E) T) 
  (R : Type) (t : itree (D +' E) R), interp_mrec ctx t = _interp_mrec ctx (observe t).
Proof.
  i. f. eapply unfold_interp_mrec; et.
Qed.

Lemma bind_ret_l : forall (E : Type -> Type) (R S : Type) (r : R) (k : R -> itree E S),
    ` x : _ <- Ret r;; k x = k r.
Proof.
  i. f. eapply bind_ret_l.
Qed.

Lemma bind_ret_r : forall (E : Type -> Type) (R : Type) (s : itree E R), ` x : R <- s;; Ret x = s.
Proof.
  i. f. eapply bind_ret_r.
Qed.

Lemma bind_tau : forall (E : Type -> Type) (R U : Type) (t : itree E U) (k : U -> itree E R),
  ` x : _ <- Tau t;; k x = Tau (` x : _ <- t;; k x).
Proof.
  i. f. eapply bind_tau.
Qed.

Lemma bind_vis: forall (E : Type -> Type) (R U V : Type) (e : E V) (ek : V -> itree E U) (k : U -> itree E R),
  ` x : _ <- Vis e ek;; k x = Vis e (fun x : V => ` x : _ <- ek x;; k x).
Proof.
  i. f. eapply bind_vis.
Qed.

Lemma bind_trigger: forall (E : Type -> Type) (R U : Type) (e : E U) (k : U -> itree E R),
    ` x : _ <- ITree.trigger e;; k x = Vis e (fun x : U => k x).
Proof. i. f. eapply bind_trigger. Qed.

Lemma bind_bind : forall (E : Type -> Type) (R S T : Type) (s : itree E R) (k : R -> itree E S) (h : S -> itree E T),
    ` x : _ <- (` x : _ <- s;; k x);; h x = ` r : R <- s;; ` x : _ <- k r;; h x.
Proof. i. f. eapply bind_bind. Qed.

Lemma unfold_bind :
forall (E : Type -> Type) (R S : Type) (t : itree E R) (k : R -> itree E S),
` x : _ <- t;; k x = ITree._bind k (fun t0 : itree E R => ` x : _ <- t0;; k x) (observe t).
Proof. i. f. apply unfold_bind. Qed.

Lemma interp_mrec_bind:
  forall (D E : Type -> Type) (ctx : forall T : Type, D T -> itree (D +' E) T)
         (U T : Type) (t : itree (D +' E) U) (k : U -> itree (D +' E) T),
    interp_mrec ctx (` x : _ <- t;; k x) = ` x : U <- interp_mrec ctx t;; interp_mrec ctx (k x)
.
Proof. ii. f. eapply interp_mrec_bind. Qed.


Hint Rewrite unfold_interp_mrec : itree_axiom.
Hint Rewrite bind_ret_l : itree_axiom.
Hint Rewrite bind_ret_r : itree_axiom.
Hint Rewrite bind_tau : itree_axiom.
Hint Rewrite bind_vis : itree_axiom.
Hint Rewrite bind_trigger : itree_axiom.
Hint Rewrite bind_bind : itree_axiom.
Tactic Notation "irw" "in" ident(H) := repeat (autorewrite with itree_axiom in H; cbn in H).
Tactic Notation "irw" := repeat (autorewrite with itree_axiom; cbn).

Ltac iby3 TAC :=
  first [
      instantiate (1:= fun _ _ _ => _); TAC|
      instantiate (1:= fun _ _ _ => _ <- _ ;; _); TAC|
      instantiate (1:= fun _ _ _ => _ <- (_ <- _ ;; _) ;; _); TAC|
      instantiate (1:= fun _ _ _ => _ <- (_ <- (_ <- _ ;; _) ;; _) ;; _); TAC|
      instantiate (1:= fun _ _ _ => _ <- (_ <- (_ <- (_ <- _ ;; _) ;; _) ;; _) ;; _); TAC|
      instantiate (1:= fun _ _ _ => _ <- (_ <- (_ <- (_ <- (_ <- _ ;; _) ;; _) ;; _) ;; _) ;; _); TAC|
      fail
    ]
.

Ltac iby1 TAC :=
  first [
      instantiate (1:= fun '(_, (_, _)) => _); TAC|
      instantiate (1:= fun '(_, (_, _)) => _ <- _ ;; _); TAC|
      instantiate (1:= fun '(_, (_, _)) => _ <- (_ <- _ ;; _) ;; _); TAC|
      instantiate (1:= fun '(_, (_, _)) => _ <- (_ <- (_ <- _ ;; _) ;; _) ;; _); TAC|
      instantiate (1:= fun '(_, (_, _)) => _ <- (_ <- (_ <- (_ <- _ ;; _) ;; _) ;; _) ;; _); TAC|
      instantiate (1:= fun '(_, (_, _)) => _ <- (_ <- (_ <- (_ <- (_ <- _ ;; _) ;; _) ;; _) ;; _) ;; _); TAC|
      fail
    ]
.

Ltac grind :=  f; repeat (f_equiv; ii; des_ifs_safe); f.

Definition update K V map `{Map K V map}: K -> (V -> V) -> map -> option map :=
  fun k f m => do v <- Maps.lookup k m ; Some (Maps.add k (f v) m)
.

Lemma unfold_update
      K V map `{Map K V map}
      k vf m
  :
    update k vf m = match lookup k m with
                    | Some v => Some (add k (vf v) m)
                    | None => None
                    end
.
Proof. unfold update. uo. des_ifs. Qed.

Hint Unfold update.



Inductive taus E R: itree E R -> nat -> Prop :=
| taus_tau
    itr0 n
    (TL: taus itr0 n)
  :
    taus (Tau itr0) (1 + n)
| taus_ret
    r
  :
    taus (Ret r) 0
| taus_vis
    X (e: E X) k
  :
    taus (Vis e k) 0
.

Lemma unfold_spin
      E R
  :
    (@ITree.spin E R) = tau;; ITree.spin
.
Proof.
  rewrite itree_eta_ at 1. cbn. refl.
Qed.

Lemma spin_no_ret
      E R
      r
      (SIM: @ITree.spin E R ≈ Ret r)
  :
    False
.
Proof.
  punfold SIM.
  r in SIM. cbn in *.
  dependent induction SIM; ii; clarify.
  - eapply IHSIM; ss.
Qed.

Lemma spin_no_vis
      E R
      X (e: E X) k
      (SIM: @ITree.spin E R ≈ Vis e k)
  :
    False
.
Proof.
  punfold SIM.
  r in SIM. cbn in *.
  dependent induction SIM; ii; clarify.
  - eapply IHSIM; ss.
Qed.





Theorem diverge_spin
        E R
        (itr: itree E R)
        (DIVERGE: forall m, ~taus itr m)
  :
    <<SPIN: itr = ITree.spin>>
.
Proof.
  r. f.
  revert_until R.
  ginit.
  gcofix CIH. i. gstep.
  rewrite unfold_spin.
  ides itr; swap 2 3.
  { contradict DIVERGE. ii. eapply H. econs; et. }
  { contradict DIVERGE. ii. eapply H. econs; et. }
  econs; eauto.
  gbase. eapply CIH. ii. eapply DIVERGE. econs; eauto.
Qed.

Theorem spin_diverge
        E R
        (itr: itree E R)
        (SPIN: itr = ITree.spin)
  :
    <<DIVERGE: forall m, ~taus itr m>>
.
Proof.
  ii. clarify.
  ginduction m; ii; ss.
  { inv H.
    - rewrite unfold_spin in *. ss.
    - rewrite unfold_spin in *. ss.
  }
  inv H.
  rewrite unfold_spin in *. ss. clarify. eauto.
Qed.

Theorem case_analysis
        E R
        (itr: itree E R)
  :
    (<<CONVERGE: exists (m: nat), taus itr m>>)
    \/ (<<DIVERGE: itr = ITree.spin>>)
.
Proof.
  destruct (classic (exists m, taus itr m)); et.
  right.
  eapply diverge_spin.
  ii.
  eapply Classical_Pred_Type.not_ex_all_not with (n:=m) in H. Psimpl.
  des; et.
Qed.

Theorem spin_spin
        E R
        (i_src i_tgt: itree E R)
        (SPIN: i_src = ITree.spin)
        (SIM: i_src ≈ i_tgt)
  :
    <<SPIN: i_tgt = ITree.spin>>
.
Proof.
  clarify.
  r. f.
  revert_until R.
  ginit.
  gcofix CIH. i. gstep.
  rewrite unfold_spin.
  ides i_tgt; swap 2 3.
  { apply spin_no_ret in SIM. ss. }
  { apply spin_no_vis in SIM. ss. }
  econs; eauto.
  gbase. eapply CIH. rewrite tau_eutt in SIM. ss.
Qed.