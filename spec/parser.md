
<!--
# specifying flor
#
# Mon Mar  7 06:24:41 JST 2016
-->

## atoms

```radial
  1
```
parses to
```ruby
  [ '_num', 1, 1 ]
```
---

```radial
  11.01
```
parses to
```ruby
  [ '_num', 11.01, 1 ]
```
---

```radial
  true
```
parses to
```ruby
  [ '_boo', true, 1 ]
```
---

```radial
  false
```
parses to
```ruby
  [ '_boo', false, 1 ]
```
---

```radial
  null
```
parses to
```ruby
  [ '_nul', nil, 1 ]
```
---

```radial
  abc
```
parses to
```ruby
  [ 'abc', [], 1 ]
```
---

```radial
  'def'
```
parses to
```ruby
  [ '_sqs', 'def', 1 ]
```
---

```radial
  "ghi"
```
parses to
```ruby
  [ '_dqs', 'ghi', 1 ]
```
---

```radial
  /jkl/i
```
parses to
```ruby
  [ '_rxs', '/jkl/i', 1 ]
```
---

```radial
  [ 1, 2, 3 ]
```
parses to
```ruby
  [ '_arr', [
    [ '_num', 1, 1 ], [ '_num', 2, 1 ], [ '_num', 3, 1 ]
  ], 1 ]
```
---

```radial
  [ 1 2 3 ]
```
parses to
```ruby
  [ '_arr', [
    [ '_num', 1, 1 ], [ '_num', 2, 1 ], [ '_num', 3, 1 ]
  ], 1 ]
```
---

```radial
  [1 2
  3]
```
parses to
```ruby
  [ '_arr', [
    [ '_num', 1, 1 ], [ '_num', 2, 1 ], [ '_num', 3, 2 ]
  ], 1 ]
```
---

```radial
  { a: A, b: 2, c: true }
```
parses to
```ruby
  [ '_obj', [
    [ 'a', [], 1 ], [ 'A', [], 1 ],
    [ 'b', [], 1 ], [ '_num', 2, 1 ],
    [ 'c', [], 1 ], [ '_boo', true, 1 ]
  ], 1 ]
```
---

```radial
  { a: A b: 2 c: true }
```
parses to
```ruby
  [ '_obj', [
    [ 'a', [], 1 ], [ 'A', [], 1 ],
    [ 'b', [], 1 ], [ '_num', 2, 1 ],
    [ 'c', [], 1 ], [ '_boo', true, 1 ]
  ], 1 ]
```
---

```radial
  { a: A # ah ah ah
    b: 2 c: # oh oh oh
      true }
```
parses to
```ruby
  [ '_obj', [
    [ 'a', [], 1 ], [ 'A', [], 1 ],
    [ 'b', [], 2 ], [ '_num', 2, 2 ],
    [ 'c', [], 2 ], [ '_boo', true, 3 ]
  ], 1 ]
```
---

## operations

```radial
  10 + 11 - 5
```
parses to
```ruby
  [ '-', [
    [ '+', [
      [ '_num', 10, 1 ],
      [ '_num', 11, 1 ]
    ], 1 ],
    [ '_num', 5, 1 ]
  ], 1 ]
```
---

```radial
  1 + 1 * 2
```
parses to
```ruby
  [ '+', [
    [ '_num', 1, 1 ],
    [ '*', [
      [ '_num', 1, 1 ],
      [ '_num', 2, 1 ]
    ], 1 ]
  ], 1 ]
```
---

```radial
  + 10 11 12
```
parses to
```ruby
  [ '+', [
    [ '_att', [ [ '_num', 10, 1 ] ], 1 ],
    [ '_att', [ [ '_num', 11, 1 ] ], 1 ],
    [ '_att', [ [ '_num', 12, 1 ] ], 1 ]
  ], 1 ]
```
---

```radial
  +
    10
    11
    12
```
parses to
```ruby
  [ '+', [
    [ '_num', 10, 2 ],
    [ '_num', 11, 3 ],
    [ '_num', 12, 4 ]
  ], 1 ]
```
---

## lines

```radial
  sequence
```
parses to
```ruby
  [ 'sequence', [], 1 ]
```
---

```radial
  sequence
    a
    b
```
parses to
```ruby
  [ 'sequence', [
    [ 'a', [], 2 ],
    [ 'b', [], 3 ]
  ], 1 ]
```
---

```radial
  sequence a b
```
parses to
```ruby
  [ 'sequence', [
    [ '_att', [ [ 'a', [], 1 ] ], 1 ],
    [ '_att', [ [ 'b', [], 1 ] ], 1 ]
  ], 1 ]
```
---

```radial
  sequence a, vars: 1, timeout: 1h, b
```
parses to
```ruby
  [ 'sequence', [
    [ '_att', [ [ 'a', [], 1 ] ], 1 ],
    [ '_att', [ [ 'vars', [], 1 ], [ '_num', 1, 1 ], ], 1 ],
    [ '_att', [ [ 'timeout', [], 1 ], [ '1h', [], 1 ], ], 1 ],
    [ '_att', [ [ 'b', [], 1 ] ], 1 ]
  ], 1 ]
```
---

```radial
  sequence a: 1 + 1, 2
```
parses to
```ruby
  [ 'sequence', [
    [ '_att', [
      [ 'a', [], 1 ],
      [ '+', [
        [ '_num', 1, 1 ],
        [ '_num', 1, 1 ]
      ], 1 ],
    ], 1 ],
    [ '_att', [
      [ '_num', 2, 1 ]
    ], 1 ]
  ], 1 ]
```

```radial
  sequence
    define sum a b
      +
        a
        b
    apply sum 1 2
```
parses to
```ruby
  [ 'sequence', [
    [ 'define', [
      [ '_att', [ [ 'sum', [], 2 ], ], 2 ],
      [ '_att', [ [ 'a', [], 2 ], ], 2 ],
      [ '_att', [ [ 'b', [], 2 ], ], 2 ],
      [ '+', [ [ 'a', [], 4 ], [ 'b', [], 5 ] ], 3 ]
    ], 2 ],
    [ 'apply', [
      [ '_att', [ [ 'sum', [], 6 ], ], 6 ],
      [ '_att', [ [ '_num', 1, 6 ], ], 6 ],
      [ '_att', [ [ '_num', 2, 6 ], ], 6 ]
    ], 6 ]
  ], 1 ]
```

## comments

```radial
  sequence # long time
    a
    b # no see
```
parses to
```ruby
  [ 'sequence', [
    [ 'a', [], 2 ],
    [ 'b', [], 3 ]
  ], 1 ]
```
---

```radial
  sequence # slash slash
    a
    b # baby
```
parses to
```ruby
  [ 'sequence', [
    [ 'a', [], 2 ],
    [ 'b', [], 3 ]
  ], 1 ]
```
---

## line breaks

```radial
  [ 1, 2 # trois
    4 ]
```
parses to
```ruby
  [ '_arr', [
    [ '_num', 1, 1 ],
    [ '_num', 2, 1 ],
    [ '_num', 4, 2 ]
  ], 1 ]
```
---

```radial
  { a: "anthracite" # comment
    b: "blue-yellow" cc: "carmin"
  }
```
parses to
```ruby
  [ '_obj', [
    [ 'a', [], 1 ],
    [ '_dqs', 'anthracite', 1 ],
    [ 'b', [], 2 ],
    [ '_dqs', 'blue-yellow', 2 ],
    [ 'cc', [], 2 ],
    [ '_dqs', 'carmin', 2 ],
  ], 1 ]
```
---

```radial
  sequence a, b, [ 1 # in the middle
    2], c
```
parses to
```ruby
  [ 'sequence', [
    [ '_att', [ [ 'a', [], 1 ] ], 1 ],
    [ '_att', [ [ 'b', [], 1 ] ], 1 ],
    [ '_att', [ [ '_arr', [ [ '_num', 1, 1 ], [ '_num', 2, 2 ] ], 1 ], ], 1 ],
    [ '_att', [ [ 'c', [], 2 ] ], 2 ]
  ], 1 ]
```
---

## parentheses

```radial
  sequence timeout: (+ 7 8 "h")
    a
    b
```
parses to
```ruby
  [ 'sequence', [
    [ '_att', [
      [ 'timeout', [], 1 ],
      [ '+', [
        [ '_att', [ [ '_num', 7, 1 ] ], 1 ],
        [ '_att', [ [ '_num', 8, 1 ] ], 1 ],
        [ '_att', [ [ '_dqs', 'h', 1 ] ], 1 ]
      ], 1 ],
    ], 1 ],
    [ 'a', [], 2 ],
    [ 'b', [], 3 ]
  ], 1 ]
```
