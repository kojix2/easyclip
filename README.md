# EasyClip

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

EasyClip.copy('text')  # Copy 'text' to clipboard
puts EasyClip.paste    # Output text from the clipboard
```

## Contributing

1. Fork (<https://github.com/kojix2/easyclip/fork>)
2. Feature branch (`git checkout -b new-feature`)
3. Commit (`git commit -am 'Add feature'`)
4. Push (`git push origin new-feature`)
5. Pull request

## License

MIT 
