config.load_autoconfig(True)

c.colors.webpage.darkmode.enabled = True 
c.completion.use_best_match = True 

c.editor.command = ['nvim', '-f', '{}']
c.window.hide_decoration = True

c.tabs.position = 'left'
c.tabs.show = 'switching'
c.url.auto_search = 'naive'
c.fonts.default_size = '14pt'

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

config.bind('<Ctrl-O>', 'tab-focus stack-prev')
config.bind('<Ctrl-I>', 'tab-focus stack-next')
