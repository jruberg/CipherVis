root = exports ? this

log = root.utils.log
_.each(root.str, (f, name) -> String.prototype[name] = f)
_.each(root.arr, (f, name) -> Array.prototype[name] = f)
des = root.des

## Settings

DEBUG = true

# Validate the key and plaintext; return error if etiher fails to validate.
validate = (key, plain) ->

  generic_validate = (name, str) ->

    if str == ""
      "#{name} empty"
    else if str.length < 16
      "#{name} too short"
    else if str.length > 16
      "#{name} too long"
    else unless str.is_hex()
      "non-hex chars in #{name}"
    else
      ""

  k_msg = generic_validate("key", key)
  p_msg = generic_validate("plaintext", plain)

  if k_msg
    if p_msg
      "#{k_msg.caps()}; #{p_msg}"
    else
      k_msg.caps()
  else
    if p_msg
      p_msg.caps()
    else
      ""


$(document).ready ->

  results = {}

  # Run DES when the arrows are clicked.
  $("#encipher").click ->
    k = $("#key").val()
    p = $("#plaintext").val()

    val = validate(k, p)

    if val
      $("#error").text(val).fadeIn(500)
      results = {}
    else
      $("#error").fadeOut(500, () -> $(this).text(""))

      results = des(k, p)
      $("#ciphertext").text results.c_hex

      display_des($("#display"), results, -> return)

  $("#plaintext, #key").keydown (e) -> $("#encipher").click() if e.keyCode == 13

  if DEBUG
    # Set defaults
    $("#key").val("3B3898371520F75E")
    $("#plaintext").val("0123456789ABCDEF")

## Display helpers ##

# Reveal a step by sliding it up.
show = ($d, id, callback, t = show.default_t) ->
  $d.find(id).fadeIn(t).children(".step").fadeIn(t).end()
    .children(".spacer").slideUp(t, callback)
show.default_t = 1000

# Reveal a step and contained code.
show_code = ($d, id, callback, t = show.default_t, t2 = show_code.default_t2) ->
  show $d, id, ( ->
    $d.find(id).find(".code_line").fadeIn(t2, callback)
    callback()
  ), t
show_code.default_t2 = show.default_t / 2

# Handles placing text in code boxes such that it's spaced properly (does this
# by actually inserting several spans).
insert = ($d, id, cl, text, num) ->
  if root.utils.is_string(text)
    text = text.split('')
  words = text.print(num).split(' ')
  spans = _.map(words, (word) ->
    $("<span></span>").addClass("word").text(word).get(0)
  )
  $d.find(id).find(cl).empty().append(spans)
  $(spans).show()

## Display steps ##

display_des = ($d, res, callback) ->
  display_des_binary($d, res, callback)

display_des_binary = ($d, res, callback) ->
  insert $d, "#binary", ".one", res.p_hex, 1
  insert $d, "#binary", ".two", res.p, 4
  show_code $d, "#binary", -> display_des_ip($d, res, callback)

display_des_ip = ($d, res, callback) ->
  insert $d, "#ip", ".one", res.p, 4
  insert $d, "#ip", ".two", res.ip, 4
  show_code $d, "#ip", -> display_des_subkeys($d, res, callback)

display_des_subkeys = ($d, res, callback) ->
  show $d, "#subkeys", -> display_des_pc1($d, res, callback)

display_des_pc1 = ($d, res, callback) ->
  insert $d, "#pc1", ".one", res.k, 4
  insert $d, "#pc1", ".two", res.k_pc1, 4
  $("#subkey-list").show()
  show_code $d, "#pc1", -> display_des_split($d, res, callback)

display_des_split = ($d, res, callback) ->
  insert $d, "#split", ".one", res.cd[0].slice(0, 28), 4
  insert $d, "#split", ".two", res.cd[0].slice(28), 4
  show_code $d, "#split", -> display_des_shifts($d, res, callback)

display_des_shifts = ($d, res, callback) ->
  show $d, "#shifts", -> display_des_shift(1, $d, res, callback)

display_des_shift = (i, $d, res, callback) ->
  if i == 16
    f = ->
      display_des_pc2s($d, res, callback)
      callback()
  else
    f = ->
      display_des_shift(i+1, $d, res, callback)
      callback()

  insert $d, "#shift#{i}", ".one", res.cd[i].slice(0, 28), 4
  insert $d, "#shift#{i}", ".two", res.cd[i].slice(28), 4
  $d.find("#shift#{i}").find(".one, .two").fadeIn(show.default_t / 2, f)

display_des_pc2s = ($d, res, callback) ->
  return

