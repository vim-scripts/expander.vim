" Author: Michael Benfield (leftfist AT mac DOT com)
" Version: 1
" Last Modified: 2004 Jan 30
"
" expander vim plugin
"
" Put this file in your plugin directory (~.vim/plugin/).

python << EOF
import vim, copy

def ss():
    sw = int(vim.eval("&sw"))
    return " " * sw

expander_table = {
"c": """
class $1 {
$#$1($0);
$#~$1();
};""",

"f": """
for( $0; ; )""",

"fb": """
for( $0; ; ) {
}""",

"fe": """
for(;;)
$#$0""",

"feb": """
for(;;) {
$#$0
}""",

"fi": """
for($1::iterator i = $2.begin(); i != $2.end(); ++i)
$#$0""",

"fib": """
for($1::iterator i = $2.begin(); i != $2.end(); ++i) {
$#$0
}""",

"ig": """
#ifndef $1
#define $1
$0
#endif // $1
""",

"s": """
struct $0 {
};""",

"sw": """
switch($1) {
$#case $0
$#default: assert(false);
}""",

"t": """
template<$0>""",

"u": """
union $0 {
};"""
}
expander_separator = "@"

def expander_add(d):
    for k, v in d.iteritems():
        expander_table[k] = v

class expander:
    def __init__(self):
        self.initial_cursor = vim.current.window.cursor
        self.initial_line = vim.current.line
    def expand(self):
        "Inserts expanded text & removes abbreviation"
        self.parse_abbrev()
        if not expander_table.has_key(self.abbr_args[0]):
            vim.current.window.cursor = (self.initial_cursor[0],
                                         self.initial_cursor[1] + 1)
            return
        self.to_insert = copy.copy(expander_table[self.abbr_args[0]])
        self.make_list()
        self.change_tabs()
        self.make_subs()
        self.fix_first_line()
        self.fix_other_lines()
        self.insert_text()
        self.move_cursor()
    def parse_abbrev(self):
        "Finds beginning of argument list & breaks argument list up"
        i = self.initial_line.find(expander_separator)
        if i == -1:
            self.abbr_args = []
        i2 = self.initial_cursor[1]
        self.abbr_args = self.initial_line[i+1:i2+1].split(expander_separator)
        self.initial_arg_column = i
    def make_list(self):
        if type(self.to_insert) != str: return
        self.to_insert = self.to_insert.splitlines()[1:]
    def change_tabs(self):
        spaces = int(vim.eval("&sw")) * " "
        for line_count, s in enumerate(self.to_insert):
            self.to_insert[line_count] = s.replace("$#", spaces)
    def make_subs(self):
        "Makes substitutions & checks for $0"
        to_insert = self.to_insert
        self.new_cursor_line = 0
        self.new_cursor_column = 0
        for line_count, s in enumerate(to_insert):
            for i in range(len(self.abbr_args) - 1, 0, -1):
                # go backwards so eg looking for $1 won't gobble $10
                to_insert[line_count] = \
                    to_insert[line_count].replace("$" + str(i),
                                                  self.abbr_args[i])
            nc = to_insert[line_count].find("$0")
            if nc != -1:
                self.new_cursor_line = line_count
                self.new_cursor_column = nc
                to_insert[line_count] = to_insert[line_count].replace("$0", '')

    def fix_first_line(self):
        "Puts text from the line the cursor is on into to_insert"
        to_insert = self.to_insert
        to_insert[0] = self.initial_line[:(self.initial_arg_column)] + \
                       to_insert[0] + \
                       self.initial_line[self.initial_cursor[1]+1:]
    def fix_other_lines(self):
        for i, s in enumerate(self.to_insert[1:]):
            self.to_insert[i+1] = " " * self.initial_arg_column + s
    def insert_text(self):
        vim.current.line = self.to_insert[0]
        if(len(self.to_insert) > 1):
            vim.current.range.append(self.to_insert[1:])
    def move_cursor(self):
        vim.current.window.cursor = \
                (self.new_cursor_line + self.initial_cursor[0],
                 self.new_cursor_column + self.initial_arg_column)
EOF
map! <silent> <C-e> <ESC>:python expander().expand()<CR>i
