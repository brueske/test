# PyLearn

A macOS app for learning to **read** Python. Paste or write a Python script in
the left panel (which takes up 2/3 of the window, with Sublime/Xcode-style
syntax coloring), then flip to **Explain** mode to turn the code into a set of
selectable, hyperlink-like terms grouped by Python concept. Hovering highlights
each term; clicking shows a plain-language definition and example in the upper
right; and an **Analyze** button sends your selection to a model (Claude's API
or a local LLM) for a deeper explanation.

## Requirements

- macOS 13 (Ventura) or later
- Xcode 15 or later

## Build & run

1. Open `PyLearn.xcodeproj` in Xcode.
2. Select the **PyLearn** scheme and press **Run** (⌘R).

## Layout & controls

```
┌───────────────────────────────┬───────────────────────────┐
│  [ Edit | Explain ]           │   Definition              │
│                               │   (focused term + example)│
│   Code surface (2/3)          ├───────────────────────────┤
│                               │   Ask a Model             │
│                               │   [Local LLM | Claude API]│
│                               │   [ Analyze ]  + output   │
└───────────────────────────────┴───────────────────────────┘
```

- **Edit / Explain** toggle (top-left): *Edit* is an editable, syntax-colored
  text view. *Explain* converts the text into selectable term chips.
- **Hover** a term to highlight that chunk.
- **Click** a term to show its definition (top-right). A blue outline marks the
  focused term.
- **Arrow keys** (←/→/↑/↓) move from term to term once one is selected.
- **⇧-click** a second term to select the contiguous range between them.
- **⌘-click** to toggle discrete, non-adjacent terms — selected in order, so you
  can experiment with rearranging a phrase like puzzle pieces.
- Selecting multiple terms never shows more than one definition (it tracks the
  most recently clicked term).
- **Analyze** (bottom-right) sends the selected term(s) to the chosen model.
  With nothing selected it sends the whole script. (Tip: ⌘A inside the editor
  selects all the text.)

## Settings (⌘,)

- **Models tab** — your Claude API key + model (default `claude-opus-4-8`), and
  the local LLM base URL + model. The local option targets an OpenAI-compatible
  `/chat/completions` endpoint, so it works with **Ollama**
  (`http://localhost:11434/v1`) or **LM Studio** (`http://localhost:1234/v1`).
- **Definitions tab** — choose the built-in offline dictionary (default) or an
  online source (`docs.python.org` / `devdocs.io`). Online lookups are
  best-effort and fall back to the offline text when unreachable.

## How term grouping works

`PythonTokenizer` lexes the source, then groups raw tokens into learning-sized
"terms": keywords, operators, literals, and bare names each stand alone, while a
call or attribute chain (e.g. `print("hi")` or `math.pi`) is grouped into a
single term so the concept reads as one unit without disappearing into the whole
line.

## Source layout

| File | Role |
|------|------|
| `PyLearnApp.swift` | App entry point + Settings scene |
| `ContentView.swift` | 2/3 ↔ 1/3 split layout |
| `CodePanelView.swift` | Edit/Explain toggle + code surface |
| `SyntaxHighlightingTextView.swift` | `NSTextView` with live Python coloring |
| `TermFlowView.swift` | Explain-mode chips: hover, click, multi-select, arrows |
| `DefinitionView.swift` | Upper-right definition box |
| `LLMPanelView.swift` | Lower-right model picker + Analyze |
| `SettingsView.swift` | Preferences (API key, endpoints, definition source) |
| `PythonTokenizer.swift` | Lexer + term grouping |
| `PythonSyntax.swift` | Keyword/builtin sets + color theme |
| `PythonDefinitions.swift` | Offline definition dictionary |
| `DefinitionProvider.swift` | Offline/online definition resolution |
| `LLMService.swift` | Claude Messages API + local OpenAI-compatible calls |
| `AppModel.swift` | Shared observable state |

## Notes

- The app is sandboxed with outbound network access (`PyLearn.entitlements`) so
  it can reach the model endpoints.
- Your Claude API key is stored in the app's preferences and is sent only to
  `api.anthropic.com`.
