{-# LANGUAGE MultiWayIf #-}
module Experiment19 where

import Data.Ratio

-- a = -diff(0,x)
-- d/dt v = a
-- d/dt x = v

type Number = Rational
type Time = Rational
type Rez = Rational
type Location = Rational
data AddInf a = Fin a | Inf deriving (Eq, Ord, Show)

run :: Rez -> Location -> Number -> [(Time, Location, Number)]
run rez x0 v0 = (0,x0,v0) : go 0 x0 v0 where
  go t x v = case step rez x v of
    Just (dt,x',v') -> let t' = t + dt in (t', x', v') : go t' x' v'
    Nothing -> []

step :: Rez -> Location -> Number -> Maybe (Time, Location, Number)
step rez x v = answer where
  a = -(discretize rez x xdot - 0)
  vdot = a
  xdot = discretize rez v vdot
  maybe_dt = minimum [eta rez v vdot, eta rez x xdot]
  answer = case maybe_dt of
    Fin dt -> Just (dt, x + xdot*dt, v + vdot*dt)
    Inf -> Nothing

eta :: Rez -> Number -> Number -> AddInf Time
eta rez x xdot = case fence rez x of
  Nothing -> case compare xdot 0 of
    EQ -> Inf
    GT -> Fin $ (rez / xdot)
    LT -> Fin $ (rez / (-xdot))
  Just (a,b) -> case compare xdot 0 of
    EQ -> Inf
    GT -> Fin $ (b - x) / xdot
    LT -> Fin $ (x - a) / (-xdot)


fence :: (RealFrac a) => a -> a -> Maybe (a, a)
fence rez x =
  let y = (x - rez/2) / rez in
  let (i', r) = properProperFraction y in
  let i = fromInteger i' in
  if | r == 0    -> Nothing
     | otherwise -> Just (i * rez + rez/2, (i+1) * rez + rez/2)

discretize :: (Ord a, RealFrac a) => a -> a -> a -> a
discretize rez x xdot =
  let y = x / rez in
  let (i', r) = properProperFraction y in
  let i = fromInteger i' in
  if | r < 1/2   -> i * rez
     | r > 1/2   -> (i + 1) * rez
     | otherwise ->
        case compare xdot 0 of
          GT -> (i + 1) * rez
          LT -> i * rez
          EQ -> (i + 1/2) * rez

properProperFraction q =
  let (i,r) = properFraction q in
  case compare q 0 of
    EQ -> (0,0)
    GT -> (i,r)
    LT | r == 0    -> (i, r)
       | otherwise -> (i - 1, r + 1)
