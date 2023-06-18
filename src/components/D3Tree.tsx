import React, { useEffect, useRef } from 'react';
import * as d3 from 'd3';

export const D3Tree = ({ data, levels }: {data: any, levels: number}) => {
  const ref = useRef<SVGSVGElement>(null);

  useEffect(() => {
    if (!ref.current) return;

    d3.select(ref.current).selectAll("*").remove();

    const svg = d3.select(ref.current);
    const width = +svg.attr("width");
    const height = +svg.attr("height");

    const treeLayout = d3.tree<any>().size([2 ** levels * 80, levels * 80]); // Multiply number of leaves by a suitable spacing factor

    const root = d3.hierarchy(data);
    const leafCount = root.leaves().length;
    treeLayout(root);
    const g = svg.append("g").attr("transform", "translate(50,50)");

    // Adding nodes
    g.selectAll("circle")
      .data(root.descendants())
      .enter()
      .append("circle")
      // @ts-ignore
      .attr("cx", (d) => d.x)
      // @ts-ignore
      .attr("cy", (d) => d.y)
      .attr("r", 5)
      .style("fill", (d) => "none")
      .style("stroke", (d) => "black");

    // Adding node labels
    g.selectAll("text")
      .data(root.descendants())
      .enter()
      .append("text")
      // @ts-ignore
      .attr("x", (d) => d.x)
      // @ts-ignore
      .attr("y", (d) => d.y + 20)
      .attr("dy", 4) // slight offset to center the text
      .text((d) => d.data.name)
      .attr("font-size", "12px")
      .attr("text-anchor", "middle")
      .attr("fill", (d) => d.data.attributes.color || "black");

    // Adding links
    g.selectAll("line")
      .data(root.links())
      .enter()
      .append("line")
      // @ts-ignore
      .attr("x1", (d) => d.source.x)
      // @ts-ignore
      .attr("y1", (d) => d.source.y)
      // @ts-ignore
      .attr("x2", (d) => d.target.x)
      // @ts-ignore
      .attr("y2", (d) => d.target.y)
      .style("stroke", "black");

    // Add zoom and pan
    const zoom = d3
      .zoom()
      .scaleExtent([0.1, 4])
      .on("zoom", (event) => {
        g.attr("transform", event.transform);
      });
      // @ts-ignore
    svg.call(zoom);

    // Compute the new scale and translate
    const x0 = 0;
    const y0 = 0;
    const x1 = 2 ** levels * 10;
    const y1 = levels * 16;
    const dx = x1 - x0;
    const dy = y1 - y0;
    const x = (x0 + x1) / 2;
    const y = (y0 + y1) / 2;
    const scale = Math.max(1, Math.min(width / Math.abs(dx), height / Math.abs(dy)));
    const translate = [width / 2 - scale * x, height / 2 - scale * y];

    // Apply initial zoom
    // @ts-ignore
    svg.call(zoom.transform, d3.zoomIdentity.translate(translate[0], translate[1]).scale(1 / scale));
  }, [data]);

  return <svg ref={ref} width="1200" height="600"></svg>;
}
