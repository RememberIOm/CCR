Require Import Coqlib.
Require Import Universe.
Require Import STS.
Require Import Behavior.
Require Import ModSem.
Require Import Skeleton.
Require Import PCM.
Require Import HoareDef.
Require Import Stack1 Client1 BW1.
Require Import TODO TODOYJ Logic.

Set Implicit Arguments.

Definition hcall {X Y} (fn: gname) (varg: X): itree (hCallE +' pE +' eventE) Y :=
  vret <- trigger (hCall false fn varg↑);; vret <- vret↓ǃ;; Ret vret.

Section MAIN.

  Context `{Σ: GRA.t}.
  Context `{@GRA.inG bwRA Σ}.

  Let getbool_spec:  fspec := (mk_simple "Client"
                                         (fun (_: unit) _ o => (⌜True⌝))
                                         (fun _ _ => (⌜True⌝))).

  Let putint_spec:  fspec := (mk_simple "Client"
                                        (fun (_: unit) _ o => (⌜True⌝))
                                        (fun _ _ => (⌜True⌝))).

  Definition ClientStb: list (gname * fspec) :=
    Seal.sealing "stb" [("getbool", getbool_spec) ; ("putint", putint_spec)].

  Let main_spec:  fspec := (mk_simple "Main"
                                     (fun (_: unit) _ o => (Own (GRA.embed (bw_frag true)) ** ⌜o = ord_top⌝))
                                     (fun _ _ => (⌜True⌝))).

  Definition main_body: list val -> itree (hCallE +' pE +' eventE) val :=
    fun _ =>
      `b: val <- hcall "getbool" ([]: list val);; `b: bool <- (unbool b)?;;
      APC;;
      `i: Z <- trigger (Choose _);;
      guarantee(i = if b then 0xffffff%Z else 0%Z);;
      `_: val <- hcall "putint" [Vint i];;
      Ret Vundef
    .

  Definition MainStb: list (gname * fspec) :=
    Seal.sealing "stb" [("main", main_spec)].

  Definition MainSbtb: list (gname * fspecbody) :=
    [("main", mk_specbody main_spec main_body)
    ]
  .

  Definition MainSem: ModSem.t := {|
    ModSem.fnsems := List.map (fun '(fn, fsb) => (fn, fun_to_tgt (ClientStb++MainStb) fn fsb)) MainSbtb;
    ModSem.mn := "Main";
    ModSem.initial_mr := ε;
    ModSem.initial_st := tt↑;
  |}
  .

  Definition Main: Mod.t := {|
    Mod.get_modsem := fun _ => MainSem;
    Mod.sk := Sk.unit;
  |}
  .

End MAIN.
Global Hint Unfold MainStb: main.