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
    'cs': 'https://codesearch.spotify.net/search?q={}',
    'gc': 'https://calendar.google.com/calendar/u/0/r/search?q={}',
    'git': 'https://github.com/search?q={}',
    'gm': 'https://www.google.com/maps?q={}',
    'j': 'https://spotify.atlassian.net/browse/{}',
    'y': 'https://youtube.com/results?search_query={}',
}

config.bind('<Alt-Shift-u>', 'spawn --userscript qute-keepassxc --key 177C5800F00A9FAB', mode='insert')
config.bind('pw', 'spawn --userscript qute-keepassxc --key 177C5800F00A9FAB', mode='normal')
config.bind('pt', 'spawn --userscript qute-keepassxc --key 177C5800F00A9FAB --totp', mode='normal')

config.unbind('d')
config.bind('x', 'tab-close')

config.bind('<Ctrl-O>', 'tab-focus last')

config.bind('yo', 'spawn open -a "Vivaldi" {url}')
config.bind('ys', 'spawn ~/.local/bin/skd {url}')

config.bind('gv', 'spawn umpv {url}')
config.bind(';v', 'hint links spawn umpv {hint-url}')
config.bind(';s', 'hint links spawn ~/.local/bin/skd {hint-url}')

config.bind('<Ctrl-J>','completion-item-focus next',  mode='command')
config.bind('<Ctrl-K>','completion-item-focus prev',  mode='command')
