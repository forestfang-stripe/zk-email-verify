import React, { useEffect, useRef } from "react";
import * as d3 from "d3";

export const D3Tree = ({ data, levels, index }: { data: any; levels: number, index: number }) => {
  const ref = useRef<SVGSVGElement>(null);
  const divRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!ref.current || !divRef.current) return;

    d3.select(ref.current).selectAll("*").remove();

    const svg = d3.select(ref.current);
    const rect = divRef.current.getBoundingClientRect();
    const width = Math.max(rect.width - 32, 400);
    const height = Math.max(rect.height - 32, 400);
    ref.current.setAttribute("width", width.toString());
    ref.current.setAttribute("height", height.toString());

    const dWidth = 80;
    const dHeight = 80;
    const treeLayout = d3.tree<any>().size([2 ** levels * dWidth, levels * dHeight]); // Multiply number of leaves by a suitable spacing factor

    const root = d3.hierarchy(data);
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
      .style("stroke", (d) => "white");

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
      .attr("fill", (d) => d.data.attributes.color || "white");

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
      .style("stroke", "white");

    // Add zoom and pan
    const zoom = d3
      .zoom()
      .scaleExtent([0.1, 4])
      .on("zoom", (event) => {
        g.attr("transform", event.transform);
        console.log(event.transform);
      });
    // @ts-ignore
    svg.call(zoom);

    // Compute the new scale and translate
    const x0 = 0;
    const y0 = 0;
    const x1 = 2 ** levels * dWidth;
    const y1 = levels * dHeight;
    const dx = x1 - x0;
    const dy = y1 - y0;
    const x = index >= 0 ? index * dWidth : (x0 + x1) / 2;
    const y = (y0 + y1) / 2;
    const scale = Math.max(
      1,
      Math.min(width / Math.abs(dx), height / Math.abs(dy))
    );
    const translate = [width / 2 - scale * x, height / 2 - scale * y];

    // Apply initial zoom
    svg.call(
      // @ts-ignore
      zoom.transform,
      d3.zoomIdentity.translate(translate[0], translate[1]).scale(1 / scale)
    );
  }, [data]);

  return (
    <div ref={divRef} style={{width: '100%', height: '100%'}}>
      <svg ref={ref} />
    </div>
  );
};
