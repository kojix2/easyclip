# EasyClip

[![test](https://github.com/kojix2/easyclip/actions/workflows/test.yml/badge.svg)](https://github.com/kojix2/easyclip/actions/workflows/test.yml)

Crystal module for clipboard interaction.

## Installation

Add to `shard.yml`:

```yaml
dependencies:
  easy_clip:
    github: kojix2/easyclip
```

Run `shards install`

## Usage


```crystal
require "easyclip"

# Copy 'text' to clipboard
EasyClip.copy("text")

# Paste text from the clipboard
str = EasyClip.paste
```

## Contributing

1. Fork (<https://github.com/kojix2/easyclip/fork>)
2. Feature branch (`git checkout -b new-feature`)
3. Commit (`git commit -am 'Add feature'`)
4. Push (`git push origin new-feature`)
5. Pull request

## License

MIT 
