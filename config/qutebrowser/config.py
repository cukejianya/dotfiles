import os

import catppuccin

config.load_autoconfig()
# valid options are 'mocha', 'macchiato', 'frappe', and 'latte'
catppuccin.setup(c, 'mocha', True)

c.colors.webpage.darkmode.enabled = False 
c.completion.use_best_match = True 

c.editor.command = ['nvim', '-f', '{}']
c.window.hide_decoration = True

c.tabs.position = 'left'
c.tabs.show = 'switching'
c.fonts.tabs.selected = "32pt Sans"
c.fonts.tabs.unselected = "30pt Sans"
c.tabs.title.format = '{index}'
c.tabs.favicons.scale = 0.8
c.tabs.width = '5%'

c.url.auto_search = 'naive'
c.fonts.default_size = '18pt'

c.zoom.default = "125%"

c.url.searchengines = {
    'DEFAULT': 'https://duckduckgo.com/?q={}',
    'gc': 'https://calendar.google.com/calendar/u/0/r/search?q={}',
    'git': 'https://github.com/search?q={}',
    'gm': 'https://www.google.com/maps?q={}',
    'y': 'https://youtube.com/results?search_query={}',
}

# Private work overlay: extra search engines.
work_config = os.path.expanduser('~/.dotfiles-work/qutebrowser/work.py')
if os.path.exists(work_config):
    config.source(work_config)

config.bind('<Alt-Shift-u>', 'spawn --userscript qute-keepassxc --key 177C5800F00A9FAB', mode='insert')
config.bind('pw', 'spawn --userscript qute-keepassxc --key 177C5800F00A9FAB', mode='normal')
config.bind('pt', 'spawn --userscript qute-keepassxc --key 177C5800F00A9FAB --totp', mode='normal')

config.unbind('d')
config.bind('x', 'tab-close')

config.bind('<Ctrl-O>', 'tab-focus last')

config.bind('yo', 'spawn open {url} -a "Vivaldi"')
config.bind('ys', 'spawn ~/.local/bin/skd {url}')

config.bind('gv', 'spawn /usr/local/bin/umpv {url}')
config.bind(';v', 'hint links spawn /usr/local/bin/umpv {hint-url}')
config.bind(';s', 'hint links spawn ~/.local/bin/skd {hint-url}')

config.bind('<Ctrl-J>','completion-item-focus next',  mode='command')
config.bind('<Ctrl-K>','completion-item-focus prev',  mode='command')
