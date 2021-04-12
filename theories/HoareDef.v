Require Import Coqlib.
Require Import Universe.
Require Import STS.
Require Import Behavior.
Require Import ModSem.
Require Import Skeleton.
Require Import PCM.
From Ordinal Require Export Ordinal Arithmetic Inaccessible.
Require Import Any.

Generalizable Variables E R A B C X Y Σ.

Set Implicit Arguments.

(* Section sealing. *)
(*   (* Local Set Primitive Projections. *) *)
(*   Record sealing X (x: X) := (* mk_sealing *) { contents_of: X; sealing_prf: contents_of = x }. *)
(* End sealing. *)
(* Ltac hide_with NAME term := *)
(*   eassert(NAME: sealing term) by (econs; eauto); *)
(*   rewrite <- sealing_prf with (s:=NAME) in * *)
(* . *)
(* Ltac hide term := *)
(*   let NAME := fresh "_SEAL" in *)
(*   hide_with NAME term *)
(* . *)
(* Ltac unhide_term term := rewrite sealing_prf with (x:=term) in *; *)
(*                     match goal with *)
(*                     | [ H: sealing term |- _ ] => clear H *)
(*                     end. *)
(* Ltac unhide_name NAME := rewrite sealing_prf with (s:=NAME) in *; clear NAME. *)
(* Ltac unhide x := *)
(*   match (type of x) with *)
(*   | sealing _ => unhide_name x *)
(*   | _ => unhide_term x *)
(*   end. *)
(* Notation "☃ y" := (@contents_of _ y _) (at level 60, only printing). (** ☁☞ **) *)
(* Goal forall x, 5 + 5 = x. i. hide 5. cbn. hide_with MYNAME x. unhide x. unhide _SEAL. cbn. Abort. *)



Arguments transl_all {Σ} _%string_scope {T}%type_scope _%itree_scope. (*** TODO: move to ModSem ***)

Inductive ord: Type :=
| ord_pure (n: Ord.t)
| ord_top
.

Definition is_pure (o: ord): bool := match o with | ord_pure _ => true | _ => false end.

Definition ord_lt (next cur: ord): Prop :=
  match next, cur with
  | ord_pure next, ord_pure cur => (next < cur)%ord
  | _, ord_top => True
  | _, _ => False
  end
.

(**
(defface hi-light-green-b
  '((((min-colors 88)) (:weight bold :foreground "dark magenta"))
    (t (:weight bold :foreground "dark magenta")))
  "Face for hi-lock mode."
  :group 'hi-lock-faces)

 **)


Section PSEUDOTYPING.

(*** execute following commands in emacs (by C-x C-e)
     (progn (highlight-phrase "Any" 'hi-red-b) (highlight-phrase "Any_src" 'hi-green-b) (highlight-phrase "Any_tgt" 'hi-blue-b)
            (highlight-phrase "Any_mid" 'hi-light-green-b)
            (highlight-phrase "Y" 'hi-green-b) (highlight-phrase "Z" 'hi-green-b)) ***)
Let Any_src := Any.t. (*** src argument (e.g., List nat) ***)
Let Any_mid := Any.t. (*** src argument (e.g., List nat) ***)
Let Any_tgt := Any.t. (*** tgt argument (i.e., list val) ***)

Section PROOF.
  (* Context {myRA} `{@GRA.inG myRA Σ}. *)
  Context {Σ: GRA.t}.
  Let GURA: URA.t := GRA.to_URA Σ.
  Local Existing Instance GURA.
  Context {X Y Z: Type}.

  Definition HoareCall
             (tbr: bool)
             (ord_cur: ord)
             (P: X -> Y -> Any_tgt -> ord -> Σ -> Prop)
             (Q: X -> Z -> Any_tgt -> Σ -> Prop):
    gname -> Y -> itree Es Z :=
    fun fn varg_src =>
      '(marg, farg) <- trigger (Choose _);; put marg farg;; (*** updating resources in an abstract way ***)
      rarg <- trigger (Choose Σ);; discard rarg;; (*** virtual resource passing ***)
      x <- trigger (Choose X);; varg_tgt <- trigger (Choose Any_tgt);;
      ord_next <- trigger (Choose _);;
      guarantee(P x varg_src varg_tgt  ord_next rarg);; (*** precondition ***)

      guarantee(ord_lt ord_next ord_cur /\ (tbr = true -> is_pure ord_next) /\ (tbr = false -> ord_next = ord_top));;
      vret_tgt <- trigger (Call fn varg_tgt);; (*** call ***)

      rret <- trigger (Take Σ);; forge rret;; (*** virtual resource passing ***)
      vret_src <- trigger (Take Z);;
      checkWf;;
      assume(Q x vret_src vret_tgt rret);; (*** postcondition ***)

      Ret vret_src (*** return to body ***)
  .

End PROOF.















(*** TODO: Move to Coqlib. TODO: Somehow use case_ ??? ***)
(* Definition map_fst A0 A1 B (f: A0 -> A1): (A0 * B) -> (A1 * B) := fun '(a, b) => (f a, b). *)
(* Definition map_snd A B0 B1 (f: B0 -> B1): (A * B0) -> (A * B1) := fun '(a, b) => (a, f b). *)

Variant hCallE: Type -> Type :=
| hCall (tbr: bool) (fn: gname) (varg_src: Any_src): hCallE Any_src
(*** tbr == to be removed ***)
.

Notation Es' := (hCallE +' pE +' eventE).

Program Fixpoint _APC (at_most: Ord.t) {wf Ord.lt at_most}: itree Es' unit :=
  break <- trigger (Choose _);;
  if break: bool
  then Ret tt
  else
    n <- trigger (Choose Ord.t);;
    trigger (Choose (n < at_most)%ord);;
    '(fn, varg) <- trigger (Choose _);;
    trigger (hCall true fn varg);;
    _APC n.
Next Obligation.
  eapply Ord.lt_well_founded.
Qed.

Definition APC: itree Es' unit :=
  at_most <- trigger (Choose _);;
  guarantee(at_most < kappa)%ord;;
  _APC at_most
.

Lemma unfold_APC:
  forall at_most, _APC at_most =
                  break <- trigger (Choose _);;
                  if break: bool
                  then Ret tt
                  else
                    n <- trigger (Choose Ord.t);;
                    guarantee (n < at_most)%ord;;
                    '(fn, varg) <- trigger (Choose _);;
                    trigger (hCall true fn varg);;
                    _APC n.
Proof.
  i. unfold _APC. rewrite Fix_eq; eauto.
  { repeat f_equal. extensionality break. destruct break; ss.
    repeat f_equal. extensionality n.
    unfold guarantee. rewrite bind_bind.
    repeat f_equal. extensionality p.
    rewrite bind_ret_l. repeat f_equal. extensionality x. destruct x. auto. }
  { i. replace g with f; auto. extensionality o. eapply H. }
Qed.
Global Opaque _APC.





Section CANCEL.

  Context `{Σ: GRA.t}.

  (*** spec table ***)
  Record fspec: Type := mk {
    mn: mname;
    X: Type; (*** a meta-variable ***)
    AA: Type;
    AR: Type;
    precond: X -> AA -> Any_tgt -> ord -> Σ -> Prop; (*** meta-variable -> new logical arg -> current logical arg -> resource arg -> Prop ***)
    postcond: X -> AR -> Any_tgt -> Σ -> Prop; (*** meta-variable -> new logical ret -> current logical ret -> resource ret -> Prop ***)
  }
  .

  Record fspecbody: Type := mk_specbody {
    fsb_fspec:> fspec;
    fsb_body: fsb_fspec.(AA) -> itree (hCallE +' pE +' eventE) fsb_fspec.(AR);
  }
  .

  (*** argument remains the same ***)
  (* Definition mk_simple (mn: string) {X: Type} (P: X -> Any_tgt -> Σ -> ord -> Prop) (Q: X -> Any_tgt -> Σ -> Prop): fspec. *)
  (*   econs. *)
  (*   { apply mn. } *)
  (*   { i. apply (P X0 X2 X3 H /\ X1↑ = X2). } *)
  (*   { i. apply (Q X0 X2 X3 /\ X1↑ = X2). } *)
  (* Unshelve. *)
  (*   apply (list val). *)
  (*   apply (val). *)
  (* Defined. *)
  Definition mk_simple (mn: string) {X: Type} (P: X -> Any_tgt -> ord -> Σ -> Prop) (Q: X -> Any_tgt -> Σ -> Prop): fspec :=
    @mk mn X (list val) (val) (fun x y a o r => P x a o r /\ y↑ = a) (fun x z a r => Q x a r /\ z↑ = a)
  .




  Section INTERP.
  (* Variable stb: gname -> option fspec. *)
  (*** TODO: I wanted to use above definiton, but doing so makes defining ms_src hard ***)
  (*** We can fix this by making ModSemL.fnsems to a function, but doing so will change the type of
       ModSemL.add to predicate (t -> t -> t -> Prop), not function.
       - Maybe not. I thought one needed to check uniqueness of gname at the "add",
         but that might not be the case.
         We may define fnsems: string -> option (list val -> itree Es val).
         When adding two ms, it is pointwise addition, and addition of (option A) will yield None when both are Some.
 ***)
  (*** TODO: try above idea; if it fails, document it; and refactor below with alist ***)
  Variable stb: list (gname * fspec).

  Definition handle_hCallE_src: hCallE ~> itree Es :=
    fun _ '(hCall tbr fn varg_src) =>
      match tbr with
      | true => tau;; trigger (Choose _)
      | false => trigger (Call fn varg_src)
      end
  .

  Definition interp_hCallE_src `{E -< Es}: itree (hCallE +' E) ~> itree Es :=
    interp (case_ (bif:=sum1) (handle_hCallE_src)
                  ((fun T X => trigger X): E ~> itree Es))
  .

  Definition body_to_src {AA AR} (body: AA -> itree (hCallE +' pE +' eventE) AR): AA -> itree Es AR :=
    fun varg_src => interp_hCallE_src (body varg_src)
  .

  Definition fun_to_src {AA AR} (body: AA -> itree (hCallE +' pE +' eventE) AR): (Any_src -> itree Es Any_src) :=
    (cfun (body_to_src body))
  .





  Definition handle_hCallE_mid (ord_cur: ord): hCallE ~> itree Es :=
    fun _ '(hCall tbr fn varg_src) =>
      tau;;
      ord_next <- (if tbr then o0 <- trigger (Choose _);; Ret (ord_pure o0) else Ret ord_top);;
      guarantee(ord_lt ord_next ord_cur);;
      let varg_mid: Any_mid := (Any.pair ord_next↑ varg_src) in
      trigger (Call fn varg_mid)
  .

  Definition interp_hCallE_mid `{E -< Es} (ord_cur: ord): itree (hCallE +' E) ~> itree Es :=
    interp (case_ (bif:=sum1) (handle_hCallE_mid ord_cur)
                  ((fun T X => trigger X): E ~> itree Es))
  .

  Definition body_to_mid {AA AR} (ord_cur: ord) (body: (AA) -> itree (hCallE +' pE +' eventE) AR): AA -> itree Es AR :=
    fun varg_mid => interp_hCallE_mid ord_cur (body varg_mid)
  .

  Definition fun_to_mid {AA AR} (body: AA -> itree (hCallE +' pE +' eventE) AR): (Any_mid -> itree Es Any_src) :=
    fun varg_mid =>
      '(ord_cur, varg_src) <- varg_mid↓ǃ;;
      vret_src <- (match ord_cur with
                   | ord_pure n => (interp_hCallE_mid ord_cur APC);; trigger (Choose _)
                   | _ => (body_to_mid ord_cur body) varg_src
                   end);;
      Ret vret_src↑
  .





  Definition handle_hCallE_tgt (ord_cur: ord): hCallE ~> itree Es :=
    fun _ '(hCall tbr fn varg_src) =>
      '(_, f) <- (List.find (fun '(_fn, _) => dec fn _fn) stb)ǃ;;
      varg_src <- varg_src↓ǃ;;
      vret_src <- (HoareCall tbr ord_cur (f.(precond)) (f.(postcond)) fn varg_src);;
      Ret vret_src↑
  .

  Definition interp_hCallE_tgt `{E -< Es} (ord_cur: ord): itree (hCallE +' E) ~> itree Es :=
    interp (case_ (bif:=sum1) (handle_hCallE_tgt ord_cur)
                  ((fun T X => trigger X): E ~> itree Es))
  .

  Definition body_to_tgt {AA AR} (ord_cur: ord)
             (body: AA -> itree (hCallE +' pE +' eventE) AR): AA -> itree Es AR :=
    fun varg_tgt => interp_hCallE_tgt ord_cur (body varg_tgt)
  .

  Definition HoareFun
             {X Y Z: Type}
             (P: X -> Y -> Any_tgt -> ord -> Σ -> Prop)
             (Q: X -> Z -> Any_tgt -> Σ -> Prop)
             (body: Y -> itree Es' Z): Any_tgt -> itree Es Any_tgt := fun varg_tgt =>
    varg_src <- trigger (Take Y);;
    x <- trigger (Take X);;
    rarg <- trigger (Take Σ);; forge rarg;; (*** virtual resource passing ***)
    (checkWf);;
    ord_cur <- trigger (Take _);;
    assume(P x varg_src varg_tgt  ord_cur rarg);; (*** precondition ***)


    vret_src <- match ord_cur with
                | ord_pure n => (interp_hCallE_tgt ord_cur APC);; trigger (Choose _)
                | _ => (body_to_tgt ord_cur body) varg_src
                end;;
    (* vret_src <- body ord_cur varg_src;; (*** "rudiment": we don't remove extcalls because of termination-sensitivity ***) *)

    vret_tgt <- trigger (Choose Any_tgt);;
    '(mret, fret) <- trigger (Choose _);; put mret fret;; (*** updating resources in an abstract way ***)
    rret <- trigger (Choose Σ);; guarantee(Q x vret_src vret_tgt rret);; (*** postcondition ***)
    (discard rret);; (*** virtual resource passing ***)

    Ret vret_tgt (*** return ***)
  .

  Definition fun_to_tgt (fn: gname) (sb: fspecbody): (Any_tgt -> itree Es Any_tgt) :=
    let fs: fspec := sb.(fsb_fspec) in
    (HoareFun (fs.(precond)) (fs.(postcond)) sb.(fsb_body))
  .

(*** NOTE:
body can execute eventE events.
Notably, this implies it can also execute UB.
With this flexibility, the client code can naturally be included in our "type-checking" framework.
Also, note that body cannot execute "rE" on its own. This is intended.

NOTE: we can allow normal "callE" in the body too, but we need to ensure that it does not call "HoareFun".
If this feature is needed; we can extend it then. At the moment, I will only allow hCallE.
***)

  End INTERP.



  Variable md_tgt: ModL.t.
  Let ms_tgt: ModSemL.t := (ModL.get_modsem md_tgt (Sk.load_skenv md_tgt.(ModL.sk))).

  Variable sbtb: list (gname * fspecbody).
  Let stb: list (gname * fspec) := List.map (fun '(gn, fsb) => (gn, fsb_fspec fsb)) sbtb.
  Hypothesis WTY: ms_tgt.(ModSemL.fnsems) = List.map (fun '(fn, sb) => (fn, (transl_all sb.(fsb_fspec).(mn)) <*> fun_to_tgt stb fn sb)) sbtb.

  Definition ms_src: ModSemL.t := {|
    ModSemL.fnsems := List.map (fun '(fn, sb) => (fn, (transl_all sb.(fsb_fspec).(mn)) <*> fun_to_src (fsb_body sb))) sbtb;
    ModSemL.initial_mrs := List.map (fun '(mn, (mr, mp)) => (mn, (ε, mp))) ms_tgt.(ModSemL.initial_mrs);
    (*** Note: we don't use resources, so making everything as a unit ***)
  |}
  .

  Definition md_src: ModL.t := {|
    ModL.get_modsem := fun _ => ms_src;
    ModL.sk := Sk.unit;
    (*** It is already a whole-program, so we don't need Sk.t anymore. ***)
    (*** Note: Actually, md_tgt's sk could also have been unit, which looks a bit more uniform. ***)
  |}
  .

  Definition ms_mid: ModSemL.t := {|
    ModSemL.fnsems := List.map (fun '(fn, sb) => (fn, (transl_all sb.(fsb_fspec).(mn)) <*> fun_to_mid (fsb_body sb))) sbtb;
    (* ModSem.initial_mrs := []; *)
    ModSemL.initial_mrs := List.map (fun '(mn, (mr, mp)) => (mn, (ε, mp))) ms_tgt.(ModSemL.initial_mrs);
    (*** Note: we don't use resources, so making everything as a unit ***)
  |}
  .

  Definition md_mid: ModL.t := {|
    ModL.get_modsem := fun _ => ms_mid;
    ModL.sk := Sk.unit;
    (*** It is already a whole-program, so we don't need Sk.t anymore. ***)
    (*** Note: Actually, md_tgt's sk could also have been unit, which looks a bit more uniform. ***)
  |}
  .













  Lemma interp_hCallE_src_bind
        `{E -< Es} A B
        (itr: itree (hCallE +' E) A) (ktr: A -> itree (hCallE +' E) B)
    :
      interp_hCallE_src (v <- itr ;; ktr v) = v <- interp_hCallE_src (itr);; interp_hCallE_src (ktr v)
  .
  Proof. unfold interp_hCallE_src. ired. grind. Qed.

  Lemma interp_hCallE_tgt_bind
        `{E -< Es} A B
        (itr: itree (hCallE +' E) A) (ktr: A -> itree (hCallE +' E) B)
        stb0 cur
    :
      interp_hCallE_tgt stb0 cur (v <- itr ;; ktr v) = v <- interp_hCallE_tgt stb0 cur (itr);; interp_hCallE_tgt stb0 cur (ktr v)
  .
  Proof. unfold interp_hCallE_tgt. ired. grind. Qed.

End CANCEL.

End PSEUDOTYPING.

















  Hint Resolve Ord.lt_le_lt Ord.le_lt_lt OrdArith.lt_add_r OrdArith.le_add_l
       OrdArith.le_add_r Ord.lt_le
       Ord.lt_S
       Ord.S_lt
       Ord.S_supremum
       Ord.S_pos
    : ord.
  Hint Resolve Ord.le_trans Ord.lt_trans: ord_trans.
  Hint Resolve OrdArith.add_base_l OrdArith.add_base_r: ord_proj.

  Global Opaque EventsL.interp_Es.

  Require Import SimGlobal.






  Require Import Red.

  Ltac interp_red := rewrite interp_vis ||
                             rewrite interp_ret ||
                             rewrite interp_tau ||
                             rewrite interp_trigger ||
                             rewrite interp_bind.

  Ltac _red_itree f :=
    match goal with
    | [ |- ITree.bind' _ ?itr = _] =>
      match itr with
      | ITree.bind' _ _ =>
        instantiate (f:=_continue); apply bind_bind; fail
      | Tau _ =>
        instantiate (f:=_break); apply bind_tau; fail
      | Ret _ =>
        instantiate (f:=_continue); apply bind_ret_l; fail
      | _ =>
        fail
      end
    | _ => fail
    end.

  (*** TODO: Move to ModSem.v ***)
  Lemma interp_Es_unwrapU
        `{Σ: GRA.t}
        prog R st0 (r: option R)
    :
      EventsL.interp_Es prog (unwrapU r) st0 = r <- unwrapU r;; Ret (st0, r)
  .
  Proof.
    unfold unwrapU. des_ifs.
    - rewrite EventsL.interp_Es_ret. grind.
    - rewrite EventsL.interp_Es_triggerUB. unfold triggerUB. grind.
  Qed.

  Lemma interp_Es_unwrapN
        `{Σ: GRA.t}
        prog R st0 (r: option R)
    :
      EventsL.interp_Es prog (unwrapN r) st0 = r <- unwrapN r;; Ret (st0, r)
  .
  Proof.
    unfold unwrapN. des_ifs.
    - rewrite EventsL.interp_Es_ret. grind.
    - rewrite EventsL.interp_Es_triggerNB. unfold triggerNB. grind.
  Qed.

  Lemma interp_Es_assume
        `{Σ: GRA.t}
        prog st0 (P: Prop)
    :
      EventsL.interp_Es prog (assume P) st0 = assume P;; tau;; tau;; tau;; Ret (st0, tt)
  .
  Proof.
    unfold assume.
    repeat (try rewrite EventsL.interp_Es_bind; try rewrite bind_bind). grind.
    rewrite EventsL.interp_Es_eventE.
    repeat (try rewrite EventsL.interp_Es_bind; try rewrite bind_bind). grind.
    rewrite EventsL.interp_Es_ret.
    refl.
  Qed.

  Lemma interp_Es_guarantee
        `{Σ: GRA.t}
        prog st0 (P: Prop)
    :
      EventsL.interp_Es prog (guarantee P) st0 = guarantee P;; tau;; tau;; tau;; Ret (st0, tt)
  .
  Proof.
    unfold guarantee.
    repeat (try rewrite EventsL.interp_Es_bind; try rewrite bind_bind). grind.
    rewrite EventsL.interp_Es_eventE.
    repeat (try rewrite EventsL.interp_Es_bind; try rewrite bind_bind). grind.
    rewrite EventsL.interp_Es_ret.
    refl.
  Qed.





Ltac _red_Es_aux f itr :=
  match itr with
  | ITree.bind' _ _ =>
    instantiate (f:=_continue); eapply EventsL.interp_Es_bind; fail
  | Tau _ =>
    instantiate (f:=_break); apply EventsL.interp_Es_tau; fail
  | Ret _ =>
    instantiate (f:=_continue); apply EventsL.interp_Es_ret; fail
  | trigger ?e =>
    instantiate (f:=_break);
    match (type of e) with
    | context[callE] => apply EventsL.interp_Es_callE
    | context[eventE] => apply EventsL.interp_Es_eventE
    | context[EventsL.pE] => apply EventsL.interp_Es_pE
    | context[EventsL.rE] => apply EventsL.interp_Es_rE
    | _ => fail 2
    end
  | triggerUB =>
    instantiate (f:=_break); apply EventsL.interp_Es_triggerUB; fail
  | triggerNB =>
    instantiate (f:=_break); apply EventsL.interp_Es_triggerNB; fail
  | unwrapU _ =>
    instantiate (f:=_break); apply interp_Es_unwrapU; fail
  | unwrapN _ =>
    instantiate (f:=_break); apply interp_Es_unwrapN; fail
  | assume _ =>
    instantiate (f:=_break); apply interp_Es_assume; fail
  | guarantee _ =>
    instantiate (f:=_break); apply interp_Es_guarantee; fail
  | _ =>
    fail
  end
.

(*** TODO: move to ITreeLib ***)
Lemma bind_eta E X Y itr0 itr1 (ktr: ktree E X Y): itr0 = itr1 -> itr0 >>= ktr = itr1 >>= ktr. i; subst; refl. Qed.

Ltac _red_Es f :=
  match goal with
  | [ |- ITree.bind' _ (EventsL.interp_Es _ ?itr _) = _ ] =>
    eapply bind_eta; _red_Es_aux f itr
  | [ |- EventsL.interp_Es _ ?itr _ = _] =>
    _red_Es_aux f itr
  | _ => fail
  end.

Ltac _red_lsim f :=
  (_red_Es f) || (_red_itree f) || (fail).

Ltac ired_l := try (prw _red_lsim 2 0).
Ltac ired_r := try (prw _red_lsim 1 0).

Ltac ired_both := ired_l; ired_r.

  Ltac mred := repeat (cbn; ired_both).
  Ltac Esred :=
            try rewrite ! EventsL.interp_Es_rE; try rewrite ! EventsL.interp_Es_pE;
            try rewrite ! EventsL.interp_Es_eventE; try rewrite ! EventsL.interp_Es_callE;
            try rewrite ! EventsL.interp_Es_triggerNB; try rewrite ! EventsL.interp_Es_triggerUB (*** igo ***).
  (*** step and some post-processing ***)
  Ltac _step :=
    match goal with
    (*** terminal cases ***)
    | [ |- gpaco5 _ _ _ _ _ _ _ (triggerUB >>= _) _ ] =>
      unfold triggerUB; mred; _step; ss; fail
    | [ |- gpaco5 _ _ _ _ _ _ _ (triggerNB >>= _) _ ] =>
      exfalso
    | [ |- gpaco5 _ _ _ _ _ _ _ _ (triggerUB >>= _) ] =>
      exfalso
    | [ |- gpaco5 _ _ _ _ _ _ _ _ (triggerNB >>= _) ] =>
      unfold triggerNB; mred; _step; ss; fail

    (*** assume/guarantee ***)
    | [ |- gpaco5 _ _ _ _ _ _ _ (assume ?P ;; _) _ ] =>
      let tvar := fresh "tmp" in
      let thyp := fresh "TMP" in
      remember (assume P) as tvar eqn:thyp; unfold assume in thyp; subst tvar
    | [ |- gpaco5 _ _ _ _ _ _ _ (guarantee ?P ;; _) _ ] =>
      let tvar := fresh "tmp" in
      let thyp := fresh "TMP" in
      remember (guarantee P) as tvar eqn:thyp; unfold guarantee in thyp; subst tvar
    | [ |- gpaco5 _ _ _ _ _ _ _ _ (assume ?P ;; _) ] =>
      let tvar := fresh "tmp" in
      let thyp := fresh "TMP" in
      remember (assume P) as tvar eqn:thyp; unfold assume in thyp; subst tvar
    | [ |- gpaco5 _ _ _ _ _ _ _ _ (guarantee ?P ;; _) ] =>
      let tvar := fresh "tmp" in
      let thyp := fresh "TMP" in
      remember (guarantee P) as tvar eqn:thyp; unfold guarantee in thyp; subst tvar

    (*** default cases ***)
    | _ =>
      (gstep; econs; eauto; try (by eapply OrdArith.lt_from_nat; ss);
       (*** some post-processing ***)
       i;
       try match goal with
           | [ |- (eq ==> _)%signature _ _ ] =>
             let v_src := fresh "v_src" in
             let v_tgt := fresh "v_tgt" in
             intros v_src v_tgt ?; subst v_tgt
           end)
    end
  .
  Ltac steps := repeat (mred; try _step; des_ifs_safe).
  Ltac seal_left :=
    match goal with
    | [ |- gpaco5 _ _ _ _ _ _ _ ?i_src ?i_tgt ] => seal i_src
    end.
  Ltac seal_right :=
    match goal with
    | [ |- gpaco5 _ _ _ _ _ _ _ ?i_src ?i_tgt ] => seal i_tgt
    end.
  Ltac unseal_left :=
    match goal with
    | [ |- gpaco5 _ _ _ _ _ _ _ (@Seal.sealing _ _ ?i_src) ?i_tgt ] => unseal i_src
    end.
  Ltac unseal_right :=
    match goal with
    | [ |- gpaco5 _ _ _ _ _ _ _ ?i_src (@Seal.sealing _ _ ?i_tgt) ] => unseal i_tgt
    end.
  Ltac force_l := seal_right; _step; unseal_right.
  Ltac force_r := seal_left; _step; unseal_left.
  (* Ltac mstep := gstep; econs; eauto; [eapply from_nat_lt; ss|]. *)

  From ExtLib Require Import
       Data.Map.FMapAList.

  Hint Resolve cpn3_wcompat: paco.
  Ltac init :=
    split; ss; ii; clarify; rename y into varg; eexists 100%nat; ss; des; clarify;
    ginit; []; unfold alist_add, alist_remove; ss;
    unfold fun_to_tgt, cfun, HoareFun; ss.