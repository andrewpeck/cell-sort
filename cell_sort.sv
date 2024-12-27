// MIT License
//
// Copyright (c) 2024 Andrew Peck
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

`resetall
`timescale 1ns / 1ps
`default_nettype none

module cell_sort # (
  int SORTB = 8,
  int METAB = 32,
  int DEPTH = 8,
  int REV   = 0
) (
  input wire             clk,
  input wire             rst,

  // common data input
  input wire [SORTB-1:0] data_i,
  input wire [METAB-1:0] metadata_i,
  input wire             dav_i,

  output reg [SORTB-1:0] data_o [DEPTH],
  output reg [METAB-1:0] metadata_o [DEPTH]
);

  wire [0:0]       push [DEPTH+1];
  wire [SORTB-1:0] data [DEPTH+1];
  wire [METAB-1:0] metadata [DEPTH+1];

  assign push[DEPTH] = 0; // the "best" cell never gets pushed into

  // output
  always_ff @(posedge clk) begin
    for (int i=0; i<DEPTH; i=i+1) begin
      data_o[i] <= data[i];
      metadata_o[i] <= metadata[i];
    end
  end

  generate begin : gen_sorters
    for (genvar i=1; i<DEPTH+1; i=i+1) begin : gen_i

      unit_cell #(
        .SORTB    (SORTB),
        .METAB    (METAB),
        .REV      (REV)
      ) u_cell (
        .clk                 (clk),
        .rst                 (rst),

        // data inputs
        .data_i              (data_i),
        .metadata_i          (metadata_i),
        .dav_i               (dav_i),

        // data inputs
        .neighbor_data_i     (data[i]),
        .neighbor_metadata_i (metadata[i]),
        .neighbor_push_i     (push[i]),

        // data outputs
        .neighbor_data_o     (data[i-1]),
        .neighbor_metadata_o (metadata[i-1]),
        .neighbor_push_o     (push[i-1]));

    end
  end
  endgenerate

endmodule
