# danger-vale

A plugin for [danger](https://danger.systems/ruby/) which checks prose commited to git repositories.

## Dependencies
You need to [install the vale command](https://github.com/errata-ai/vale) to use this plugin.


## Usage
Follow the instructions to [set up Danger for your project](https://danger.systems/guides/getting_started.html).

Then call `vale.lint_files` in your `Dangerfile`:

<blockquote>Lint all added and modified files
  <pre>
vale.lint_files</pre>
</blockquote>

<blockquote>Lint specific files
  <pre>
vale.lint_files ["README.md"]</pre>
</blockquote>

Danger will add inline comments to the lines that generate vale warnings or errors.

## License

See [LICENSE.txt](LICENSE.txt)