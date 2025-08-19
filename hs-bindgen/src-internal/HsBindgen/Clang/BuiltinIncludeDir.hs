module HsBindgen.Clang.BuiltinIncludeDir (
    clangPrintResourceDir
  , getResourceDir
  ) where

import Control.Monad ((<=<))
import System.Environment (getExecutablePath)
import System.IO.Error (tryIOError)
import System.Process (readProcess)

import Clang.Args

import HsBindgen.Clang
import HsBindgen.Imports
import HsBindgen.Util.Tracer

{-------------------------------------------------------------------------------
-------------------------------------------------------------------------------}

-- | Get @libclang@ to print the resource directory
--
-- This causes @libclang@ to print the resource directory to @STDOUT@.  We
-- execute @hs-bindgen-cli print-resource-dir@ so that we can capture the output
-- in a sub-process.
--
-- Note that we /cannot/ capture this output using file descriptor redirection
-- because Clang does not flush the output stream buffer.  Using a C++ binding
-- to do so resolves this issue, but linking to LLVM is problematic since many
-- LLVM/Clang distributions do not include LLVM shared libraries.
clangPrintResourceDir :: IO ()
clangPrintResourceDir =
    void $ withClang' nullTracer clangSetup (const (return Nothing))
  where
    clangSetup :: ClangSetup
    clangSetup = defaultClangSetup clangArgs $
      ClangInputMemory "hs-bindgen-print-resource-dir.h" ""

    clangArgs :: ClangArgs
    clangArgs = def{
        clangOtherArgs = ["-print-resource-dir"]
      }

{-------------------------------------------------------------------------------
-------------------------------------------------------------------------------}

-- | TODO
--
-- WARNING This function only works when called via @hs-bindgen-cli@.
getResourceDir :: IO (Maybe FilePath)
getResourceDir = handleErrors <=< tryIOError $ do
    exe <- getExecutablePath
    readProcess exe ["clang-print-resource-dir"] ""
  where
    handleErrors :: Either IOError FilePath -> IO (Maybe FilePath)
    handleErrors = \case
      Right s -> return $ Just s -- TODO assert single line, strip newline
      Left{}  -> return Nothing  -- TODO trace error
