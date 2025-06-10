import LeanHypothesis.FFI

def testDir : IO Unit := do
  let currentDir ← IO.currentDir
  IO.println s!"Current directory: {currentDir}"
  let cmd := s!"cd {currentDir}/python && uv run leanhypothesis generate int 2"
  IO.println s!"Command: {cmd}"
  
  let result ← IO.Process.output {
    cmd := "sh"
    args := #["-c", cmd]
  }
  IO.println s!"Exit code: {result.exitCode}"
  IO.println s!"Stdout: {result.stdout}"
  IO.println s!"Stderr: {result.stderr}"

#eval testDir
