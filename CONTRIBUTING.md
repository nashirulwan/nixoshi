# Contributing

Everything in this repository is intended for a public GitHub audience.

- Keep only reusable rice, applications, documentation, examples, and tests.
- Do not add real hardware UUIDs, private IP addresses, personal runtime state, internal service topology, secrets, agent plans, or local build outputs.
- Keep `home/default.nix` account-neutral: consumers set `home.username` and `home.homeDirectory`.
- Keep compositor, Noctalia, and HyperHDR defaults independent of connector names, fixed resolutions, and refresh rates.
- Use safe documented examples for host-specific values. Deployment aliases belong behind the optional `privateRoot` argument; mutable Noctalia state belongs in a consumer-local path or an explicit `nixoshiSettingsFile` override.
- Run `tests/public-portability.sh`, `tests/mango-output-toggle.sh`, and `tests/hyperhdr-output-chooser.sh`, then parse changed Nix and JSON files before submitting changes.
- Do not commit or push until the private workspace can compose and evaluate the selected public revision.
