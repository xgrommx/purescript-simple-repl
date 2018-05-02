module Node.SimpleRepl where

import Prelude

import Control.Monad.Aff (Aff, runAff)
import Control.Monad.Aff.Class (liftAff)
import Control.Monad.Aff.Console (log)
import Control.Monad.Eff (Eff)
import Control.Monad.Eff.Console (CONSOLE, error)
import Control.Monad.Eff.Exception (message)
import Control.Monad.Reader.Class (ask)
import Control.Monad.Reader.Trans (ReaderT, runReaderT)
import Data.Either (either)
import Node.ReadLine (Interface, READLINE, Completer)
import Node.ReadLine.Aff.Simple as RLA

type Repl e a = ReaderT Interface (Aff (console :: CONSOLE, readline :: READLINE | e)) a

prompt :: forall e. Repl e Unit
prompt = liftAff <<< RLA.prompt =<< ask

setPrompt :: forall e. String -> Repl e Unit
setPrompt s = liftAff <<< RLA.setPrompt s 0 =<< ask

close :: forall e. Repl e Unit
close = liftAff <<< RLA.close =<< ask

setLineHandler :: forall e. Repl e String
setLineHandler = liftAff <<< RLA.setLineHandler =<< ask

readLine :: forall e. Repl e String
readLine = prompt *> setLineHandler

simpleRepl :: forall e. Repl e Unit -> Eff (console :: CONSOLE, readline :: READLINE | e) Unit
simpleRepl = runWithInterface RLA.simpleInterface

completionRepl :: forall e. Completer e -> Repl e Unit -> Eff (console :: CONSOLE, readline :: READLINE | e) Unit
completionRepl comp = runWithInterface (RLA.completionInterface comp)

runWithInterface
  :: forall e
   . Aff (console :: CONSOLE, readline :: READLINE | e) Interface
  -> Repl e Unit
  -> Eff (console :: CONSOLE, readline :: READLINE | e) Unit
runWithInterface int rep
  = void
  $ runAff (either (error <<< message) pure)
  $ runReaderT (rep *> close)
  =<< int

putStrLn :: forall e. String -> Repl e Unit
putStrLn = liftAff <<< log
