# SPDX-License-Identifier: Apache-2.0
"""Experiment 53: parking lot occupancy counter."""
import cocotb

from chiplab_helpers import PARKING_COUNTER, reset_manual, sample, step


SENSOR_A = 1 << 0
SENSOR_B = 1 << 1
ENABLE = 1 << 4
ENTERED = 1 << 4
EXITED = 1 << 5
ACTIVE = 1 << 6
INVALID = 1 << 7
BOTH = SENSOR_A | SENSOR_B
ENTRY = (SENSOR_A, BOTH, SENSOR_B, 0)
EXIT = (SENSOR_B, BOTH, SENSOR_A, 0)


async def crossing(dut, path, count, event):
    # A/B: entry 00 -> 10 -> 11 -> 01 -> 00; exit uses the reverse order.
    for sensors in path[:-1]:
        assert await step(dut, PARKING_COUNTER, ENABLE | sensors) == ACTIVE | count
        # A stopped vehicle must not count twice.
        assert await step(dut, PARKING_COUNTER, ENABLE | sensors) == ACTIVE | count

    expected = min(count + 1, 15) if event == ENTERED else max(count - 1, 0)
    assert await step(dut, PARKING_COUNTER, ENABLE) == event | expected
    assert await step(dut, PARKING_COUNTER, ENABLE) == expected
    return expected


@cocotb.test()
async def test_parking_counter(dut):
    await reset_manual(dut)
    assert await sample(dut, PARKING_COUNTER, 0) == 0

    # Fill and empty the lot, including saturation at both limits.
    count = 0
    for _ in range(17):
        count = await crossing(dut, ENTRY, count, ENTERED)
    for _ in range(17):
        count = await crossing(dut, EXIT, count, EXITED)

    # Turn back at each point, from either side: no complete crossing.
    for path in (ENTRY, EXIT):
        for depth in range(1, 4):
            outward = path[:depth]
            for sensors in (*outward, *reversed(outward[:-1])):
                assert await step(dut, PARKING_COUNTER, ENABLE | sensors) == ACTIVE
            assert await step(dut, PARKING_COUNTER, ENABLE) == 0

    # Skipped sensor steps discard the attempt until both sensors are clear.
    for path in ((BOTH,), (SENSOR_A, SENSOR_B), (SENSOR_B, SENSOR_A),
                 (SENSOR_A, BOTH, 0), (SENSOR_B, BOTH, 0),
                 (SENSOR_A, BOTH, SENSOR_B, SENSOR_A),
                 (SENSOR_B, BOTH, SENSOR_A, SENSOR_B)):
        for sensors in path:
            output = await step(dut, PARKING_COUNTER, ENABLE | sensors)
        assert output == INVALID | ACTIVE
        assert await step(dut, PARKING_COUNTER, ENABLE | BOTH) == INVALID | ACTIVE
        assert await step(dut, PARKING_COUNTER, ENABLE) == 0
    await crossing(dut, ENTRY, 0, ENTERED)

    # Disable and deselection pause a crossing; pulses clear after one clock.
    assert await step(dut, PARKING_COUNTER, ENABLE | SENSOR_A) == ACTIVE | 1
    assert await step(dut, PARKING_COUNTER, BOTH) == ACTIVE | 1
    await step(dut, 0, ENABLE | BOTH)
    assert await sample(dut, PARKING_COUNTER, 0) == ACTIVE | 1
    assert await step(dut, PARKING_COUNTER, ENABLE | BOTH) == ACTIVE | 1
    assert await step(dut, PARKING_COUNTER, ENABLE | SENSOR_B) == ACTIVE | 1
    assert await step(dut, PARKING_COUNTER, ENABLE) == ENTERED | 2
    assert await step(dut, PARKING_COUNTER, 0) == 2
    await crossing(dut, EXIT, 2, EXITED)

    # Reset aborts an incomplete crossing and clears occupancy.
    await step(dut, PARKING_COUNTER, ENABLE | SENSOR_A)
    await reset_manual(dut)
    assert await sample(dut, PARKING_COUNTER, 0) == 0
