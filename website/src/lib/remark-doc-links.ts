type Node = { type?: string; url?: string; children?: Node[] };
type File = { path?: string; history?: string[] };

export function remarkDocLinks() {
  return (tree: Node, file: File) => {
    const source = file.path ?? file.history?.[0] ?? '';
    const normalizedSource = source.replace(/\\/g, '/');
    const relativeSource = normalizedSource.match(/(?:^|\/)docs\/(.*)$/)?.[1] ?? '';
    const sourceDir = relativeSource ? relativeSource.split('/').slice(0, -1).join('/') : '';
    const rewrite = (node: Node) => {
      if ((node.type === 'link' || node.type === 'image') && node.url) {
        const url = node.url;
        const [pathname, hash = ''] = url.split('#', 2);
        const resolved = `${sourceDir ? `${sourceDir}/` : ''}${pathname}`.split('/').reduce<string[]>((parts, item) => {
          if (!item || item === '.') return parts;
          if (item === '..') parts.pop();
          else parts.push(item);
          return parts;
        }, []).join('/');
        if (/^assets\/(screenshots|demo)\//.test(resolved)) {
          node.url = resolved.replace(/^assets\/(screenshots|demo)\//, '/media/$1/');
        } else if (/\.md$/.test(pathname)) {
          const slug = resolved.replace(/^docs\//, '').replace(/\.md$/, '');
          node.url = `/docs/${slug}/${hash ? `#${hash}` : ''}`;
        } else if (resolved === 'LICENSE') {
          node.url = `https://github.com/kristyancarvalho/hyprism/blob/main/LICENSE${hash ? `#${hash}` : ''}`;
        } else if (/^(?:\.\.\/|\.\/)/.test(pathname) && resolved) {
          node.url = `https://github.com/kristyancarvalho/hyprism/blob/main/${resolved}${hash ? `#${hash}` : ''}`;
        }
      }
      node.children?.forEach(rewrite);
    };
    rewrite(tree);
  };
}
