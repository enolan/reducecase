{-# LANGUAGE FlexibleInstances,TypeFamilies #-}
import Control.Monad.IO.Class (liftIO)
import Control.Monad.Random (evalRand, Rand, RandT)
import Data.Functor.Identity (Identity)
import Data.IORef (newIORef, readIORef, writeIORef)
import Data.List (sort)
import qualified Data.Map.Strict as M
import Data.Maybe (fromJust)
import System.Random (getStdGen, mkStdGen, RandomGen, StdGen)
import Test.Hspec
import Test.Hspec.Core.Spec
import Test.Hspec.QuickCheck
import Test.QuickCheck

import ADEL

main :: IO ()
main = hspec $ do
    describe "minimalSubMapSatisfyingM" $ before getStdGen $ do
        it "finds the minimal submap of empty maps" $ idRand $ do
            res <- minimalSubMapSatisfyingM (makeSizedMap 0) (const (return True))
            return (res `shouldBe` M.empty)
        it "finds a subset of size 5" $ idRand $ do
            res <- minimalSubMapSatisfyingM (makeSizedMap 200) (\m -> return $ M.size m >= 5)
            return (res `shouldSatisfy` (\m -> M.size m == 5))
    describe "minimalSubMapSatisfyingM quickCheck" $ do
        prop "finds a subset of arbitrary size" $
            \(gen :: StdGen) (sizeA :: NonNegative Int) sizeB ->
                let [NonNegative smaller, NonNegative bigger] = sort [sizeA, sizeB]
                    submap = evalRand
                        (minimalSubMapSatisfyingM (makeSizedMap bigger) (\m -> return $ M.size m >= smaller))
                        gen in M.size submap == smaller


instance RandomGen g => Example (RandT g Identity Expectation) where
    type Arg (RandT g Identity Expectation) = g
    evaluateExample randEx params act progressCallback = do
        resRef <- newIORef Nothing
        act $ \gen -> writeIORef resRef $ Just $ evalRand randEx gen
        res <- fromJust <$> readIORef resRef
        evaluateExample res params (\act' -> act' ()) progressCallback

instance Arbitrary StdGen where
    arbitrary = mkStdGen <$> arbitrary

idRand :: Rand g a -> Rand g a
idRand = id

makeSizedMap :: Int -> M.Map Int ()
makeSizedMap 0 = M.empty
makeSizedMap n | n > 0 = M.insert n () $ makeSizedMap (n-1)
               | otherwise = error "makeSizedMap negative"