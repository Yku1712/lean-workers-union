#!/usr/bin/env lean4

import Lean

-- ============================================
-- Lean Worker Tool URL Generation
-- ============================================
-- This module provides the interface for tools to generate shareable URLs
-- that describe tool output and can be rendered on the union static site.
--
-- Usage:
--   A tool calls generateToolUrl with the tool name, parameters, and output hash
--   The result is a shareable URL like:
--     https://lean-workers-union.oneapp.dev/union/{tool}/{id}
--   or
--     https://meta-introspector.github.io/lean-workers-union/results/{tool}/{id}

open Lean
open Std

namespace UnionUrl

-- ============================================
-- URL Components
-- ============================================

-- Base URL for the union site
def unionBaseUrl : String := "https://lean-workers-union.oneapp.dev/union/"

-- Alternative base URL for GitHub Pages
def githubPagesBaseUrl : String := "https://meta-introspector.github.io/lean-workers-union/"

-- Result URL path
def resultPath : String := "results/"

-- Union URL path (parameter-based)
def unionPath : String := "union/"

-- ============================================
-- Tool Types
-- ============================================

-- Tool category
inductive ToolCategory
  | Build         -- Build operations
  | Proof         -- Proof generation
  | Compile       -- Compilation operations
  | Generate      -- Content generation
  | Verify        -- Verification operations
  | Deploy        -- Deployment operations
  | Sync          -- Synchronization
  | Custom of String  -- Custom tool category
  deriving Repr, DecidableEq

-- Tool result type
structure ToolResult where
  toolName  : String
  categoryId  : ToolCategory
  description : String
  outputHash : String
  params     : List (String × String)  -- parameter name × value pairs
  createdAt  : String
  expiresAt  : Option String

-- ============================================
-- URL Generation
-- ============================================

-- Generate a unique result identifier from hash
def generateResultId (hash : String) : String :=
  String.take 8 (hash.foldl (fun acc c => String.replace acc "" "") "") ++ "_" ++ String.substring hash 0 16

-- Build parameter string from list of pairs
def paramsToString (params : List (String × String)) : String :=
  params.foldl (fun acc (name, value) =>
    if acc == "" then
      name ++ "=" ++ value
    else
      acc ++ "&" ++ name ++ "=" ++ value) ""

-- Encode tool parameters for URL
def encodeParams (params : List (String × String)) : String :=
  params.foldl (fun acc (name, value) =>
    let encoded := value.replace " " "+" |>.replace "/" "%2F".replace "?" "%3F"
    if acc == "" then
      name ++ "=" ++ encoded
    else
      acc ++ "&" ++ name ++ "=" ++ encoded) ""

-- Generate union URL (parameter-based) for a tool result
def generateUnionUrl (result : ToolResult) : String :=
  let id := result.outputHash.take 16
  unionBaseUrl ++ unionPath ++ result.toolName ++ "/" ++ id ++ "?" ++ encodeParams result.params

-- Generate GitHub Pages result URL
def generateResultUrl (result : ToolResult) : String :=
  let id := result.outputHash.take 16
  githubPagesBaseUrl ++ resultPath ++ result.toolName ++ "/" ++ id

-- Generate shareable short URL
def generateShortUrl (result : ToolResult) : String :=
  let toolName := result.toolName
  let short := "lw-" ++ toolName ++ "-" ++ result.outputHash.take 8
  short

-- Resolve short URL to full URL
def resolveShortUrl (short : String) : Option String :=
  if short.startsWith "lw-" then
    let toolName := String.drop 3 short |>.takeWhile (fun c => c ≠ '-')
    let hash := String.drop (toolName.length + 3 + 1) short
    some (githubPagesBaseUrl ++ resultPath ++ toolName ++ "/" ++ hash)
  else
    none

-- ============================================
-- URL Rendering Parameters
-- ============================================

-- Get URL parameters for rendering
def urlParameters (result : ToolResult) : String :=
  let params := result.params
  let paramList := params.foldl (fun acc (name, value) =>
    acc ++ "<p><strong>" ++ name ++ "</strong>: " ++ value ++ "</p>") ""
  paramList

-- Get tool description for rendering
def toolDescription (result : ToolResult) : String :=
  result.description

-- Get metadata for HTML rendering
def renderMetadata (result : ToolResult) : String :=
  "Tool: " ++ result.toolName ++
  " | Category: " ++ result.categoryId.toString ++
  " | Created: " ++ result.createdAt ++
  " | Output: " ++ result.outputHash

-- ============================================
-- Examples
-- ============================================

-- Example: Build result URL
def buildExampleUrl : String :=
  let buildResult : ToolResult :=
    {
      toolName := "lake-build",
      categoryId := ToolCategory.Build,
      description := "Full project build completed",
      outputHash := "abc123def456789",
      params := [("build-target", "ChoirUnion"), ("build-time", "25s")],
      createdAt := "2026-10-12T22:44:07Z",
      expiresAt := none
    }
  generateUnionUrl buildResult

-- Example: Proof result URL
def proofExampleUrl : String :=
  let proofResult : ToolResult :=
    {
      toolName := "proof-check",
      categoryId := ToolCategory.Proof,
      description := "Proof verification passed",
      outputHash := "xyz789abc456",
      params := [("theorem", "isGcpTwinConsistentWithBase"), ("steps", "12"), ("verified", "true")],
      createdAt := "2026-10-12T23:00:00Z",
      expiresAt := none
    }
  generateUnionUrl proofResult

end UnionUrl
