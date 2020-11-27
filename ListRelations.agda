{-# OPTIONS --cubical --no-import-sorts #-}

module ListRelations where

open import Size
open import Cubical.Core.Everything
open import Cubical.Foundations.Prelude
open import Cubical.Foundations.Everything
open import Cubical.Functions.Logic renaming (⊥ to ⊥ₚ)
open import Cubical.Relation.Everything
open import Cubical.HITs.PropositionalTruncation as PropTrunc
  renaming (rec to ∥rec∥; map to ∥map∥)
open import Cubical.HITs.SetQuotients renaming ([_] to eqCl)
open import Cubical.Data.Sigma
open import Cubical.Data.List renaming (map to mapList)
open import Cubical.Data.Empty renaming (elim to ⊥-elim; rec to ⊥-rec)
open import Cubical.Relation.Binary
open import Cubical.Relation.Nullary
open BinaryRelation

open import Preliminaries

-- canonical relation lifting on trees
data ListRel {ℓ}{X Y : Type ℓ} (R : X → Y → Type ℓ)
     : List X → List Y → Type ℓ where
  [] : ListRel R [] []
  _∷_ : ∀{x y xs ys} → R x y → ListRel R xs ys
    → ListRel R (x ∷ xs) (y ∷ ys)

-- another relation lifting: two lists are (Relator R)-related if for
-- each element in a list there merely exists an R-related element in
-- the other list
DRelator : ∀{ℓ}{X Y : Type ℓ} (R : X → Y → Type ℓ)
  → List X → List Y → Type ℓ 
DRelator R xs ys =
  ∀ x → x ∈ xs → ∃[ y ∈ _ ] y ∈ ys × R x y

Relator : ∀{ℓ}{X : Type ℓ} (R : X → X → Type ℓ)
  → List X → List X → Type ℓ 
Relator R xs ys =
  DRelator R xs ys × DRelator R ys xs

isPropRelator : ∀{ℓ}{X : Type ℓ} (R : X → X → Type ℓ)
  → ∀ xs ys → isProp (Relator R xs ys)
isPropRelator R _ _ =
  isProp× (isPropΠ (λ _ → isPropΠ (λ _ → propTruncIsProp)))
          (isPropΠ (λ _ → isPropΠ (λ _ → propTruncIsProp)))

Relatorₚ : ∀{ℓ}{X : Type ℓ} (R : X → X → hProp ℓ)
  → List X → List X → hProp ℓ 
Relatorₚ R xs ys =
  Relator (λ x y → ⟨ R x y ⟩) xs ys ,
  isPropRelator _ xs ys

-- reflexivity, symmetry and transitivity of the relator
reflDRelator : ∀{ℓ}{X : Type ℓ} {R : X → X → Type ℓ}
  → (∀ x → R x x)
  → ∀ xs → DRelator R xs xs
reflDRelator reflR xs x mx = ∣ x , mx , reflR x ∣

reflRelator : ∀{ℓ}{X : Type ℓ} {R : X → X → Type ℓ}
  → (∀ x → R x x)
  → ∀ xs → Relator R xs xs
reflRelator reflR xs = (reflDRelator reflR xs) , (reflDRelator reflR xs)  

symRelator : ∀{ℓ}{X : Type ℓ} {R : X → X → Type ℓ}
  → ∀ {xs ys} → Relator R xs ys → Relator R ys xs
symRelator (p , q) = q , p

transDRelator : ∀{ℓ}{X : Type ℓ} {R : X → X → Type ℓ}
  → (∀ {x y z} → R x y → R y z → R x z)
  → ∀ {xs ys zs} → DRelator R xs ys → DRelator R ys zs → DRelator R xs zs
transDRelator transR p q x mx =
  ∥rec∥ propTruncIsProp
    (λ { (y , my , ry) → ∥map∥ (λ { (z , mz , rz) → z , mz , transR ry rz }) (q y my)})
    (p x mx)

transRelator : ∀{ℓ}{X : Type ℓ} {R : X → X → Type ℓ}
  → (∀ {x y z} → R x y → R y z → R x z)
  → ∀ {xs ys zs} → Relator R xs ys → Relator R ys zs → Relator R xs zs
transRelator transR (p , q) (p' , q') =
  transDRelator transR p p' , transDRelator transR q' q

isEquivRelRelator : ∀{ℓ}{X : Type ℓ} {R : X → X → Type ℓ}
  → isEquivRel R → isEquivRel (Relator R)
isEquivRelRelator (equivRel reflR _ transR) =
  equivRel (reflRelator reflR)
           (λ _ _ r → r .snd , r .fst)
           λ _ _ _ → transRelator (transR _ _ _)

-- the relation Relator R is decidable if the relation R is decidable
decMem : ∀{ℓ}{X : Type ℓ} {R : X → X → Type ℓ} 
  → (∀ x y → Dec (R x y)) → ∀ x ys
  → Dec (Σ[ y ∈ _ ] (y ∈ ys) × R x y)
decMem decR x [] = no (λ { () })
decMem decR x (y ∷ ys) with decR x y
... | yes p = yes (y , here , p)
... | no ¬p with decMem decR x ys
... | yes (z , m , r) = yes (z , there m , r)
... | no ¬q = no (λ { (._ , here , r') → ¬p r'
                    ; (w , there m' , r') → ¬q (w , m' , r') })

decDRelator : ∀{ℓ}{X : Type ℓ} {R : X → X → Type ℓ} 
  → (∀ x y → Dec (R x y)) → ∀ xs ys → Dec (DRelator R xs ys)
decDRelator decR [] ys = yes (λ _ ())
decDRelator decR (x ∷ xs) ys with decDRelator decR xs ys
... | no ¬p = no (λ q → ¬p (λ y my → q y (there my)))
... | yes p with decMem decR x ys
... | yes q = yes (λ { ._ here → ∣ q ∣
                     ; y (there m) → p y m })
... | no ¬q = no (λ q → ∥rec∥ isProp⊥ ¬q (q  _ here))

decRelator : ∀{ℓ}{X : Type ℓ} {R : X → X → Type ℓ}
  → (∀ x y → Dec (R x y)) → ∀ xs ys → Dec (Relator R xs ys)
decRelator decR xs ys with decDRelator decR xs ys
... | no ¬p = no (λ x → ¬p (fst x))
... | yes p with decDRelator decR ys xs
... | yes q = yes (p , q)
... | no ¬q = no (λ z → ¬q (snd z))

-- relator and mapList
DRelatorFunMapList : {X Y : Type}(f g : X → Y)
  → {R : Y → Y → Type} → (∀ x → R (f x) (g x))
  → ∀ xs → DRelator R (mapList f xs) (mapList g xs)
DRelatorFunMapList f g {R = R} r xs x mx with pre∈mapList mx
... | (y , my , eq) = ∣ g y , ∈mapList my , subst (λ z → R z (g y)) eq (r y) ∣ 

RelatorFunMapList : {X Y : Type}(f g : X → Y)
  → {R : Y → Y → Type} → (∀ x → R (f x) (g x))
  → (∀ {x x'} → R x x' → R x' x)
  → ∀ xs → Relator R (mapList f xs) (mapList g xs)
RelatorFunMapList f g r Rsym xs =
  DRelatorFunMapList f g r xs , DRelatorFunMapList g f (λ x → Rsym (r x)) xs

