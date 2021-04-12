Require Import Coqlib.
Require Import ITreelib.
Require Import Universe.
Require Import STS.
Require Import Behavior.
Require Import ModSem.
Require Import Skeleton.
Require Import PCM.
Require Import HoareDef.

Generalizable Variables E R A B C X Y Σ.

Set Implicit Arguments.



Section PROOF.

  Context `{Σ: GRA.t}.
  (* Context `{@GRA.inG memRA Σ}. *)

  (***
        void* x = malloc(1);
        *x = 42;
        (* unknown_call(x); *)
        y = *x;
        return y;
   ***)
  Definition mainF: Any.t -> itree Es Any.t :=
    fun _ =>
      (* x <- ((↓) <$> trigger (Call "alloc" [Vint 1]↑)) >>= (ǃ);; *)
      x <- trigger (Call "alloc" [Vint 1]↑);;
      `x: val <- x↓ǃ;;
      trigger (Call "store" [x ; Vint 42]↑);;
      (* trigger (Call "unknown_call" [x]);; *)
      (* `y: val <- ((↓) <$> trigger (Call "load" [x]↑)) >>= (ǃ);; *)
      y <- trigger (Call "load" [x]↑);;
      `y: val <- y↓ǃ;;
      Ret y↑
  .

  Definition MainSem: ModSem.t := {|
    ModSem.fnsems := [("main", mainF)];
    ModSem.mn := "Main";
    ModSem.initial_mr := ε;
    ModSem.initial_st := tt↑;
  |}
  .

  Definition Main: Mod.t := {|
    Mod.get_modsem := fun _ => MainSem;
    (* Mod.sk := Sk.unit; *)
    Mod.sk := [("main", Sk.Gfun)];
  |}
  .
End PROOF.