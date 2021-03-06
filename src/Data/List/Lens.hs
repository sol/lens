{-# LANGUAGE LiberalTypeSynonyms #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE Rank2Types #-}
-----------------------------------------------------------------------------
-- |
-- Module      :  Data.List.Lens
-- Copyright   :  (C) 2012 Edward Kmett
-- License     :  BSD-style (see the file LICENSE)
-- Maintainer  :  Edward Kmett <ekmett@gmail.com>
-- Stability   :  provisional
-- Portability :  portable
--
-- Traversals for manipulating parts of a list.
--
----------------------------------------------------------------------------
module Data.List.Lens
  (
  -- * Partial Lenses
    _head
  , _tail
  , _last
  , _init
  -- * Traversals
  , traverseHead
  , traverseTail
  , traverseInit
  , traverseLast
  ) where

import Control.Applicative
import Control.Lens

-- | A partial 'Lens' reading and writing to the 'head' of a /non-empty/ list.
--
-- Attempting to read or write to the 'head' of an /empty/ list will result in an 'error'.
--
-- >>> [1,2,3]^._head
-- 1
_head :: Simple Lens [a] a
_head _ [] = error "_head: empty list"
_head f (a:as) = (:as) <$> f a
{-# INLINE _head #-}

-- | A partial 'Lens' reading and writing to the 'tail' of a /non-empty/ list
--
-- Attempting to read or write to the 'tail' of an /empty/ list will result in an 'error'.
--
-- >>> _tail .~ [3,4,5] $ [1,2]
-- [1,3,4,5]
_tail :: Simple Lens [a] [a]
_tail _ [] = error "_tail: empty list"
_tail f (a:as) = (a:) <$> f as
{-# INLINE _tail #-}

-- | A partial 'Lens' reading and writing to the last element of a /non-empty/ list
--
-- Attempting to read or write to the last element of an /empty/ list will result in an 'error'.
--
-- >>> [1,2]^._last
-- 2
_last :: Simple Lens [a] a
_last _ []     = error "_last: empty list"
_last f [a]    = return <$> f a
_last f (a:as) = (a:) <$> _last f as
{-# INLINE _last #-}

-- | A partial 'Lens' reading and replacing all but the a last element of a /non-empty/ list
--
-- Attempting to read or write to all but the last element of an /empty/ list will result in an 'error'.
--
-- >>> [1,2,3,4]^._init
-- [1,2,3]
_init :: Simple Lens [a] [a]
_init _ [] = error "_init: empty list"
_init f as = (++ [Prelude.last as]) <$> f (Prelude.init as)
{-# INLINE _init #-}

-- | A traversal for reading and writing to the head of a list
--
-- The position of the head in the original list (0) is available as the index.
--
-- >>> traverseHead +~ 1 $ [1,2,3]
-- [2,2,3]
--
-- @'traverseHead' :: 'Applicative' f => (a -> f a) -> [a] -> f [a]@
traverseHead :: SimpleIndexedTraversal Int [a] a
traverseHead = index $ \f aas -> case aas of
  []     -> pure []
  (a:as) -> (:as) <$> f (0::Int) a
{-# INLINE traverseHead #-}

-- | A traversal for editing the tail of a list
--
-- The position of each element /in the original list/ is available as the index.
--
-- >>> traverseTail +~ 1 $ [1,2,3]
-- [1,3,4]
--
-- @'traverseTail' :: 'Applicative' f => (a -> f a) -> [a] -> f [a]@
traverseTail :: SimpleIndexedTraversal Int [a] a
traverseTail = index $ \f aas -> case aas of
  []     -> pure []
  (a:as) -> (a:) <$> itraverse (f . (+1)) as
{-# INLINE traverseTail #-}

-- | A traversal the last element in a list
--
-- The position of the last element in the original list is available as the index.
--
-- >>> traverseLast +~ 1 $ [1,2,3]
-- [1,2,4]
--
-- @'traverseLast' :: 'Applicative' f => (a -> f a) -> [a] -> f [a]@
traverseLast :: SimpleIndexedTraversal Int [a] a
traverseLast = index $ \f xs0 -> let
    go [a]    n = return <$> f n a
    go (a:as) n = (a:) <$> (go as $! n + 1)
    go []     _ = pure []
  in go xs0 (0::Int) where
{-# INLINE traverseLast #-}

-- | A traversal of all but the last element of a list
--
-- The position of each element is available as the index.
--
-- >>> traverseInit +~ 1 $ [1,2,3]
-- [2,3,3]
--
-- @'traverseInit' :: 'Applicative' f => (a -> f a) -> [a] -> f [a]@
traverseInit :: SimpleIndexedTraversal Int [a] a
traverseInit = index $ \f aas -> case aas of
  [] -> pure []
  as -> (++ [Prelude.last as]) <$> itraverse f (Prelude.init as)
{-# INLINE traverseInit #-}
