# HTML Mixed with Markdown

## Inline HTML

This paragraph has <strong>HTML bold</strong> and <em>HTML italic</em> mixed in.

<mark>Highlighted text</mark> using the mark tag.

Text with <sub>subscript</sub> and <sup>superscript</sup>.

<kbd>Ctrl</kbd> + <kbd>C</kbd> to copy.

## Block HTML

<div style="padding: 1rem; background: #f0f0f0; border-radius: 4px;">
  <p>This is a div with inline styles.</p>
  <p>Markdown <strong>does not</strong> render inside HTML blocks by default.</p>
</div>

<details>
<summary>Click to expand</summary>

This content is hidden by default. It can contain **markdown** formatting once there's a blank line after the HTML tag.

- List item one
- List item two

</details>

<details>
<summary>Another collapsible with code</summary>

```ruby
class Example
  def initialize
    @hidden = true
  end
end
```

</details>

## Definition List (HTML)

<dl>
  <dt>RailsPress</dt>
  <dd>A mountable blog engine for Rails</dd>
  <dt>Lexxy</dt>
  <dd>A rich text editor built on Lexical</dd>
  <dt>ActionText</dt>
  <dd>Rails' built-in rich text framework</dd>
</dl>
