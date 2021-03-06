COBOL.vim
=========

Vim runtime files for COBOL programming language

## Installation

Use your favourite plugin manager - just make sure plugin will be earlier
in order than default `$VIMRUNTIME`.

### [minPlug](https://github.com/Jorengarenar/minPlug):
```
MinPlug Jorengarenar/COBOl.vim
```

### [vim-plug](https://github.com/junegunn/vim-plug):
```vim
Plug 'Jorengarenar/COBOl.vim'
```

### Vim's packages
```bash
mkdir -p ~/.vim/pack/plugins/start
cd ~/.vim/pack/plugins/start
git clone https://github.com/Jorengarenar/COBOl.vim.git
```

### [NeoBundle](https://github.com/Shougo/neobundle.vim)
```vim
NeoBundle 'Jorengarenar/COBOl.vim'
```

## Configuration

Global (or buffer) variables:

|    variable (`g:`/`b:`)   |   def   | description |
|---------------------------|---------|-------------|
| `cobol_legacy_code`       |   `0`   | set to `1` for legacy mode
| `cobol_colorcolumns`      |   `0`   | set to `1` to use `colorcolumn` as borders between areas
| `cobol_folding`           |   `0`   | set to `1` for syntax based code folding
| `cobol_autoupper`         |   `0`   | set to `1` to automatically change keywords to uppercase
| `cobol_indent_data_items` |   `1`   | indentation of items in `DATA DIVISION` (`0` - all in area A, `1` - to area B, `2` - each level more indented)
| `cobol_indent_id_paras`   |   `0`   | indent paragraphs in `IDENTIFICATION DIVISION` to area B
| `cobol_comp_mp_cobc`      |   `0`   | if set to `1`, `compiler` will set `cobc\ -O\ -x` as `makeprg`
| `cobol_format_free`       |   `0`   | set to `1` to have file in to have FORMAT FREE without compiler directives
| `cobol_comp_mp`           |  `""`   | if not empty and `cobol_comp_mp_cobc` not set to `1`, the value will be used to set `makeprg`
| `cobol_syntax_compl`      |   `1`   | set to `0` to disable setting `omnifunc` to `syntaxcomplete#Complete`
| `cobol_inline_comment`    |   `1`   | set to `0` to disable highlighting inline comments (`*> ...`)

---

Contains updated version of [tpope](https://github.com/tpope)'s [cobol.zip](http://www.vim.org/scripts/script.php?script_id=1655)
