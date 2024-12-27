# MIT License
#
# Copyright (c) 2024 Andrew Peck
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import os
import random

import cocotb
from cocotb.runner import get_runner
import pytest
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb_test.simulator import run

async def reset(dut):
    dut.rst.value = 1
    for _ in range(8):
        await RisingEdge(dut.clk)
    dut.rst.value = 0

@cocotb.test()
async def cell_sort_ascending(dut):
    await cell_sort_test(dut, "ascending")

@cocotb.test()
async def cell_sort_random(dut):
    await cell_sort_test(dut, "random")

async def cell_sort_test(dut, test):
    """Test for priority encoder with randomized data on all inputs"""

    cocotb.start_soon(Clock(dut.clk, 20, units="ns").start())  # Create a clock

    SORTB = dut.SORTB.value
    METAB = dut.METAB.value
    DEPTH = dut.DEPTH.value
    LATENCY = 3

    dut.new_data_valid_i.value = 1
    dut.new_data_i.value = 0
    await reset(dut)

    din_fifo = [0]*LATENCY
    data = [0]*DEPTH

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    for i in range(256):

        # generate a new sample, drive the input
        if test=="ascending":
            din = i
        elif test=="random":
            din = random.randint(0,2**SORTB - 1)
        else:
            raise ValueError(f"Invalid test {test} specified")
            din = 0

        dut.new_data_i.value = din
        din_fifo.append(din)

        # find the expected value
        din_prev = din_fifo.pop(0)
        data.append(din_prev)
        data.sort()
        data.pop(0)

        print(f"{i}, pushing {din_prev}")
        found = [int(x) for x in dut.new_data_o.value]
        expect = data
        print(f" > found  = {found}")
        print(f" > expect = {expect}")
        assert found == expect

        await RisingEdge(dut.clk)

@pytest.mark.parametrize("sortb", [8])
@pytest.mark.parametrize("metab", [0, 8])
@pytest.mark.parametrize("depth", [8, 16, 32])
def test_cell_sort(sortb, metab, depth):

    module = os.path.splitext(os.path.basename(__file__))[0]

    verilog_sources = [
        'cell_sort.sv',
        'unit_cell.sv',
    ]

    parameters = {}
    parameters['SORTB'] = sortb
    parameters['METAB'] = metab
    parameters['DEPTH'] = depth

    runner=get_runner("verilator")

    runner.build(
        verilog_sources=verilog_sources,
        vhdl_sources=[],
        hdl_toplevel="cell_sort",
        always=True,
        build_args=["--trace", "--trace-fst", "--trace-depth", "2"],
        parameters=parameters,
        )
    runner.test(
        hdl_toplevel="cell_sort",
        test_module=module,
        test_args=["--trace", "--trace-fst", "--trace-depth", "2"],
        gui=1
    )

if __name__ == "__main__":
    test_cell_sort(8,8,16)
