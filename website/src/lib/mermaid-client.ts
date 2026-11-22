const palettes = {
  light: { background: '#fbf1c7', primaryColor: '#f2e5bc', primaryTextColor: '#282828', primaryBorderColor: '#b57614', lineColor: '#665c54', secondaryColor: '#ebdbb2', tertiaryColor: '#fbf1c7', noteBkgColor: '#ebdbb2', noteTextColor: '#282828', actorBkg: '#f2e5bc', actorBorder: '#b57614', signalColor: '#3c3836', signalTextColor: '#282828', labelBoxBkgColor: '#f2e5bc', textColor: '#282828', mainBkg: '#f2e5bc', nodeBorder: '#b57614', clusterBkg: '#fbf1c7', clusterBorder: '#d5c4a1', edgeLabelBackground: '#fbf1c7' },
  dark: { background: '#1d2021', primaryColor: '#3c3836', primaryTextColor: '#ebdbb2', primaryBorderColor: '#d79921', lineColor: '#a89984', secondaryColor: '#282828', tertiaryColor: '#1d2021', noteBkgColor: '#504945', noteTextColor: '#ebdbb2', actorBkg: '#3c3836', actorBorder: '#d79921', signalColor: '#ebdbb2', signalTextColor: '#ebdbb2', labelBoxBkgColor: '#3c3836', textColor: '#ebdbb2', mainBkg: '#3c3836', nodeBorder: '#d79921', clusterBkg: '#282828', clusterBorder: '#504945', edgeLabelBackground: '#282828' },
};

let counter = 0;

async function render() {
  const figures = document.querySelectorAll<HTMLElement>('figure.mermaid-diagram');
  if (!figures.length) return;
  const { default: mermaid } = await import('mermaid');
  const theme = document.documentElement.dataset.theme === 'dark' ? 'dark' : 'light';
  mermaid.initialize({ startOnLoad: false, securityLevel: 'strict', theme: 'base', themeVariables: { ...palettes[theme], fontFamily: 'IBM Plex Sans Variable, sans-serif' } });
  for (const figure of figures) {
    if (figure.dataset.renderedTheme === theme) continue;
    const source = figure.dataset.source ?? '';
    try {
      const { svg } = await mermaid.render(`mermaid-${++counter}`, source);
      let output = figure.querySelector<HTMLElement>('.mermaid-output');
      if (!output) {
        output = document.createElement('div');
        output.className = 'mermaid-output';
        figure.append(output);
      }
      output.innerHTML = svg;
      figure.dataset.renderedTheme = theme;
      figure.classList.add('is-rendered');
      figure.classList.remove('has-error');
    } catch (error) {
      console.error('Mermaid render failed', error);
      figure.classList.add('has-error');
      figure.dataset.renderedTheme = theme;
    }
  }
}

if (document.querySelector('figure.mermaid-diagram')) {
  render();
  new MutationObserver(() => render()).observe(document.documentElement, { attributes: true, attributeFilter: ['data-theme'] });
}
