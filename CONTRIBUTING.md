# Contributing to Toka

Thanks for taking the time to contribute.

## Developer Certificate of Origin

This project uses the Developer Certificate of Origin (DCO) 1.1. By submitting a
contribution you certify that you have the right to submit it under the
Apache License 2.0 and that you agree to the DCO:

<https://developercertificate.org/>

Sign off every commit:

```bash
git commit -s -m "your message"
```

The sign-off adds a `Signed-off-by: Your Name <you@example.com>` trailer. Pull
requests without sign-offs may be asked to amend the commits.

## Pull requests

- Keep changes focused and explain the problem they solve.
- Run the checks in the README (`scripts/test-rules.sh`, Gradle compile).
- Do not include real Firebase configuration, keystores, `.env` files, APKs or
  personal data.
- Security issues go to the address in `SECURITY.md`, not to public issues.

## License

By contributing, you agree that your contribution is licensed under the
Apache License 2.0 (see `LICENSE`) and that copyright in the project remains
with Tucunar SpA and its contributors.
