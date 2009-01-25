-- File created: 2008-10-10 22:03:00

module Tests.Base ( PString(unPS), Path(unP), COpts(unCOpts)
                  , fromRight, isRight
                  ) where

import System.FilePath (extSeparator, pathSeparators)
import Test.QuickCheck

import System.FilePath.Glob.Base (CompOptions(..))

import Utils (fromRight, isRight)

newtype PString = PatString { unPS    :: String } deriving Show
newtype Path    = Path      { unP     :: String } deriving Show
newtype COpts   = COpts     { unCOpts :: CompOptions } deriving Show

alpha = extSeparator : pathSeparators ++ "-^!" ++ ['a'..'z'] ++ ['0'..'9']

instance Arbitrary PString where
   arbitrary = sized $ \size -> do
      let xs =
             (1, return "**/") :
             map (\(a,b) -> (a*100,b))
             [ (40, plain)
             , (20, return "?")
             , (20, charRange)
             , (10, return "*")
             , (10, openRange)
             ]

      s <- mapM (const $ frequency xs) [1..size]
      return.PatString $ concat s

instance Arbitrary Path where
   arbitrary = sized $ \size -> do
      s <- mapM (const plain) [1..size `mod` 16]
      return.Path $ concat s

instance Arbitrary COpts where
   arbitrary = do
      [a,b,c,d,e] <- vector 5
      return.COpts $ CompOptions a b c d e False

plain = sized $ \size -> do
   s <- mapM (const $ elements alpha) [0..size `mod` 3]
   return s

charRange = do
   s <- plain
   if s `elem` ["^","!"]
      then do
         s' <- plain
         return$ "[" ++ s ++ s' ++ "]"
      else
         return$ "[" ++ s ++       "]"

openRange = do
   probA <- choose (0,1) :: Gen Float
   probB <- choose (0,1) :: Gen Float
   a <- if probA > 0.4
           then fmap (Just .abs) arbitrary
           else return Nothing
   b <- if probB > 0.4
           then fmap (Just .abs) arbitrary
           else return Nothing
   return.concat $
      [ "<"
      , maybe "" show (a :: Maybe Int)
      , "-"
      , maybe "" show (b :: Maybe Int)
      , ">"
      ]
