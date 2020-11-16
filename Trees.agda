{-# OPTIONS --cubical --no-import-sorts #-}

module Trees where

open import Cubical.Core.Everything
open import Cubical.Foundations.Prelude
open import Cubical.Foundations.Everything
open import Cubical.Functions.Logic renaming (⊥ to ⊥ₚ)
open import Cubical.Relation.Everything
open import Cubical.HITs.PropositionalTruncation as PropTrunc
open import Cubical.HITs.SetQuotients renaming ([_] to eqCl)
open import Cubical.Data.Sigma
open import Cubical.Data.List
open import Cubical.Data.Empty renaming (elim to ⊥-elim; rec to ⊥-rec)

open import Cubical.Relation.Binary

record Tree : Type where
  coinductive
  field
    force : List Tree
open Tree public

data relLift {ℓ}{X Y : Type ℓ} (R : X → Y → Type ℓ) : List X → List Y → Type ℓ where
  [] : relLift R [] []
  _∷_ : ∀{x y xs ys} → R x y → relLift R xs ys → relLift R (x ∷ xs) (y ∷ ys)

record Bisim (xs ys : Tree) : Type where
  coinductive
  field
    forceEq : relLift Bisim (force xs) (force ys)
open Bisim

refl-Bisim : ∀ t → Bisim t t
refl-Bisim' : ∀ t → relLift Bisim t t
forceEq (refl-Bisim ts) = refl-Bisim' (force ts)
refl-Bisim' [] = []
refl-Bisim' (t ∷ ts) = (refl-Bisim t) ∷ refl-Bisim' ts

misib : {t₁ t₂ : Tree} → t₁ ≡ t₂ → Bisim t₁ t₂
misib {t₁} = J (λ x p → Bisim t₁ x) (refl-Bisim t₁)    

bisim : {t₁ t₂ : Tree} → Bisim t₁ t₂ → t₁ ≡ t₂
bisim' : {t₁ t₂ : List Tree} → relLift Bisim t₁ t₂ → t₁ ≡ t₂
force (bisim b i) = bisim' (forceEq b) i
bisim' [] = refl
bisim' (b ∷ bs) = cong₂ {C = λ _ _ → List Tree} _∷_ (bisim b) (bisim' bs)

data _∈_ {ℓ}{X : Type ℓ} (x : X) : List X → Type ℓ where
  here : ∀{y xs} → x ≡ y → x ∈ (y ∷ xs)
  there : ∀{y xs} → x ∈ xs → x ∈ (y ∷ xs)

relator : ∀{ℓ}{X Y : Type ℓ} (R : X → Y → Type ℓ)
  → List X → List Y → Type ℓ 
relator R xs ys =
  (∀ x → x ∈ xs → ∃[ y ∈ _ ] y ∈ ys × R x y)
  ×
  (∀ y → y ∈ ys → ∃[ x ∈ _ ] x ∈ xs × R x y)

record ExtEq (xs ys : Tree) : Type where
  coinductive
  field
    forceExt : relator ExtEq (force xs) (force ys)
open ExtEq public

νPfin : Type
νPfin = Tree / ExtEq



-- Cont : ∀ ℓ → Type (ℓ-suc ℓ)
-- Cont ℓ = Σ (Type ℓ) λ S → S → Type ℓ

-- ⟦_⟧ : ∀{ℓ} → Cont ℓ → Type ℓ → Type ℓ
-- ⟦ S , P ⟧ X = Σ S λ s → P s → X

-- record ν {ℓ} (C : Cont ℓ) : Type ℓ where
--   coinductive
--   field
--     force : ⟦ C ⟧ (ν C)

-- open ν

-- head : ∀{ℓ} {C : Cont ℓ} (x : ν C) → C .fst
-- head x = force x .fst

-- tails : ∀{ℓ} {C : Cont ℓ} (x : ν C)
--   → C .snd (head x) → ν C
-- tails x p = force x .snd p

-- eqLift : ∀{ℓ X Y} {C : Cont ℓ} (R : X → Y → Type ℓ)
--   → ⟦ C ⟧ X → ⟦ C ⟧ Y → Type ℓ 
-- eqLift {C = S , P} R (s₁ , v₁) (s₂ , v₂) =
--   Σ[ s ∈ s₁ ≡ s₂ ]
--     ({p₁ : P s₁}{p₂ : P s₂} → (λ i → P (s i)) [ p₁ ≡ p₂ ] → R (v₁ p₁) (v₂ p₂))

-- record νEq {ℓ} (C : Cont ℓ) (xs ys : ν C) : Type ℓ where
--   coinductive
--   field
--     forceEq : eqLift (νEq C) (force xs) (force ys)

-- open νEq

-- misib : ∀{ℓ} {C : Cont ℓ} {t₁ t₂ : ν C} → t₁ ≡ t₂ → νEq C t₁ t₂
-- forceEq (misib eq) = (λ i → head (eq i)) , (λ p → misib (λ i → tails (eq i) (p i)))

-- coind : ∀{ℓ} {C : Cont ℓ} {t₁ t₂ : ν C} → νEq C t₁ t₂ → t₁ ≡ t₂
-- force (coind {C = S , P} {ts₁}{ts₂} bis i) =
--   forceEq bis .fst i ,
--   λ p → coind (forceEq bis .snd {{!!}}{{!!}} {!!}) i
-- --  ,
-- --  λ p → coind {t₁ = cont ts₁ .snd {!subst P ? ?!}}{cont ts₂ .snd {!!}} {!!} i 

-- {- Finish coinduction principle -}

-- relator : ∀{ℓ X Y} {C : Cont ℓ} (R : X → Y → Type ℓ)
--   → ⟦ C ⟧ X → ⟦ C ⟧ Y → Type ℓ 
-- relator {C = S , P} R (s₁ , v₁) (s₂ , v₂) =
--   ((p₁ : P s₁) → ∃[ p₂ ∈ P s₂ ] R (v₁ p₁) (v₂ p₂))
--   × 
--   ((p₂ : P s₂) → ∃[ p₁ ∈ P s₁ ] R (v₁ p₁) (v₂ p₂))

-- relatorₚ : ∀{ℓ X Y} {C : Cont ℓ} (R : X → Y → Type ℓ)
--   → ⟦ C ⟧ X → ⟦ C ⟧ Y → hProp ℓ
-- relatorₚ R c₁ c₂ = relator R c₁ c₂ ,
--   isProp× (isPropΠ (λ _ → propTruncIsProp)) (isPropΠ (λ _ → propTruncIsProp))

-- record νRel {ℓ} (C : Cont ℓ) (xs ys : ν C) : Type ℓ where
--   coinductive
--   field
--     forceR : relator (νRel C) (force xs) (force ys)

-- open νRel

-- νQ : ∀{ℓ} (C : Cont ℓ) → Type ℓ
-- νQ C = ν C / νRel C



-- {-
-- data ν {ℓ} (C : Cont ℓ) (X : Type ℓ) : Type ℓ
-- record ▹ν {ℓ} (C : Cont ℓ) (X : Type ℓ) : Type ℓ

-- data ν C X where
--   leaf : X → ν C X
--   node : ▹ν C X → ν C X 

-- record ▹ν C X where
--   coinductive
--   field
--     force : ⟦ C ⟧ (ν C X)

-- open ▹ν

-- head : ∀{ℓ} {C : Cont ℓ} {X : Type ℓ} (x : ▹ν C X) → C .fst
-- head x = force x .fst

-- tails : ∀{ℓ} {C : Cont ℓ} {X : Type ℓ} (x : ▹ν C X)
--   → C .snd (head x) → ν C X
-- tails x p = force x .snd p

-- safe-leaf : ∀{ℓ X} {C : Cont ℓ} → X → ν C X → X
-- safe-leaf _ (leaf x) = x
-- safe-leaf x (node _) = x

-- safe-node : ∀{ℓ X} {C : Cont ℓ} → ▹ν C X → ν C X → ▹ν C X
-- safe-node xs (leaf _) = xs
-- safe-node _ (node xs) = xs

-- caseν : ∀{ℓ ℓ' X} {B : Type ℓ'} {C : Cont ℓ} → B → B → ν C X → B
-- caseν t f (leaf x) = t
-- caseν t f (node x) = f

-- leafInj : ∀{ℓ X} {C : Cont ℓ} {x y : X} → leaf {C = C} x ≡ leaf y → x ≡ y
-- leafInj {x = x} eq = cong (safe-leaf x) eq

-- nodeInj : ∀{ℓ X} {C : Cont ℓ} {xs ys : ▹ν C X} → node xs ≡ node ys → xs ≡ ys
-- nodeInj {xs = xs} eq = cong (safe-node xs) eq

-- leaf-disj-node : ∀{ℓ X} {C : Cont ℓ} {x : X} {xs : ▹ν C X}
--   → leaf x ≡ node xs → ⊥
-- leaf-disj-node {X = X}{C} {x} eq = lower (subst (caseν (ν C X) (Lift ⊥)) eq (leaf x))

-- νmap : ∀{ℓ X Y} (C : Cont ℓ) (f : X → Y) → ν C X → ν C Y
-- ▹νmap : ∀{ℓ X Y} (C : Cont ℓ) (f : X → Y) → ▹ν C X → ▹ν C Y

-- νmap C f (leaf x) = leaf (f x)
-- νmap C f (node xs) = node (▹νmap C f xs)

-- force (▹νmap C f xs) = head xs , λ p → νmap C f (tails xs p)

-- νbind : ∀{ℓ X Y} (C : Cont ℓ) (f : X → ν C Y) → ν C X → ν C Y
-- ▹νbind : ∀{ℓ X Y} (C : Cont ℓ) (f : X → ν C Y) → ▹ν C X → ▹ν C Y

-- νbind C f (leaf x) = f x
-- νbind C f (node xs) = node (▹νbind C f xs)

-- force (▹νbind C f xs) = head xs , λ p → νbind C f (tails xs p)

-- eqLift : ∀{ℓ X Y} {C : Cont ℓ} (R : X → Y → Type ℓ)
--   → ⟦ C ⟧ X → ⟦ C ⟧ Y → Type ℓ 
-- eqLift {C = S , P} R (s₁ , v₁) (s₂ , v₂) =
--   Σ[ s ∈ s₁ ≡ s₂ ]
--     ({p₁ : P s₁}{p₂ : P s₂} → (λ i → P (s i)) [ p₁ ≡ p₂ ] → R (v₁ p₁) (v₂ p₂))

-- --  → (p₁ : P s₁) → R (v₁ p₁) (v₂ (subst P eq p₁))

-- eqLiftRefl : ∀{ℓ X} {C : Cont ℓ}
--   → {R : X → X → Type ℓ} → (∀{x y} → x ≡ y → R x y)
--   → {t₁ t₂ : ⟦ C ⟧ X} → t₁ ≡ t₂ → eqLift R t₁ t₂
-- eqLiftRefl {C = S , P} {R} reflR {s₁ , v₁}{s₂ , v₂} eq =
--   (λ i → eq i .fst) ,
--   (λ p → reflR (λ i → eq i .snd (p i)))

-- --λ p → subst (λ x → R (v p) (v x)) (sym (substRefl {B = P} p)) (reflR (v p))

-- data νEq {ℓ} (C : Cont ℓ) {X} : Rel (ν C X) (ν C X) ℓ
-- record ▹νEq {ℓ} (C : Cont ℓ) {X} (xs ys : ▹ν C X) : Type ℓ

-- data νEq C where
--   leafEq : ∀{x y} → x ≡ y → νEq C (leaf x) (leaf y)
--   nodeEq : ∀{xs ys} →  ▹νEq C xs ys → νEq C (node xs) (node ys)

-- record ▹νEq C xs ys where
--   coinductive
--   field
--     forceEq : eqLift (νEq C) (force xs) (force ys)

-- open ▹νEq

-- misib : ∀{ℓ X} {C : Cont ℓ} {t₁ t₂ : ν C X} → t₁ ≡ t₂ → νEq C t₁ t₂
-- ▹misib : ∀{ℓ X} {C : Cont ℓ} {t₁ t₂ : ▹ν C X} → t₁ ≡ t₂ → ▹νEq C t₁ t₂

-- misib {t₁ = leaf x} {leaf y} eq = leafEq (leafInj eq)
-- misib {t₁ = leaf x} {node ys} eq = ⊥-rec (leaf-disj-node eq)
-- misib {t₁ = node xs} {leaf y} eq = ⊥-rec (leaf-disj-node (sym eq))
-- misib {t₁ = node xs} {node ys} eq = nodeEq (▹misib (nodeInj eq))

-- forceEq (▹misib eq) = (λ i → head (eq i)) , (λ p → misib (λ i → tails (eq i) (p i)))

-- coind : ∀{ℓ X} {C : Cont ℓ} {t₁ t₂ : ν C X} → νEq C t₁ t₂ → t₁ ≡ t₂
-- ▹coind : ∀{ℓ X} {C : Cont ℓ} {t₁ t₂ : ▹ν C X} → ▹νEq C t₁ t₂ → t₁ ≡ t₂

-- coind (leafEq eq) = cong leaf eq
-- coind (nodeEq bis) = cong node (▹coind bis)

-- force (▹coind {C = S , P} {ts₁}{ts₂} bis i) =
--   forceEq bis .fst i ,
--   λ p → coind (forceEq bis .snd {{!!}}{{!!}} {!!}) i
-- --  ,
-- --  λ p → coind {t₁ = cont ts₁ .snd {!subst P ? ?!}}{cont ts₂ .snd {!!}} {!!} i 

-- {- Finish coinduction principle -}

-- relator : ∀{ℓ X Y} {C : Cont ℓ} (R : X → Y → Type ℓ)
--   → ⟦ C ⟧ X → ⟦ C ⟧ Y → Type ℓ 
-- relator {C = S , P} R (s₁ , v₁) (s₂ , v₂) =
--   ((p₁ : P s₁) → ∃[ p₂ ∈ P s₂ ] R (v₁ p₁) (v₂ p₂))
--   × 
--   ((p₂ : P s₂) → ∃[ p₁ ∈ P s₁ ] R (v₁ p₁) (v₂ p₂))

-- relatorₚ : ∀{ℓ X Y} {C : Cont ℓ} (R : X → Y → Type ℓ)
--   → ⟦ C ⟧ X → ⟦ C ⟧ Y → hProp ℓ
-- relatorₚ R c₁ c₂ = relator R c₁ c₂ ,
--   isProp× (isPropΠ (λ _ → propTruncIsProp)) (isPropΠ (λ _ → propTruncIsProp))

-- -- relator : ∀{ℓ X Y} {C : Cont ℓ} (R : X → Y → hProp ℓ) → ⟦ C ⟧ X → ⟦ C ⟧ Y → hProp ℓ 
-- -- relator {C = S , P} R (s₁ , v₁) (s₂ , v₂) =
-- --   ∀[ p₁ ∶ P s₁ ] ∃[ p₂ ∶ P s₂ ] R (v₁ p₁) (v₂ p₂)

-- data νRel {ℓ} (C : Cont ℓ) {X Y} (R : X → Y → Type ℓ)
--   : Rel (ν C X) (ν C Y) ℓ
-- record ▹νRel {ℓ} (C : Cont ℓ) {X Y} (R : X → Y → Type ℓ)
--   (xs : ▹ν C X) (ys : ▹ν C Y) : Type ℓ

-- data νRel C R where
--   leafR : ∀{x y} → R x y → νRel C R (leaf x) (leaf y)
--   nodeR : ∀{xs ys} →  ▹νRel C R xs ys → νRel C R (node xs) (node ys)

-- record ▹νRel C R xs ys where
--   coinductive
--   field
--     forceR : relator (νRel C R) (force xs) (force ys)

-- open ▹νRel

-- {- Define a version νRelₚ targeting hProp where R targets hProp. For
-- this one surely needs the coinduction principle of νC -}

-- νSim : ∀ {ℓ} (C : Cont ℓ) {X} →  Rel (ν C X) (ν C X) ℓ
-- νSim C = νRel C _≡_

-- νQ : 


-- {- Define a version νSimₚ targeting hProp (so νRelₚ instantiated to ≡ₚ) -}
-- -}



-- -- νRelProp : ∀ {ℓ} (C : Cont ℓ) {X Y} (R : X → Y → hProp ℓ) {t₁ t₂}
-- --   → isProp (νRel C R t₁ t₂)
-- -- νRelProp' : ∀ {ℓ} (C : Cont ℓ) {X Y} (R : X → Y → hProp ℓ) {t₁ t₂}
-- --   → isProp (▹νRel C R t₁ t₂)
-- -- νRelₚ : ∀ {ℓ} (C : Cont ℓ) {X Y} (R : X → Y → hProp ℓ) → ν C X → ν C Y → hProp ℓ

-- -- data νRel C R where
-- --   leafR : ∀{x y} → ⟨ R x y ⟩ → νRel C R (leaf x) (leaf y)
-- --   nodeR : ∀{xs ys} →  ▹νRel C R xs ys → νRel C R (node xs) (node ys)

-- -- record ▹νRel C R xs ys where
-- --   coinductive
-- --   field
-- --     forceR : ⟨ relator (νRelₚ C R) (cont xs) (cont ys) ⟩ 

-- -- νRelProp C R (leafR x) (leafR x₁) = cong leafR (R _ _ .snd x x₁)
-- -- νRelProp C R (nodeR x) (nodeR x₁) = cong nodeR (νRelProp' C R x x₁)

-- -- νRelProp' C R {t₁}{t₂} r s = {!!}

-- -- νRelₚ C R t₁ t₂ = νRel C R t₁ t₂ , νRelProp C R

-- -- -- -- mem : ∀{ℓ X} {C : Cont ℓ} (R : X → X → hProp ℓ) → X → ⟦ C ⟧ X → hProp ℓ 
-- -- -- -- mem {C = S , P} R x (s , v) = ∃[ p ∶ P s ] R x (v p)




-- -- -- --mem : ∀{ℓ X} {C : Cont ℓ} → PropRel X (⟦ C ⟧ X) ℓ 
-- -- -- --fst mem x c = ⟨ x ∈ c ⟩
-- -- -- --snd mem x c = isProp⟨⟩ (x ∈ c)

-- -- -- _∼_ : ∀{ℓ X} {C : Cont ℓ} → Rel (ν C X) (ν C X) ℓ
-- -- -- t₁ ∼ t₂ = νRel {!!} {!mem!} t₁ t₂


-- -- -- {-
-- -- -- open import Cubical.Data.Nat

-- -- -- data Test : Type where
-- -- --   leaf : Test
-- -- --   node : (ℕ → Test) → Test 

-- -- -- r : ℕ → Test
-- -- -- r zero = leaf
-- -- -- r (suc n) = node (λ _ → r n)

-- -- -- t0 : Test
-- -- -- t0 = node r
-- -- -- -}
