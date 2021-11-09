Require Import Coqlib.
Require Import ITreelib.
Require Import ImpPrelude.
Require Import STS.
Require Import Behavior.
Require Import ModSem.
Require Import Skeleton.
Require Import PCM.
Require Import HoareDef STB.
Require Import MWHeader.
Require Import Mem1.

Set Implicit Arguments.



Section PROOF.

  Notation pget := (p0 <- trigger PGet;; p0 <- p0↓ǃ;; Ret p0) (only parsing).
  Notation pput p0 := (trigger (PPut p0↑)) (only parsing).

  Let Es := (hAPCE +' Es).

  Definition loopF: list val -> itree Es val :=
    fun varg =>
      _ <- (pargs [] varg)?;;
      `_: val <- ccallU "run" ([]: list val);;
      `_: val <- ccallU "loop" ([]: list val);;
      Ret Vundef
  .

  Definition mainF: list val -> itree Es val :=
    fun varg =>
      _ <- (pargs [] varg)?;;;
      _ <- Ret tt;;;
      pput (empty (K:=Z) (V:=Z));;;
      `_: val <- ccallU "init" ([]: list val);;
      `_: val <- ccallU "loop" ([]: list val);;
      Ret Vundef
  .

  Definition putF: list val -> itree Es val :=
    fun varg =>
      '(k, v) <- (pargs [Tint; Tint] varg)?;;
      full0 <- pget;;
      _ <- pput (add k v full0);;;
      syscallU "print" [k];;;
      Ret Vundef
  .

  Definition getF: list val -> itree Es val :=
    fun varg =>
      k <- (pargs [Tint] varg)?;;
      `full0: (Z -> option Z) <- pget;;
      v <- (full0 k)ǃ;;;
      syscallU "print" [k];;;
      Ret (Vint v)
  .

  Context `{Σ: GRA.t}.
  Context `{@GRA.inG memRA Σ}.
  Context `{@GRA.inG AppRA.t Σ}.
  Context `{@GRA.inG mapRA Σ}.
  Context `{@GRA.inG mwRA Σ}.
  Context `{@GRA.inG spRA Σ}.


  Definition MWsbtb: list (string * fspecbody) :=
    [("main", mk_specbody main_spec (cfunU mainF));
    ("loop", mk_specbody loop_spec (cfunU loopF));
    ("put", mk_specbody put_spec (cfunU putF));
    ("get", mk_specbody get_spec (cfunU getF))
    ].

  Context `{@GRA.inG mwRA Σ}.

  Definition SMWSem: SModSem.t := {|
    SModSem.fnsems := MWsbtb;
    SModSem.mn := "MW";
    SModSem.initial_mr := (GRA.embed sp_black) ⋅ GRA.embed ((mw_state Maps.empty));
    SModSem.initial_st := (empty (K:=Z) (V:=Z))↑;
  |}
  .

  Definition SMW: SMod.t := {|
    SMod.get_modsem := fun _ => SMWSem;
    SMod.sk := [("main", Sk.Gfun); ("loop", Sk.Gfun); ("put", Sk.Gfun); ("get", Sk.Gfun)];
  |}
  .

  Definition MW: Mod.t := (SMod.to_tgt (fun _ => to_stb (MWStb ++ AppStb ++ MapStb ++ MemStb)) SMW).

End PROOF.
