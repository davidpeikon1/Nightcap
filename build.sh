#!/bin/bash
# Build all-in-one HTML by inlining CSS and JS into preview.html

CSS=$(cat assets/nightcap-landing.css)
QUIZ_JS=$(cat assets/nightcap-quiz.js)
WAITLIST_JS=$(cat assets/nightcap-waitlist.js)

# Read preview.html and replace external references with inlined content
python3 -c "
import re, sys

with open('preview.html', 'r') as f:
    html = f.read()

with open('assets/nightcap-landing.css', 'r') as f:
    css = f.read()

with open('assets/nightcap-quiz.js', 'r') as f:
    quiz_js = f.read()

with open('assets/nightcap-waitlist.js', 'r') as f:
    waitlist_js = f.read()

# Replace CSS link with inline style
html = re.sub(
    r'<link rel=\"stylesheet\" href=\"assets/nightcap-landing\.css\">',
    '<style>\n' + css + '\n</style>',
    html
)

# Replace script tags with inline scripts
html = re.sub(
    r'<script src=\"assets/nightcap-quiz\.js\"></script>',
    '<script>\n' + quiz_js + '\n</script>',
    html
)

html = re.sub(
    r'<script src=\"assets/nightcap-waitlist\.js\"></script>',
    '<script>\n' + waitlist_js + '\n</script>',
    html
)

with open('public/index.html', 'w') as f:
    f.write(html)

# Also write the preview file
with open('nightcap-preview-all-in-one.html', 'w') as f:
    f.write(html)

print('Built public/index.html and nightcap-preview-all-in-one.html')
"
