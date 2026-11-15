# Legacy settings bridge

The active addon is now `ASRAdvisor`. This folder only declares the old
`ASAdvisorDB` saved variable so the client loads existing builds and preferences
before `ASRAdvisor` initializes. It contains no Lua code and creates no interface.
Keep this folder enabled when upgrading from v0.6.1 or earlier.
