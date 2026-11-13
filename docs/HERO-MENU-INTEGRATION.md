# Hero-menu builder entry: cancelled

Requested: a button immediately to the right of the eye in the hero/main menu, matching its size, border and horizontal gap; left-click opens the builder, right-click opens builder settings, before starting a run.

The installed client has a separate Glue VM for that screen. Ordinary Interface/AddOns code runs in the world UI VM. The local native source confirms that the glue addon screen reads installed-addon metadata without loading addons (crates/benilla-app/src/ui_script/addons.rs, InstalledAddOn comment). No supported addon entry point for executing ASAdvisor and its saved build library in Glue has been found.

No hero-menu button is installed by this preparation, and no game files or executable have been changed. A supported client extension is needed: load an explicitly opted-in addon in Glue with safe catalogue/SavedVariables access, or expose a builder menu hook with a supported transition to its UI. Once that exists, match the eye's native bounds and spacing rather than hardcoding a screen position.

The user cancelled this feature. It is outside the publication scope.