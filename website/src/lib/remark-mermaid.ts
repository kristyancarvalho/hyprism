type Node = { type?: string; lang?: string | null; value?: string; children?: Node[] };

const escape = (value: string) => value.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');

export function remarkMermaid() {
  return (tree: Node) => {
    const visit = (node: Node) => {
      node.children?.forEach((child, index) => {
        if (child.type === 'code' && child.lang === 'mermaid') {
          const source = child.value ?? '';
          const label = source.split('\n')[0].trim() || 'diagram';
          node.children![index] = {
            type: 'html',
            value: `<figure class="mermaid-diagram" data-source="${escape(source)}" role="img" aria-label="Diagram (${escape(label)})"><pre class="mermaid-source"><code>${escape(source)}</code></pre></figure>`,
          };
        } else {
          visit(child);
        }
      });
    };
    visit(tree);
  };
}
