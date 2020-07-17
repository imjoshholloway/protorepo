# API

Centralized api definitions using [`protocol buffers`][protocol-buffers] with linting and code generation using [`buf`][bufbuild].

All protos live in the `proto/` directory, following the convention of: `proto/<service>/<version>/<service>.proto`.

The generated code also live in this repository following the convention of `<service>/<version>/`.

See the [`example`](./proto/example/v1/example.proto) for an example service.

## Usage

All commands are accessible via `make`. Some of the more common ones needed are:

- `deps` - Install all the dependences
- `protodeps` - Update the third party proto dependencies
- `buf-local` - Performs linting and local breaking change detection against the local repository's `mainline` branch.
- `buf-lint` - Performs linting using [`buf`][bufbuild] to ensure all protos conform to standards.
- `buf-breaking` - Performs breaking change detection against the remote `mainline` branch.
- `protos` - Generates any `*.pb.go` files.

### Using third party definitions

All third party dependencies should be added to `protodeps.toml` and downloaded with `make protodeps`.

As an example, to add the https://github.com/googleapis/api-common-protos proto definitions
we would add the repository to the `protodeps.toml`:

```toml
[[dependencies]]
  target = "github.com/googleapis/api-common-protos"
  revision = "be41e82ef4af6406b4cf331af00a837f813c0c3bj"
```

Run `make protodeps` to download the files to the `third_party/proto` directory.
Then, you can `import google/api/annotations.proto` in your proto definitions.

**Note:** It's highly likely that third party definitions won't conform to the styleguide
so you may also need to add rules to `lint.ignore`. This allows directories or
files to be excluded from all lint checkers when running buf check lint. The specified
directory or file paths should be relative to their root.

```yaml
lint:
  ignore:
    - google
```

[protocol-buffers]: https://developers.google.com/protocol-buffers/
[bufbuild]: https://buf.build/
