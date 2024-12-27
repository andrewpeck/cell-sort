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

module unit_cell # (
  int SORTB = 8,
  int METAB = 32,
  int REV   = 0
) (
  input wire              clk,
  input wire              rst,

  // common data input
  input wire [SORTB-1:0]  data_i,
  input wire [METAB-1:0]  metadata_i,
  input wire              dav_i,

  // cell to cell comms in
  input wire [SORTB-1:0]  neighbor_data_i,
  input wire [METAB-1:0]  neighbor_metadata_i,
  input wire              neighbor_push_i,

  // cell to cell comms out
  output wire [SORTB-1:0] neighbor_data_o,
  output wire [METAB-1:0] neighbor_metadata_o,
  output wire             neighbor_push_o

);

  logic [SORTB-1:0] data;
  logic [METAB-1:0] metadata;
  wire              comparator = REV == 0 ? (data_i > data) : (data_i < data);

  assign neighbor_push_o = comparator;
  assign neighbor_data_o = data;
  assign neighbor_metadata_o = metadata;

  always_ff @(posedge clk) begin

    if (dav_i) begin
      if (neighbor_push_i)  begin
        data     <= neighbor_data_i;
        metadata <= neighbor_metadata_i;
      end else if (comparator) begin
        data     <= data_i;
        metadata <= metadata_i;
      end
    end

    if (rst) begin
      data     <= REV == 0 ? 0 : ~0;
      metadata <= 0;
    end
  end

endmodule
