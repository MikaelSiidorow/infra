/// <reference types="tree-sitter-cli/dsl" />
// @ts-check

module.exports = grammar({
  name: "po",

  // Newlines in extras: they don't create tree nodes, so mergiraf's tree
  // diffing operates on a compact tree of just messages and their parts.
  extras: (_$) => [/[ \t]/, /\r?\n/],

  rules: {
    source_file: ($) =>
      repeat(choice($.message, $.obsolete_entry)),

    message: ($) =>
      seq(
        optional($.comments),
        optional($.msgctxt),
        $.msgid,
        optional($.msgid_plural),
        choice($.msgstr, repeat1($.msgstr_plural)),
      ),

    // Wrapper node for comments preceding a message or obsolete entry.
    // Marked as a commutative parent in mergiraf so that adding different
    // reference comments on both sides of a merge resolves cleanly.
    comments: ($) => repeat1($.comment),

    // Obsolete entries (#~ lines) can be preceded by regular comments like
    // #: references. Without this wrapper, the parser fails when it sees
    // a comment followed by #~ instead of msgid.
    obsolete_entry: ($) =>
      prec.right(seq(optional($.comments), repeat1($.obsolete_comment))),

    comment: ($) =>
      choice(
        $.translator_comment,
        $.extracted_comment,
        $.reference_comment,
        $.flag_comment,
        $.previous_comment,
      ),

    // Each comment type is a single token. Trailing newlines are NOT included
    // in the token (they're consumed by extras) so that mergiraf's @virtual_line@
    // splitting doesn't trigger, and commutative parent rendering works correctly.
    translator_comment: (_$) =>
      token(seq("#", optional(seq(" ", /[^\n]*/)))),
    extracted_comment: (_$) =>
      token(seq("#.", optional(seq(" ", /[^\n]*/)))),
    reference_comment: (_$) =>
      token(seq("#:", optional(seq(" ", /[^\n]*/)))),
    flag_comment: (_$) =>
      token(seq("#,", optional(seq(" ", /[^\n]*/)))),
    previous_comment: (_$) =>
      token(seq("#|", optional(seq(" ", /[^\n]*/)))),
    obsolete_comment: (_$) =>
      token(seq("#~", optional(seq(" ", /[^\n]*/)))),

    // Keyword blocks: the keyword followed by one or more strings.
    // Newlines between continuation strings are consumed by extras.
    msgctxt: ($) => seq("msgctxt", repeat1($.string)),
    msgid: ($) => seq("msgid", repeat1($.string)),
    msgid_plural: ($) => seq("msgid_plural", repeat1($.string)),
    msgstr: ($) => seq("msgstr", repeat1($.string)),
    msgstr_plural: ($) =>
      seq("msgstr[", /[0-9]+/, "]", repeat1($.string)),

    // A string is a single token — no child nodes, minimal tree overhead.
    string: (_$) =>
      token(
        seq(
          '"',
          repeat(
            choice(
              /\\[\\'"abtnvfr]/,
              /\\[0-7]{1,3}/,
              /\\x[0-9a-fA-F]{2}/,
              /[^\\"\n]+/,
            ),
          ),
          '"',
        ),
      ),
  },
});
