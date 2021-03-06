{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE OverloadedStrings #-}

module NLP.Morphology.PT.Verb.Base where

import           Data.List                (elemIndex)
import           Data.Text                (Text)
import qualified Data.Text                as T
import           NLP.Morphology.PT.Common
import           NLP.Morphology.Txt

data Impersonal
  = INF
  | GER
  deriving (Show, Eq, Enum, Bounded)

data Personal
  = IPRS
  | IPRF
  | IIPF
  | IPPF
  | IFUT
  | IFPR
  | SPRS
  | SIPF
  | SFUT
  | IMPA
  | IMPN
  | INFP
  deriving (Show, Eq, Enum, Bounded)

data NominalVerb
  = PPP
  deriving (Show, Eq, Enum, Bounded)

-- data MoodTense
--   = IPRS
--   | IPRF
--   | IIPF
--   | IPPF
--   | IFUT
--   | IFPR
--   | SPRS
--   | SIPF
--   | SFUT
--   | IMPA
--   | IMPN
--   | INFP
--   | INF
--   | GER
--   | PPP
--   deriving (Show, Eq, Enum, Bounded)

data GenderNumber
  = MS
  | FS
  | MP
  | FP
  deriving (Show, Eq, Enum, Bounded)

data Morpheme
  = A
  | E
  | I
  | O
  | U
  | S
  | MOS
  | IS
  | M
  | STE
  | STES
  | DES
  | RA
  | RE
  | VA
  | VE
  | SE
  | R
  | NDO
  | D
  | Z
  | C
  | LV
  | MRoot Text
  | L Text
  deriving (Show, Read, Eq)

getThematicVowel :: Citation -> ThematicVowel
getThematicVowel = maybe Z' toEnum . flip elemIndex "aeiou" . T.head . T.takeEnd 2 . T.toLower

mkRoot :: Citation -> Root
mkRoot c
  | lastLetter == "C" && baseTV == 'a' = Root CQU baseRoot
  | lastLetter == "G" && baseTV == 'a' = Root GGU baseRoot
  | lastLetter == "C" && baseTV == 'e' = Root CÇ baseRoot
  | lastLetter == "C" && baseTV == 'i' = Root CÇ baseRoot
  | lastLetter == "Ç" && baseTV == 'a' = Root ÇC baseRoot
  | lastLetter == "G" && baseTV == 'i' = Root GJ baseRoot
  | last2Letters == "GU" && baseTV == 'e' = Root GUG baseRoot
  | otherwise = Root Reg baseRoot
  where
    baseRoot     = getRoot c
    baseTV       = T.last $ T.init c
    lastLetter   = T.takeEnd 1 baseRoot
    last2Letters = T.takeEnd 2 baseRoot

orthRoot :: Root -> Text
orthRoot (Root Reg r) = r
orthRoot (Root Irr r) = r
orthRoot (Root CQU r) = (<> "QU") $ T.dropEnd 1 r
orthRoot (Root QUC r) = (<> "C")  $ T.dropEnd 2 r
orthRoot (Root GGU r) = (<> "GU") $ T.dropEnd 1 r
orthRoot (Root GUG r) = (<> "G")  $ T.dropEnd 2 r
orthRoot (Root CÇ  r) = (<> "Ç")  $ T.dropEnd 1 r
orthRoot (Root ÇC  r) = (<> "C")  $ T.dropEnd 1 r
orthRoot (Root GJ  r) = (<> "J")  $ T.dropEnd 1 r

class Morph a where
  morph :: a -> Morpheme
  allom :: a -> Morpheme
  zerom :: a -> Morpheme
  allom = morph
  zerom = const Z

instance Morph Root where
  morph = MRoot . doRoot
  allom = MRoot . orthRoot

doRoot r = case r of
  Root Cmp "hav" -> "h"
  _              -> root r

instance Morph ThematicVowel where
  morph = tread . T.init . tshow

instance Morph Personal where
  morph = ([Z, Z, VA, RA, R, R, Z, SE, R, C, C, R] !!) . fromEnum
  allom = ([Z, RA, VE, RE, C, C, Z, SE, R, C, C, R] !!) . fromEnum

instance Morph Impersonal where
  morph = ([R, NDO] !!) . fromEnum

instance Morph NominalVerb where
  morph = const D

instance Morph Person where
  morph = ([Z, S, Z, MOS, IS, M] !!) . fromEnum
  allom = ([O, S, Z, MOS, DES, M] !!) . fromEnum

instance Morph Gender where
  morph = ([O, A] !!) . fromEnum

instance Morph Number where
  morph = ([Z, S] !!) . fromEnum

iprfm :: Person -> Morpheme
iprfm = ([I, STE, U, MOS, STES, M] !!) . fromEnum

bounds :: (Enum a, Bounded a) => [a]
bounds = [minBound .. maxBound]

instance Txt Morpheme where
  txt Z         = "∅"
  txt LV        = "E"
  txt (L s)     = s
  txt (MRoot r) = r
  txt m         = tshow m

instance Txt [Morpheme] where
  txt ts = T.intercalate "-" (fmap txt ts)

instance Txt [[Morpheme]] where
  txt ts = T.intercalate "\n" (fmap txt ts)

instance Txt [[[Morpheme]]] where
  txt ts = T.intercalate "\n\n" (fmap txt ts)

data VStructure
  = Pers Citation Root ThematicVowel Personal   Person
  | Impr Citation Root ThematicVowel Impersonal
  | Nom  Citation Root ThematicVowel NominalVerb    Gender       Number
  | Comp Citation VStructure VStructure
  deriving (Show, Eq)

instance Txt VStructure where
  txt (Pers c r t m p)  = T.intercalate "-" [txt r, txt t, tshow m, tshow p]
  txt (Impr c r t m)    = T.intercalate "-" [txt r, txt t, tshow m]
  txt (Nom c r t m g n) = T.intercalate "-" [txt r, txt t, tshow m, tshow g, tshow n]
  txt (Comp c v1 v2) = T.intercalate "+" [txt v1, txt v2]
