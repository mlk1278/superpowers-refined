# Capture matrix

Read this when writing a matrix for `scripts/ux-capture`. Paths passed to the
command resolve from the working directory; relative `storageState` resolves
from `--project-root`. Run from the consuming project, using the absolute
script path from the loaded ux-gate skill.

```json
{
  "baseUrl": "http://localhost:3000",
  "themes": ["light", "dark"],
  "viewports": [{"width": 1440, "height": 900, "dpr": 1}],
  "theme": {"mode": "class", "target": "html", "values": {"light": "", "dark": "dark"}},
  "pathways": [{
    "name": "settings",
    "path": "/settings",
    "steps": [
      {"name": "open", "waitFor": "form"},
      {"name": "name", "action": "fill", "selector": "input[name=name]", "value": "Ada", "capture": false},
      {"name": "save-focus", "action": "press", "key": "Tab", "expectFocus": "button[type=submit]"},
      {"name": "save", "action": "press", "key": "Enter", "waitFor": "text=Saved"}
    ]
  }]
}
```

`baseUrl` and nonempty `pathways` are required. Each pathway has a unique
`name` and a route `path`. Omitted `steps` defaults to one step named `open`;
explicitly empty step lists, themes, or viewports are errors. Names and state
labels use letters, digits, underscores, or hyphens. Output tags must be unique.

Defaults: light/dark themes; viewports 375×812 at DPR 2, 768×1024 at DPR 1,
and 1440×900 at DPR 1. Override these with the project's supported set.

Optional matrix fields:

- `storageState`: Playwright auth-state JSON path. Obtain it using the project's
  login procedure. A missing configured file stops the run.
- `theme`: `mode` is `media` (default, color-scheme emulation), `class`,
  `attribute` (`data-theme`), or `localStorage`. `target` defaults to `html`;
  `key` is the localStorage key, default `theme`. `values` maps each theme
  name to the value to set. Match the app's theme initialization.
- `fonts`: required web-font families. Each must have a loaded FontFace
  declaration; omit system/generic fallback families.
- `allowOverflow`, `allowOverlap`, `allowLight`: CSS selectors exempting
  intentional layouts from those checks, including matching descendants.
- `referenceScreens`: unchanged routes to use as design examples, captured
  at the first viewport in every theme on an unfiltered full run.

Step fields:

| Field | Meaning |
|---|---|
| `name` | Unique step label within its pathway. |
| `state` | Output label, default `default`; does not create a UI state. Seed or select the state separately. |
| `action` | `click`, `hover`, `focus`, `scroll`, `fill`, or `press`; omit for capture/assertions only. |
| `selector` | Playwright selector for the action. Required except for page-level `press`. |
| `value` / `key` | String for `fill` / key combination for `press`, such as `Tab`, `Shift+Tab`, `Enter`, or `Escape`. |
| `expectFocus` | CSS selector that must match the active element after the action. |
| `waitFor` | Playwright selector that must become visible before capture. |
| `capture` | Default true. False retains actions and checks but skips all step images. |
| `fullPage` | Default false; true captures the full page. |
| `crops` | Component selectors to capture at DPR 2. |
| `motion` | True adds normal/reduced-motion frames to a filmstrip on full runs. |

Crops and reduced-motion frames replay earlier actions in fresh browser
contexts. Those contexts share the server: seed resettable fixtures for
mutating pathways so repeated actions reach the same state.

`--smoke` uses the first viewport and every matrix theme, skipping axe,
filmstrips, references, and diffs. `--pathway <name>` is repeatable.
`--baseline <dir>` compares same-named stills. `--video` records optional
local video; reviewers receive images.

`mechanical.json` records checks and artifact paths per step. Exit 0 means
no findings at `should` or above, 1 means findings, and 2 means cannot run.
A missing optional axe module is `unavailable`; a failed installed scan or
requested capture artifact is a blocker. Missing baseline stills are `new`.
